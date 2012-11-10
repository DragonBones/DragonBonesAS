package dragonBones.display
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	
	public class NativeDisplayBridge implements IDisplayBridge
	{
		protected var _display:DisplayObject;
		public function get display():Object
		{
			return _display;
		}
		
		public function set display(value:Object):void
		{
			if(_display == value){
				return;
			}
			if(_display)
			{
				var parent:DisplayObjectContainer = _display.parent;
				if(parent)
				{
					var index:int = _display.parent.getChildIndex(_display);
				}
				removeDisplay();
			}
			_display = value as DisplayObject;
			addDisplay(parent, index);
		}
		
		public function NativeDisplayBridge()
		{
		}
		
		public function update(matrix:Matrix):void
		{
			var pivotBitmap:PivotBitmap = _display as PivotBitmap;
			if(pivotBitmap)
			{
				if (pivotBitmap.pivotX != 0 || pivotBitmap.pivotY != 0)
				{
					matrix.tx -= matrix.a * pivotBitmap.pivotX + matrix.c * pivotBitmap.pivotY;
					matrix.ty -= matrix.b * pivotBitmap.pivotX + matrix.d * pivotBitmap.pivotY;
				}
			}
			_display.transform.matrix = matrix;
		}
		
		public function addDisplay(container:Object, index:int = -1):void
		{
			if(container && _display)
			{
				if(index < 0)
				{
					container.addChild(_display);
				}
				else
				{
					container.addChildAt(_display, Math.min(index, container.numChildren));
				}
			}
		}
		
		public function removeDisplay():void
		{
			if(_display && _display.parent)
			{
				_display.parent.removeChild(_display);
			}
		}
	}
}