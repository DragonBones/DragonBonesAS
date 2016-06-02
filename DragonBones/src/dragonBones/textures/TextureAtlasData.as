package dragonBones.textures
{
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public class TextureAtlasData extends BaseObject
	{
		public var autoSearch:Boolean;
		public var scale:Number;
		public var modifyScale:Number;
		public var name:String;
		public var imagePath:String;
		public const textures:Object = {};
		
		public function TextureAtlasData(self:TextureAtlasData)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			autoSearch = false;
			modifyScale = 1;
			scale = 1;
			name = null;
			imagePath = null;
			
			var i:String = null;
			
			for (i in textures)
			{
				(textures[i] as TextureData).returnToPool();
				delete textures[i];
			}
		}
		
		public function generateTexture():TextureData
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
			return null;
		}
		
		public function addTexture(value:TextureData):void
		{
			if (value && value.name && !textures[value.name])
			{
				textures[value.name] = value;
				value.parent = this;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		public function getTexture(name:String):TextureData
		{
			return textures[name] as TextureData;
		}
	}
}