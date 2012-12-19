package dragonBones.utils 
{
	import dragonBones.objects.Node;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/** @private */
	public class TransfromUtils 
	{
		private static var _helpMatrix:Matrix = new Matrix();
		private static var _helpPoint:Point = new Point();
		
		public static function transfromPointWithParent(boneData:Node, parentData:Node):void 
		{
			nodeToMatrix(parentData, _helpMatrix);
			
			_helpPoint.x = boneData.x;
			_helpPoint.y = boneData.y;
			
			_helpMatrix.invert();
			_helpPoint = _helpMatrix.transformPoint(_helpPoint);
			boneData.x = _helpPoint.x;
			boneData.y = _helpPoint.y;
			
			boneData.skewX -= parentData.skewX;
			boneData.skewY -= parentData.skewY;
		}
		
		private static function nodeToMatrix(node:Node, matrix:Matrix):void
		{
			matrix.a = node.scaleX * Math.cos(node.skewY)
			matrix.b = node.scaleX * Math.sin(node.skewY)
			matrix.c = -node.scaleY * Math.sin(node.skewX);
			matrix.d = node.scaleY * Math.cos(node.skewX);
			
			matrix.tx = node.x;
			matrix.ty = node.y;
		}
	}
	
}