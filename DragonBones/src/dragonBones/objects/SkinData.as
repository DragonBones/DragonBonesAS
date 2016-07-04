package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * 皮肤数据。
	 * @version DragonBones 3.0
	 */
	public final class SkinData extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 数据名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		
		/**
		 * @private
		 */
		public const slots:Object = {};
		
		/**
		 * @private
		 */
		public function SkinData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			name = null;
			
			var i:String = null;
			
			for (i in slots)
			{
				(slots[i] as SlotDisplayDataSet).returnToPool();
				delete slots[i];
			}
		}
		
		/**
		 * @private
		 */
		public function addSlot(value:SlotDisplayDataSet):void
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
		
		/**
		 * @private
		 */
		public function getSlot(name:String):SlotDisplayDataSet
		{
			return slots[name] as SlotDisplayDataSet;
		}
	}
}