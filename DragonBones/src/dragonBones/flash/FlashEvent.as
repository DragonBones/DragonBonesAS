package dragonBones.flash
{
	import flash.events.Event;
	
	import dragonBones.events.EventObject;
	
	public final class FlashEvent extends Event
	{
		public var eventObject:EventObject = null;
		
		public function FlashEvent(type:String, data:EventObject)
		{
			super(type);
			
			eventObject = data;
		}
		
		override public function clone():Event
		{
			const event:FlashEvent = new FlashEvent(this.type, eventObject);
			
			return event;
		}
	}
}