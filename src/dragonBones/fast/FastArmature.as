package dragonBones.fast
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import dragonBones.animation.IAnimatable;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.fast.animation.FastAnimation;
	import dragonBones.fast.animation.FastAnimationState;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.DragonBonesData;
	import dragonBones.objects.Frame;

	use namespace dragonBones_internal;
	
	/**
	 * 无法换肤
	 */
	public class FastArmature extends EventDispatcher implements IAnimatable
	{
		/**
		 * The name should be same with ArmatureData's name
		 */
		public var name:String;
		/**
		 * An object that can contain any user extra data.
		 */
		public var userData:Object;
		
		/** @private */
		protected var _animation:FastAnimation;
		
		/** @private */
		protected var _display:Object;
		
		/** @private Store bones based on bones' hierarchy (From root to leaf)*/
		public var boneList:Vector.<FastBone>;
		protected var _boneDic:Object;
		
		/** @private Store slots based on slots' zOrder*/
		public var slotList:Vector.<FastSlot>;
		protected var _slotDic:Object;
		
		public var slotHasChildArmatureList:Vector.<FastSlot>;
		
		dragonBones_internal var __dragonBonesData:DragonBonesData;
		dragonBones_internal var _armatureData:ArmatureData;
		dragonBones_internal var _slotsZOrderChanged:Boolean;
		dragonBones_internal var _eventList:Vector.<Event>;
		
		private var _delayDispose:Boolean;
		private var _lockDispose:Boolean;
		
		public function FastArmature(display:Object)
		{
			super(this);
			_display = display;
			_animation = new FastAnimation(this);
			_slotsZOrderChanged = false;
			_armatureData = null;
			
			boneList = new Vector.<FastBone>;
			_boneDic = {};
			slotList = new Vector.<FastSlot>;
			_slotDic = {};
			slotHasChildArmatureList = new Vector.<FastSlot>;
			
			_delayDispose = false;
			_lockDispose = false;
			
		}
		
		/**
		 * Cleans up any resources used by this instance.
		 */
		public function dispose():void
		{
			_delayDispose = true;
			if(!_animation || _lockDispose)
			{
				return;
			}
			
			userData = null;
			
			_animation.dispose();
			var i:int = slotList.length;
			while(i --)
			{
				slotList[i].dispose();
			}
			i = boneList.length;
			while(i --)
			{
				boneList[i].dispose();
			}
			
			slotList.fixed = false;
			slotList.length = 0;
			boneList.fixed = false;
			boneList.length = 0;
			_eventList.length = 0;
			
			_armatureData = null;
			_animation = null;
			slotList = null;
			boneList = null;
			_eventList = null;
			
		}
		
		/**
		 * Update the animation using this method typically in an ENTERFRAME Event or with a Timer.
		 * @param The amount of second to move the playhead ahead.
		 */
		public function advanceTime(passedTime:Number):void
		{
			_lockDispose = true;
			_animation.advanceTime(passedTime);
			
			var bone:FastBone;
			var slot:FastSlot;
			var i:int = boneList.length;
			while(i --)
			{
				bone = boneList[i];
				bone.update();
			}
			
			i = slotList.length;
			while(i --)
			{
				slot = slotList[i];
				slot.update();
			}
			
			i = slotHasChildArmatureList.length;
			while(i--)
			{
				slot = slotList[i];
				if(slot._isShowDisplay)
				{
					var childArmature:FastArmature = slot.childArmature;
					if(childArmature)
					{
						childArmature.advanceTime(passedTime);
					}
				}
			}
			
			_lockDispose = false;
			if(_delayDispose)
			{
				dispose();
			}
		}

		/**
		 * Add a Bone instance to this Armature instance.
		 * @param A Bone instance.
		 * @param (optional) The parent's name of this Bone instance.
		 * @see dragonBones.Bone
		 */
		public function addBone(bone:FastBone, parentName:String = null):void
		{
			var parentBone:FastBone;
			if(parentName)
			{
				parentBone = getBone(parentName);
			}
			bone.setArmature(this);
			bone.setParent(parentBone);
			boneList.unshift(bone);
			_boneDic[bone.name] = bone;
		}
		
		/**
		 * Add a slot to a bone as child.
		 * @param slot A Slot instance
		 * @param boneName bone name
		 * @see dragonBones.core.DBObject
		 */
		public function addSlot(slot:FastSlot, parentBoneName:String):void
		{
			var bone:FastBone = getBone(parentBoneName);
			if(bone)
			{
				slot.setArmature(this);
				slot.setParent(bone);
				slot.addDisplayToContainer(display);
				slotList.push(slot);
				_slotDic[slot.name] = slot;
				if(slot.hasChildArmature)
				{
					slotHasChildArmatureList.push(slot);
				}
				
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * Sort all slots based on zOrder
		 */
		public function updateSlotsZOrder():void
		{
			slotList.fixed = false;
			slotList.sort(sortSlot);
			slotList.fixed = true;
			var i:int = slotList.length;
			while(i --)
			{
				var slot:FastSlot = slotList[i];
				if(slot._isShowDisplay)
				{
					//_display 实际上是container, 这个方法就是把原来的显示对象放到container中的第一个
					slot.addDisplayToContainer(_display);
				}
			}
			
			_slotsZOrderChanged = false;
		}
		
		private function sortBoneList():void
		{
			var i:int = boneList.length;
			if(i == 0)
			{
				return;
			}
			var helpArray:Array = [];
			while(i --)
			{
				var level:int = 0;
				var bone:FastBone = boneList[i];
				var boneParent:FastBone = bone;
				while(boneParent)
				{
					level ++;
					boneParent = boneParent.parent;
				}
				helpArray[i] = [level, bone];
			}
			
			helpArray.sortOn("0", Array.NUMERIC|Array.DESCENDING);
			
			i = helpArray.length;
			
			slotList.fixed = false;
			while(i --)
			{
				boneList[i] = helpArray[i][1];
			}
			boneList.fixed = true;
			
			helpArray.length = 0;
		}
		
		/** @private When AnimationState enter a key frame, call this func*/
		dragonBones_internal function arriveAtFrame(frame:Frame, animationState:FastAnimationState):void
		{
			
			
			if(frame.event && this.hasEventListener(FrameEvent.ANIMATION_FRAME_EVENT))
			{
				var frameEvent:FrameEvent = new FrameEvent(FrameEvent.ANIMATION_FRAME_EVENT);
				frameEvent.animationState = animationState;
				frameEvent.frameLabel = frame.event;
				_eventList.push(frameEvent);
			}

			if(frame.action)
			{
				animation.gotoAndPlay(frame.action);
			}
		}
		
		private function sortSlot(slot1:FastSlot, slot2:FastSlot):int
		{
			return slot1.zOrder < slot2.zOrder?1: -1;
		}
		
		/**
		 * ArmatureData.
		 * @see dragonBones.objects.ArmatureData.
		 */
		public function get armatureData():ArmatureData
		{
			return _armatureData;
		}
		
		/**
		 * An Animation instance
		 * @see dragonBones.animation.Animation
		 */
		public function get animation():FastAnimation
		{
			return _animation;
		}
		
		/**
		 * Armature's display object. It's instance type depends on render engine. For example "flash.display.DisplayObject" or "startling.display.DisplayObject"
		 */
		public function get display():Object
		{
			return _display;
		}
		
		
		public function getBone(boneName:String):FastBone
		{
			return _boneDic[boneName];
		}
		public function getSlot(slotName:String):FastSlot
		{
			return _slotDic[slotName];
		}
	}
}