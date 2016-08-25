package dragonBones.objects
{
	import flash.geom.Point;
	
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.geom.Transform;
	import dragonBones.textures.TextureData;
	
	/**
	 * @private
	 */
	public class DisplayData extends BaseObject
	{
		public var isRelativePivot:Boolean;
		public var type:int;
		public var name:String;
		public var texture:TextureData;
		public var armature:ArmatureData;
		public var mesh:MeshData;
		public const pivot:Point = new Point();
		public const transform:Transform = new Transform();
		
		public function DisplayData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			isRelativePivot = false;
			type = DragonBones.DISPLAY_TYPE_IMAGE;
			name = null;
			texture = null;
			armature = null;
			
			if (mesh)
			{
				mesh.returnToPool();
				mesh = null;
			}
			
			pivot.x = 0;
			pivot.y = 0;
			transform.identity();
		}
	}
}