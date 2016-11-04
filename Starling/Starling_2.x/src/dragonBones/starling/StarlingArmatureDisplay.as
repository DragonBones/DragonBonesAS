package dragonBones.starling
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.animation.WorldClock;
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
		dragonBones_internal const _subTextures:Object = {};
		
		/**
		 * @private
		 */
		public function StarlingArmatureDisplay()
		{
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		public function _onClear():void
		{
			for (var i:String in _subTextures) 
			{
				//th._subTextures[i].dispose();
				delete _subTextures[i];
			}
			
			if (_armature)
			{
				advanceTimeBySelf(false);
			}
			
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
		 * @private
		 */
		public function _onReplaceTexture(texture:Object):void 
		{
			for (var i:String in _subTextures) 
			{
				//th._subTextures[i].dispose();
				delete _subTextures[i];
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
		public function advanceTimeBySelf(on:Boolean):void
		{
			if (on)
			{
				StarlingFactory._clock.add(this._armature);
			} 
			else 
			{
				StarlingFactory._clock.remove(this._armature);
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