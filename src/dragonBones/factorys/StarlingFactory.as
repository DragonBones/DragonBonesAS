package dragonBones.factorys 
{
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.display.StarlingDisplayBridge;
	import dragonBones.objects.Node;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.TextureData;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.dragonBones_internal;
	
	import starling.display.Sprite;
	import starling.display.Image;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace dragonBones_internal;
	
	/**
	 *
	 * @author Akdcl
	 */
	public class StarlingFactory extends BaseFactory 
	{
		public static function getTextureDisplay(textureData:TextureData, fullName:String):Image 
		{
			var subTextureXML:XML = textureData.getSubTextureXML(fullName);
			if (subTextureXML) 
			{
				var subTexture:SubTexture = textureData.subTextures[fullName];
				if(!subTexture)
				{
					var rect:Rectangle = new Rectangle(
						int(subTextureXML.attribute(ConstValues.A_X)),
						int(subTextureXML.attribute(ConstValues.A_Y)),
						int(subTextureXML.attribute(ConstValues.A_WIDTH)),
						int(subTextureXML.attribute(ConstValues.A_HEIGHT))
					);
					subTexture = new SubTexture(textureData.texture as Texture, rect);
					textureData.subTextures[fullName] = subTexture;
				}
				var image:Image = new Image(subTexture);
				image.pivotX = int(subTextureXML.attribute(ConstValues.A_PIVOT_X));
				image.pivotY = int(subTextureXML.attribute(ConstValues.A_PIVOT_Y));
				return image;
			}
			return null;
		}
		
		override public function set textureData(value:TextureData):void
		{
			super.textureData = value;
			if(_textureData)
			{
				_textureData.bitmap;
			}
		}
		
		public var autoDisposeBitmapData:Boolean = true;
		
		public function StarlingFactory() 
		{
			super();
		}
		
		override protected function generateArmature():Armature 
		{
			if (!textureData.texture) 
			{
				if(textureData.dataType == BytesType.ATF)
				{
					textureData.texture = Texture.fromAtfData(textureData.rawData);
				}
				else
				{
					textureData.texture = Texture.fromBitmap(textureData.bitmap);
					//no need to keep the bitmapData
					if (autoDisposeBitmapData) 
					{
						textureData.bitmap.bitmapData.dispose();
					}
				}
			}
			
			var armature:Armature = new Armature(new Sprite());
			return armature;
		}
		
		override protected function generateBone():Bone 
		{
			var bone:Bone = new Bone(new StarlingDisplayBridge());
			return bone;
		}
		
		override protected function getBoneTextureDisplay(textureName:String):Object
		{
			return getTextureDisplay(_textureData, textureName);
		}
	}
}