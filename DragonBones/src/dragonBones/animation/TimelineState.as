package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.TimelineData;
	
	/**
	 * @private
	 */
	public class TimelineState extends BaseObject
	{
		internal var _playState: int; // -1 start 0 play 1 complete
		internal var _currentPlayTimes:uint;
		internal var _currentTime:Number;
		internal var _timelineData:TimelineData;
		
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
		protected var _mainTimeline:AnimationTimelineState;
		
		public function TimelineState(self:TimelineState)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		override protected function _onClear():void
		{
			_playState = -1;
			_currentPlayTimes = 0;
			_currentTime = -1;
			_timelineData = null;
			
			_frameRate = 0;
			_keyFrameCount =0;
			_frameCount = 0;
			_position = 0.0;
			_duration = 0.0
			_animationDutation = 0.0
			_timeScale = 1.0
			_timeOffset = 0.0
			_currentFrame = null;
			_armature = null;
			_animationState = null;
			_mainTimeline = null;
		}
		
		protected function _onUpdateFrame():void {}
		protected function _onArriveAtFrame():void {}
		
		protected function _setCurrentTime(passedTime:Number):Boolean
		{
			const prevState:int = _playState;
			var currentPlayTimes:uint = 0;
			var currentTime:Number = 0.0;
			
			if (_mainTimeline && _keyFrameCount === 1) 
			{
				_playState = _animationState._timeline._playState >= 0 ? 1 : -1;
				currentPlayTimes = 1;
				currentTime = _mainTimeline._currentTime;
			}
			else if (!_mainTimeline || _timeScale !== 1.0 || _timeOffset !== 0.0)  // Scale and offset.
			{
				const playTimes:uint = _animationState.playTimes;
				const totalTime:Number = playTimes * _duration;
				
				passedTime *= _timeScale;
				if (_timeOffset !== 0.0) 
				{
					passedTime += _timeOffset * _animationDutation;
				}
				
				if (playTimes > 0 && (passedTime >= totalTime || passedTime <= -totalTime)) 
				{
					if (_playState <= 0 && _animationState._playheadState === 3) 
					{
						_playState = 1;
					}
					
					currentPlayTimes = playTimes;
					
					if (passedTime < 0.0) 
					{
						currentTime = 0.0;
					}
					else 
					{
						currentTime = _duration;
					}
				}
				else 
				{
					if (_playState !== 0 && _animationState._playheadState === 3) 
					{
						_playState = 0;
					}
					
					if (passedTime < 0.0) 
					{
						passedTime = -passedTime;
						currentPlayTimes = Math.floor(passedTime / _duration);
						currentTime = _duration - (passedTime % _duration);
					}
					else 
					{
						currentPlayTimes = Math.floor(passedTime / _duration);
						currentTime = passedTime % _duration;
					}
				}
			}
			else 
			{
				_playState = _animationState._timeline._playState;
				currentPlayTimes = _animationState._timeline._currentPlayTimes;
				currentTime = _mainTimeline._currentTime;
			}
			
			currentTime += _position;
			
			if (_currentPlayTimes === currentPlayTimes && _currentTime === currentTime) 
			{
				return false;
			}
			
			// Clear frame flag when timeline start or loopComplete.
			if (
				(prevState < 0 && _playState !== prevState) ||
				(_playState <= 0 && _currentPlayTimes !== currentPlayTimes)
			) 
			{
				_currentFrame = null;
			}
			
			_currentPlayTimes = currentPlayTimes;
			_currentTime = currentTime;
			
			return true;
		}
		
		public function _init(armature: Armature, animationState: AnimationState, timelineData: TimelineData): void 
		{
			_armature = armature;
			_animationState = animationState;
			_timelineData = timelineData;
			_mainTimeline = _animationState._timeline;
			
			if (this === _mainTimeline)
			{
				_mainTimeline = null;
			}
			
			_frameRate = _armature.armatureData.frameRate;
			_keyFrameCount = _timelineData.frames.length;
			_frameCount = _animationState.animationData.frameCount;
			_position = _animationState._position;
			_duration = _animationState._duration;
			_animationDutation = _animationState.animationData.duration;
			_timeScale = !_mainTimeline ? 1.0 : (1.0 / _timelineData.scale);
			_timeOffset = !_mainTimeline ? 0.0 : _timelineData.offset;
		}
		
		public function fadeOut():void {}
		
		public function invalidUpdate():void
		{
			_timeScale = this == _animationState._timeline? 1: (1 / _timelineData.scale);
			_timeOffset = this == _animationState._timeline? 0: _timelineData.offset;
		}
		
		public function update(passedTime:Number):void
		{
			if (_playState <= 0 && _setCurrentTime(passedTime)) 
			{
				const currentFrameIndex:uint = _keyFrameCount > 1 ? uint(_currentTime * _frameRate) : 0;
				const currentFrame:FrameData = _timelineData.frames[currentFrameIndex];
				
				if (_currentFrame !== currentFrame) 
				{
					_currentFrame = currentFrame;
					_onArriveAtFrame();
				}
				
				_onUpdateFrame();
			}
		}
	}
}