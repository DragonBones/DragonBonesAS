package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * 龙骨数据，包含多个骨架数据。
	 * @see dragonBones.objects.ArmatureData
	 * @version DragonBones 3.0
	 */
	public class DragonBonesData extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 是否开启共享搜索。 [true: 开启, false: 不开启]
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
		 * 所有的骨架数据。
		 * @see dragonBones.objects.ArmatureData
		 * @version DragonBones 3.0
		 */
		public const armatures:Object = {};
		
		/**
		 * @private
		 */
		private const _armatureNames:Vector.<String> = new Vector.<String>();
		
		/**
		 * @private
		 */
		public function DragonBonesData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			autoSearch = false;
			frameRate = 0;
			name = null;
			
			var i:String = null;
			for (i in armatures)
			{
				(armatures[i] as ArmatureData).returnToPool();
				delete armatures[i];
			}
			
			if (_armatureNames.length)
			{
				_armatureNames.length = 0;
			}
		}
		
		/**
		 * @language zh_CN
		 * 获取指定名称的骨架数据。
		 * @param name 骨架数据名称。
		 * @see dragonBones.objects.ArmatureData
		 * @version DragonBones 3.0
		 */
		public function getArmature(name:String):ArmatureData
		{
			return armatures[name] as ArmatureData;
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
		 * 所有骨架的数据名称。
		 * @see #armatures
		 * @version DragonBones 3.0
		 */
		public function get armatureNames():Vector.<String>
		{
			return _armatureNames;
		}
	}
}