package dragonBones.objects
{
	import flash.geom.Matrix;
	
	import dragonBones.core.BaseObject;
	
	/**
	 * @private
	 */
	public final class MeshData extends BaseObject
	{
		public var skinned:Boolean;
		public var name:String;
		public const slotPose:Matrix = new Matrix();
		
		public const uvs:Vector.<Number> = new Vector.<Number>(); // vertices * 2
		public const vertices:Vector.<Number> = new Vector.<Number>(); // vertices * 2
		public const vertexIndices:Vector.<uint> = new Vector.<uint>(); // triangles * 3
		
		public const boneIndices:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(); // vertices bones
		public const weights:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(); // vertices bones
		public const boneVertices:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(); // vertices bones * 2
		
		public const bones:Vector.<BoneData> = new Vector.<BoneData>(); // bones
		public const inverseBindPose:Vector.<Matrix> = new Vector.<Matrix>(); // bones
		
		public function MeshData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			skinned = false;
			name = null;
			slotPose.identity();
			uvs.fixed = false;
			uvs.length = 0;
			vertices.fixed = false;
			vertices.length = 0;
			vertexIndices.fixed = false;
			vertexIndices.length = 0;
			boneIndices.fixed = false;
			boneIndices.length = 0;
			weights.fixed = false;
			weights.length = 0;
			boneVertices.fixed = false;
			boneVertices.length = 0;
			bones.fixed = false;
			bones.length = 0;
			inverseBindPose.fixed = false;
			inverseBindPose.length = 0;
		}
	}
}