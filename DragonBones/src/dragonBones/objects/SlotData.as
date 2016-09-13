package dragonBones.objects
{
	import flash.geom.ColorTransform;
	
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	
	/**
	 * @language zh_CN
	 * 插槽数据。
	 * @see dragonBones.Slot
	 * @version DragonBones 3.0
	 */
	public class SlotData extends BaseObject
	{
		/**
		 * @private
		 */
		public static const DEFAULT_COLOR:ColorTransform = new ColorTransform();
		
		/**
		 * @private
		 */
		public static function generateColor():ColorTransform
		{
			return new ColorTransform();
		}
		
		/**
		 * @private
		 */
		public var displayIndex:int;
		
		/**
		 * @private
		 */
		public var zOrder:int;
		
		/**
		 * @private
		 */
		public var blendMode:int;
		
		/**
		 * @language zh_CN
		 * 数据名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		
		/**
		 * @language zh_CN
		 * 所属的父骨骼数据。
		 * @see dragonBones.objects.BoneData
		 * @version DragonBones 3.0
		 */
		public var parent:BoneData;
		
		/**
		 * @private
		 */
		public var color:ColorTransform;
		
		/**
		 * @private
		 */
		public const actions: Vector.<ActionData> = new Vector.<ActionData>(0, true);
		
		/**
		 * @private
		 */
		public function SlotData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			displayIndex = 0;
			zOrder = 0;
			blendMode = DragonBones.BLEND_MODE_NORMAL;
			name = null;
			parent = null;
			color = null;
			
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
		}
	}
}