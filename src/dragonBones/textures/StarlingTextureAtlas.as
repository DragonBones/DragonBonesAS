package dragonBones.textures
{
	import dragonBones.utils.ConstValues;
	
	import flash.geom.Rectangle;
	
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class StarlingTextureAtlas extends TextureAtlas implements ITextureAtlas
	{
		protected var _subTextureDic:Object;
		
		private var _atlasScale:Number;
		
		protected var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		public function StarlingTextureAtlas(texture:Texture, textureAtlasXML:XML, atlasScale:Number = NaN)
		{
			if(isNaN(atlasScale))
			{
				_atlasScale = texture.scale;
			}
			else
			{
				_atlasScale = atlasScale;
			}
			
			super(texture, textureAtlasXML);
			if(textureAtlasXML)
			{
				_name = textureAtlasXML.attribute(ConstValues.A_NAME);
			}
			_subTextureDic = {};
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			for each(var subTexture:SubTexture in _subTextureDic) {
				subTexture.dispose();
			}
			
			_subTextureDic = null;
		}
		
		override public function getTexture(name:String):Texture
		{
			var texture:Texture = _subTextureDic[name];
			if(!texture)
			{
				texture = super.getTexture(name);
				if(texture)
				{
					_subTextureDic[name] = texture;
				}
			}
			return texture;
		}
		
		//1.4
		override protected function parseAtlasXml(atlasXml:XML):void
		{
			var scale:Number = _atlasScale;
			
			for each (var subTexture:XML in atlasXml.SubTexture)
			{
				var name:String        = subTexture.attribute("name");
				var x:Number           = parseFloat(subTexture.attribute("x")) / scale;
				var y:Number           = parseFloat(subTexture.attribute("y")) / scale;
				var width:Number       = parseFloat(subTexture.attribute("width")) / scale;
				var height:Number      = parseFloat(subTexture.attribute("height")) / scale;
				var frameX:Number      = parseFloat(subTexture.attribute("frameX")) / scale;
				var frameY:Number      = parseFloat(subTexture.attribute("frameY")) / scale;
				var frameWidth:Number  = parseFloat(subTexture.attribute("frameWidth")) / scale;
				var frameHeight:Number = parseFloat(subTexture.attribute("frameHeight")) / scale;
				
				//1.4
				var region:SubTextureData = new SubTextureData(x, y, width, height);
				region.pivotX = int(subTexture.attribute(ConstValues.A_PIVOT_X));
				region.pivotY = int(subTexture.attribute(ConstValues.A_PIVOT_Y));
				
				var frame:Rectangle  = frameWidth > 0 && frameHeight > 0 ?
					new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;
				
				addRegion(name, region, frame);
			}
		}
	}
}