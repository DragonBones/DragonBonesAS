package dragonBones.core
{
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.events.IEventDispatcher;

	/**
	 * @language zh_CN
	 * 骨架显示容器和事件的接口。
	 * @see dragonBones.Armature#display
	 * @version DragonBones 4.5
	 */
	public interface IArmatureDisplay extends IEventDispatcher
	{
		/**
		 * @private
		 */
		function _debugDraw():void;
		
		/**
		 * @private
		 */
		function _onReplaceTexture(texture:Object):void;
		
		/**
		 * @language zh_CN
		 * 释放显示对象和骨架。 (骨架会回收到内存池)
		 * @version DragonBones 4.5
		 */
		function dispose():void;
		
		/**
		 * @language zh_CN
		 * 由显示容器来更新骨架和动画。
		 * @param on 开启或关闭显示容器对骨架与动画的更新。
		 * @version DragonBones 4.5
		 */
		function advanceTimeBySelf(on:Boolean):void;
		
		/**
		 * @language zh_CN
		 * 获取使用这个显示容器的骨架。
		 * @see dragonBones.Armature
		 * @version DragonBones 4.5
		 */
		function get armature():Armature;
		
		/**
		 * @language zh_CN
		 * 获取使用骨架的动画控制器。
		 * @see dragonBones.animation.Animation
		 * @version DragonBones 4.5
		 */
		function get animation():Animation;
	}
}