package dragonBones.events
{
	import dragonBones.Armature;
	
	import flash.events.Event;

	public class AnimationEvent extends flash.events.Event
	{
		public static const MOVEMENT_CHANGE:String = "movementChange";
		public static const START:String = "animationStart";
		public static const COMPLETE:String = "movementComplete";
		public static const LOOP_COMPLETE:String = "movementLoopComplete";
		
		public var exMovementID:String;
		public var movementID:String;
		
		public function get armature():Armature
		{
			return target as Armature;
		}

		public function AnimationEvent(type:String, cancelable:Boolean = false) 
		{
			super(type, false, cancelable);
		}
		
		override public function clone():Event
		{
			var event:AnimationEvent = new AnimationEvent(type, cancelable);
			event.exMovementID = exMovementID;
			event.movementID = movementID;
			return event;
		}
	}
}