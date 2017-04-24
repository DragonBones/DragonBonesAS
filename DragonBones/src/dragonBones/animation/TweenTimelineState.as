package dragonBones.animation
{
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
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
			if (progress <= 0.0) 
			{
				return 0.0;
			} 
			else if (progress >= 1.0) 
			{
				return 1.0;
			}
			
			var value:Number = 1.0;
			if (easing > 2.0)
			{
				return progress;
			}
			else if (easing > 1.0) // Ease in out
			{
				value = 0.5 * (1.0 - Math.cos(progress * Math.PI));
				easing -= 1.0;
			}
			else if (easing > 0.0) // Ease out
			{
				value = 1.0 - Math.pow(1.0 - progress, 2.0);
			}
			else if (easing >= -1) // Ease in
			{
				easing *= -1.0;
				value = Math.pow(progress, 2.0);
			}
			else if (easing >= -2.0) // Ease out in
			{
				easing *= -1.0;
				value = Math.acos(1.0 - progress * 2.0) / Math.PI;
				easing -= 1.0;
			}
			else
			{
				return progress;
			}
			
			return (value - progress) * easing + progress;
		}
		
		dragonBones_internal static function _getCurveEasingValue(progress:Number, samples:Vector.<Number>):Number
		{
			if (progress <= 0.0) 
			{
				return 0.0;
			} 
			else if (progress >= 1.0) 
			{
				return 1.0;
			}
			
			const segmentCount:uint = samples.length + 1; // + 2 - 1
			const valueIndex:uint = Math.floor(progress * segmentCount);
			const fromValue:Number = valueIndex === 0 ? 0.0 : samples[valueIndex - 1];
			const toValue:Number = (valueIndex === segmentCount - 1) ? 1.0 : samples[valueIndex];
			
			return fromValue + (toValue - fromValue) * (progress * segmentCount - valueIndex);
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
		
		override protected function _onClear():void
		{
			super._onClear();
			
			_tweenProgress = 0.0;
			_tweenEasing = DragonBones.NO_TWEEN;
			_curve = null;
		}
		
		override protected function _onArriveAtFrame():void
		{
			if (
				_keyFrameCount > 1 &&
				(
					_currentFrame.next !== _timelineData.frames[0] ||
					_animationState.playTimes === 0 ||
					_animationState.currentPlayTimes < _animationState.playTimes - 1
				)
			) 
			{
				const currentFrame:TweenFrameData = _currentFrame as TweenFrameData;
				_tweenEasing = currentFrame.tweenEasing;
				_curve = currentFrame.curve;
			}
			else 
			{
				_tweenEasing = DragonBones.NO_TWEEN;
				_curve = null;
			}
			
		}
		
		override protected function _onUpdateFrame():void
		{
			if (_tweenEasing != DragonBones.NO_TWEEN)
			{
				_tweenProgress = (_currentTime - _currentFrame.position + _position) / _currentFrame.duration;
				if (_tweenEasing != 0.0)
				{
					_tweenProgress = _getEasingValue(_tweenProgress, _tweenEasing);
				}
			}
			else if (_curve)
			{
				_tweenProgress = (_currentTime - _currentFrame.position + _position) / _currentFrame.duration;
				_tweenProgress = _getCurveEasingValue(_tweenProgress, _curve);
			}
			else
			{
				_tweenProgress = 0.0;
			}
		}
	}
}