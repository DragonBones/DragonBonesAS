package dragonBones.objects
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0, Flash 10
	* @langversion 3.0
	* @version 2.0
	*/
	
	/**
	 * The XMLDataParser class creates and parses xml data from dragonBones generated maps.
	 */
	public class XMLDataParser
	{
		/**
		 * Parse the SkeletonData.
		 * @param	xml The SkeletonData xml to parse.
		 * @return A SkeletonData instance.
		 */
		public static function parseSkeletonData(xml:XML):SkeletonData
		{
			return DataParser.parseData(xml);
		}
	}
}