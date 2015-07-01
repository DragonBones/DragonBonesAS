package dragonBones
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import dragonBones.animation.Animation;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.FastAnimation;
	import dragonBones.animation.IAnimatable;
	import dragonBones.animation.TimelineState;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
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
		protected var _boneList:Vector.<Bone>;
		
		/** @private Store slots based on slots' zOrder*/
		protected var _slotList:Vector.<Slot>;
		
		dragonBones_internal var __dragonBonesData:DragonBonesData;
		dragonBones_internal var _armatureData:ArmatureData;
		dragonBones_internal var _slotsZOrderChanged:Boolean;
		dragonBones_internal var _eventList:Vector.<Event>;
		
		private var _delayDispose:Boolean;
		private var _lockDispose:Boolean;
		
		public function FastArmature(display:Object)
		{
			_animation = new FastAnimation(this);
			_slotsZOrderChanged = false;
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
			var i:int = _slotList.length;
			while(i --)
			{
				_slotList[i].dispose();
			}
			i = _boneList.length;
			while(i --)
			{
				_boneList[i].dispose();
			}
			
			_slotList.fixed = false;
			_slotList.length = 0;
			_boneList.fixed = false;
			_boneList.length = 0;
			_eventList.length = 0;
			
			_armatureData = null;
			_animation = null;
			_slotList = null;
			_boneList = null;
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
			
			var i:int = _boneList.length;
			while(i --)
			{
				var bone:Bone = _boneList[i];
				bone.update(isFading);
			}
			
			i = _slotList.length;
			while(i --)
			{
				var slot:Slot = _slotList[i];
				slot.update();
				if(slot._isShowDisplay)
				{
					var childArmature:Armature = slot.childArmature;
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

		/** @private When AnimationState enter a key frame, call this func*/
		dragonBones_internal function arriveAtFrame(frame:Frame):void
		{
			
			
			if(frame.event && this.hasEventListener(FrameEvent.ANIMATION_FRAME_EVENT))
			{
				var frameEvent:FrameEvent = new FrameEvent(FrameEvent.ANIMATION_FRAME_EVENT);
				frameEvent.frameLabel = frame.event;
				_eventList.push(frameEvent);
			}

			if(frame.action)
			{
				animation.gotoAndPlay(frame.action);
			}
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
	}
}