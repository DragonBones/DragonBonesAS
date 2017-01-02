package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @private
	 */
	public final class SkinData extends BaseObject
	{
		public var name:String;
		public const slots:Object = {};
		
		public function SkinData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			for (var k:String in slots)
			{
				(slots[k] as SkinSlotData).returnToPool();
				delete slots[k];
			}
			
			name = null;
			//slots.clear();
		}
		
		public function addSlot(value:SkinSlotData):void
		{
			if (value && value.slot && !slots[value.slot.name])
			{
				slots[value.slot.name] = value;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		public function getSlot(name:String):SkinSlotData
		{
			return slots[name] as SkinSlotData;
		}
	}
}