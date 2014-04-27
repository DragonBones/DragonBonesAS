package dragonBones.utils
{
	import flash.geom.Matrix;
	
	import dragonBones.objects.DBTransform;
	
	/** @private */
	final public class TransformUtil
	{
		private static const HALF_PI:Number = Math.PI * 0.5;
		private static const DOUBLE_PI:Number = Math.PI * 2;
		
		private static const _helpMatrix:Matrix = new Matrix();
		
		public static function formatTransform(transform:DBTransform):void
		{
			var dSkew:Number = formatRadian(transform.skewY - transform.skewX);
			if(dSkew > HALF_PI || dSkew < -HALF_PI)
			{
				transform.scaleX *= -1;
				transform.skewY = formatRadian(transform.skewY - Math.PI);
			}
		} 
		
		public static function transformPointWithParent(transform:DBTransform, parent:DBTransform):void
		{
			transformToMatrix(parent, _helpMatrix);
			_helpMatrix.invert();
			
			var x:Number = transform.x;
			var y:Number = transform.y;
			
			transform.x = _helpMatrix.a * x + _helpMatrix.c * y + _helpMatrix.tx;
			transform.y = _helpMatrix.d * y + _helpMatrix.b * x + _helpMatrix.ty;
			
			transform.skewX = formatRadian(transform.skewX - parent.skewX);
			transform.skewY = formatRadian(transform.skewY - parent.skewY);
			
			formatTransform(transform);
		}
		
		public static function transformToMatrix(transform:DBTransform, matrix:Matrix):void
		{
			matrix.a = transform.scaleX * Math.cos(transform.skewY)
			matrix.b = transform.scaleX * Math.sin(transform.skewY)
			matrix.c = -transform.scaleY * Math.sin(transform.skewX);
			matrix.d = transform.scaleY * Math.cos(transform.skewX);
			matrix.tx = transform.x;
			matrix.ty = transform.y;
		}
		
		public static function formatRadian(radian:Number):Number
		{
			radian %= DOUBLE_PI;
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
	}
	
}