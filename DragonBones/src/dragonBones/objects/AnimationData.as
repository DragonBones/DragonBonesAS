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
		 * @private
		 */
		public var hasAsynchronyTimeline:Boolean;
		
		/**
		 * @language zh_CN
		 * 持续的帧数。
		 * @version DragonBones 3.0
		 */
		public var frameCount:uint;
		
		/**
		 * @language zh_CN
		 * 循环播放的次数。 [0: 无限循环播放, [1~N]: 循环播放 N 次]
		 * @version DragonBones 3.0
		 */
		public var playTimes:uint;
		
		/**
		 * @language zh_CN
		 * 开始的时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public var position:Number;
		
		/**
		 * @language zh_CN
		 * 持续的时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public var duration:Number;
		
		/**
		 * @language zh_CN
		 * 淡入混合的时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public var fadeInTime:Number;
		
		/**
		 * @private
		 */
		public var cacheTimeToFrameScale:Number;
		
		/**
		 * @language zh_CN
		 * 数据名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		
		/**
		 * @private
		 */
		public var animation:AnimationData;
		
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
		public const ffdTimelines:Object = {}; // <skinName ,<slotName, <displayIndex, FFDTimelineData>>>
		
		/**
		 * @private
		 */
		public const cachedFrames:Vector.<Boolean> = new Vector.<Boolean>(0, true);
		
		/**
		 * @private
		 */
		public function AnimationData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			var i:String = null;
			for (i in boneTimelines)
			{
				(boneTimelines[i] as BoneTimelineData).returnToPool();
				delete boneTimelines[i];
			}
			
			for (i in slotTimelines)
			{
				(slotTimelines[i] as SlotTimelineData).returnToPool();
				delete slotTimelines[i];
			}
			
			for (i in ffdTimelines) {
				for (var j:String in ffdTimelines[i]) {
					for (var k:String in ffdTimelines[i][j]) {
						(ffdTimelines[i][j][k] as FFDTimelineData).returnToPool();
					}
				}
				
				delete ffdTimelines[i];
			}
			
			hasAsynchronyTimeline = false;
			frameCount = 0;
			playTimes = 0;
			position = 0;
			duration = 0;
			fadeInTime = 0;
			cacheTimeToFrameScale = 0;
			name = null;
			animation = null;
			zOrderTimeline = null;
			
			if (cachedFrames.length)
			{
				cachedFrames.fixed = false;
				cachedFrames.length = 0;
				cachedFrames.fixed = true;
			}
		}
		
		/**
		 * @private
		 */
		public function cacheFrames(value:Number):void
		{
			if (animation)
			{
				return;
			}
			
			const cacheFrameCount:uint = Math.max(Math.floor((frameCount + 1) * scale * value), 1);
			
			cacheTimeToFrameScale = cacheFrameCount / (duration + 0.000001); //
			cachedFrames.fixed = false;
			cachedFrames.length = 0; // Clear vector 
			cachedFrames.length = cacheFrameCount;
			cachedFrames.fixed = true;
			
			for each (var boneTimeline:BoneTimelineData in boneTimelines)
			{
				boneTimeline.cacheFrames(cacheFrameCount);
			}
			
			for each (var slotTimeline:SlotTimelineData in slotTimelines)
			{
				slotTimeline.cacheFrames(cacheFrameCount);
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
				if (!slot[value.displayIndex])
				{
					slot[value.displayIndex] = value;
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
		public function getFFDTimeline(skinName:String, slotName:String, displayIndex:uint):FFDTimelineData
		{
			const skin:Object = ffdTimelines[skinName];
			if (skin)
			{
				const slot:Object = skin[slotName];
				if (slot)
				{
					return slot[displayIndex] as FFDTimelineData;
				}
			}
			
			return null;
		}
	}
}