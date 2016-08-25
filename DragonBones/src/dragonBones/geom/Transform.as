package dragonBones.geom
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * @language zh_CN
	 * 2D 变换。
	 * @version DragonBones 3.0
	 */
	public final class Transform
	{
		/**
		 * @private
		 */
		public static function normalizeRadian(value:Number):Number
		{
			value = (value + Math.PI) % (Math.PI * 2);
			// value += value > 0? -Math.PI: Math.PI;
			if (value > 0)
			{
				value -= Math.PI;
			}
			else
			{
				value += Math.PI;
			}
			
			return value;
		}
		
		/**
		 * @private
		 */
		public static function transformPoint(matrix:Matrix, x:Number, y:Number, result:Point, delta:Boolean = false):void
		{
			result.x = matrix.a * x + matrix.c * y;
			result.y = matrix.b * x + matrix.d * y;
			
			if (!delta)
			{
				result.x += matrix.tx;
				result.y += matrix.ty;
			}
		}
		
		/**
		 * @language zh_CN
		 * 水平位移。
		 * @version DragonBones 3.0
		 */
		public var x:Number = 0;
		
		/**
		 * @language zh_CN
		 * 垂直位移。
		 * @version DragonBones 3.0
		 */
		public var y:Number = 0;
		
		/**
		 * @language zh_CN
		 * 水平倾斜。 (以弧度为单位)
		 * @version DragonBones 3.0
		 */
		public var skewX:Number = 0;
		
		/**
		 * @language zh_CN
		 * 垂直倾斜。 (以弧度为单位)
		 * @version DragonBones 3.0
		 */
		public var skewY:Number = 0;
		
		/**
		 * @language zh_CN
		 * 水平缩放。
		 * @version DragonBones 3.0
		 */
		public var scaleX:Number = 1;
		
		/**
		 * @language zh_CN
		 * 垂直缩放。
		 * @version DragonBones 3.0
		 */
		public var scaleY:Number = 1;
		
		/**
		 * @private
		 */
		public function Transform()
		{
		}
		
		/**
		 * @private
		 */
		public function toString():String 
		{
			return "[object dragonBones.geom.Transform] x:" + x + " y:" + y + " skewX:" + skewX * 180 / Math.PI + " skewY:" + skewY * 180 / Math.PI + " scaleX:" + scaleX + " scaleY:" + scaleY;
		}
		
		/**
		 * @private
		 */
		[inline]
		final public function copyFrom(value:Transform):Transform
		{
			x = value.x;
			y = value.y;
			skewX = value.skewX;
			skewY = value.skewY;
			scaleX = value.scaleX;
			scaleY = value.scaleY;
			
			return this;
		}
		
		/**
		 * @private
		 */
		[inline]
		final public function clone():Transform
		{
			const value:Transform = new Transform();
			value.copyFrom(this);
			
			return value;
		}
		
		/**
		 * @private
		 */
		[inline]
		final public function identity():Transform
		{
			x = y = skewX = skewY = 0;
			scaleX = scaleY = 1;
			
			return this;
		}
		
		/**
		 * @private
		 */
		[inline]
		final public function add(value:Transform):Transform
		{
			x += value.x;
			y += value.y;
			skewX += value.skewX;
			skewY += value.skewY;
			scaleX *= value.scaleX;
			scaleY *= value.scaleY;
			
			return this;
		}
		
		/**
		 * @private
		 */
		[inline]
		final public function minus(value:Transform):Transform
		{
			x -= value.x;
			y -= value.y;
			skewX = normalizeRadian(skewX - value.skewX);
			skewY = normalizeRadian(skewY - value.skewY);
			scaleX /= value.scaleX;
			scaleY /= value.scaleY;
			
			return this;
		}
		
		/**
		 * @private
		 */
		[inline]
		final public function fromMatrix(matrix:Matrix):Transform
		{
			const PI_Q:Number = Math.PI * 0.25;
			
			const backupScaleX:Number = scaleX, backupScaleY:Number = scaleY;
			
			x = matrix.tx;
			y = matrix.ty;
			
			//skewX = Math.atan2(-matrix.c, matrix.d);
			//skewY = Math.atan2(matrix.b, matrix.a);
			skewX = Math.atan(-matrix.c / matrix.d);
			skewY = Math.atan(matrix.b / matrix.a);
			if (skewX != skewX) skewX = 0;
			if (skewY != skewY) skewY = 0;
			
			// scaleY = (skewX > -PI_Q && skewX < PI_Q)? matrix.d / Math.cos(skewX): -matrix.c / Math.sin(skewX);
			if (skewX > -PI_Q && skewX < PI_Q)
			{
				scaleY = matrix.d / Math.cos(skewX);
			}
			else
			{
				scaleY = -matrix.c / Math.sin(skewX);
			}
			
			// scaleX = (skewY > -PI_Q && skewY < PI_Q)? matrix.a / Math.cos(skewY):  matrix.b / Math.sin(skewY);
			if (skewY > -PI_Q && skewY < PI_Q)
			{
				scaleX = matrix.a / Math.cos(skewY);
			}
			else
			{
				scaleX = matrix.b / Math.sin(skewY);
			}
			
			if (backupScaleX >=0 && scaleX < 0)
			{
				scaleX = -scaleX;
				skewY = skewY - Math.PI;
			}
			
			if (backupScaleY >= 0 && scaleY < 0)
			{
				scaleY = -scaleY;
				skewX = skewX - Math.PI;
			}
			
			return this;
		}
		
		/**
		 * @language zh_CN
		 * 转换为矩阵。
		 * @version DragonBones 3.0
		 */
		[inline]
		final public function toMatrix(matrix:Matrix):Transform
		{
			matrix.a = scaleX * Math.cos(skewY);
			matrix.b = scaleX * Math.sin(skewY);
			matrix.c = -scaleY * Math.sin(skewX);
			matrix.d = scaleY * Math.cos(skewX);
			matrix.tx = x;
			matrix.ty = y;
			
			return this;
		}
		
		/**
		 * @language zh_CN
		 * 旋转。 (以弧度为单位)
		 * @version DragonBones 3.0
		 */
		[inline]
		final public function get rotation():Number
		{
			return skewY;
		}
		[inline]
		final public function set rotation(value:Number):void
		{
			const dValue:Number = value - skewY;
			skewX += dValue;
			skewY += dValue;
		}
	}
}