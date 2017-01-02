package dragonBones.starling
{
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.core.IArmatureDisplay;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	
	import starling.display.Sprite;
	
	use namespace dragonBones_internal;
	
	/**
	 * @inheritDoc
	 */
	public final class StarlingArmatureDisplay extends Sprite implements IArmatureDisplay
	{
		public static var useDefaultStarlingEvent:Boolean = false;
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
		public function _onClear():void
		{
			_armature = null;
		}
		/**
		 * @private
		 */
		public function _dispatchEvent(type:String, eventObject:EventObject):void
		{
			if (useDefaultStarlingEvent)
			{
				dispatchEventWith(type, false, eventObject);
			}
			else
			{
				const event:StarlingEvent = new StarlingEvent(type, eventObject);
				dispatchEvent(event);
			}
		}
		/**
		 * @private
		 */
		public function _debugDraw(isEnabled:Boolean):void
		{
		}
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if (_armature)
			{
				_armature.dispose();
				_armature = null;
			}
			
			super.dispose();
		}
		/**
		 * @inheritDoc
		 */
		public function hasEvent(type:String):Boolean
		{
			return hasEventListener(type);
		}
		/**
		 * @inheritDoc
		 */
		public function addEvent(type:String, listener:Function):void
		{
			addEventListener(type, listener);
		}
		/**
		 * @inheritDoc
		 */
		public function removeEvent(type:String, listener:Function):void
		{
			removeEventListener(type, listener);
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
		
		/**
		 * @deprecated
		 */
		public function advanceTimeBySelf(on:Boolean):void
		{
			if (on)
			{
				StarlingFactory._clock.add(_armature);
			} 
			else 
			{
				StarlingFactory._clock.remove(_armature);
			}
		}
	}
}