package dragonBones.textures
{
	import flash.geom.Rectangle;
	
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public class TextureData extends BaseObject
	{
		public static function generateRectangle():Rectangle
		{
			return new Rectangle();
		}
		
		public var rotated:Boolean;
		public var name:String;
		public var frame:Rectangle;
		public var parent:TextureAtlasData;
		public const region:Rectangle = new Rectangle();
		
		public function TextureData(self:TextureData)
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
			rotated = false;
			name = null;
			frame = null;
			parent = null;
			region.x = 0;
			region.y = 0;
			region.width = 0;
			region.height = 0;
		}
	}
}