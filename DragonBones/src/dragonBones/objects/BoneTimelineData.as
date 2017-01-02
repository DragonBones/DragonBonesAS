package dragonBones.objects
{
	import dragonBones.geom.Transform;
	
	/**
	 * @private
	 */
	public final class BoneTimelineData extends TimelineData
	{
		public const originalTransform:Transform = new Transform();
		public var bone:BoneData;
		
		public function BoneTimelineData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			originalTransform.identity();
			bone = null;
		}
	}
}