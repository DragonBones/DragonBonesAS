package dragonBones.objects
{
	
	/**
	 * Node provides a base class for any object that has a transformation.
	 */
	public class Node
	{
		
		public var x:Number;
		public var y:Number;
		public var scaleX:Number;
		public var scaleY:Number;
		public var skewX:Number;
		public var skewY:Number;
		public var pivotX:Number;
		public var pivotY:Number;
		public var z:int;
		
		public function get rotation():Number
		{
			return skewX;
		}
		public function set rotation(value:Number):void
		{
			skewX = skewY = value;
		}
		
		public function Node(x:Number = 0, y:Number = 0, skewX:Number = 0, skewY:Number = 0, scaleX:Number = 1, scaleY:Number = 1)
		{
			this.x = x || 0;
			this.y = y || 0;
			this.skewX = skewX || 0;
			this.skewY = skewY || 0;
			this.scaleX = scaleX;
			this.scaleY = scaleY;
			
			pivotX = 0;
			pivotY = 0;
			z = 0;
		}
		
		public function copy(node:Node):void
		{
			x = node.x;
			y = node.y;
			scaleX = node.scaleX;
			scaleY = node.scaleY;
			skewX = node.skewX;
			skewY = node.skewY;
			
			pivotX = node.pivotX;
			pivotY = node.pivotY;
			z = node.z;
		}
		
		public function toString():String {
			var _str:String = "x:" + x + " y:" + y + " skewX:" + skewX + " skewY:" + skewY + " scaleX:" + scaleX + " scaleY:" + scaleY;
			return _str;
		}
	}
}