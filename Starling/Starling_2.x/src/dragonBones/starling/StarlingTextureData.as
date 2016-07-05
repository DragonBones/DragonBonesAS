package dragonBones.starling
{
	import dragonBones.textures.TextureData;
	
	import starling.textures.Texture;
	
	/**
	 * @private
	 */
	public final class StarlingTextureData extends TextureData
	{
		public var texture:Texture = null;
		
		public function StarlingTextureData()
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
	}
}