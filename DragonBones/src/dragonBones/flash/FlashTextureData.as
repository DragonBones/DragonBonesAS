package dragonBones.flash
{
	import flash.display.BitmapData;
	
	import dragonBones.textures.TextureData;
	
	/**
	 * @private
	 */
	public final class FlashTextureData extends TextureData
	{
		public var texture:BitmapData;
		
		public function FlashTextureData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			if (texture)
			{
				texture.dispose();
				texture = null;
			}
		}
	}
}