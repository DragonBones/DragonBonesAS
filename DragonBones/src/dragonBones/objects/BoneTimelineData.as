package dragonBones.objects
{
	import flash.geom.Matrix;
	
	import dragonBones.geom.Transform;
	
	/**
	 * @private
	 */
	public final class BoneTimelineData extends TimelineData
	{
		public static function cacheFrame(cacheFrames:Vector.<Matrix>, cacheFrameIndex:uint, globalTransformMatrix:Matrix):Matrix
		{
			const cacheMatrix:Matrix = cacheFrames[cacheFrameIndex] = new Matrix();
			cacheMatrix.copyFrom(globalTransformMatrix);
			
			return cacheMatrix;
		}
		
		public var bone:BoneData;
		public const originTransform:Transform = new Transform();
		public const cacheFrames:Vector.<Matrix> = new Vector.<Matrix>(0, true);
		
		public function BoneTimelineData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			bone = null;
			originTransform.identity();
			
			if (cacheFrames.length)
			{
				cacheFrames.fixed = false;
				cacheFrames.length = 0;
				cacheFrames.fixed = true;
			}
		}
	}
}