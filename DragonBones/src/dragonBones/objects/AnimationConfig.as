package dragonBones.objects
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.animation.AnimationFadeOutMode;
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * @beta
	 * 动画配置，描述播放一个动画所需要的全部信息。
	 * @version DragonBones 5.0
	 */
	public final class AnimationConfig extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 是否暂停淡出的动画。
		 * @default true
		 * @version DragonBones 5.0
		 */
		public var pauseFadeOut: Boolean;
		/**
		 * @language zh_CN
		 * 淡出模式。
		 * @default dragonBones.animation.AnimationFadeOutMode.All
		 * @see dragonBones.animation.AnimationFadeOutMode
		 * @version DragonBones 5.0
		 */
		public var fadeOutMode: int;
		/**
		 * @language zh_CN
		 * 淡出时间。 [-1: 与淡入时间同步, [0~N]: 淡出时间] (以秒为单位)
		 * @default -1
		 * @version DragonBones 5.0
		 */
		public var fadeOutTime: Number;
		/**
		 * @language zh_CN
		 * 淡出缓动方式。
		 * @default 0
		 * @version DragonBones 5.0
		 */
		public var fadeOutEasing: Number;
		/**
		 * @language zh_CN
		 * 是否以增加的方式混合。
		 * @default false
		 * @version DragonBones 5.0
		 */
		public var additiveBlending: Boolean;
		/**
		 * @language zh_CN
		 * 是否对插槽的显示对象有控制权。
		 * @default true
		 * @version DragonBones 5.0
		 */
		public var displayControl: Boolean;
		/**
		 * @language zh_CN
		 * 是否暂停淡入的动画，直到淡入过程结束。
		 * @default true
		 * @version DragonBones 5.0
		 */
		public var pauseFadeIn: Boolean;
		/**
		 * @language zh_CN
		 * 否能触发行为。
		 * @default true
		 * @version DragonBones 5.0
		 */
		public var actionEnabled: Boolean;
		/**
		 * @language zh_CN
		 * 播放次数。 [-1: 使用动画数据的播放次数, 0: 无限循环播放, [1~N]: 循环播放 N 次]
		 * @default -1
		 * @version DragonBones 5.0
		 */
		public var playTimes: int;
		/**
		 * @language zh_CN
		 * 混合图层。
		 * @default 0
		 * @version DragonBones 5.0
		 */
		public var layer: int;
		/**
		 * @language zh_CN
		 * 开始时间。 (以秒为单位)
		 * @default 0
		 * @version DragonBones 5.0
		 */
		public var position: Number;
		/**
		 * @language zh_CN
		 * 持续时间。 [-1: 使用动画数据的持续时间, 0: 动画停止, (0~N]: 持续时间] (以秒为单位)
		 * @default -1
		 * @version DragonBones 5.0
		 */
		public var duration: Number;
		/**
		 * @language zh_CN
		 * 播放速度。 [(-N~0): 倒转播放, 0: 停止播放, (0~1): 慢速播放, 1: 正常播放, (1~N): 快速播放]
		 * @default 1
		 * @version DragonBones 3.0
		 */
		public var timeScale: Number;
		/**
		 * @language zh_CN
		 * 淡入时间。 [-1: 使用动画数据的淡入时间, [0~N]: 淡入时间] (以秒为单位)
		 * @default -1
		 * @version DragonBones 5.0
		 */
		public var fadeInTime: Number;
		/**
		 * @language zh_CN
		 * 自动淡出时间。 [-1: 不自动淡出, [0~N]: 淡出时间] (以秒为单位)
		 * @default -1
		 * @version DragonBones 5.0
		 */
		public var autoFadeOutTime: Number;
		/**
		 * @language zh_CN
		 * 淡入缓动方式。
		 * @default 0
		 * @version DragonBones 5.0
		 */
		public var fadeInEasing: Number;
		/**
		 * @language zh_CN
		 * 权重。
		 * @default 1
		 * @version DragonBones 5.0
		 */
		public var weight: Number;
		/**
		 * @language zh_CN
		 * 动画状态名。
		 * @version DragonBones 5.0
		 */
		public var name: String;
		/**
		 * @language zh_CN
		 * 动画数据名。
		 * @version DragonBones 5.0
		 */
		public var animationName: String;
		/**
		 * @language zh_CN
		 * 动画组。
		 * @version DragonBones 5.0
		 */
		public var group: String;
		/**
		 * @language zh_CN
		 * 骨骼遮罩。
		 * @version DragonBones 5.0
		 */
		public const boneMask: Vector.<String> = new Vector.<String>();
		/**
		 * @private
		 */
		public function AnimationConfig()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear(): void 
		{
			pauseFadeOut = true;
			fadeOutMode = AnimationFadeOutMode.All;
			fadeOutTime = -1.0;
			fadeOutEasing = 0.0;
			
			additiveBlending = false;
			displayControl = true;
			pauseFadeIn = true;
			actionEnabled = true;
			playTimes = -1;
			layer = 0;
			position = 0.0;
			duration = -1.0;
			timeScale = -100.0;
			fadeInTime = -1.0;
			autoFadeOutTime = -1.0;
			fadeInEasing = 0.0;
			weight = 1.0;
			name = null;
			animationName = null;
			group = null;
			boneMask.length = 0;
		}
		
		public function clear(): void 
		{
			_onClear();
		}
		
		public function copyFrom(value: AnimationConfig): void 
		{
			pauseFadeOut = value.pauseFadeOut;
			fadeOutMode = value.fadeOutMode;
			autoFadeOutTime = value.autoFadeOutTime;
			fadeOutEasing = value.fadeOutEasing;
			
			additiveBlending = value.additiveBlending;
			displayControl = value.displayControl;
			pauseFadeIn = value.pauseFadeIn;
			actionEnabled = value.actionEnabled;
			playTimes = value.playTimes;
			layer = value.layer;
			position = value.position;
			duration = value.duration;
			timeScale = value.timeScale;
			fadeInTime = value.fadeInTime;
			fadeOutTime = value.fadeOutTime;
			fadeInEasing = value.fadeInEasing;
			weight = value.weight;
			name = value.name;
			animationName = value.animationName;
			group = value.group;
			
			boneMask.length = value.boneMask.length;
			for (var i:uint = 0, l:uint = boneMask.length; i < l; ++i) 
			{
				boneMask[i] = value.boneMask[i];
			}
		}
		
		public function containsBoneMask(name: String): Boolean 
		{
			return boneMask.length === 0 || boneMask.indexOf(name) >= 0;
		}
		
		public function addBoneMask(armature: Armature, name: String, recursive: Boolean = true): void 
		{
			const currentBone: Bone = armature.getBone(name);
			if (!currentBone) 
			{
				return;
			}
			
			if (boneMask.indexOf(name) < 0) // Add mixing
			{
				boneMask.push(name);
			}
			
			if (recursive) // Add recursive mixing.
			{
				const bones:Vector.<Bone> = armature.getBones();
				for (var i:uint = 0, l:uint = bones.length; i < l; ++i) 
				{
					const bone:Bone = bones[i];
					if (boneMask.indexOf(bone.name) < 0 && currentBone.contains(bone))
					{
						boneMask.push(bone.name);
					}
				}
			}
		}
		
		public function removeBoneMask(armature: Armature, name: String, recursive: Boolean = true): void 
		{
			var index:int = boneMask.indexOf(name);
			if (index >= 0)  // Remove mixing.
			{
				boneMask.splice(index, 1);
			}
			
			if (recursive) 
			{
				const currentBone:Bone = armature.getBone(name);
				if (currentBone) 
				{
					const bones:Vector.<Bone> = armature.getBones();
					if (boneMask.length > 0) // Remove recursive mixing.
					{
						for (var i:uint = 0, l:uint = bones.length; i < l; ++i) 
						{
							var bone:Bone = bones[i];
							index = boneMask.indexOf(bone.name);
							if (index >= 0 && currentBone.contains(bone)) 
							{
								boneMask.splice(index, 1);
							}
						}
					}
					else // Add unrecursive mixing.
					{
						for (i = 0, l = bones.length; i < l; ++i) 
						{
							bone = bones[i];
							if (!currentBone.contains(bone)) 
							{
								boneMask.push(bone.name);
							}
						}
					}
				}
			}
		}
	}
}