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
		public const region:Rectangle = new Rectangle();
		public var frame:Rectangle;
		public var parent:TextureAtlasData;
		
		public function TextureData(self:TextureData)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		override protected function _onClear():void
		{
			rotated = false;
			name = null;
			region.x = 0.0;
			region.y = 0.0;
			region.width = 0.0;
			region.height = 0.0;
			frame = null;
			parent = null;
		}
		
		public function copyFrom(value: TextureData): void 
		{
			rotated = value.rotated;
			name = value.name;
			
			if (!frame && value.frame) 
			{
				frame = TextureData.generateRectangle();
			}
			else if (frame && !value.frame) 
			{
				frame = null;
			}
			
			if (frame && value.frame) 
			{
				frame.copyFrom(value.frame);
			}
			
			parent = value.parent;
			region.copyFrom(value.region);
		}
	}
}