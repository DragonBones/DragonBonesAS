package dragonBones.flash
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.core.IArmatureDisplayContainer;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	
	use namespace dragonBones_internal;
	
	/**
	 * @inheritDoc
	 */
	public class FlashArmatureDisplayContainer extends Sprite implements IArmatureDisplayContainer
	{
		/**
		 * @private
		 */
		private var _time:Number;
		
		/**
		 * @private
		 */
		dragonBones_internal var _armature:Armature;
		
		/**
		 * @private
		 */
		public function FlashArmatureDisplayContainer()
		{
			super();
		}
		
		/**
		 * @private
		 */
		private function _advanceTimeHandler(event:Event):void
		{
			const passedTime:Number = new Date().getTime() * 0.001 - _time;
			_time += passedTime;
			this._armature.advanceTime(passedTime);
		}
		
		/**
		 * @inheritDoc
		 */
		public function _onClear():void
		{
			advanceTimeBySelf(false);
			
			_time = 0;
			
			_armature = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function _dispatchEvent(eventObject:EventObject):void
		{
			const event:FlashEvent = new FlashEvent(eventObject.type, eventObject);
			
			this.dispatchEvent(event);
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
				_time = new Date().getTime() * 0.001;
				this.addEventListener(Event.ENTER_FRAME, _advanceTimeHandler);
			}
			else
			{
				this.removeEventListener(Event.ENTER_FRAME, _advanceTimeHandler);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			if (_armature)
			{
				_armature.dispose();
			}
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