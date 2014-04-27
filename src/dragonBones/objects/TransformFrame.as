package dragonBones.objects
{
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	/** @private */
	final public class TransformFrame extends Frame
	{
<<<<<<< HEAD
		//NaN:no tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
=======
		//NaN:auto tween, -2:no tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
>>>>>>> 653d606cd9ac0e0fb69e707ff6c17b09a310e84f
		public var tweenEasing:Number;
		public var tweenRotate:int;
		public var tweenScale:Boolean;
		public var displayIndex:int;
		public var visible:Boolean;
		public var zOrder:Number;
		
		public var global:DBTransform;
		public var transform:DBTransform;
		public var pivot:Point;
		public var color:ColorTransform;
		
		
		public function TransformFrame()
		{
			super();
			
			tweenEasing = NaN;
			tweenRotate = 0;
			tweenScale = true;
			displayIndex = 0;
			visible = true;
			zOrder = NaN;
			
			global = new DBTransform();
			transform = new DBTransform();
			pivot = new Point();
		}
		
		override public function dispose():void
		{
			super.dispose();
			global = null;
			transform = null;
			pivot = null;
			color = null;
		}
	}
	
}