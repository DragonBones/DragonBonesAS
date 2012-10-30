package dragonBones.display{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	public class PivotBitmap extends Bitmap{
		//Pivot
		public var pX:Number = 0;
		public var pY:Number = 0;
		
		public function PivotBitmap(bitmapData:BitmapData = null, pixelSnapping:String = "auto", smoothing:Boolean = false){
			super(bitmapData, pixelSnapping, smoothing);
		}
		
		public function update(_matrix:Matrix):void{
			if (pX != 0 || pY != 0)
			{
				var tx:Number = _matrix.tx;
				var ty:Number = _matrix.ty;
				_matrix.tx = tx - _matrix.a * pX - _matrix.c * pY;
				_matrix.ty = ty - _matrix.b * pX - _matrix.d * pY;
			}
			transform.matrix = _matrix;
		}
	}
}