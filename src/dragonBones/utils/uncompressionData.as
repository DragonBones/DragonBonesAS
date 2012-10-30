package dragonBones.utils{
	import dragonBones.errors.UnknownDataError;
	import dragonBones.objects.SkeletonAndTextureRawData;
	
	import flash.utils.ByteArray;
	
	public function uncompressionData(_byteArray:ByteArray):SkeletonAndTextureRawData {
		var _dataType:String = BytesType.getType(_byteArray);
		switch(_dataType){
			case BytesType.SWF:
			case BytesType.PNG:
			case BytesType.JPG:
			case BytesType.ATF:
				try {
					_byteArray.position = _byteArray.length - 4;
					var _strSize:int = _byteArray.readInt();
					var _position:uint = _byteArray.length - 4 - _strSize;
					
					var _xmlByte:ByteArray = new ByteArray();
					_xmlByte.writeBytes(_byteArray, _position, _strSize);
					_xmlByte.uncompress();
					_byteArray.length = _position;
					
					var _skeletonXML:XML = XML(_xmlByte.readUTFBytes(_xmlByte.length));
					
					_byteArray.position = _byteArray.length - 4;
					_strSize = _byteArray.readInt();
					_position = _byteArray.length - 4 - _strSize;
					
					_xmlByte.length = 0;
					_xmlByte.writeBytes(_byteArray, _position, _strSize);
					_xmlByte.uncompress();
					_byteArray.length = _position;
					var _textureAtlasXML:XML = XML(_xmlByte.readUTFBytes(_xmlByte.length));
				}catch (_e:Error) {
					throw new Error("Uncompression error!");
				}
				var _sat:SkeletonAndTextureRawData = new SkeletonAndTextureRawData(_skeletonXML, _textureAtlasXML, _byteArray);
				return _sat;
			case BytesType.ZIP:
				throw new Error("Can not uncompression zip!");
			default:
				throw new UnknownDataError();
		}
		return null;
	}
}