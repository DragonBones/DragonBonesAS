package dragonBones.objects
{
	import flash.geom.Matrix;

	/**
	 * @private
	 */
	public final class SlotTimelineData extends TimelineData
	{
		public static function cacheFrame(cacheFrames:Vector.<Matrix>, cacheFrameIndex:uint, globalTransformMatrix:Matrix):Matrix
		{
			const cacheMatrix:Matrix = cacheFrames[cacheFrameIndex] = new Matrix();
			cacheMatrix.copyFrom(globalTransformMatrix);
			
			return cacheMatrix;
		}
		
		public var slot:SlotData;
		public const cacheFrames:Vector.<Matrix> = new Vector.<Matrix>(0, true);
		
		public function SlotTimelineData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			slot = null;
			
			if (cacheFrames.length)
			{
				cacheFrames.fixed = false;
				cacheFrames.length = 0;
				cacheFrames.fixed = true;
			}
		}
	}
}