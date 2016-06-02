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
		/**
		 * @private AnimationState
		 */
		dragonBones_internal var _isCompleted:Boolean;
		
		/**
		 * @private AnimationState
		 */
		dragonBones_internal var _currentTime:uint;
		
		protected var _isReverse:Boolean;
		protected var _hasAsynchronyTimeline:Boolean;
		protected var _keyFrameCount:uint;
		protected var _frameCount:uint;
		protected var _currentPlayTimes:uint;
		protected var _position:uint;
		protected var _duration:uint;
		protected var _clipDutation:uint;
		protected var _timeScale:Number;
		protected var _timeOffset:Number;
		protected var _timeToFrameSccale:Number;
		protected var _currentFrame:FrameData;
		protected var _timeline:TimelineData;
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
			_currentTime = 0;
			
			_isReverse = false;
			_hasAsynchronyTimeline = false;
			_keyFrameCount =0;
			_frameCount = 0;
			_currentPlayTimes = 0;
			_position = 0;
			_duration = 0;
			_clipDutation = 0;
			_timeScale = 1;
			_timeOffset = 0;
			_timeToFrameSccale = 0;
			_currentFrame = null;
			_timeline = null;
			_armature = null;
			_animationState = null;
		}
		
		protected function _onFadeIn():void
		{
		}
		
		protected function _onUpdateFrame(isUpdate:Boolean):void
		{
		}
		
		protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
		}
		
		protected function _onCrossFrame(frame:FrameData):void
		{
		}
		
		protected function _setCurrentTime(value:int):Boolean
		{
			if (_hasAsynchronyTimeline)
			{
				const playTimes:uint = _animationState.playTimes;
				const totalTimes:uint = playTimes * _duration;
				
				value *= _timeScale;
				if (_timeOffset != 0)
				{
					value += _timeOffset * _clipDutation;
				}
				
				if (playTimes > 0 && (value >= totalTimes || value <= -totalTimes))
				{	
					_isCompleted = true;
					_currentPlayTimes = playTimes;
					
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
						_currentPlayTimes = -value / _duration;
						value = _duration - (value % _duration);
					}
					else
					{
						_currentPlayTimes = value / _duration;
						value %= _duration;
					}
					
					if (_currentPlayTimes > playTimes)
					{
						_currentPlayTimes = playTimes;
					}
				}
				
				value += _position;
			}
			else
			{
				// _isCompleted = _animationState._timeline._isCompleted;
				// _currentPlayTimes = _animationState._timeline._currentPlayTimes;
			}
			
			if (_currentTime == value)
			{
				return false;
			}
			
			if (_keyFrameCount == 1 && value > _position && this != _animationState._timeline)
			{
				_isCompleted = true;
			}
			
			_isReverse = _currentTime > value;
			_currentTime = value;
			
			return true;
		}
		
		public function invalidUpdate():void
		{
			_timeScale = this == _animationState._timeline? 1: (1 / _timeline.scale);
			_timeOffset = this == _animationState._timeline? 0: _timeline.offset;
		}
		
		public function setCurrentTime(value:uint):void
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
					_currentFrame = _timeline.frames[uint(_currentTime * _timeToFrameSccale)]; // floor
					_onArriveAtFrame(false);
					_onUpdateFrame(false);
					break;
			}
			
			// _currentFrame = null; // TODO For first event frame
		}
		
		public function fadeIn(armature:Armature, animationState:AnimationState, timelineData:TimelineData):void
		{
			_armature = armature;
			_animationState = animationState;
			_timeline = timelineData;
			
			const isMainTimeline:Boolean = this == _animationState._timeline;
			
			_hasAsynchronyTimeline = isMainTimeline || _animationState.clip.hasAsynchronyTimeline;
			_keyFrameCount = _timeline.frames.length;
			_frameCount = _animationState.clip.frameCount;
			_position = _animationState._position;
			_duration = _animationState._duration;
			_clipDutation = _animationState._clipDutation;
			_timeScale = isMainTimeline? 1: (1 / _timeline.scale);
			_timeOffset = isMainTimeline? 0: _timeline.offset;
			_timeToFrameSccale = _frameCount / (_clipDutation + 1);
			
			_onFadeIn();
			
			setCurrentTime(0);
		}
		
		public function fadeOut():void
		{
		}
		
		public function update(time:int):void
		{
			if (!_isCompleted && _setCurrentTime(time) && _keyFrameCount)
			{
				//const currentFrameIndex:uint = _keyFrameCount > 1? currentFrameIndex = _currentTime * _timeToFrameSccale: 0;
				var currentFrameIndex:uint = 0;
				if (_keyFrameCount > 1)
				{
					currentFrameIndex = uint(_currentTime * _timeToFrameSccale);
				}
				
				const currentFrame:FrameData = _timeline.frames[currentFrameIndex];
				if (_currentFrame != currentFrame)
				{
					if (_keyFrameCount > 1)
					{
						var crossedFrame:FrameData = _currentFrame || currentFrame.prev;
						_currentFrame = currentFrame;
						
						if (_isReverse)
						{
							while (crossedFrame != currentFrame)
							{
								_onCrossFrame(crossedFrame);
								crossedFrame = crossedFrame.prev;
							}
						}
						else
						{
							while (crossedFrame != currentFrame)
							{
								crossedFrame = crossedFrame.next;
								_onCrossFrame(crossedFrame);
							}
						}
						
						_onArriveAtFrame(true);
					}
					else
					{
						_currentFrame = currentFrame;
						_onCrossFrame(_currentFrame);
						_onArriveAtFrame(true);
					}
				}
				
				_onUpdateFrame(true);
			}
		}
	}
}