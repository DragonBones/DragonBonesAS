package dragonBones.objects
{
	final public class AnimationData extends Timeline
	{
		public var name:String;
		public var frameRate:uint;
		public var fadeTime:Number;
		public var playTimes:int;
		//NaN:no tween, -2:auto tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2] ease in out
		public var tweenEasing:Number;
		public var lastFrameDuration:Number;
		
		//string map
		public var hideTimelineNameMap:Object;
		
		private var _timelineList:Vector.<TransformTimeline>;
		public function get timelineList():Vector.<TransformTimeline>
		{
			return _timelineList;
		}
		
		private var _timelineCachedMap:Object;
		
		public function AnimationData()
		{
			super();
			fadeTime = 0;
			playTimes = 0;
			tweenEasing = -2;
			hideTimelineNameMap = {};
			
			_timelineList = new Vector.<TransformTimeline>;
			_timelineList.fixed = true;
			
			_timelineCachedMap = {};
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			//clear
			hideTimelineNameMap = null;
			
			_timelineList.fixed = false;
			for each(var timeline:TransformTimeline in _timelineList)
			{
				timeline.dispose();
			}
			_timelineList.fixed = false;
			_timelineList.length = 0;
			_timelineList = null;
			
			for each(var timelineCached:TimelineCached in _timelineCachedMap)
			{
				timelineCached.dispose();
			}
			//clear
			_timelineCachedMap = null;
		}
		
		public function getTimeline(timelineName:String):TransformTimeline
		{
			var i:int = _timelineList.length;
			while(i --)
			{
				if(_timelineList[i].name == timelineName)
				{
					return _timelineList[i];
				}
			}
			return null;
		}
		
		public function addTimeline(timeline:TransformTimeline):void
		{
			if(!timeline)
			{
				throw new ArgumentError();
			}
			
			if(_timelineList.indexOf(timeline) < 0)
			{
				_timelineList.fixed = false;
				_timelineList[_timelineList.length] = timeline;
				_timelineList.fixed = true;
			}
		}
		
		public function getTimelineCached(timelineName:String):TimelineCached
		{
			var timelineCached:TimelineCached = _timelineCachedMap[timelineName];
			if(!timelineCached)
			{
				_timelineCachedMap[timelineName] =
					timelineCached = new TimelineCached();
			}
			return timelineCached;
		}
	}
}