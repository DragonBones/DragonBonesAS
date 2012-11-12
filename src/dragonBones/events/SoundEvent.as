package dragonBones.events
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.events.Event;
	
	use namespace dragonBones_internal;
	
	public class SoundEvent extends Event
	{
		public static const SOUND:String = "soundFrame";
		
		public var movementID:String;
		
		public var sound:String;
		public var soundEffect:String;
		
		dragonBones_internal var _armature:Armature;
		public function get armature():Armature
		{
			return _armature;
		}
		
		dragonBones_internal var _bone:Bone;
		public function get bone():Bone
		{
			return _bone;
		}
		
		public function SoundEvent(type:String, cancelable:Boolean=false)
		{
			super(type, false, cancelable);
		}
		
		override public function clone():Event
		{
			var event:SoundEvent = new SoundEvent(type, cancelable);
			event.movementID = movementID;
			event.sound = sound;
			event.soundEffect = soundEffect;
			event._armature = _armature;
			event._bone = _bone;
			return event;
		}
	}
}