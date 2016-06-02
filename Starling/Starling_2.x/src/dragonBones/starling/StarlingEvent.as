package dragonBones.starling
{
	import dragonBones.events.EventObject;
	
	import starling.events.Event;
	
	public final class StarlingEvent extends Event
	{
		public function StarlingEvent(data:EventObject)
		{
			super(data.type, false, data);
		}
		
		public function get eventObject():EventObject
		{
			return this.data as EventObject;
		}
	}
}