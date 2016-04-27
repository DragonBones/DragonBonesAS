package dragonBones.objects 
{
	import flash.geom.Matrix;

	/**
	 * ...
	 * @author sukui
	 */
	public class MeshData extends DisplayData
	{
		public var skinned:Boolean = false;
		public var numVertex:uint = 0;
		public var numTriangle:uint = 0;
		public const triangles:Vector.<uint> = new Vector.<uint>(0, true);
		public const vertices:Vector.<VertexData> = new Vector.<VertexData>(0, true);
		public const vertexBones:Vector.<VertexBoneData> = new Vector.<VertexBoneData>(0, true);
		public const bones:Vector.<BoneData> = new Vector.<BoneData>();
		public const inverseBindPose:Vector.<Matrix> = new Vector.<Matrix>();
		public const slotPose:Matrix = new Matrix();
		
		public function MeshData() 
		{
			super();
		}
		
		override public function dispose():void 
		{
			super.dispose();
			
			triangles.fixed= false;
			triangles.length = 0;
			vertices.fixed= false;
			vertices.length = 0;
			vertexBones.fixed= false;
			vertexBones.length = 0;
			bones.fixed= false;
			bones.length = 0;
			inverseBindPose.fixed= false;
			inverseBindPose.length = 0;
		}
	}
}