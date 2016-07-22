package dragonBones.animation
{
	/**
	 * @language zh_CN
	 * 动画混合时，使用的淡出方式。
	 * @see dragonBones.animation.Animation#fadeIn()
	 * @version DragonBones 4.5
	 */
	public final class AnimationFadeOutMode
	{
		/**
		 * @language zh_CN
		 * 不淡出动画。
		 * @version DragonBones 4.5
		 */
		public static const None:int = 0;
		
		/**
		 * @language zh_CN
		 * 淡出同层的动画。
		 * @version DragonBones 4.5
		 */
		public static const SameLayer:int = 1;
		
		/**
		 * @language zh_CN
		 * 淡出同组的动画。
		 * @version DragonBones 4.5
		 */
		public static const SameGroup:int = 2;
		
		/**
		 * @language zh_CN
		 * 淡出同层并且同组的动画。
		 * @version DragonBones 4.5
		 */
		public static const SameLayerAndGroup:int = 3;
		
		/**
		 * @language zh_CN
		 * 淡出所有动画。
		 * @version DragonBones 4.5
		 */
		public static const All:int = 4;
	}
}