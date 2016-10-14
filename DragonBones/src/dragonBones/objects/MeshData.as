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
		public const slotPose:Matrix = new Matrix();
		
		public const uvs:Vector.<Number> = new Vector.<Number>(0, true); // vertices * 2
		public const vertices:Vector.<Number> = new Vector.<Number>(0, true); // vertices * 2
		public const vertexIndices:Vector.<uint> = new Vector.<uint>(0, true); // triangles * 3
		
		public const boneIndices:Vector.<Vector.<uint>> = new Vector.<Vector.<uint>>(0, true); // vertices bones
		public const weights:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(0, true); // vertices bones
		public const boneVertices:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(0, true); // vertices bones * 2
		
		public const bones:Vector.<BoneData> = new Vector.<BoneData>(0, true); // bones
		public const inverseBindPose:Vector.<Matrix> = new Vector.<Matrix>(0, true); // bones
		
		public function MeshData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			skinned = false;
			slotPose.identity();
			
			if (uvs.length)
			{
				uvs.fixed = false;
				uvs.length = 0;
				uvs.fixed = true;
			}
			
			if (vertices.length)
			{
				vertices.fixed = false;
				vertices.length = 0;
				vertices.fixed = true;
			}
			
			if (vertexIndices.length)
			{
				vertexIndices.fixed = false;
				vertexIndices.length = 0;
				vertexIndices.fixed = true;
			}
			
			if (boneIndices.length)
			{
				boneIndices.fixed = false;
				boneIndices.length = 0;
				boneIndices.fixed = true;
			}
			
			if (weights.length)
			{
				weights.fixed = false;
				weights.length = 0;
				weights.fixed = true;
			}
			
			if (boneVertices.length)
			{
				boneVertices.fixed = false;
				boneVertices.length = 0;
				boneVertices.fixed = true;
			}
			
			
			if (bones.length)
			{
				bones.fixed = false;
				bones.length = 0;
				bones.fixed = true;
			}
			
			if (inverseBindPose.length)
			{
				inverseBindPose.fixed = false;
				inverseBindPose.length = 0;
				inverseBindPose.fixed = true;
			}
		}
	}
}