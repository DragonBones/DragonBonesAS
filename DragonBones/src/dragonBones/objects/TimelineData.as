package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public class TimelineData extends BaseObject
	{
		/**
		 * @private
		 */
		public var scale:Number;
		
		/**
		 * @private
		 */
		public var offset:Number;
		
		/**
		 * @private
		 */
		public const frames:Vector.<FrameData> = new Vector.<FrameData>(0, true);
		
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
			scale = 1;
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