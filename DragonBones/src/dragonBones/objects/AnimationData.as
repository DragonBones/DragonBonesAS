package dragonBones.objects
{
	/**
	 * @language zh_CN
	 * 动画数据。
	 * @version DragonBones 3.0
	 */
	public final class AnimationData extends TimelineData
	{
		/**
		 * @language zh_CN
		 * 持续的帧数。
		 * @version DragonBones 3.0
		 */
		public var frameCount:uint;
		/**
		 * @language zh_CN
		 * 播放次数。 [0: 无限循环播放, [1~N]: 循环播放 N 次]
		 * @version DragonBones 3.0
		 */
		public var playTimes:uint;
		/**
		 * @language zh_CN
		 * 持续时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public var duration:Number;
		/**
		 * @language zh_CN
		 * 淡入时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public var fadeInTime:Number;
		/**
		 * @private
		 */
		public var cacheFrameRate:Number;
		/**
		 * @language zh_CN
		 * 数据名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		/**
		 * @private
		 */
		public var zOrderTimeline:ZOrderTimelineData;
		/**
		 * @private
		 */
		public const boneTimelines:Object = {};
		/**
		 * @private
		 */
		public const slotTimelines:Object = {};
		/**
		 * @private
		 */
		public const ffdTimelines:Object = {}; // skinName ,slotName, mesh
		/**
		 * @private
		 */
		public const cachedFrames:Vector.<Boolean> = new Vector.<Boolean>();
		/**
		 * @private
		 */
		public const boneCachedFrameIndices: Object = {}; //Object<Vector.<Number>>
		/**
		 * @private
		 */
		public const slotCachedFrameIndices: Object = {}; //Object<Vector.<Number>>
		/**
		 * @private
		 */
		public function AnimationData()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			for (var k:String in boneTimelines)
			{
				(boneTimelines[k] as BoneTimelineData).returnToPool();
				delete boneTimelines[k];
			}
			
			for (k in slotTimelines)
			{
				(slotTimelines[k] as SlotTimelineData).returnToPool();
				delete slotTimelines[k];
			}
			
			for (k in ffdTimelines) {
				for (var kA:String in ffdTimelines[k]) 
				{
					for (var kB:String in ffdTimelines[k][kA]) 
					{
						(ffdTimelines[k][kA][kB] as FFDTimelineData).returnToPool();
					}
				}
				
				delete ffdTimelines[k];
			}
			
			for (k in boneCachedFrameIndices) 
			{
				// boneCachedFrameIndices[i].length = 0;
				delete boneCachedFrameIndices[k];
			}
			
			for (k in slotCachedFrameIndices) {
				// slotCachedFrameIndices[i].length = 0;
				delete slotCachedFrameIndices[k];
			}
			
			if (zOrderTimeline) 
			{
				zOrderTimeline.returnToPool();
			}
			
			frameCount = 0;
			playTimes = 0;
			duration = 0.0;
			fadeInTime = 0.0;
			cacheFrameRate = 0.0;
			name = null;
			//boneTimelines.clear();
			//slotTimelines.clear();
			//ffdTimelines.clear();
			cachedFrames.fixed = false;
			cachedFrames.length = 0;
			//boneCachedFrameIndices.clear();
			//boneCachedFrameIndices.clear();
			zOrderTimeline = null;
		}
		/**
		 * @private
		 */
		public function cacheFrames(frameRate:Number):void
		{
			if (cacheFrameRate > 0.0)
			{
				return;
			}
			
			cacheFrameRate = Math.max(Math.ceil(frameRate * scale), 1.0);
			const cacheFrameCount:uint = Math.ceil(cacheFrameRate * duration) + 1; // uint
			cachedFrames.length = cacheFrameCount;
			cachedFrames.fixed = true;
			
			for (var k:String in boneTimelines) 
			{
				var indices:Vector.<int> = new Vector.<int>(cacheFrameCount, true)
				for (var i:uint = 0, l:uint = indices.length; i < l; ++ i)
				{
					indices[i] = -1;
				}
				
				boneCachedFrameIndices[k] = indices;
			}
			
			for (k in slotTimelines) 
			{
				indices = new Vector.<int>(cacheFrameCount, true)
				for (i = 0, l = indices.length; i < l; ++ i)
				{
					indices[i] = -1;
				}
				
				slotCachedFrameIndices[k] = indices;
			}
		}
		/**
		 * @private
		 */
		public function addBoneTimeline(value:BoneTimelineData):void
		{
			if (value && value.bone && !boneTimelines[value.bone.name])
			{
				boneTimelines[value.bone.name] = value;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		/**
		 * @private
		 */
		public function addSlotTimeline(value:SlotTimelineData):void
		{
			if (value && value.slot && !slotTimelines[value.slot.name])
			{
				slotTimelines[value.slot.name] = value;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		/**
		 * @private
		 */
		public function addFFDTimeline(value:FFDTimelineData):void
		{
			if (value && value.skin && value.slot)
			{
				const skin:Object = ffdTimelines[value.skin.name] = ffdTimelines[value.skin.name] || {};
				const slot:Object = skin[value.slot.slot.name] = skin[value.slot.slot.name] || {};
				if (!slot[value.display.name])
				{
					slot[value.display.name] = value;
				}
				else
				{
					throw new ArgumentError();
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
		/**
		 * @private
		 */
		public function getBoneTimeline(name:String):BoneTimelineData
		{
			return boneTimelines[name] as BoneTimelineData;
		}
		/**
		 * @private
		 */
		public function getSlotTimeline(name:String):SlotTimelineData
		{
			return slotTimelines[name] as SlotTimelineData;
		}
		/**
		 * @private
		 */
		public function getFFDTimeline(skinName:String, slotName:String):Object
		{
			const skin:Object = ffdTimelines[skinName];
			if (skin)
			{
				return skin[slotName];
			}
			
			return null;
		}
		/**
		 * @private
		 */
		public function getBoneCachedFrameIndices(name: String): Vector.<int> 
		{
			return boneCachedFrameIndices[name];
		}
		/**
		 * @private
		 */
		public function getSlotCachedFrameIndices(name: String): Vector.<int> 
		{
			return slotCachedFrameIndices[name];
		}
	}
}