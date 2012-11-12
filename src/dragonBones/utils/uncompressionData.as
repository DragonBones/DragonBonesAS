package dragonBones.utils{
	import dragonBones.errors.UnknownDataError;
	import dragonBones.objects.SkeletonAndTextureAtlasData;
	
	import flash.utils.ByteArray;
	
	public function uncompressionData(byteArray:ByteArray):SkeletonAndTextureAtlasData 
	{
		var dataType:String = BytesType.getType(byteArray);
		switch(dataType)
		{
			case BytesType.SWF:
			case BytesType.PNG:
			case BytesType.JPG:
				try {
					byteArray.position = byteArray.length - 4;
					var strSize:int = byteArray.readInt();
					var position:uint = byteArray.length - 4 - strSize;
					
					var xmlBytes:ByteArray = new ByteArray();
					xmlBytes.writeBytes(byteArray, position, strSize);
					xmlBytes.uncompress();
					byteArray.length = position;
					
					var skeletonXML:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
					
					byteArray.position = byteArray.length - 4;
					strSize = byteArray.readInt();
					position = byteArray.length - 4 - strSize;
					
					xmlBytes.length = 0;
					xmlBytes.writeBytes(byteArray, position, strSize);
					xmlBytes.uncompress();
					byteArray.length = position;
					var textureAtlasXML:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
				}
				catch (e:Error)
				{
					throw new Error("Uncompression error!");
				}
				
				var sat:SkeletonAndTextureAtlasData = new SkeletonAndTextureAtlasData(skeletonXML, textureAtlasXML, byteArray);
				return sat;
			case BytesType.ZIP:
				throw new Error("Can not uncompression zip!");
			default:
				throw new UnknownDataError();
		}
		return null;
	}
}