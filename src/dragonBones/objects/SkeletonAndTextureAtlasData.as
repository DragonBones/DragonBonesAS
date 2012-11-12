package dragonBones.objects
{
	import dragonBones.errors.UnknownDataError;
	import dragonBones.utils.ConstValues;
	
	import flash.utils.ByteArray;

	public final class SkeletonAndTextureAtlasData
	{
		public var skeletonData:SkeletonData;
		public var textureAtlasData:TextureAtlasData;
		
		public function SkeletonAndTextureAtlasData(skeletonXML:XML, textureAllasXML:XML, textureBytes:ByteArray)
		{
			skeletonData = XMLDataParser.parseSkeletonData(skeletonXML);
			textureAtlasData = XMLDataParser.parseTextureAtlasData(textureAllasXML, textureBytes);
		}
		
		public function dispose():void{
			skeletonData = null;
			textureAtlasData = null;
		}
	}
}