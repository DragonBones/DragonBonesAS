package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public class TimelineData extends BaseObject
	{
		public var scale:Number;
		public var offset:Number;
		public var frames:Vector.<FrameData> = new Vector.<FrameData>(0, true);
		
		public function TimelineData(self:TimelineData)
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
			scale = 0;
			offset = 0;
			
			if (frames.length)
			{
				var prevFrame:FrameData = null;
				for each (var frame:FrameData in frames)
				{
					if (prevFrame && frame != prevFrame)
					{
						prevFrame.returnToPool();
					}
					
					prevFrame = frame;
				}
				
				frames.fixed = false;
				frames.length = 0;
				frames.fixed = true;
			}
		}
	}
}