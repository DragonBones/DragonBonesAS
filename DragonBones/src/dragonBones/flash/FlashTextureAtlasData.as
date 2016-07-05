package dragonBones.flash
{
	import flash.display.BitmapData;
	
	import dragonBones.core.BaseObject;
	import dragonBones.textures.TextureAtlasData;
	import dragonBones.textures.TextureData;
	
	public final class FlashTextureAtlasData extends TextureAtlasData
	{
		public var texture:BitmapData;
		/**
		 * @private
		 */
		public function FlashTextureAtlasData()
		{
			super(this);
		}
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			if (texture)
			{
				texture.dispose();
				texture = null;
			}
		}
		/**
		 * @private
		 */
		override public function generateTexture():TextureData
		{
			return BaseObject.borrowObject(FlashTextureData) as FlashTextureData;
		}
	}
}