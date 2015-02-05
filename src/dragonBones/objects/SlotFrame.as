package dragonBones.objects
{
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	/** @private */
	final public class SlotFrame extends Frame
	{
		//NaN:no tween, 10:auto tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
		public var tweenEasing:Number;
		public var tweenRotate:int;
		public var tweenScale:Boolean;
		public var displayIndex:int;
		public var visible:Boolean;
		public var zOrder:Number;
		
		public var pivot:Point;
		public var color:ColorTransform;
		public var scaleOffset:Point;
		
		
		public function SlotFrame()
		{
			super();
			
			tweenEasing = 10;
			tweenRotate = 0;
			tweenScale = true;
			displayIndex = 0;
			visible = true;
			zOrder = NaN;
			
			pivot = new Point();
			scaleOffset = new Point();
		}
		
		override public function dispose():void
		{
			super.dispose();
			pivot = null;
			scaleOffset = null;
			color = null;
		}
	}
	
}