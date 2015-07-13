package dragonBones.cache
{
	import flash.geom.Matrix;
	
	import dragonBones.objects.DBTransform;

	public class FrameCache
	{
		public var globalTransform:DBTransform = new DBTransform();
		public var globalTransformMatrix:Matrix = new Matrix();
		public function FrameCache()
		{
		}
		
		//浅拷贝提高效率
		public function copy(frameCache:FrameCache):void
		{
			globalTransform = frameCache.globalTransform;
			globalTransformMatrix = frameCache.globalTransformMatrix;
		}
	}
}