package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public final class EventData extends BaseObject
	{
		public var type:int;
		public var name:String;
		public var data:*;
		public var bone:BoneData;
		public var slot:SlotData;
		
		public function EventData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			type = DragonBones.EVENT_TYPE_FRAME;
			name = null;
			data = null;
			bone = null;
			slot = null;
		}
	}
}