package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.enum.ActionType;
	
	/**
	 * @private
	 */
	public final class ActionData extends BaseObject
	{
		public var type:int;
		public var bone:BoneData;
		public var slot:SlotData;
		public var animationConfig:AnimationConfig;
		
		public function ActionData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			if (animationConfig)
			{
				animationConfig.returnToPool();
			}
			
			type = ActionType.None;
			bone = null;
			slot = null;
			animationConfig = null;
		}
	}
}
