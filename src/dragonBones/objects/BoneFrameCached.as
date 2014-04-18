package dragonBones.objects
{
	/** @private */
	public final class BoneFrameCached extends FrameCached
	{
		public var slotFrameCachedMap:Object;
		
		public function BoneFrameCached()
		{
			slotFrameCachedMap = {};
		}
		
		override public function dispose():void
		{
			super.dispose();
			for each(var frameCached:FrameCached in slotFrameCachedMap)
			{
				frameCached.dispose();
			}
			//slotFrameCachedMap.clear();
			slotFrameCachedMap = null;
		}
	}
}