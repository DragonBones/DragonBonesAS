package dragonBones.objects 
{
	/**
	 * @private
	 */
	public class FFDTimelineData extends TimelineData
	{
		public var skin:SkinData;
		public var slot:SkinSlotData;
		public var display:DisplayData;
		
		public function FFDTimelineData() 
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			skin = null;
			slot = null;
			display = null;
		}
	}

}