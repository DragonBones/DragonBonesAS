package dragonBones.objects
{
	public final class TimelineCached
	{
		private var _timeline:Vector.<BoneFrameCached>;
		
		public function TimelineCached()
		{
			_timeline = new Vector.<BoneFrameCached>;
		}
		
		public function dispose():void
		{
			var i:int = _timeline.length;
			while(i --)
			{
				_timeline[i].dispose();
			}
			_timeline.fixed = false;
			_timeline.length = 0;
			_timeline = null;
		}
		
		public function getFrame(framePosition:int):BoneFrameCached
		{
			return _timeline.length > framePosition?_timeline[framePosition]:null;
		}
		
		public function addFrame(framePosition:int, frameDuration:int):BoneFrameCached
		{
			var frame:BoneFrameCached = new BoneFrameCached();
			_timeline.fixed = false;
			if(_timeline.length < framePosition)
			{
				_timeline.length = framePosition;
			}
			for(var i:int = framePosition;i < framePosition + frameDuration;i ++)
			{
				_timeline[i] = frame;
			}
			_timeline.fixed = true;
			
			return frame;
		}
	}
}