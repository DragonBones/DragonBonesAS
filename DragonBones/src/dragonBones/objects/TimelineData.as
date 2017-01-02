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
		/**
		 * @private
		 */
		public var offset:Number;
		/**
		 * @private
		 */
		public const frames:Vector.<FrameData> = new Vector.<FrameData>();
		/**
		 * @private
		 */
		public function TimelineData(self:TimelineData)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			scale = 1.0;
			offset = 0.0;
			
			var prevFrame:FrameData = null;
			for (var i:uint = 0, l:uint = frames.length; i < l; ++i) // Find key frame data.
			{
				const frame:FrameData = frames[i];
				if (prevFrame && frame !== prevFrame)
				{
					prevFrame.returnToPool();
				}
				
				prevFrame = frame;
			}
			
			frames.fixed = false;
			frames.length = 0;
		}
	}
}