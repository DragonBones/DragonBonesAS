package dragonBones.utils {
	import dragonBones.objects.Node;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	
	public class TransfromUtils {
		private static var helpMatrix1:Matrix = new Matrix();
		private static var helpMatrix2:Matrix = new Matrix();
		
		private static var heloPoint1:Point = new Point();
		private static var heloPoint2:Point = new Point();
		
		public static function transfromPointWidthParent(_boneData:Node, _parentData:Node):void {
			nodeToMatrix(_boneData, helpMatrix1);
			nodeToMatrix(_parentData, helpMatrix2);
			
			helpMatrix2.invert();
			helpMatrix1.concat(helpMatrix2);
			
			matrixToNode(helpMatrix1, _boneData);
		}
		
		private static function nodeToMatrix(_node:Node, _matrix:Matrix):void{
			_matrix.a = _node.scaleX * Math.cos(_node.skewY)
			_matrix.b = _node.scaleX * Math.sin(_node.skewY)
			_matrix.c = -_node.scaleY * Math.sin(_node.skewX);
			_matrix.d = _node.scaleY * Math.cos(_node.skewX);
			
			_matrix.tx = _node.x;
			_matrix.ty = _node.y;
		}
		
		private static function matrixToNode(_matrix:Matrix, _node:Node):void{
			heloPoint1.x = 0;
			heloPoint1.y = 1;
			heloPoint1 = _matrix.deltaTransformPoint(heloPoint1);
			heloPoint2.x = 1;
			heloPoint2.y = 0;
			heloPoint2 = _matrix.deltaTransformPoint(heloPoint2);
			
			_node.skewX = Math.atan2(heloPoint1.y, heloPoint1.x) - Math.PI * 0.5;
			_node.skewY = Math.atan2(heloPoint2.y, heloPoint2.x);
			_node.scaleX = Math.sqrt(_matrix.a * _matrix.a + _matrix.b * _matrix.b);
			_node.scaleY = Math.sqrt(_matrix.c * _matrix.c + _matrix.d * _matrix.d);
			_node.x = _matrix.tx;
			_node.y = _matrix.ty;
		}
	}
	
}