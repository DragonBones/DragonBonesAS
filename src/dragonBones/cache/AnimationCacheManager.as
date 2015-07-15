package dragonBones.cache
{
	import dragonBones.core.ICacheUser;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.fast.FastArmature;
	import dragonBones.fast.animation.FastAnimationState;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;

	use namespace dragonBones_internal;
	
	public class AnimationCacheManager
	{
		public var cacheGeneratorArmature:FastArmature
		public var armatureData:ArmatureData;
		public var frameRate:Number;
		public var animationCacheDic:Object = {};
//		public var boneFrameCacheDic:Object = {};
		public var slotFrameCacheDic:Object = {};
		public function AnimationCacheManager()
		{
		}
		
		public static function initWithArmatureData(armatureData:ArmatureData, frameRate:Number = 0):AnimationCacheManager
		{
			var output:AnimationCacheManager = new AnimationCacheManager();
			output.armatureData = armatureData;
			if(frameRate<=0)
			{
				var animationData:AnimationData = armatureData.animationDataList[0];
				if(animationData)
				{
					output.frameRate = animationData.frameRate;
				}
			}
			else
			{
				output.frameRate = frameRate;
			}
			
			return output;
		}
		
		public function initAllAnimationCache():void
		{
			for each(var animationData:AnimationData in armatureData.animationDataList)
			{
				animationCacheDic[animationData.name] = AnimationCache.initWithAnimationData(animationData,armatureData);
			}
		}
		
		public function initAnimationCache(animationName:String):void
		{
			animationCacheDic[animationName] = AnimationCache.initWithAnimationData(armatureData.getAnimationData(animationName),armatureData);
		}
		
		public function bindCacheUserArmatures(armatures:Array):void
		{
			for each(var armature:FastArmature in armatures)
			{
				bindCacheUserArmature(armature);
			}
			
		}
		
		public function bindCacheUserArmature(armature:FastArmature):void
		{
			armature.animation.animationCacheManager = this;
			
			var cacheUser:ICacheUser;
//			for each(cacheUser in armature._boneDic)
//			{
//				cacheUser.frameCache = boneFrameCacheDic[cacheUser.name];
//			}
			for each(cacheUser in armature._slotDic)
			{
				cacheUser.frameCache = slotFrameCacheDic[cacheUser.name];
			}
		}
		
		public function setCacheGeneratorArmature(armature:FastArmature):void
		{
			cacheGeneratorArmature = armature;
			
			var cacheUser:ICacheUser;
//			for each(cacheUser in armature._boneDic)
//			{
//				boneFrameCacheDic[cacheUser.name] = new FrameCache();
//			}
			for each(cacheUser in armature._slotDic)
			{
				slotFrameCacheDic[cacheUser.name] = new SlotFrameCache();
			}
			
			for each(var animationCache:AnimationCache in animationCacheDic)
			{
//				animationCache.initBoneTimelineCacheDic(armature._boneDic, boneFrameCacheDic);
				animationCache.initSlotTimelineCacheDic(armature._slotDic, slotFrameCacheDic);
			}
		}
		
		public function generateAllAnimationCache():void
		{
			for each(var animationCache:AnimationCache in animationCacheDic)
			{
				generateAnimationCache(animationCache.name);
			}
		}
		
		public function generateAnimationCache(animationName:String):void
		{
			var temp:Boolean = cacheGeneratorArmature.enableCache;
			cacheGeneratorArmature.enableCache = false;
			var animationCache:AnimationCache = animationCacheDic[animationName];
			if(!animationCache)
			{
				return;
			}
			cacheGeneratorArmature.animation.gotoAndPlay(animationName,0,-1,1);
			var animationState:FastAnimationState = cacheGeneratorArmature.animation.animationState;
			var passTime:Number = 1 / frameRate;
			cacheGeneratorArmature._disableEventDispatch = true;
			do
			{
				cacheGeneratorArmature.advanceTime(passTime);
				animationCache.addFrame();
				
			}while (!animationState.isComplete);
			
			cacheGeneratorArmature._disableEventDispatch = false;
			cacheGeneratorArmature._eventList.length = 0;
			resetCacheGeneratorArmature();
			cacheGeneratorArmature.enableCache = temp;
		}
		
		/**
		 * 将缓存生成器骨架重置，生成动画缓存后调用。
		 */
		public function resetCacheGeneratorArmature():void
		{
			cacheGeneratorArmature.resetAnimation();
		}
		
		public function getAnimationCache(animationName:String):AnimationCache
		{
			return animationCacheDic[animationName];
		} 
	}
}