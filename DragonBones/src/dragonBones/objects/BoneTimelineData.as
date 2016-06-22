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
		public const cachedFrames:Vector.<Matrix> = new Vector.<Matrix>(0, true);
		
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
			
			if (cachedFrames.length)
			{
				cachedFrames.fixed = false;
				cachedFrames.length = 0;
				cachedFrames.fixed = true;
			}
		}
		
		public function cacheFrames(cacheFrameCount:uint):void
		{
			cachedFrames.fixed = false;
			cachedFrames.length = 0;
			cachedFrames.length = cacheFrameCount;
			cachedFrames.fixed = true;
		}
	}
}