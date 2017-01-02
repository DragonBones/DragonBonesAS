package dragonBones.objects
{
	import flash.geom.Point;
	
	import dragonBones.core.BaseObject;
	import dragonBones.enum.DisplayType;
	import dragonBones.geom.Transform;
	import dragonBones.textures.TextureData;
	
	/**
	 * @private
	 */
	public class DisplayData extends BaseObject
	{
		public var isRelativePivot:Boolean;
		public var inheritAnimation:Boolean;
		public var type:int;
		public var name:String;
		public var path:String;
		public var share:String;
		public const pivot:Point = new Point();
		public const transform:Transform = new Transform();
		public var texture:TextureData;
		public var armature:ArmatureData;
		public var mesh:MeshData;
		public var boundingBox: BoundingBoxData;
		
		public function DisplayData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			if (boundingBox) 
			{
				boundingBox.returnToPool();
			}
			
			isRelativePivot = false;
			type = DisplayType.None;
			name = null;
			path = null;
			share = null;
			pivot.x = 0.0;
			pivot.y = 0.0;
			transform.identity();
			texture = null;
			armature = null;
			mesh = null;
			boundingBox = null;
		}
	}
}