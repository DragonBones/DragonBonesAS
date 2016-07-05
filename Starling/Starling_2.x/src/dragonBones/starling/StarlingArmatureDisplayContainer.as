package dragonBones.starling
{
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.core.IArmatureDisplayContainer;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	
	use namespace dragonBones_internal;
	
	/**
	 * @inheritDoc
	 */
	public final class StarlingArmatureDisplayContainer extends Sprite implements IArmatureDisplayContainer
	{
		public static const useDefaultStarlingEvent:Boolean = false;
		
		/**
		 * @private
		 */
		dragonBones_internal var _armature:Armature;
		
		/**
		 * @private
		 */
		public function StarlingArmatureDisplayContainer()
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
			
			this.dispose();
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
				_armature.dispose();
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