package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @private
	 */
	public final class SlotDisplayDataSet extends BaseObject
	{
		public var slot:SlotData;
		public const displays:Vector.<DisplayData> = new Vector.<DisplayData>(0, true);
		
		public function SlotDisplayDataSet()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			slot = null;
			
			if (displays.length)
			{
				for each (var display:DisplayData in displays)
				{
					display.returnToPool();
				}
				
				displays.fixed = false;
				displays.length = 0;
				displays.fixed = true;
			}
		}
	}
}