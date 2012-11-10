package dragonBones.animation 
{
	
	/**
	 * 
	 * @author Akdcl
	 */
	internal class ProcessBase 
	{
		protected static const SINGLE:int = -4;
		protected static const LIST_START:int = -3;
		protected static const LIST_LOOP_START:int = -2;
		protected static const LIST:int = -1;
		
		protected var _currentFrame:Number;
		protected var _totalFrames:int;
		protected var _currentPrecent:Number;
		
		protected var _durationTween:int;
		protected var _duration:int;
		
		protected var _loop:int;
		protected var _tweenEasing:int;
		
		protected var _toIndex:int;

		public function get isPlaying():Boolean
		{
			return !_isComplete && !_isPause;
		}
		
		protected var _isComplete:Boolean;
		public function get isComplete():Boolean
		{
			return _isComplete;
		}
		
		protected var _isPause:Boolean;
		public function get isPause():Boolean
		{
			return _isPause;
		}
		
		protected var _timeScale:Number;
		public function get timeScale():Number 
		{
			return _timeScale;
		}
		public function set timeScale(value:Number):void 
		{
			_timeScale = value;
		}
		
		public function ProcessBase() 
		{
			_timeScale = 1;
			_isComplete = true;
			_isPause = false;
			_currentFrame = 0;
		}
		
		public function dispose():void
		{
		}
		
		public function gotoAndPlay(animation:Object, _durationTo:int = 0, durationTween:int = 0, loop:* = false, tweenEasing:Number = NaN):void 
		{
			_isComplete = false;
			_isPause = false;
			_currentFrame = 0;
			_totalFrames = _durationTo;
			_tweenEasing = tweenEasing;
		}
		
		public function play():void 
		{
			if(_isComplete)
			{
				_isComplete = false;
				_currentFrame = 0;
			}
			_isPause = false;
		}
		
		public function stop():void 
		{
			_isPause = true;
		}
		
		final public function update():void 
		{
			if (_isComplete || _isPause) 
			{
				return;
			}
			if (_totalFrames <= 0) 
			{
				_currentFrame = _totalFrames = 1;
			}
			_currentFrame += _timeScale;
			_currentPrecent = _currentFrame / _totalFrames;
			_currentFrame %= _totalFrames;
			updateHandler();
		}
		
		protected function updateHandler():void 
		{
		}
	}
	
}