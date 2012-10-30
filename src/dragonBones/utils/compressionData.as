package dragonBones.utils{
	import flash.utils.ByteArray;
	
	public function compressionData(_skeletonXML:XML, _textureAtlasXML:XML, _byteArray:ByteArray):ByteArray {
		var _byteArrayCopy:ByteArray = new ByteArray();
		_byteArrayCopy.writeBytes(_byteArray);
		
		var _xmlByte:ByteArray = new ByteArray();
		_xmlByte.writeUTFBytes(_textureAtlasXML.toXMLString());
		_xmlByte.compress();
		
		_byteArrayCopy.position = _byteArrayCopy.length;
		_byteArrayCopy.writeBytes(_xmlByte);
		_byteArrayCopy.writeInt(_xmlByte.length);
		
		_xmlByte.length = 0;
		_xmlByte.writeUTFBytes(_skeletonXML.toXMLString());
		_xmlByte.compress();
		
		_byteArrayCopy.position = _byteArrayCopy.length;
		_byteArrayCopy.writeBytes(_xmlByte);
		_byteArrayCopy.writeInt(_xmlByte.length);
		
		return _byteArrayCopy;
	}
}