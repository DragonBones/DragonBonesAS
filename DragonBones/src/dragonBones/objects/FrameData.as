package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public class FrameData extends BaseObject
	{
		public var position:Number;
		public var duration:Number;
		public var prev:FrameData;
		public var next:FrameData;
		
		public function FrameData(self:FrameData)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		override protected function _onClear():void
		{
			position = 0.0;
			duration = 0.0;
			prev = null;
			next = null;
		}
	}
}