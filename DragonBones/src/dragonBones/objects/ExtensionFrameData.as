package dragonBones.objects
{
	/**
	 * @private
	 */
	public final class ExtensionFrameData extends TweenFrameData
	{
		public const tweens:Vector.<Number> = new Vector.<Number>();
		
		public function ExtensionFrameData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			tweens.fixed = false;
			tweens.length = 0;
		}
	}
}