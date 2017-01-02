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
		 * @private
		 */
		public const transform:Transform = new Transform();
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
		public var userData: CustomData;
		/**
		 * @private
		 */
		public function BoneData()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			if (userData) 
			{
				userData.returnToPool();
			}
			
			inheritTranslation = false;
			inheritRotation = false;
			inheritScale = false;
			bendPositive = false;
			chain = 0;
			chainIndex = 0;
			weight = 0.0;
			length = 0.0;
			name = null;
			transform.identity();
			parent = null;
			ik = null;
			userData = null;
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