package dragonBones.starling
{
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.animation.WorldClock;
	import dragonBones.core.IArmatureDisplay;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	
	use namespace dragonBones_internal;
	
	/**
	 * @inheritDoc
	 */
	public final class StarlingArmatureDisplay extends Sprite implements IArmatureDisplay
	{
		public static var useDefaultStarlingEvent:Boolean = false;
		
		/*
		private static const _clock:WorldClock = new WorldClock();
		private static function _clockHandler(event:EnterFrameEvent):void 
		{
			_clock.advanceTime(event.passedTime);
		}
		*/
		
		/**
		 * @private
		 */
		dragonBones_internal var _armature:Armature;
		
		/**
		 * @private
		 */
		public function StarlingArmatureDisplay()
		{
			super();
		}
		
		/**
		 * @private
		 */
		private function _advanceTimeHandler(event:EnterFrameEvent):void
		{
			this._armature.advanceTime(event.passedTime);
		}
		
		/**
		 * @inheritDoc
		 */
		public function _onClear():void
		{
			_armature = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function _dispatchEvent(eventObject:EventObject):void
		{
			if (useDefaultStarlingEvent)
			{
				this.dispatchEventWith(eventObject.type, false, eventObject);
			}
			else
			{
				const event:StarlingEvent = new StarlingEvent(eventObject);
				this.dispatchEvent(event);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function _debugDraw():void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasEvent(type:String):Boolean
		{
			return this.hasEventListener(type);
		}
		
		/**
		 * @inheritDoc
		 */
		public function addEvent(type:String, listener:Function):void
		{
			this.addEventListener(type, listener);
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeEvent(type:String, listener:Function):void
		{
			this.removeEventListener(type, listener);
		}
		
		/**
		 * @inheritDoc
		 */
		public function advanceTimeBySelf(on:Boolean):void
		{
			if (on)
			{
				this.addEventListener(EnterFrameEvent.ENTER_FRAME, _advanceTimeHandler);
			}
			else
			{
				this.removeEventListener(EnterFrameEvent.ENTER_FRAME, _advanceTimeHandler);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if (_armature)
			{
				advanceTimeBySelf(false);
				_armature.dispose();
				_armature = null;
			}
			
			super.dispose();
		}
		
		/**
		 * @inheritDoc
		 */
		public function get armature():Armature
		{
			return _armature;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get animation():Animation
		{
			return _armature.animation;
		}
	}
}