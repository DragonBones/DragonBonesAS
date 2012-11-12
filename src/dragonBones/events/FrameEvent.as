package dragonBones.events
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.events.Event;
	
	use namespace dragonBones_internal;
	
	public class FrameEvent extends Event
	{
		public static const MOVEMENT_FRAME_EVENT:String = "movementFrameEvent";
		public static const BONE_FRAME_EVENT:String = "boneFrameEvent";
		
		public var movementID:String;
		
		public var frameLabel:String;
		
		public function get armature():Armature
		{
			return target as Armature;
		}
		
		dragonBones_internal var _bone:Bone;
		public function get bone():Bone
		{
			return _bone;
		}
		
		public function FrameEvent(type:String, cancelable:Boolean=false)
		{
			super(type, false, cancelable);
		}
		
		override public function clone():Event
		{
			var event:FrameEvent = new FrameEvent(type, cancelable);
			event.movementID = movementID;
			event.frameLabel = frameLabel;
			event._bone = _bone;
			return event;
		}
	}
}