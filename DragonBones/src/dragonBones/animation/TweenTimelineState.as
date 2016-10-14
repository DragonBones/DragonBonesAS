package dragonBones.animation
{
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.ExtensionFrameData;
	import dragonBones.objects.TweenFrameData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public class TweenTimelineState extends TimelineState
	{
		protected static const TWEEN_TYPE_NONE:int = 0;
		protected static const TWEEN_TYPE_ONCE:int = 1;
		protected static const TWEEN_TYPE_ALWAYS:int = 2;
		
		dragonBones_internal static function _getEasingValue(progress:Number, easing:Number):Number
		{
			if (progress <= 0) 
			{
				return 0;
			} 
			else if (progress >= 1) 
			{
				return 1;
			}
			
			var value:Number = 1;
			if (easing > 2)
			{
				return progress;
			}
			else if (easing > 1) // Ease in out
			{
				value = 0.5 * (1 - Math.cos(progress * Math.PI));
				easing -= 1;
			}
			else if (easing > 0) // Ease out
			{
				value = 1 - Math.pow(1 - progress, 2);
			}
			else if (easing >= -1) // Ease in
			{
				easing *= -1;
				value = Math.pow(progress, 2);
			}
			else if (easing >= -2) // Ease out in
			{
				easing *= -1;
				value = Math.acos(1 - progress * 2) / Math.PI;
				easing -= 1;
			}
			else
			{
				return progress;
			}
			
			return (value - progress) * easing + progress;
		}
		
		dragonBones_internal static function _getCurveEasingValue(progress:Number, sampling:Vector.<Number>):Number
		{
			if (progress <= 0) 
			{
				return 0;
			} 
			else if (progress >= 1) 
			{
				return 1;
			}
			
			var x:Number = 0;
			var y:Number = 0;
			
			for (var i:uint = 0, l:uint = sampling.length; i < l; i += 2) 
			{
				x = sampling[i];
				y = sampling[i + 1];
				if (x >= progress) 
				{
					if (i == 0)
					{
						return y * progress / x;
					}
					else
					{
						const xP:Number = sampling[i - 2];
						const yP:Number = sampling[i - 1]; // i - 2 + 1
						return yP + (y - yP) * (progress - xP) / (x - xP);
					}
				}
			}
			
			return y + (1 - y) * (progress - x) / (1 - x);
		}
		
		protected var _tweenProgress:Number;
		protected var _tweenEasing:Number;
		protected var _curve:Vector.<Number>;
		
		public function TweenTimelineState(self:TimelineState)
		{
			super(self);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			_tweenProgress = 0;
			_tweenEasing = DragonBones.NO_TWEEN;
			_curve = null;
		}
		
		override protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
			const currentFrame:TweenFrameData = this._currentFrame as TweenFrameData;
			_tweenEasing = currentFrame.tweenEasing;
			_curve = currentFrame.curve;
			
			if (
				this._keyFrameCount <= 1 ||
				(
					this._currentFrame.next == this._timeline.frames[0] && 
					(_tweenEasing != DragonBones.NO_TWEEN || _curve) &&
					this._animationState.playTimes > 0 && 
					this._animationState.currentPlayTimes == this._animationState.playTimes - 1
				)
			)
			{
				_tweenEasing = DragonBones.NO_TWEEN;
				_curve = null;
			}
		}
		
		override protected function _onUpdateFrame(isUpdate:Boolean):void
		{
			if (_tweenEasing != DragonBones.NO_TWEEN)
			{
				_tweenProgress = (this._currentTime - this._currentFrame.position + this._position) / this._currentFrame.duration;
				if (_tweenEasing != 0)
				{
					_tweenProgress = _getEasingValue(_tweenProgress, _tweenEasing);
				}
			}
			else if (_curve)
			{
				_tweenProgress = (this._currentTime - this._currentFrame.position + this._position) / this._currentFrame.duration;
				_tweenProgress = _getCurveEasingValue(_tweenProgress, _curve);
			}
			else
			{
				_tweenProgress = 0;
			}
		}
		
		protected function _updateExtensionKeyFrame(current:ExtensionFrameData, next:ExtensionFrameData, result:ExtensionFrameData):int
		{
			var tweenType:int = TWEEN_TYPE_NONE;
			var i:uint = 0, l:uint = 0;
			
			if (current.type == next.type)
			{
				for (i = 0, l = current.tweens.length; i < l; ++i)
				{
					const tweenDuration:Number = next.tweens[i] - current.tweens[i];
					result.tweens[i] = tweenDuration;
					
					if (tweenDuration > 0)
					{
						tweenType = TWEEN_TYPE_ALWAYS;
					}
				}
			}
			
			if (tweenType == TWEEN_TYPE_NONE)
			{
				if (result.type != current.type)
				{
					tweenType = TWEEN_TYPE_ONCE;
					result.type = current.type;
				}
				
				if (result.tweens.length != current.tweens.length)
				{
					tweenType = TWEEN_TYPE_ONCE;
					result.tweens.fixed = false;
					result.tweens.length = current.tweens.length;
					result.tweens.fixed = true;
				}
				
				if (result.keys.length != current.keys.length)
				{
					tweenType = TWEEN_TYPE_ONCE;
					result.keys.fixed = false;
					result.keys.length = current.keys.length;
					result.keys.fixed = true;
				}
				
				for (i = 0, l = current.keys.length; i < l; ++i)
				{
					const key:Number = current.keys[i];
					if (result.keys[i] != key)
					{
						tweenType = TWEEN_TYPE_ONCE;
						result.keys[i] = key;
					}
				}
			}
			
			return tweenType;
		}
	}
}