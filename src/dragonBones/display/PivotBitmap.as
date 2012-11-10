package dragonBones.display
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	public class PivotBitmap extends Bitmap
	{
		//Pivot
		public var pivotX:Number = 0;
		public var pivotY:Number = 0;
		
		public function PivotBitmap(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=false)
		{
			super(bitmapData, pixelSnapping, smoothing);
		}
	}
}