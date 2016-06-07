package dragonBones.objects 
{
	/**
	 * @private
	 */
	public class FFDTimelineData extends TimelineData
	{
		public var displayIndex:uint;
		public var skin:SkinData;
		public var slot:SlotDisplayDataSet;
		
		public function FFDTimelineData() 
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			displayIndex = 0;
			skin = null;
			slot = null;
		}
	}

}