package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @private
	 */
	public final class ActionData extends BaseObject
	{
		public var type:int;
		public var data:Array;
		public var bone:BoneData;
		public var slot:SlotData;
		
		public function ActionData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			type = 0;
			data = null;
			bone = null;
			slot = null;
		}
	}
}