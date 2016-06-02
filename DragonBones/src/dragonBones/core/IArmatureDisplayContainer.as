package dragonBones.core
{
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.events.IEventDispatcher;

	/**
	 * @language zh_CN
	 * 骨架显示容器和事件接口。
	 * @see dragonBones.Armature#display
	 * @version DragonBones 3.0
	 */
	public interface IArmatureDisplayContainer extends IEventDispatcher
	{
		/**
		 * @language zh_CN
		 * 释放资源。
		 * @version DragonBones 3.0
		 */
		function dispose():void;
		
		/**
		 * @language zh_CN
		 * @param on 开启自动更新
		 * @version DragonBones 3.0
		 */
		function advanceTimeSelf(on:Boolean):void;
		
		/**
		 * @language zh_CN
		 * 获得使用这个显示容器的骨架。
		 * @see dragonBones.Armature
		 * @version DragonBones 3.0
		 */
		function get armature():Armature;
		
		/**
		 * @language zh_CN
		 * 获得使用这个显示容器的骨架的动画控制器。
		 * @see dragonBones.animation.Animation
		 * @version DragonBones 3.0
		 */
		function get animation():Animation;
	}
}