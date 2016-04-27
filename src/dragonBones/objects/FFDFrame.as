package dragonBones.objects 
{
	/**
	 * ...
	 * @author sukui
	 */
	public class FFDFrame extends Frame
	{
		//NaN:no tween, 10:auto tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
		public var tweenEasing:Number;
		public var offset:int;
		public var vertices:Vector.<Number>;
		
		public function FFDFrame() 
		{
			
		}
		
	}

}