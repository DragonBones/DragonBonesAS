package dragonBones.utils
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import dragonBones.objects.DBTransform;
	
	/**
	 * @author CG
	 */
	final public class TransformUtil
	{
		public static const ANGLE_TO_RADIAN:Number = Math.PI / 180;
		public static const RADIAN_TO_ANGLE:Number = 180 / Math.PI;
		
		private static const HALF_PI:Number = Math.PI * 0.5;
		private static const DOUBLE_PI:Number = Math.PI * 2;
		
		private static const _helpTransformMatrix:Matrix = new Matrix();
		private static const _helpParentTransformMatrix:Matrix = new Matrix();
		
		//optimized by freem-trg
		private static var tmpSkewXArray:Vector.<Number> = new Vector.<Number>(4);
 		private static var tmpSkewYArray:Vector.<Number> = new Vector.<Number>(4);
 		private static var ACCURACY : Number = 0.0001;
 
		public static function transformToMatrix(transform:DBTransform, matrix:Matrix):void
		{
			matrix.a = transform.scaleX * Math.cos(transform.skewY)
			matrix.b = transform.scaleX * Math.sin(transform.skewY)
			matrix.c = -transform.scaleY * Math.sin(transform.skewX);
			matrix.d = transform.scaleY * Math.cos(transform.skewX);
			matrix.tx = transform.x;
			matrix.ty = transform.y;
		}
		
		[Inline]
 		private static function isEqual(n1:Number, n2:Number):Boolean
 		{
 			if (n1 >= n2)
 			{
 				return (n1 - n2) <= ACCURACY;
 			}
 			else
 			{
 				return (n2 - n1) <= ACCURACY;
 			}
 		}
 
		public static function formatRadian(radian:Number):Number
		{
			//radian %= DOUBLE_PI;
			if (radian > Math.PI)
			{
				radian -= DOUBLE_PI;
			}
			if (radian < -Math.PI)
			{
				radian += DOUBLE_PI;
			}
			return radian;
		}
		
		//这个算法如果用于骨骼间的绝对转相对请改为DBTransform.divParent()方法
		public static function globalToLocal(transform:DBTransform, parent:DBTransform):void
		{
			transformToMatrix(transform, _helpTransformMatrix);
			transformToMatrix(parent, _helpParentTransformMatrix);
			
			_helpParentTransformMatrix.invert();
			_helpTransformMatrix.concat(_helpParentTransformMatrix);
			
			matrixToTransform(_helpTransformMatrix, transform, transform.scaleX * parent.scaleX >= 0, transform.scaleY * parent.scaleY >= 0);
		}
		
		public static function matrixToTransform(matrix:Matrix, transform:DBTransform, scaleXF:Boolean, scaleYF:Boolean):void
		{
			transform.x = matrix.tx;
			transform.y = matrix.ty;
			transform.scaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b) * (scaleXF ? 1 : -1);
			transform.scaleY = Math.sqrt(matrix.d * matrix.d + matrix.c * matrix.c) * (scaleYF ? 1 : -1);
			
			tmpSkewXArray[0] = Math.acos(matrix.d / transform.scaleY);
			tmpSkewXArray[1] = -tmpSkewXArray[0];
			tmpSkewXArray[2] = Math.asin(-matrix.c / transform.scaleY);
			tmpSkewXArray[3] = tmpSkewXArray[2] >= 0 ? Math.PI - tmpSkewXArray[2] : tmpSkewXArray[2] - Math.PI;
			
			if(isEqual(tmpSkewXArray[0],tmpSkewXArray[2]) || isEqual(tmpSkewXArray[0],tmpSkewXArray[3]))
			{
				transform.skewX = tmpSkewXArray[0];
			}
			else 
			{
				transform.skewX = tmpSkewXArray[1];
			}
			
			tmpSkewYArray[0] = Math.acos(matrix.a / transform.scaleX);
			tmpSkewYArray[1] = -tmpSkewYArray[0];
			tmpSkewYArray[2] = Math.asin(matrix.b / transform.scaleX);
			tmpSkewYArray[3] = tmpSkewYArray[2] >= 0 ? Math.PI - tmpSkewYArray[2] : tmpSkewYArray[2] - Math.PI;
			
			if(isEqual(tmpSkewYArray[0],tmpSkewYArray[2]) || isEqual(tmpSkewYArray[0],tmpSkewYArray[3]))
			{
				transform.skewY = tmpSkewYArray[0];
			}
			else 
			{
				transform.skewY = tmpSkewYArray[1];
			}
		}
		private static const _helpMatrix:Matrix = new Matrix();
		public static function applyMatrixToPoint(targetPoint:Point, matrix:Matrix, returnNewPoint:Boolean = false):Point
		{
			_helpMatrix.tx = targetPoint.x;
			_helpMatrix.ty = targetPoint.y;
			
			_helpMatrix.concat(matrix);
			
			if(returnNewPoint)
			{
				return new Point(_helpMatrix.tx, _helpMatrix.ty);
			}
			else
			{
				targetPoint.x = _helpMatrix.tx;
				targetPoint.y = _helpMatrix.ty;
				return targetPoint;
			}
		}
		//确保角度在-180到180之间
		public static function normalizeRotation(rotation:Number):Number
		{
			rotation = (rotation + Math.PI)%(2*Math.PI);
			rotation = rotation > 0 ? rotation : 2*Math.PI + rotation;
			return rotation - Math.PI;
		}
		
		[Inline]
		public static function matrixToTransformPosition(matrix:Matrix, transform:DBTransform):void
		{
			transform.x = matrix.tx;
			transform.y = matrix.ty;
		}
		
		[Inline]
		public static function matrixToTransformScale(matrix:Matrix, transform:DBTransform, scaleXF:Boolean, scaleYF:Boolean):void
		{
			transform.scaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b) * (scaleXF ? 1 : -1);
			transform.scaleY = Math.sqrt(matrix.d * matrix.d + matrix.c * matrix.c) * (scaleYF ? 1 : -1);
		}
		
		[Inline]
		public static function matrixToTransformRotation(matrix:Matrix, transform:DBTransform, scaleX:Number, scaleY:Number):void
		{
			tmpSkewXArray[0] = Math.acos(matrix.d / scaleY);
			tmpSkewXArray[1] = -tmpSkewXArray[0];
			tmpSkewXArray[2] = Math.asin(-matrix.c / scaleY);
			tmpSkewXArray[3] = tmpSkewXArray[2] >= 0 ? Math.PI - tmpSkewXArray[2] : tmpSkewXArray[2] - Math.PI;
			
			if(isEqual(tmpSkewXArray[0], tmpSkewXArray[2]) || isEqual(tmpSkewXArray[0], tmpSkewXArray[3]))
			{
				transform.skewX = tmpSkewXArray[0];
			}
			else 
			{
				transform.skewX = tmpSkewXArray[1];
			}
			
			tmpSkewYArray[0] = Math.acos(matrix.a / scaleX);
			tmpSkewYArray[1] = -tmpSkewYArray[0];
			tmpSkewYArray[2] = Math.asin(matrix.b / scaleX);
			tmpSkewYArray[3] = tmpSkewYArray[2] >= 0 ? Math.PI - tmpSkewYArray[2] : tmpSkewYArray[2] - Math.PI;
			
			if(isEqual(tmpSkewYArray[0],tmpSkewYArray[2]) || isEqual(tmpSkewYArray[0], tmpSkewYArray[3]))
			{
				transform.skewY = tmpSkewYArray[0];
			}
			else 
			{
				transform.skewY = tmpSkewYArray[1];
			}
		}
	}
}