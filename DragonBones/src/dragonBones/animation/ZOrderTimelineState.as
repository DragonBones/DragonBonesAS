package dragonBones.animation
{
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.ZOrderFrameData;

	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public final class ZOrderTimelineState extends TimelineState
	{
		public function ZOrderTimelineState()
		{
			super(this);
		}
		
		override protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
			super._onArriveAtFrame(isUpdate);
			
			_armature._sortZOrder((_currentFrame as ZOrderFrameData).zOrder);            
		}
	}
}