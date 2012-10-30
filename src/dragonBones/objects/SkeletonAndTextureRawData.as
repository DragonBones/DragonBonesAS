package dragonBones.objects{
	import dragonBones.errors.UnknownDataError;
	import dragonBones.objects.SkeletonAndTextureRawData;
	
	import dragonBones.utils.ConstValues;
	
	import flash.utils.ByteArray;

	public final class SkeletonAndTextureRawData{
		public var skeletonXML:XML;
		public var textureAtlasXML:XML;
		public var textureBytes:ByteArray;
		
		public function SkeletonAndTextureRawData(_skeletonXML:XML, _textureAllasXML:XML, _textureBytes:ByteArray){
			skeletonXML = _skeletonXML;
			textureAtlasXML = _textureAllasXML;
			textureBytes = _textureBytes;
			checkVersion();
		}
		
		public function dispose():void{
			skeletonXML = null;
			textureAtlasXML = null;
			textureBytes = null;
		}
		
		private function checkVersion():void{
			var _version:String = skeletonXML.attribute(ConstValues.A_VERSION);
			switch(_version){
				case ConstValues.VERSION:
					break;
				default:
					throw new Error("Nonsupport data version!");
					break;
			}
		}
	}
}