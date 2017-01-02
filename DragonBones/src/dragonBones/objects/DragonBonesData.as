package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * 龙骨数据。
	 * 一个龙骨数据包含多个骨架数据。
	 * @see dragonBones.objects.ArmatureData
	 * @version DragonBones 3.0
	 */
	public class DragonBonesData extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 是否开启共享搜索。
		 * @default false
		 * @version DragonBones 4.5
		 */
		public var autoSearch:Boolean;
		/**
		 * @language zh_CN
		 * 动画帧频。
		 * @version DragonBones 3.0
		 */
		public var frameRate:uint;
		/**
		 * @language zh_CN
		 * 数据名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		/**
		 * @language zh_CN
		 * 所有骨架数据。
		 * @see dragonBones.objects.ArmatureData
		 * @version DragonBones 3.0
		 */
		public const armatures:Object = {};
		/**
		 * @private
		 */
		public const cachedFrames: Vector.<Number> = new Vector.<Number>();
		/**
		 * @private
		 */
		public var userData: CustomData;
		
		private const _armatureNames:Vector.<String> = new Vector.<String>();
		/**
		 * @private
		 */
		public function DragonBonesData()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			for (var k:String in armatures)
			{
				(armatures[k] as ArmatureData).returnToPool();
				delete armatures[k];
			}
			
			if (userData) 
			{
				userData.returnToPool();
			}
			
			autoSearch = false;
			frameRate = 0;
			name = null;
			//armatures.clear();
			cachedFrames.length = 0;
			userData = null;
			
			_armatureNames.length = 0;
		}
		/**
		 * @private
		 */
		public function addArmature(value:ArmatureData):void
		{
			if (value && value.name && !armatures[value.name])
			{
				armatures[value.name] = value;
				_armatureNames.push(value.name);
				
				value.parent = this;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		/**
		 * @language zh_CN
		 * 获取骨架数据。
		 * @param name 骨架数据名称。
		 * @see dragonBones.objects.ArmatureData
		 * @version DragonBones 3.0
		 */
		public function getArmature(name:String):ArmatureData
		{
			return armatures[name] as ArmatureData;
		}
		/**
		 * @language zh_CN
		 * 所有骨架数据名称。
		 * @see #armatures
		 * @version DragonBones 3.0
		 */
		public function get armatureNames():Vector.<String>
		{
			return _armatureNames;
		}
	}
}