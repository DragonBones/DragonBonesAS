package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.enum.EventType;
	
	/**
	 * @private
	 */
	public final class EventData extends BaseObject
	{
		public var type:int;
		public var name:String;
		public var bone:BoneData;
		public var slot:SlotData;
		public var data:CustomData;
		
		public function EventData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			if (data)
			{
				data.returnToPool();
			}
			
			type = EventType.None;
			name = null;
			bone = null;
			slot = null;
			data = null;
		}
	}
}