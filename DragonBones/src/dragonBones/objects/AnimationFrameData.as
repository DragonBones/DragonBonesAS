package dragonBones.objects
{
	/**
	 * @private
	 */
	public final class AnimationFrameData extends FrameData
	{
		
		public const actions:Vector.<ActionData> = new Vector.<ActionData>(0, true);
		public const events:Vector.<EventData> = new Vector.<EventData>(0, true);
		
		public function AnimationFrameData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			if (actions.length)
			{
				for each (var actionData:ActionData in actions)
				{
					actionData.returnToPool();
				}
				
				actions.fixed = false;
				actions.length = 0;
				actions.fixed = true;
			}
			
			if (events.length)
			{
				for each (var eventData:EventData in events)
				{
					eventData.returnToPool();
				}
				
				events.fixed = false;
				events.length = 0;
				events.fixed = true;
			}
		}
	}
}