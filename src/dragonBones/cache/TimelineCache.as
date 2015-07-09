package dragonBones.cache
{
	import dragonBones.core.ICacheUser;

	public class TimelineCache
	{
		public var name:String;
		public var cacheGenerator:ICacheUser;
//		public function set cacheGenerator(value:ICacheUser):void
//		{
//			_cacheGenerator = value;
//		}
//		public function get cacheGenerator():ICacheUser
//		{
//			return _cacheGenerator;
//		}
		public var frameCacheList:Vector.<FrameCache> = new Vector.<FrameCache>();
		public var currentFrameCache:FrameCache;
		public function TimelineCache()
		{
		}
		
		public function addFrame():void
		{
			var cache:FrameCache = new FrameCache();
			cache.globalTransform.copy(cacheGenerator.global);
			cache.globalTransformMatrix.copyFrom(cacheGenerator.globalTransformMatrix);
			frameCacheList.push(cache);
		}
		public function update(frameIndex:int):void
		{
			currentFrameCache.copy(frameCacheList[frameIndex]);
		}
		
		public function bindCacheUser(cacheUser:ICacheUser):void
		{
			cacheUser.frameCache = currentFrameCache;
		}
		
		
	}
}