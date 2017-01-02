package dragonBones.core
{
	import dragonBones.Armature;
	import dragonBones.animation.Animation;
	import dragonBones.events.IEventDispatcher;
	
	/**
	 * @language zh_CN
	 * 骨架代理接口。
	 * @version DragonBones 5.0
	 */
	public interface IArmatureProxy extends IEventDispatcher
	{
		/**
		 * @private
		 */
		function _onClear():void;
		/**
		 * @private
		 */
		function _debugDraw(isEnabled:Boolean):void;
		/**
		 * @language zh_CN
		 * 释放代理和骨架。 (骨架会回收到对象池)
		 * @version DragonBones 4.5
		 */
		function dispose():void;
		/**
		 * @language zh_CN
         * 获取骨架。
		 * @see dragonBones.Armature
		 * @version DragonBones 4.5
		 */
		function get armature():Armature;
		/**
		 * @language zh_CN
         * 获取动画控制器。
		 * @see dragonBones.animation.Animation
		 * @version DragonBones 4.5
		 */
		function get animation():Animation;
	}
}

