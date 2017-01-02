package dragonBones.objects
{
	import flash.geom.ColorTransform;
	
	import dragonBones.core.BaseObject;
	import dragonBones.enum.BlendMode;
	
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
		 * @private
		 */
		public const actions: Vector.<ActionData> = new Vector.<ActionData>();
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
		public var userData: CustomData;
		/**
		 * @private
		 */
		public function SlotData()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			for (var i:uint = 0, l:uint = actions.length; i < l; ++i)
			{
				actions[i].returnToPool();
			}
			
			if (userData) 
			{
				userData.returnToPool();
			}
			
			displayIndex = -1;
			zOrder = 0;
			blendMode = BlendMode.None;
			name = null;
			actions.length = 0;
			parent = null;
			color = null;
			userData = null;
		}
	}
}