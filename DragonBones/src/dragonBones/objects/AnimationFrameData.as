package dragonBones.objects
{
	/**
	 * @private
	 */
	public final class AnimationFrameData extends FrameData
	{
		
		public const actions:Vector.<ActionData> = new Vector.<ActionData>();
		public const events:Vector.<EventData> = new Vector.<EventData>();
		
		public function AnimationFrameData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			for (var i:uint = 0, l:uint = actions.length; i < l; ++i)
			{
				actions[i].returnToPool();
			}
			
			for (i = 0, l = events.length; i < l; ++i)
			{
				events[i].returnToPool();
			}
			
			actions.fixed = false;
			events.fixed = false;
			
			actions.length = 0;
			events.length = 0;
		}
	}
}