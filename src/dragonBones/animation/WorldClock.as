package dragonBones.animation
{
	import flash.utils.getTimer;
	
	public final class WorldClock
	{
		private static var _time:Number = getTimer() * 0.001;
		public static function get time():Number
		{
			return _time;
		}
		
		private static var _timeScale:Number = 1;
		public static function get timeScale():Number
		{
			return _timeScale;
		}
		public static function set timeScale(value:Number):void
		{
			if (value < 0 || isNaN(value)) 
			{
				value = 0;
			}
			_timeScale = value;
		}
		
		private static var _timeLag:Number = 1/30;
		public static function get timeLag():Number
		{
			return _timeLag;
		}
		public static function set timeLag(value:Number):void
		{
			_timeLag = value;
		}
		
		public static function update():void 
		{
			var time:Number = getTimer() * 0.001 * _timeScale;
			_timeLag = time - _time;
			_time = time;
		}
	}
}