package dragonBones.animation
{
	import dragonBones.core.DragonBones;

	/**
	 * @language zh_CN
	 * WorldClock 提供时钟的支持，为每个加入到时钟的 IAnimatable 对象更新时间。
	 * @see dragonBones.animation.IAnimatable
	 * @see dragonBones.Armature
	 * @version DragonBones 3.0
	 */
	public final class WorldClock implements IAnimateble
	{
		/**
		 * @language zh_CN
		 * 一个可以直接使用的全局 WorldClock 实例.
		 * @version DragonBones 3.0
		 */
		public static const clock:WorldClock = new WorldClock();
		
		/**
		 * @language zh_CN
		 * 当前的时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public var time:Number = new Date().getTime() / DragonBones.SECOND_TO_MILLISECOND;
		
		/**
		 * @language zh_CN
		 * 时间流逝的速度，用于实现动画的变速播放。 [0: 停止播放, (0~1): 慢速播放, 1: 正常播放, (1~N): 快速播放]
         * @default 1
		 * @version DragonBones 3.0
		 */
		public var timeScale:Number = 1;
		
		private const _animatebles:Vector.<IAnimateble> = new Vector.<IAnimateble>();
		
		/**
		 * @language zh_CN
		 * 创建一个新的 WorldClock 实例。
		 * 通常并不需要单独创建 WorldClock 的实例，可以直接使用 WorldClock.clock 静态实例。
		 * (创建更多独立的 WorldClock 可以更灵活的为需要更新的 IAnimateble 实例分组，实现不同组不同速度的动画播放)
		 * @version DragonBones 3.0
		 */
		public function WorldClock()
		{
		}
		
		/**
		 * @language zh_CN
		 * 为所有的 IAnimatable 实例向前播放一个指定的时间。 (通常这个方法需要在 ENTER_FRAME 事件的响应函数中被调用)
		 * @param passedTime 前进的时间。 (以秒为单位，当设置为 -1 时将自动计算当前帧与上一帧的时间差)
		 * @version DragonBones 3.0
		 */
		public function advanceTime(passedTime:Number):void
		{
			if (passedTime != passedTime)
			{
				passedTime = 0;
			}
			
			if (passedTime < 0)
			{
				passedTime = new Date().getTime() / DragonBones.SECOND_TO_MILLISECOND - time;
			}
			
			passedTime *= timeScale;
			
			if (passedTime < 0)
			{
				time -= passedTime;
			}
			else
			{
				time += passedTime;
			}
			
			if (passedTime)
			{
				var i: uint = 0, r: uint = 0, l: uint = _animatebles.length;
				var animateble:IAnimateble = null;
				
				for (; i < l; ++i) 
				{
					animateble = _animatebles[i];
					if (animateble) 
					{
						if (r > 0) 
						{
							_animatebles[i - r] = animateble;
							_animatebles[i] = null;
						}
						
						animateble.advanceTime(passedTime);
					} 
					else 
					{
						r++;
					}
				}
				
				if (r > 0) 
				{
					l = _animatebles.length;
					
					for (; i < l; ++i) 
					{
						animateble = _animatebles[i];
						if (animateble) 
						{
							_animatebles[i - r] = animateble;
						} 
						else 
						{
							r++;
						}
					}
					
					_animatebles.length -= r;
				}
			}
		}
		
		/** 
		 * 是否包含指定的 IAnimatable 实例
		 * @param value 指定的 IAnimatable 实例。
		 * @return  [true: 包含，false: 不包含]。
		 * @version DragonBones 3.0
		 */
		public function contains(value:IAnimateble):Boolean
		{
			return _animatebles.indexOf(value) >= 0;
		}
		
		/**
		 * @language zh_CN
		 * 添加指定的 IAnimatable 实例。
		 * @param value IAnimatable 实例。
		 * @version DragonBones 3.0
		 */
		public function add(value:IAnimateble):void
		{
			if (value && _animatebles.indexOf(value) < 0)
			{
				_animatebles.push(value);
			}
		}
		
		/**
		 * @language zh_CN
		 * 移除指定的 IAnimatable 实例。
		 * @param value IAnimatable 实例。
		 * @version DragonBones 3.0
		 */
		public function remove(value:IAnimateble):void
		{
			var index:int = _animatebles.indexOf(value);
			if (index >= 0)
			{
				_animatebles[index] = null;
			}
		}
		
		/**
		 * @language zh_CN
		 * 清除所有的 IAnimatable 实例。
		 * @version DragonBones 3.0
		 */
		public function clear():void
		{
			for (var i: uint = 0, l: uint = _animatebles.length; i < l; ++i)
			{
				_animatebles[i] = null;
			}
		}
	}
}