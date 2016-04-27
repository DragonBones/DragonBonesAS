package dragonBones.objects 
{
	import flash.geom.Point;
	
	public final class VertexData extends Point 
	{
		public var u:Number = 0;
		public var v:Number = 0;
		
		public function VertexData(x:Number=0, y:Number=0, u:Number = 0, v:Number = 0) 
		{
			super(x, y);
			this.u = u;
			this.v = v;
		}
	}

}