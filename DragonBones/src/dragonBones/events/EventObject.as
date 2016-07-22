package dragonBones.events
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.animation.AnimationState;
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * 事件数据。
	 * @version DragonBones 4.5
	 */
	public class EventObject extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 动画开始。
		 * @version DragonBones 4.5
		 */
		public static const START:String = "start";
		/**
		 * @language zh_CN
		 * 动画循环播放一次完成。
		 * @version DragonBones 4.5
		 */
		public static const LOOP_COMPLETE:String = "loopComplete";
		/**
		 * @language zh_CN
		 * 动画播放完成。
		 * @version DragonBones 4.5
		 */
		public static const COMPLETE:String = "complete";
		
		/**
		 * @language zh_CN
		 * 动画淡入开始。
		 * @version DragonBones 4.5
		 */
		public static const FADE_IN:String = "fadeIn";
		/**
		 * @language zh_CN
		 * 动画淡入完成。
		 * @version DragonBones 4.5
		 */
		public static const FADE_IN_COMPLETE:String = "fadeInComplete";
		/**
		 * @language zh_CN
		 * 动画淡出开始。
		 * @version DragonBones 4.5
		 */
		public static const FADE_OUT:String = "fadeOut";
		/**
		 * @language zh_CN
		 * 动画淡出完成。
		 * @version DragonBones 4.5
		 */
		public static const FADE_OUT_COMPLETE:String = "fadeOutComplete";
		
		/**
		 * @language zh_CN
		 * 动画帧事件。
		 * @version DragonBones 4.5
		 */
		public static const FRAME_EVENT:String = "frameEvent";
		/**
		 * @language zh_CN
		 * 动画声音事件。
		 * @version DragonBones 4.5
		 */
		public static const SOUND_EVENT:String = "soundEvent";
		
		/**
		 * @language zh_CN
		 * 事件类型。
	 	 * @version DragonBones 4.5
		 */
		public var type:String;
		
		/**
		 * @language zh_CN
		 * 事件名称。 (帧标签的名称或声音的名称)
		 * @version DragonBones 4.5
		 */
		public var name:String;
		
		/**
		 * @language zh_CN
		 * 扩展的数据。
		 * @version DragonBones 4.5
		 */
		public var data:*;
		
		/**
		 * @language zh_CN
		 * 发出事件的骨架。
		 * @version DragonBones 4.5
		 */
		public var armature:Armature;
		
		/**
		 * @language zh_CN
		 * 发出事件的骨骼。
		 * @version DragonBones 4.5
		 */
		public var bone:Bone;
		
		/**
		 * @language zh_CN
		 * 发出事件的插槽。
		 * @version DragonBones 4.5
		 */
		public var slot:Slot;
		
		/**
		 * @language zh_CN
		 * 发出事件的动画状态。
		 * @version DragonBones 4.5
		 */
		public var animationState:AnimationState;
		
		/**
		 * @language zh_CN
		 * 用户数据。
		 * @version DragonBones 4.5
		 */
		public var userData:*;
		
		/**
		 * @private
		 */
		public function EventObject()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			type = null;
			name = null;
			data = null;
			armature = null;
			bone = null;
			slot = null;
			animationState = null;
			userData = null;
		}
	}
}