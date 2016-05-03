package dragonBones.objects
{
	import flash.geom.Point;

	public final class VertexBoneData
	{
		public const indices:Vector.<uint> = new Vector.<uint>();
		public const weights:Vector.<Number> = new Vector.<Number>();
		public const vertices:Vector.<Point> = new Vector.<Point>();
		
		public function VertexBoneData()
		{
		}
		
		public function dispose():void
		{
			indices.length = 0;
			weights.length = 0;
			vertices.length = 0;
		}
	}
}