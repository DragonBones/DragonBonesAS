package dragonBones.objects
{
	final public class AnimationData extends Timeline
	{
		public var name:String;
		public var frameRate:uint;
		public var loop:int;
		public var tweenEasing:Number;
		
		private var _timelines:Object;
		public function get timelines():Object
		{
			return _timelines;
		}
		
		private var _fadeTime:Number;
		public function get fadeTime():Number
		{
			return _fadeTime;
		}
		public function set fadeTime(value:Number):void
		{
			_fadeTime = value > 0?value:0;
		}
		
		public function AnimationData()
		{
			super();
			loop = 0;
			tweenEasing = NaN;
			
			_timelines = {};
			
			_fadeTime = 0;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			for(var timelineName:String in _timelines)
			{
				(_timelines[timelineName] as TransformTimeline).dispose();
			}
			_timelines = null;
		}
		
		public function getTimeline(timelineName:String):TransformTimeline
		{
			return _timelines[timelineName] as TransformTimeline;
		}
		
		public function addTimeline(timeline:TransformTimeline, timelineName:String):void
		{
			if(!timeline)
			{
				throw new ArgumentError();
			}
			
			_timelines[timelineName] = timeline;
		}
	}
}