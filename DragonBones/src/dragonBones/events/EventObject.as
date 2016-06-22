package dragonBones.events
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.animation.AnimationState;
	import dragonBones.core.BaseObject;

	public class EventObject extends BaseObject
	{
		public static const START:String = "start";
		public static const LOOP_COMPLETE:String = "loopComplete";
		public static const COMPLETE:String = "complete";
		
		public static const FADE_IN:String = "fadeIn";
		public static const FADE_IN_COMPLETE:String = "fadeInComplete";
		public static const FADE_OUT:String = "fadeOut";
		public static const FADE_OUT_COMPLETE:String = "fadeOutComplete";
		
		public static const FRAME_EVENT:String = "frameEvent";
		public static const SOUND_EVENT:String = "soundEvent";
		
		public var type:String;
		public var name:String;
		public var data:*;
		public var armature:Armature;
		public var bone:Bone;
		public var slot:Slot;
		public var animationState:AnimationState;
		public var userData:*;
		
		public function EventObject()
		{
			super(this);
		}
		
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