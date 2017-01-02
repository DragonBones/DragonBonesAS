package dragonBones.events
{
	/**
	 * @language zh_CN
	 * 事件接口。
	 * @version DragonBones 4.5
	 */
	public interface IEventDispatcher
	{
		/**
		 * @private
		 */
		function _dispatchEvent(type:String, value:EventObject):void;
		/**
		 * @language zh_CN
		 * 是否包含指定类型的事件。
		 * @param type 事件类型。
		 * @version DragonBones 4.5
		 */
		function hasEvent(type:String):Boolean;
		/**
		 * @language zh_CN
		 * 添加事件。
		 * @param type 事件类型。
		 * @param listener 事件回调。
		 * @version DragonBones 4.5
		 */
		function addEvent(type:String, listener:Function):void;
		/**
		 * @language zh_CN
		 * 移除事件。
		 * @param type 事件类型。
		 * @param listener 事件回调。
		 * @version DragonBones 4.5
		 */
		function removeEvent(type:String, listener:Function):void;
	}
}