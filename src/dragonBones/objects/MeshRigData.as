package dragonBones.objects 
{
	import dragonBones.Bone;
	import dragonBones.utils.TransformUtil;
	import flash.geom.Matrix;
	import flash.geom.Point;
	/**
	 * ...
	 * @author sukui
	 */
	public class MeshRigData 
	{	
		public var bones:Vector.<Bone>;
		public var weights:Vector.<Number>;
		public var vertices:Vector.<Number>;
		
		private var _vertex:Point;
		
		private var _helpMatrix:Matrix;
		private var _helpPoint:Point;
		
		public function MeshRigData() 
		{
			bones = new Vector.<Bone>();
			weights = new Vector.<Number>();
			vertices = new Vector.<Number>();
			_vertex = new Point();
			
			_helpMatrix = new Matrix();
			_helpPoint = new Point();
		}
		
		public function getFinalVertex():Point
		{
			var weight:Number;
			_vertex.x = 0;
			_vertex.y = 0;
			for (var i:int = 0, len:int = bones.length; i < len; i++)
			{
				TransformUtil.transformToMatrix(bones[i].global, _helpMatrix);
				weight = weights[i];
				_helpPoint.x = vertices[i * 2];
				_helpPoint.y = vertices[i * 2 + 1];
				_helpPoint = _helpMatrix.transformPoint(_helpPoint);
				_vertex.x += _helpPoint.x * weight;
				_vertex.y += _helpPoint.y * weight;
			}
			return _vertex;
		}
		
	}

}