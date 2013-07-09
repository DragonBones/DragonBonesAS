package dragonBones.objects
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0, Flash 10
	* @langversion 3.0
	* @version 2.0
	*/
	import flash.utils.ByteArray;
	/**
	 * The DecompressedData is a convenient class for storing animation related data (data, atlas, object).
	 *
	 * @see dragonBones.Armature
	 */
	public final class DecompressedData
	{
		public var dataType:String;
		/**
		 * A xml for DragonBones data.
		 */
		public var xml:XML;
		/**
		 * A xml for atlas data.
		 */
		public var textureAtlasXML:XML;
		/**
		 * The non parsed data map.
		 */
		public var textureBytes:ByteArray;
		
		/**
		 * Creates a new DecompressedData instance.
		 * @param	xml A xml for DragonBones data.
		 * @param	textureAtlasXML A xml for atlas data.
		 * @param	textureBytes The non parsed data map.
		 */
		public function DecompressedData(xml:XML, textureAtlasXML:XML, textureBytes:ByteArray)
		{
			this.xml = xml;
			this.textureAtlasXML = textureAtlasXML;
			this.textureBytes = textureBytes;
		}
		
		public function dispose():void
		{
			xml = null;
			textureAtlasXML = null;
			textureBytes = null;
		}
	}
}