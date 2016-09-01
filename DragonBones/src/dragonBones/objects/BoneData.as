package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	import dragonBones.geom.Transform;
	
	/**
	 * @language zh_CN
	 * 骨骼数据。
	 * @see dragonBones.Bone
	 * @version DragonBones 3.0
	 */
	public class BoneData extends BaseObject
	{
		/**
		 * @private
		 */
		public var inheritTranslation:Boolean;
		
		/**
		 * @private
		 */
		public var inheritRotation:Boolean;
		
		/**
		 * @private
		 */
		public var inheritScale:Boolean;
		
		/**
		 * @private
		 */
		public var bendPositive:Boolean;
		
		/**
		 * @private
		 */
		public var chain:uint;
		
		/**
		 * @private
		 */
		public var chainIndex:uint;
		
		/**
		 * @private
		 */
		public var weight:Number;
		
		/**
		 * @private
		 */
		public var length:Number;
		
		/**
		 * @language zh_CN
		 * 数据名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		
		/**
		 * @language zh_CN
		 * 所属的父骨骼数据。
		 * @version DragonBones 3.0
		 */
		public var parent:BoneData;
		
		/**
		 * @private
		 */
		public var ik:BoneData;
		
		/**
		 * @private
		 */
		public const transform:Transform = new Transform();
		
		/**
		 * @private
		 */
		public function BoneData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			inheritTranslation = false;
			inheritRotation = false;
			inheritScale = false;
			bendPositive = false;
			chain = 0;
			chainIndex = 0;
			weight = 0;
			length = 0;
			name = null;
			parent = null;
			ik = null;
			transform.identity();
		}
		
		/**
		 * @private
		 */
		public function toString():String
		{
			return name;
		}
	}
}