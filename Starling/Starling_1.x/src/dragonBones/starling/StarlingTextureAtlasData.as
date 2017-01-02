package dragonBones.starling
{
	import dragonBones.core.BaseObject;
	import dragonBones.textures.TextureAtlasData;
	import dragonBones.textures.TextureData;
	
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public final class StarlingTextureAtlasData extends TextureAtlasData
	{
		public static function fromTextureAtlas(textureAtlas:TextureAtlas):StarlingTextureAtlasData
		{
			const textureAtlasData:StarlingTextureAtlasData = BaseObject.borrowObject(StarlingTextureAtlasData) as StarlingTextureAtlasData;
			for each(var textureName:String in textureAtlas.getNames())
			{
				const textureData:StarlingTextureData = textureAtlasData.generateTexture() as StarlingTextureData;
				textureData.name = textureName;
				textureData.texture = textureAtlas.getTexture(textureName) as SubTexture;
				textureData.rotated = textureAtlas.getRotation(textureName);
				textureData.region.copyFrom(textureAtlas.getRegion(textureName));
				//textureData.frame = textureAtlas.getFrame(textureName);
				textureAtlasData.addTexture(textureData);
			}
			
			textureAtlasData.texture = textureAtlas.texture;
			textureAtlasData.scale = textureAtlas.texture.scale;
			
			return textureAtlasData;
		}
		/**
		 * @private
		 */
		public var disposeTexture:Boolean;
		
		public var texture:Texture;
		/**
		 * @private
		 */
		public function StarlingTextureAtlasData()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			if (texture)
			{
				if (disposeTexture)
				{
					disposeTexture = false;
					texture.dispose();
				}
				
				texture = null;
			}
			else
			{
				disposeTexture = false;
			}
		}
		/**
		 * @private
		 */
		override public function generateTexture():TextureData
		{
			return BaseObject.borrowObject(StarlingTextureData) as StarlingTextureData;
		}
	}
}