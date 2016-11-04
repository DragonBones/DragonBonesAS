package dragonBones.objects
{
	import flash.geom.ColorTransform;
	
	/**
	 * @private
	 */
	public final class SlotFrameData extends TweenFrameData
	{
		public static const DEFAULT_COLOR:ColorTransform = new ColorTransform();
		
		public static function generateColor():ColorTransform
		{
			return new ColorTransform();
		}
		
		public var displayIndex:int;
		public var color:ColorTransform;
		
		public function SlotFrameData()
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
			color = null;
		}
	}
}