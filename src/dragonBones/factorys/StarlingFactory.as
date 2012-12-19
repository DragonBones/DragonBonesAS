package dragonBones.factorys
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.display.StarlingDisplayBridge;
	import dragonBones.textures.ITextureAtlas;
	import dragonBones.textures.StarlingTextureAtlas;
	import dragonBones.textures.SubTextureData;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.SubTexture;
	
	use namespace dragonBones_internal;
	
	/**
	 * A object managing the set of armature resources for Starling engine. It parses the raw data, stores the armature resources and creates armature instrances.
	 * @see dragonBones.Armature
	 */
	public class StarlingFactory extends BaseFactory
	{
		/**
		 * Creates a new <code>StarlingFactory</code>
		 */
		public function StarlingFactory()
		{
			super();
		}
		
		override protected function generateArmature():Armature
		{
			var armature:Armature = new Armature(new Sprite());
			return armature;
		}
		
		override protected function generateBone():Bone
		{
			var bone:Bone = new Bone(new StarlingDisplayBridge());
			return bone;
		}
		
		override protected function generateTextureDisplay(textureAtlas:ITextureAtlas, fullName:String, pivotX:int, pivotY:int):Object
		{
			var starlingTextureAtlas:StarlingTextureAtlas = textureAtlas as StarlingTextureAtlas;
			if(starlingTextureAtlas)
			{
				//1.4
				var subTextureData:SubTextureData = starlingTextureAtlas.getRegion(fullName) as SubTextureData;
				if(subTextureData)
				{
					pivotX = pivotX || subTextureData.pivotX;
					pivotY = pivotY || subTextureData.pivotY;
				}
				var subTexture:SubTexture = starlingTextureAtlas.getTexture(fullName) as SubTexture;
				if(subTexture)
				{
					var image:Image = new Image(subTexture);
					image.pivotX = pivotX;
					image.pivotY = pivotY;
					return image;
				}
			}
			return null;
		}
		
		override protected function generateTextureAtlas(content:Object, textureAtlasXML:XML):ITextureAtlas
		{
			var texture:Texture;
			var bitmapData:BitmapData;
			if(content is BitmapData)
			{
				bitmapData = content as BitmapData;
				texture = Texture.fromBitmapData(bitmapData);
				bitmapData.dispose();
			}
			else if(content is MovieClip)
			{
				var width:int = int(textureAtlasXML.attribute(ConstValues.A_WIDTH));
				var height:int = int(textureAtlasXML.attribute(ConstValues.A_HEIGHT));
				var movieClip:MovieClip = content as MovieClip;
				bitmapData= new BitmapData(width, height, true, 0xFF00FF);
				bitmapData.draw(movieClip);
				texture = Texture.fromBitmapData(bitmapData);
				bitmapData.dispose();
			}
			else if(content is ByteArray)
			{
				texture =  Texture.fromAtfData(content as ByteArray);
				(content as ByteArray).clear();
			}
			
			var textureAtlas:StarlingTextureAtlas = new StarlingTextureAtlas(texture, textureAtlasXML);
			return textureAtlas;
		}
	}
}