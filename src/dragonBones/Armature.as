package dragonBones
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.ColorTransform;

	import dragonBones.animation.Animation;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.IAnimatable;
	import dragonBones.animation.TimelineState;
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.ArmatureEvent;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;

	use namespace dragonBones_internal;

	/**
	 * 当slot的zOrder发生改变时触发
	 */
	[Event(name="zOrderUpdated", type="dragonBones.events.ArmatureEvent")]

	/**
	 * 当AnimationState开始混合淡入时触发（即使混合时间设置为0，仍然触发）
	 */
	[Event(name="fadeIn", type="dragonBones.events.AnimationEvent")]

	/**
	 * 当AnimationState开始混合淡出时触发（即使混合时间设置为0，仍然触发）
	 */
	[Event(name="fadeOut", type="dragonBones.events.AnimationEvent")]

	/**
	 * 当AnimationState开始播放时触发（AnimationState并不一定会在混合淡入开始时开始播放，可以通过设置使AnimationState在混合淡入结束时才开始播放）
	 */
	[Event(name="start", type="dragonBones.events.AnimationEvent")]

	/**
	 * 当AnimationState完全播放完毕后触发（如果AnimationState的播放次数设置为0，即无限循环，则不会触发）
	 */
	[Event(name="complete", type="dragonBones.events.AnimationEvent")]

	/**
	 * 当AnimationState结束一次循环时触发
	 */
	[Event(name="loopComplete", type="dragonBones.events.AnimationEvent")]

	/**
	 * 当AnimationState混合淡入结束时触发
	 */
	[Event(name="fadeInComplete", type="dragonBones.events.AnimationEvent")]

	/**
	 * 当AnimationState混合淡出结束时触发
	 */
	[Event(name="fadeOutComplete", type="dragonBones.events.AnimationEvent")]

	/**
	 * 当AnimationState进入一个事件关键帧时触发
	 */
	[Event(name="animationFrameEvent", type="dragonBones.events.FrameEvent")]

	/**
	 * 当Bone进入一个事件关键帧时触发
	 */
	[Event(name="boneFrameEvent", type="dragonBones.events.FrameEvent")]

	public class Armature extends EventDispatcher implements IAnimatable
	{
		/**
		 * 派发声音事件的单例
		 */
		private static const _soundManager:SoundEventManager = SoundEventManager.getInstance();

		/**
		 * 名字，与ArmatureData的name一致
		 */
		public var name:String;

		/**
		 * An object that can contain any user extra data.
		 */
		public var userData:Object;

		/** @private 当slot的zOrder发生改变时，需要设置此属性为 true*/
		dragonBones_internal var _slotsZOrderChanged:Boolean;
		/** @private 存储slot，顺序按照slot的zOrder升序排列*/
		dragonBones_internal var _slotList:Vector.<Slot>;
		/** @private 存储bone，顺序按照bone的从属关系从根向叶排列*/
		dragonBones_internal var _boneList:Vector.<Bone>;
		/** @private 临时存储每帧需要触发的事件，当advanceTime将要结束时，按顺序触发*/
		dragonBones_internal var _eventList:Vector.<Event>;

		/** @private 强制对bone和slot进行更新*/
		protected var _needUpdate:Boolean;

		/** @private */
		protected var _display:Object;
		/**
		 * Armature的显示对象，此对象的类型与使用的渲染引擎有直接的关系，比如flash.display.DisplayObject或startling.display.DisplayObject或其他第三方渲染引擎的显示对象
		 * Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 */
		public function get display():Object
		{
			return _display;
		}

		/** @private */
		protected var _animation:Animation;
		/**
		 * An Animation instance
		 * @see dragonBones.animation.Animation
		 */
		public function get animation():Animation
		{
			return _animation;
		}

		/**
		 * Creates a Armature blank instance.
		 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 * @see #display
		 */
		public function Armature(display:Object)
		{
			super(this);
			_display = display;
			
			_animation = new Animation(this);
			_slotsZOrderChanged = false;
			
			_slotList = new Vector.<Slot>;
			_slotList.fixed = true;
			_boneList = new Vector.<Bone>;
			_boneList.fixed = true;
			_eventList = new Vector.<Event>;
			
			_needUpdate = false;
		}
		
		/**
		 * Cleans up any resources used by this instance.
		 */
		public function dispose():void
		{
			if(!_animation)
			{
				return;
			}
			
			userData = null;
			
			_animation.dispose();
			
			for each(var slot:Slot in _slotList)
			{
				slot.dispose();
			}
			
			for each(var bone:Bone in _boneList)
			{
				bone.dispose();
			}
			
			_slotList.fixed = false;
			_slotList.length = 0;
			_boneList.fixed = false;
			_boneList.length = 0;
			_eventList.length = 0;
			
			_animation = null;
			_slotList = null;
			_boneList = null;
			_eventList = null;
			
			//_display = null;
		}
		
		/**
		 * 强制对bone和slot进行更新，当bone的动画结束时，bone将不会再更新（如果动态设置bone或属于此bone的slot的属性时，将不会在armature.advanceTime中得到任何改变）
		 */
		public function invalidUpdate():void
		{
			_needUpdate = true;
		}
		
		/**
		 * Update the animation using this method typically in an ENTERFRAME Event or with a Timer.
		 * @param The amount of second to move the playhead ahead.
		 */
		public function advanceTime(passedTime:Number):void
		{
			var i:int;
			var slot:Slot;
			var childArmature:Armature;
			
			if(_animation.isPlaying || _needUpdate) //当动画播放时或_needUpdate为true时，才会对bone和slot进行更新
			{	
				_needUpdate = false;
				_animation.advanceTime(passedTime);
				
				passedTime *= _animation.timeScale;//_animation的时间缩放会对childArmature产生影响
				
				i = _boneList.length;
				while(i --)
				{
					_boneList[i].update();
				}
				
				i = _slotList.length;
				while(i --)
				{
					slot = _slotList[i];
					slot.update();
					if(slot._isDisplayOnStage)
					{
						childArmature = slot.childArmature;
						if(childArmature)
						{
							childArmature.advanceTime(passedTime);
						}
					}
				}
				
				if(_slotsZOrderChanged)
				{
					updateSlotsZOrder();
					
					if(this.hasEventListener(ArmatureEvent.Z_ORDER_UPDATED))
					{
						this.dispatchEvent(new ArmatureEvent(ArmatureEvent.Z_ORDER_UPDATED));
					}
				}
				
				if(_eventList.length)
				{
					for each(var event:Event in _eventList)
					{
						this.dispatchEvent(event);
					}
					if(_eventList) //如果事件引起了armature.dispose()则，_eventList将不可再访问，或许应再派发事件前对_eventList进行复制，不知道有没有必要
					{
						_eventList.length = 0;
					}
				}
			}
			else //依然要对childArmature进行更新
			{
				passedTime *= _animation.timeScale;
				i = _slotList.length;
				while(i --)
				{
					slot = _slotList[i];
					if(slot._isDisplayOnStage)
					{
						childArmature = slot.childArmature;
						if(childArmature)
						{
							childArmature.advanceTime(passedTime);
						}
					}
				}
			}
		}

		/**
		 * Get all Slot instance associated with this armature.
		 * @param 是否返回Vector的副本
		 * @return A Vector.&lt;Slot&gt; instance.
		 * @see dragonBones.Slot
		 */
		public function getSlots(returnCopy:Boolean = true):Vector.<Slot>
		{
			return returnCopy?_slotList.concat():_slotList;
		}

		/**
		 * Get all Bone instance associated with this armature.
		 * @param 是否返回Vector的副本
		 * @return A Vector.&lt;Bone&gt; instance.
		 * @see dragonBones.Bone
		 */
		public function getBones(returnCopy:Boolean = true):Vector.<Bone>
		{
			return returnCopy?_boneList.concat():_boneList;
		}

		/**
		 * Retrieves a Slot by name
		 * @param The name of the Bone to retrieve.
		 * @return A Slot instance or null if no Slot with that name exist.
		 * @see dragonBones.Slot
		 */
		public function getSlot(slotName:String):Slot
		{
			var i:int = _slotList.length;
			while(i --)
			{
				if(_slotList[i].name == slotName)
				{
					return _slotList[i];
				}
			}
			return null;
		}

		/**
		 * Gets the Slot associated with this DisplayObject.
		 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 * @return A Slot instance or null if no Slot with that DisplayObject exist.
		 * @see dragonBones.Slot
		 */
		public function getSlotByDisplay(display:Object):Slot
		{
			if(display)
			{
				var i:int = _slotList.length;
				while(i --)
				{
					if(_slotList[i].display == display)
					{
						return _slotList[i];
					}
				}
			}
			return null;
		}

		/**
		 * Remove a Slot instance from this Armature instance.
		 * @param The Slot instance to remove.
		 * @see dragonBones.Slot
		 */
		public function removeSlot(slot:Slot):void
		{
			if(!slot)
			{
				throw new ArgumentError();
			}
			
			if(_slotList.indexOf(slot) >= 0)
			{
				slot.parent.removeChild(slot);
			}
			else
			{
				throw new ArgumentError();
			}
		}

		/**
		 * Remove a Slot instance from this Armature instance.
		 * @param The name of the Slot instance to remove.
		 * @see dragonBones.Slot
		 */
		public function removeSlotByName(slotName:String):void
		{
			if(!slotName)
			{
				return;
			}
			
			var slot:Slot = getSlot(slotName);
			if(slot)
			{
				removeSlot(slot);
			}
		}

		/**
		 * Retrieves a Bone by name
		 * @param The name of the Bone to retrieve.
		 * @return A Bone instance or null if no Bone with that name exist.
		 * @see dragonBones.Bone
		 */
		public function getBone(boneName:String):Bone
		{
			var i:int = _boneList.length;
			while(i --)
			{
				if(_boneList[i].name == boneName)
				{
					return _boneList[i];
				}
			}
			return null;
		}

		/**
		 * Gets the Bone associated with this DisplayObject.
		 * @param Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 * @return A Bone instance or null if no Bone with that DisplayObject exist..
		 * @see dragonBones.Bone
		 */
		public function getBoneByDisplay(display:Object):Bone
		{
			var slot:Slot = getSlotByDisplay(display);
			return slot?slot.parent:null;
		}

		/**
		 * Remove a Bone instance from this Armature instance.
		 * @param The Bone instance to remove.
		 * @see	dragonBones.Bone
		 */
		public function removeBone(bone:Bone):void
		{
			if(!bone)
			{
				throw new ArgumentError();
			}
			
			if(_boneList.indexOf(bone) >= 0)
			{
				if(bone.parent)
				{
					bone.parent.removeChild(bone);
				}
				else
				{
					bone.setArmature(null);
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}

		/**
		 * Remove a Bone instance from this Armature instance.
		 * @param The name of the Bone instance to remove.
		 * @see dragonBones.Bone
		 */
		public function removeBoneByName(boneName:String):void
		{
			if(!boneName)
			{
				return;
			}
			
			var bone:Bone = getBone(boneName);
			if(bone)
			{
				removeBone(bone);
			}
		}


		/**
		 * Add a DBObject instance to this Armature instance.
		 * @param A DBObject instance.
		 * @param (optional) The parent's name of this DBObject instance.
		 * @see dragonBones.core.DBObject
		 */
		public function addChild(object:DBObject, parentName:String = null):void
		{
			if(!object)
			{
				throw new ArgumentError();
			}
			
			if(parentName)
			{
				var boneParent:Bone = getBone(parentName);
				if (boneParent)
				{
					boneParent.addChild(object);
				}
				else
				{
					throw new ArgumentError();
				}
			}
			else
			{
				if(object.parent)
				{
					object.parent.removeChild(object);
				}
				object.setArmature(this);
			}
		}

		/**
		 * Add a Bone instance to this Armature instance.
		 * @param A Bone instance.
		 * @param (optional) The parent's name of this Bone instance.
		 * @see dragonBones.Bone
		 */
		public function addBone(bone:Bone, parentName:String = null):void
		{
			addChild(bone, parentName);
		}

		/**
		 * 按照zOrder的升序重新排列所有slot
		 */
		public function updateSlotsZOrder():void
		{
			_slotList.fixed = false;
			_slotList.sort(sortSlot);
			_slotList.fixed = true;
			var i:int = _slotList.length;
			var slot:Slot;
			while(i --)
			{
				slot = _slotList[i];
				if(slot._isDisplayOnStage)
				{
					slot._displayBridge.addDisplay(display);
				}
			}
			
			_slotsZOrderChanged = false;
		}

		/** @private */
		dragonBones_internal function addDBObject(object:DBObject):void
		{
			if(object is Slot)
			{
				var slot:Slot = object as Slot;
				if(_slotList.indexOf(slot) < 0)
				{
					_slotList.fixed = false;
					_slotList[_slotList.length] = slot;
					_slotList.fixed = true;
				}
			}
			else if(object is Bone)
			{
				var bone:Bone = object as Bone;
				if(_boneList.indexOf(bone) < 0)
				{
					_boneList.fixed = false;
					_boneList[_boneList.length] = bone;
					sortBoneList();
					_boneList.fixed = true;
				}
			}
		}

		/** @private */
		dragonBones_internal function removeDBObject(object:DBObject):void
		{
			if(object is Slot)
			{
				var slot:Slot = object as Slot;
				var index:int = _slotList.indexOf(slot);
				if(index >= 0)
				{
					_slotList.fixed = false;
					_slotList.splice(index, 1);
					_slotList.fixed = true;
				}
			}
			else if(object is Bone)
			{
				var bone:Bone = object as Bone;
				index = _boneList.indexOf(bone);
				if(index >= 0)
				{
					_boneList.fixed = false;
					_boneList.splice(index, 1);
					_boneList.fixed = true;
				}
			}
		}

		private const _helpArray:Array = [];
		/** @private */
		dragonBones_internal function sortBoneList():void
		{
			var i:int = _boneList.length;
			if(i == 0)
			{
				return;
			}
			_helpArray.length = 0;
			var level:int;
			var bone:Bone;
			var boneParent:Bone;
			while(i --)
			{
				level = 0;
				bone = _boneList[i];
				boneParent = bone;
				while(boneParent)
				{
					level ++;
					boneParent = boneParent.parent;
				}
				_helpArray[i] = {level:level, bone:bone};
			}
			
			_helpArray.sortOn("level", Array.NUMERIC|Array.DESCENDING);
			
			i = _helpArray.length;
			while(i --)
			{
				_boneList[i] = _helpArray[i].bone;
			}
			_helpArray.length = 0;
		}

		/** @private 当AnimationState到达关键帧时，会调用此方法*/
		dragonBones_internal function arriveAtFrame(frame:Frame, timelineState:TimelineState, animationState:AnimationState, isCross:Boolean):void
		{
			if(frame.event && this.hasEventListener(FrameEvent.ANIMATION_FRAME_EVENT))
			{
				var frameEvent:FrameEvent = new FrameEvent(FrameEvent.ANIMATION_FRAME_EVENT);
				frameEvent.animationState = animationState;
				frameEvent.frameLabel = frame.event;
				_eventList.push(frameEvent);
			}
			
			if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
			{
				var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
				soundEvent.armature = this;
				soundEvent.animationState = animationState;
				soundEvent.sound = frame.sound;
				_soundManager.dispatchEvent(soundEvent);
			}
			
			if(frame.action)
			{
				if(animationState.isPlaying)
				{
					animation.gotoAndPlay(frame.action);
				}
			}
		}

		private function sortSlot(slot1:Slot, slot2:Slot):int
		{
			return slot1.zOrder < slot2.zOrder?1: -1;
		}

	}
}
