package dragonBones.objects
{
	import dragonBones.core.DragonBones;
	import dragonBones.objects.SkeletonData;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.parseObjectData;
	import dragonBones.utils.parseOldXMLData;
	import dragonBones.utils.parserXMLData;
	
	import flash.utils.ByteArray;
	
	public final class DataParser
	{
		/**
		 * Compress all data into a ByteArray for serialization.
		 * @param	The DragonBones data.
		 * @param	The TextureAtlas data.
		 * @param	The ByteArray representing the map.
		 * @return ByteArray. A DragonBones compatible ByteArray.
		 */
		public static function compressData(dragonBonesData:Object, textureAtlasData:Object, textureDataBytes:ByteArray):ByteArray
		{
			var retult:ByteArray = new ByteArray();
			retult.writeBytes(textureDataBytes);
			
			var dataBytes:ByteArray = new ByteArray();
			dataBytes.writeObject(textureAtlasData);
			dataBytes.compress();
			
			retult.position = retult.length;
			retult.writeBytes(dataBytes);
			retult.writeInt(dataBytes.length);
			
			dataBytes.length = 0;
			dataBytes.writeObject(dragonBonesData);
			dataBytes.compress();
			
			retult.position = retult.length;
			retult.writeBytes(dataBytes);
			retult.writeInt(dataBytes.length);
			
			return retult;
		}
		
		/**
		 * Decompress a compatible DragonBones data.
		 * @param	compressedByteArray The ByteArray to decompress.
		 * @return A DecompressedData instance.
		 */
		public static function decompressData(bytes:ByteArray):DecompressedData
		{
			var dataType:String = BytesType.getType(bytes);
			switch (dataType)
			{
				case BytesType.SWF: 
				case BytesType.PNG: 
				case BytesType.JPG: 
				case BytesType.ATF: 
					try
					{
						bytes.position = bytes.length - 4;
						var strSize:int = bytes.readInt();
						var position:uint = bytes.length - 4 - strSize;
						
						var dataBytes:ByteArray = new ByteArray();
						dataBytes.writeBytes(bytes, position, strSize);
						dataBytes.uncompress();
						bytes.length = position;
						
						var dragonBonesData:Object;
						if(dataBytes[dataBytes.length - 1] == ">".charCodeAt(0))
						{
							dragonBonesData = XML(dataBytes.readUTFBytes(dataBytes.length));
						}
						else
						{
							dragonBonesData = dataBytes.readObject();
						}
						
						bytes.position = bytes.length - 4;
						strSize = bytes.readInt();
						position = bytes.length - 4 - strSize;
						
						dataBytes.length = 0;
						dataBytes.writeBytes(bytes, position, strSize);
						dataBytes.uncompress();
						bytes.length = position;
						
						var textureAtlasData:Object;
						if(dataBytes[dataBytes.length-1]==">".charCodeAt(0))
						{
							textureAtlasData = XML(dataBytes.readUTFBytes(dataBytes.length));
						}
						else
						{
							textureAtlasData = dataBytes.readObject();
						}
					}
					catch (e:Error)
					{
						throw new Error("Data error!");
					}
					
					var decompressedData:DecompressedData = new DecompressedData(dragonBonesData, textureAtlasData, bytes);
					decompressedData.textureBytesDataType = dataType;
					return decompressedData;
				case BytesType.ZIP:
					throw new Error("Can not decompress zip!");
				default: 
					throw new Error("Nonsupport data!");
			}
			return null;
		}
		
		public static function parseData(data:Object):SkeletonData
		{
			var version:String;
			if(data is XML)
			{
				version = data.@[ConstValues.A_VERSION];
				switch (version)
				{
					case "1.5":
					case "2.0":
					case "2.1":
					case "2.1.1":
					case "2.1.2":
					case "2.2":
						return parseOldXMLData(data as XML);
					case DragonBones.DATA_VERSION:
						return parserXMLData(data as XML);
				}
			}
			else
			{
				try
				{
					version = data[ConstValues.A_VERSION];
					switch (version)
					{
						case DragonBones.DATA_VERSION:
							return parseObjectData(data);
					}
				}
				catch(e:Error)
				{
				}
			}
			
			throw new Error("Nonsupport version!");
			
			return null;
		}
	}
}