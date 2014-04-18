package dragonBones.objects
{
	import flash.geom.Point;
	
	public final class TransformTimeline extends Timeline
	{
		public var name:String;
		public var transformed:Boolean;
		
		public var originTransform:DBTransform;
		public var originPivot:Point;
		
		public var offset:Number;
		
		public function TransformTimeline()
		{
			super();
			
			originTransform = new DBTransform();
			originPivot = new Point();
			offset = 0;
		}
		
		override public function dispose():void
		{
			super.dispose();
			originTransform = null;
			originPivot = null;
		}
	}
}