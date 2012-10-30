package dragonBones.display
{
	import flash.geom.Matrix;
	import starling.display.Image;
	import starling.textures.Texture;
	/**
	 * ...
	 * @author Cheng Liao
	 */
	public class StarlingBridgeImage extends Image
	{
		//Pivot
		public var pX:Number = 0;
		public var pY:Number = 0;
		
		public function StarlingBridgeImage(texture:Texture)
		{
			super(texture);
		}
		
		override public function set transformationMatrix(matrix:Matrix):void
        {
			if (pX != 0 || pY != 0)
			{
				var tx:Number = matrix.tx;
				var ty:Number = matrix.ty;
				matrix.tx = tx - matrix.a * pX - matrix.c * pY;
				matrix.ty = ty - matrix.b * pX - matrix.d * pY;
			}
			
			super.transformationMatrix.copyFrom(matrix);
        }
		
	}

}