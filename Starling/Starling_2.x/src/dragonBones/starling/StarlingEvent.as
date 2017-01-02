package dragonBones.starling
{
	import dragonBones.events.EventObject;
	
	import starling.events.Event;
	
	public final class StarlingEvent extends Event
	{
		public function StarlingEvent(type:String, data:EventObject)
		{
			super(false, data);
		}
		
		public function get eventObject():EventObject
		{
			return data as EventObject;
		}
	}
}