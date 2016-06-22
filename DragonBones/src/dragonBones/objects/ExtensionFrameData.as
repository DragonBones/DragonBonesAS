package dragonBones.objects
{
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public final class ExtensionFrameData extends TweenFrameData
	{
		public var type:int;
		public const tweens:Vector.<Number> = new Vector.<Number>(0, true);
		public const keys:Vector.<Number> = new Vector.<Number>(0, true);
		
		public function ExtensionFrameData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			type = DragonBones.EXTENSION_TYPE_FFD;
			
			if (tweens.length)
			{
				tweens.fixed = false;
				tweens.length = 0;
				tweens.fixed = true;
			}
			
			if (keys.length)
			{
				keys.fixed = false;
				keys.length = 0;
				keys.fixed = true;
			}
		}
	}
}