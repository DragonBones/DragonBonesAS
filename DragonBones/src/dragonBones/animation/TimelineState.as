package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.TimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public class TimelineState extends BaseObject
	{
		dragonBones_internal var _isCompleted:Boolean;
		dragonBones_internal var _currentPlayTimes:uint;
		dragonBones_internal var _currentTime:Number;
		dragonBones_internal var _timeline:TimelineData;
		
		protected var _isReverse:Boolean;
		protected var _hasAsynchronyTimeline:Boolean;
		protected var _frameRate:uint;
		protected var _keyFrameCount:uint;
		protected var _frameCount:uint;
		protected var _position:Number;
		protected var _duration:Number;
		protected var _animationDutation:Number;
		protected var _timeScale:Number;
		protected var _timeOffset:Number;
		protected var _currentFrame:FrameData;
		protected var _armature:Armature;
		protected var _animationState:AnimationState;
		
		public function TimelineState(self:TimelineState)
		{
			super(this);
			
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
			_isCompleted = false;
			_currentPlayTimes = 0;
			_currentTime = 0;
			_timeline = null;
			
			_isReverse = false;
			_hasAsynchronyTimeline = false;
			_frameRate = 0;
			_keyFrameCount =0;
			_frameCount = 0;
			_position = 0;
			_duration = 0;
			_animationDutation = 0;
			_timeScale = 1;
			_timeOffset = 0;
			_currentFrame = null;
			_armature = null;
			_animationState = null;
		}
		
		protected function _onFadeIn():void {}
		
		protected function _onUpdateFrame(isUpdate:Boolean):void {}
		
		protected function _onArriveAtFrame(isUpdate:Boolean):void {}
		
		protected function _setCurrentTime(value:Number):Boolean
		{
			var currentPlayTimes:uint = 0;
			
			if (_hasAsynchronyTimeline)
			{
				const playTimes:uint = _animationState.playTimes;
				const totalTimes:Number = playTimes * _duration;
				
				value *= _timeScale;
				if (_timeOffset != 0)
				{
					value += _timeOffset * _animationDutation;
				}
				
				if (playTimes > 0 && (value >= totalTimes || value <= -totalTimes))
				{	
					_isCompleted = true;
					currentPlayTimes = playTimes;
					
					if (value < 0)
					{
						value = 0;
					}
					else
					{
						value = _duration;
					}
				}
				else
				{
					_isCompleted = false;
					
					if (value < 0)
					{
						currentPlayTimes = uint(-value / _duration);
						value = _duration - (-value % _duration);
					}
					else
					{
						currentPlayTimes = uint(value / _duration);
						value %= _duration;
					}
					
					if (playTimes > 0 && currentPlayTimes > playTimes)
					{
						currentPlayTimes = playTimes;
					}
				}
				
				value += _position;
			}
			else
			{
				_isCompleted = _animationState._timeline._isCompleted;
				currentPlayTimes = _animationState._timeline._currentPlayTimes;
			}
			
			if (_currentTime == value)
			{
				return false;
			}
			
			if (_keyFrameCount == 1 && value > _position && this != _animationState._timeline)
			{
				_isCompleted = true;
			}
			
			_isReverse = _currentTime > value && _currentPlayTimes == currentPlayTimes;
			_currentTime = value;
			_currentPlayTimes = currentPlayTimes;
			
			return true;
		}
		
		public function invalidUpdate():void
		{
			_timeScale = this == _animationState._timeline? 1: (1 / _timeline.scale);
			_timeOffset = this == _animationState._timeline? 0: _timeline.offset;
		}
		
		public function setCurrentTime(value:Number):void
		{
			_setCurrentTime(value);
			
			switch (_keyFrameCount)
			{
				case 0:
					break;
				
				case 1:
					_currentFrame = _timeline.frames[0];
					_onArriveAtFrame(false);
					_onUpdateFrame(false);
					break;
				
				default:
					_currentFrame = _timeline.frames[uint(_currentTime * _frameRate)];
					_onArriveAtFrame(false);
					_onUpdateFrame(false);
					break;
			}
			
			_currentFrame = null;
		}
		
		public function fadeIn(armature:Armature, animationState:AnimationState, timelineData:TimelineData, time:Number):void
		{
			_armature = armature;
			_animationState = animationState;
			_timeline = timelineData;
			
			const isMainTimeline:Boolean = this == _animationState._timeline;
			
			_hasAsynchronyTimeline = isMainTimeline || _animationState.animationData.hasAsynchronyTimeline;
			_frameRate = _armature.armatureData.frameRate;
			_keyFrameCount = _timeline.frames.length;
			_frameCount = _animationState.animationData.frameCount;
			_position = _animationState._position;
			_duration = _animationState._duration;
			_animationDutation = _animationState.animationData.duration;
			_timeScale = isMainTimeline? 1: (1 / _timeline.scale);
			_timeOffset = isMainTimeline? 0: _timeline.offset;
			
			_onFadeIn();
			
			setCurrentTime(time);
		}
		
		public function fadeOut():void {}
		
		public function update(time:Number):void
		{
			if (!_isCompleted && _setCurrentTime(time) && _keyFrameCount)
			{
				//const currentFrameIndex:uint = _keyFrameCount > 1? _currentTime * _timeToFrameSccale: 0;
				var currentFrameIndex:uint = 0;
				if (_keyFrameCount > 1)
				{
					currentFrameIndex = uint(_currentTime * _frameRate);
				}
				
				const currentFrame:FrameData = _timeline.frames[currentFrameIndex];
				if (_currentFrame != currentFrame)
				{
					_currentFrame = currentFrame;
					_onArriveAtFrame(true);
				}
				
				_onUpdateFrame(true);
			}
		}
	}
}