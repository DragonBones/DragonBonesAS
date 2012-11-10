package dragonBones.display
{
	import flash.geom.Matrix;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	
	public class StarlingDisplayBridge implements IDisplayBridge
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
		
		public function StarlingDisplayBridge()
		{
		}
		
		public function update(matrix:Matrix):void
		{
			if (_display.pivotX != 0 || _display.pivotY != 0)
			{
				matrix.tx -= matrix.a * _display.pivotX + matrix.c * _display.pivotY;
				matrix.ty -= matrix.b * _display.pivotX + matrix.d * _display.pivotY;
			}
			_display.transformationMatrix.copyFrom(matrix);
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