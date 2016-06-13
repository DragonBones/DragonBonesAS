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
		
		public const actions:Vector.<ActionData> = new Vector.<ActionData>(0, true);
		public const events:Vector.<EventData> = new Vector.<EventData>(0, true);
		
		public function FrameData(self:FrameData)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			position = 0;
			duration = 0;
			prev = null;
			next = null;
			
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