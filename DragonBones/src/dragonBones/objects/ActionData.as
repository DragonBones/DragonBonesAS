package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
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
			type = DragonBones.ACTION_TYPE_PLAY;
			data = null;
			bone = null;
			slot = null;
		}
	}
}