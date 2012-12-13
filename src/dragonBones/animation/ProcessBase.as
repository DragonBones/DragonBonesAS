package dragonBones.animation
{
	
	/**
	 * Provides an abstract base class for key-frame processing classes.
	 *
	 */
	internal class ProcessBase
	{
		protected static const SINGLE:int = -4;
		protected static const LIST_START:int = -3;
		protected static const LIST_LOOP_START:int = -2;
		protected static const LIST:int = -1;
		
		protected var _currentTime:Number;
		protected var _totalTime:Number;
		protected var _progress:Number;
		
		protected var _loop:int;
		protected var _duration:Number;
		protected var _rawDuration:Number;
		
		protected var _nextFrameDataTimeEdge:Number;
		protected var _frameDuration:Number;
		protected var _nextFrameDataID:int;
		
		/**
		 * Indicates whether the animation is playing
		 */
		public function get isPlaying():Boolean
		{
			return !_isComplete && !_isPause;
		}
		
		protected var _isComplete:Boolean;
		/**
		 * Indicates whether the animation is completed
		 */
		public function get isComplete():Boolean
		{
			return _isComplete;
		}
		
		protected var _isPause:Boolean;
		/**
		 * Indicates whether the animation is paused
		 */
		public function get isPause():Boolean
		{
			return _isPause;
		}
		
		protected var _timeScale:Number;
		/**
		 * The amount by which passed time should be scaled. Used to slow down or speed up animations. Defaults to 1.
		 */
		public function get timeScale():Number
		{
			return _timeScale;
		}
		public function set timeScale(value:Number):void
		{
			if(value < 0)
			{
				value = 0;
			}
			_timeScale = value;
		}
		
		/**
		 * Creates a new <code>ProcessBase</code>
		 */
		public function ProcessBase()
		{
			_isComplete = true;
			_isPause = false;
			_timeScale = 1;
			_currentTime = 0;
		}
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose():void
		{
		}
		
		/**
		 * Moves the playhead.
		 */
		public function play():void
		{
			if(_isComplete)
			{
				_isComplete = false;
				_currentTime = 0;
			}
			_isPause = false;
		}
		/**
		 * Stops the playhead
		 */
		public function stop():void
		{
			_isPause = true;
		}
		
		/**
		 * Updates the state.
		 */
		final public function update():void
		{
			if (_isComplete || _isPause)
			{
				return;
			}
			if(_totalTime > 0)
			{
				_currentTime += WorldClock.timeLag;
				_progress = _currentTime / _totalTime;
				_currentTime %= _totalTime;
			}
			else
			{
				_progress = 1;
			}
			updateHandler();
		}
		
		/**
		 * Provides a abstract function for sub-classes processing the update logic.
		 */
		protected function updateHandler():void
		{
		}
	}
	
}