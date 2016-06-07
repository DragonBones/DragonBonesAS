package dragonBones
{
	import dragonBones.animation.Animation;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.IAnimateble;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.IArmatureDisplayContainer;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	import dragonBones.events.IEventDispatcher;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.SkinData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 骨架，是龙骨骨骼动画系统的核心，由显示容器、骨骼、插槽、动画、事件系统构成。
     * @see dragonBones.objects.ArmatureData
     * @see dragonBones.Bone
     * @see dragonBones.Slot
     * @see dragonBones.animation.Animation
     * @see dragonBones.core.IArmatureDisplayContainer
	 * @version DragonBones 3.0
	 */
	public final class Armature extends BaseObject implements IAnimateble
	{
		/**
		 * @language zh_CN
		 * 声音事件管理器，声音事件统一由声音事件管理器派发。
		 * @version DragonBones 3.0
		 */
		public static const soundEventManager:IEventDispatcher = null;
		
		/**
		 * @language zh_CN
		 * 可以用于存储临时数据。
		 * @version DragonBones 3.0
		 */
		public var userData:Object;
		
		/**
		 * @private Bone
		 */
		dragonBones_internal var _bonesDirty:Boolean;
		
		/**
		 * @private AnimationState
		 */
		dragonBones_internal var _cacheFrameIndex:int;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _armatureData:ArmatureData;
		
		/**
		 * @private Factory AnimationState
		 */
		dragonBones_internal var _skinData:SkinData;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _animation:Animation;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _display:IArmatureDisplayContainer;
		
		/**
		 * @private Slot
		 */
		dragonBones_internal var _replaceTexture:Object;
		
		/**
		 * @private Slot
		 */
		dragonBones_internal var _parent:Slot;
		
		/**
		 * @private AnimationTimelineState
		 */
		dragonBones_internal var _action:ActionData;
		
		/**
		 * @private
		 */
		private var _delayDispose:Boolean;
		
		/**
		 * @private
		 */
		private var _lockEvent:Boolean;
		
		/**
		 * @private
		 */
		private var _slotsDirty:Boolean;
		
		/**
		 * @private Store bones based on bones' hierarchy (From root to leaf)
		 */
		private const _bones:Vector.<Bone> = new Vector.<Bone>(0, true);
		
		/**
		 * @private Store slots based on slots' zOrder (From low to high)
		 */
		private const _slots:Vector.<Slot> = new Vector.<Slot>(0, true);
		
		/**
		 * @private
		 */
		private const _events:Vector.<EventObject> = new Vector.<EventObject>;
		
		/**
		 * @private
		 */
		public function Armature()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			userData = null;
			
			_bonesDirty = false;
			_cacheFrameIndex = -1;
			_armatureData = null;
			_skinData = null;
			
			if (_animation)
			{
				_animation.returnToPool();
				_animation = null;
			}
			
			_display = null;
			_replaceTexture = null;
			_parent = null;
			_action = null;
			
			_delayDispose = false;
			_lockEvent = false;
			_slotsDirty = false;
			
			if (_bones.length)
			{
				for each (var bone:Bone in _bones)
				{
					bone.returnToPool();
				}
				
				_bones.fixed = false;
				_bones.length = 0;
				_bones.fixed = true;
			}
			
			if (_slots.length)
			{
				for each (var slot:Slot in _slots)
				{
					slot.returnToPool();
				}
				
				_slots.fixed = false;
				_slots.length = 0;
				_slots.fixed = true;
			}
			
			if (_events.length)
			{
				for each (var event:EventObject in _events)
				{
					slot.returnToPool();
				}
				
				_events.fixed = false;
				_events.length = 0;
				_events.fixed = true;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			_delayDispose = true;
		}
		
		/**
		 * @private
		 */
		private function _sortBones():void
		{
			const total:uint = _bones.length;
			if (!total)
			{
				return;
			}
			
			const sortHelper:Vector.<Bone> = _bones.concat();
			var index:uint = 0;
			var count:uint = 0;
			
			_bones.length = 0; // clear
			_bones.length = total;
			while(count < total)
			{
				const bone:Bone = sortHelper[index++];
				
				if (index >= total)
				{
					index = 0;
				}
				
				if (_bones.indexOf(bone) >= 0)
				{
					continue;
				}
				
				if (bone.parent && _bones.indexOf(bone.parent) < 0)
				{
					continue;
				}
				
				if (bone.ik && _bones.indexOf(bone.ik) < 0)
				{
					continue;
				}
				
				if (bone.ik && bone.ikChain > 0 && bone.ikChainIndex == bone.ikChain)
				{
					_bones.splice(_bones.indexOf(bone.parent) + 1, 0, bone); // ik, parent, bone, children
					count++;
				}
				else
				{
					_bones[count++] = bone;
				}
			}
			
			_bones.length = total; // Modify splice
		}
		
		/**
		 * @private
		 */
		private function _sortSlots():void
		{
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _addBoneToBoneList(value:Bone):void
		{
			if (_bones.indexOf(value) < 0)
			{
				_bonesDirty = true;
				_bones.fixed = false;
				_bones[_bones.length] = value;
				_animation._timelineStateDirty = true;
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _removeBoneFromBoneList(value:Bone):void
		{
			var index:int = _bones.indexOf(value);
			if (index >= 0)
			{
				_bones.fixed = false;
				_bones.splice(index, 1);
				_bones.fixed = true;
				_animation._timelineStateDirty = true;
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _addSlotToSlotList(value:Slot):void
		{
			if (_slots.indexOf(value) < 0)
			{
				_slotsDirty = true;
				_slots.fixed = false;
				_slots[_slots.length] = value;
				_animation._timelineStateDirty = true;
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _removeSlotFromSlotList(value:Slot):void
		{
			var index:int = _slots.indexOf(value);
			if (index >= 0)
			{
				_slots.fixed = false;
				_slots.splice(index, 1);
				_slots.fixed = true;
				_animation._timelineStateDirty = true;
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _bufferEvent(value:EventObject, type:String):void
		{
			value.type = type;
			value.armature = this;
			_events.push(value);
		}
		
		/**
		 * Update the animation using this method typically in an ENTERFRAME Event or with a Timer.
		 * @param The amount of second to move the playhead ahead.
		 */
		public function advanceTime(passedTime:Number):void
		{
			const scaledPassedTime:Number = passedTime * _animation.timeScale;
			
			//
			_animation._advanceTime(passedTime);
			
			//
			if (_bonesDirty)
			{
				_bonesDirty = false;
				_sortBones();
				_bones.fixed = true;
			}
			
			if (_slotsDirty)
			{
				_slotsDirty = false;
				_sortSlots();
				_slots.fixed = true;
			}
			
			//
			var i:uint = 0, l:uint = 0;
			
			for (i = 0, l = _bones.length; i < l; ++i)
			{
				_bones[i]._update(_cacheFrameIndex);
			}
			
			for (i = 0, l = _slots.length; i < l; ++i)
			{
				const slot:Slot = _slots[i];
				
				slot._update(_cacheFrameIndex);
				
				const childArmature:Armature = slot.childArmature;
				if (childArmature)
				{
					if (slot.inheritAnimation) // Animation's time scale will impact to childArmature
					{
						childArmature.advanceTime(scaledPassedTime);
					}
					else
					{
						childArmature.advanceTime(passedTime);
					}
				}
			}
			
			//
			if (!_lockEvent && _events.length > 0)
			{
				_lockEvent = true;
				
				for (i = 0, l = _events.length; i < l; ++i)
				{
					const event:EventObject = _events[i];
					
					if (soundEventManager && event.type == EventObject.SOUND_EVENT)
					{
						soundEventManager._dispatchEvent(event);
					}
					else
					{
						_display._dispatchEvent(event);
					}
					
					event.returnToPool();
				}
				
				_events.length = 0;
				
				_lockEvent = false;
			}
			
			if (_action)
			{
				switch (_action.type)
				{
					case DragonBones.ACTION_TYPE_PLAY:
						_animation.play(_action.data[0], _action.data[1]);
						break;
					
					case DragonBones.ACTION_TYPE_STOP:
						const animationName:String = _action.data[0];
						if (animationName)
						{
							const animationState:AnimationState = _animation.getState(animationName);
							if (animationState)
							{
								animationState.stop();
							}
						}
						else
						{
							_animation.stop();
						}
						break;
					
					case DragonBones.ACTION_TYPE_GOTO_AND_PLAY:
						_animation.gotoAndPlayWithTime(_action.data[0], _action.data[1], _action.data[2]);
						break;
					
					case DragonBones.ACTION_TYPE_GOTO_AND_STOP:
						_animation.gotoAndStopWithTime(_action.data[0], _action.data[1]);
						break;
					
					case DragonBones.ACTION_TYPE_FADE_IN:
						_animation.fadeIn(_action.data[0], _action.data[1], _action.data[2]);
						break;
					
					case DragonBones.ACTION_TYPE_FADE_OUT:
						// TODO
						break;
				}
				
				_action = null;
			}
			
			if (_delayDispose)
			{
				this._onClear();
			}
		}
		
		/**
		 * Force update bones and slots. (When bone's animation play complete, it will not update.) 
		 */
		public function invalidUpdate(boneName:String = null):void
		{
			if (boneName)
			{
				const bone:Bone = getBone(boneName);
				
				if (bone)
				{
					bone.invalidUpdate();
				}
			}
			else
			{
				for each(var eachBone:Bone in _bones)
				{
					eachBone.invalidUpdate();
				}
			}
		}
		
		/**
		 * Retrieves a Slot by name
		 * @param The name of the Bone to retrieve.
		 * @return A Slot instance or null if no Slot with that name exist.
		 * @see dragonBones.Slot
		 */
		public function getSlot(name:String):Slot
		{
			for each(var slot:Slot in _slots)
			{
				if (slot.name == name)
				{
					return slot;
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
			for each(var slot:Slot in _slots)
			{
				if (slot.display == display)
				{
					return slot;
				}
			}
			
			return null;
		}
		
		/**
		 * Add a slot to a bone as child.
		 * @param slot A Slot instance
		 * @param boneName bone name
		 * @see dragonBones.core.DBObject
		 */
		public function addSlot(value:Slot, boneName:String):void
		{
			const bone:Bone = getBone(boneName);
			if (bone)
			{
				value._setArmature(this);
				value._setParent(bone);
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * Remove a Slot instance from this Armature instance.
		 * @param The Slot instance to remove.
		 * @see dragonBones.Slot
		 */
		public function removeSlot(value:Slot):void
		{
			if (value && value.armature == this)
			{
				value._setParent(null);
				value._setArmature(null);
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * Retrieves a Bone by name
		 * @param The name of the Bone to retrieve.
		 * @return A Bone instance or null if no Bone with that name exist.
		 * @see dragonBones.Bone
		 */
		public function getBone(name:String):Bone
		{
			for each(var bone:Bone in _bones)
			{
				if (bone.name == name)
				{
					return bone;
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
			const slot:Slot = getSlotByDisplay(display);
			
			return slot? slot.parent: null;
		}
		
		/**
		 * @language zh_CN
		 * 将一个指定的骨骼添加到骨架中。
		 * @param bone 需要添加的骨骼。
		 * @param parentName 需要添加到指定的父骨骼的名称，如果未指定名称则添加到骨架根部。 (默认: <code>null</code>)
		 * @see	dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function addBone(value:Bone, parentName:String = null):void
		{
			if (value)
			{
				value._setArmature(this);
				value._setParent(parentName? getBone(parentName): null);
			}
			else
			{
				throw new ArgumentError();
			}
			
		}
		
		/**
		 * @language zh_CN
		 * 将一个指定的骨骼从骨架中移除。
		 * @param bone 需要移除的骨骼
		 * @see	dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function removeBone(value:Bone):void
		{
			if (value && value.armature == this)
			{
				value._setParent(null);
				value._setArmature(null);
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * @language zh_CN
		 * 替换骨架的主贴图，根据渲染引擎的不同，提供不同的贴图数据。
		 * @see dragonBones.Bone
		 * @version DragonBones 4.5
		 */
		public function setReplaceTexture(texture:Object):void
		{
			_replaceTexture = texture;
			for each (var slot:Slot in _slots)
			{
				slot.invalidUpdate();
			}
		}
		
		/**
		 * @language zh_CN
		 * 获得该骨架所有骨骼的列表，注意这里返回的是直接引用。
		 * @see dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function getBones():Vector.<Bone>
		{
			return _bones;
		}
		
		/**
		 * @language zh_CN
		 * 获得此骨架所有插槽的列表，注意这里返回的是直接引用。
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function getSlots():Vector.<Slot>
		{
			return _slots;
		}
		
		/**
		 * @language zh_CN
		 * 骨架名称。
		 * @see dragonBones.objects.ArmatureData#name
		 * @version DragonBones 3.0
		 */
		public function get name():String
		{
			return _armatureData? _armatureData.name: null;
		}
		
		/**
		 * @language zh_CN
		 * 获得骨架数据。
    	 * @see dragonBones.objects.ArmatureData
		 * @version DragonBones 4.5
		 */
		public function get armatureData():ArmatureData
		{
			return _armatureData;
		}
		
		/**
		 * @language zh_CN
		 * 获得显示容器，插槽的显示对象都会以此显示容器为父级，根据渲染平台的不同，类型会不同，通常是 DisplayObjectContainer 类型。
		 * @version DragonBones 3.0
		 */
		public function get display():IArmatureDisplayContainer
		{
			return _display;
		}
		
		/**
		 * @language zh_CN
		 * 获得父插槽实例。
    	 * @see dragonBones.Slot
		 * @version DragonBones 4.5
		 */
		public function get parent():Slot
		{
			return _parent;
		}
		
		/**
		 * @language zh_CN
		 * 获得动画控制器实例。
    	 * @see dragonBones.animation.Animation
		 * @version DragonBones 3.0
		 */
		public function get animation():Animation	
		{
			return _animation;
		}
		
		/**
		 * @language zh_CN
		 * 动画缓存的帧率，当设置一个大于 0 的帧率时，将会开启动画缓存机制。
		 * 通过将动画数据缓存在内存中来提高运行性能，会有一定的内存开销。
		 * 帧率不宜设置的过高，通常跟动画的帧率相当且低于程序的帧率。
		 * 开启动画缓存后，某些功能将会失效，比如 Bone 和 Slot 的 offset 属性等。
		 * @see dragonBones.objects.DragonBonesData#frameRate
		 * @see dragonBones.objects.ArmatureData#frameRate
		 * @version DragonBones 4.0
		 */
		public function get cacheFrameRate():uint
		{
			return _armatureData.cacheFrameRate;
		}
		public function set cacheFrameRate(value:uint):void
		{
			if (_armatureData.cacheFrameRate == value)
			{
				return;
			}
			
			_armatureData.cacheFrames(value);
		}
		
		/**
		 * @language zh_CN
		 * 添加事件。
		 * @param type 事件类型。
		 * @version DragonBones 3.0
		 */
		public function hasEventListener(type:String):void
		{
			_display.hasEvent(type);
		}
		
		/**
		 * @language zh_CN
		 * 添加事件。
		 * @param type 事件类型。
		 * @param listener 事件监听。
		 * @version DragonBones 3.0
		 */
		public function addEventListener(type:String, listener:Function):void
		{
			_display.addEvent(type, listener);
		}
		
		/**
		 * @language zh_CN
		 * 移除事件。
		 * @param type 事件类型。
		 * @param listener 事件监听。
		 * @version DragonBones 3.0
		 */
		public function removeEventListener(type:String, listener:Function):void
		{
			_display.removeEvent(type, listener);
		}
	}
}