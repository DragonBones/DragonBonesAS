package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * 龙骨数据，包含多个骨架数据。
	 * @see dragonBones.objects.ArmatureData
	 * @version DragonBones 3.0
	 */
	public final class DragonBonesData extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 是否自动搜索。 [<code>true</code>: 启用, <code>false</code>: 不启用] (默认: <code>false</code>)
		 * @see dragonBones.objects.ArmatureData
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
		private const _armatures:Vector.<ArmatureData> = new Vector.<ArmatureData>();
		
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
			
			if (_armatures.length)
			{
				_armatures.length = 0;
			}
		}
		
		/**
		 * @language zh_CN
		 * 获得指定名称的骨架。
		 * @param name 骨架名称
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
				_armatures.push(value);
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * @language zh_CN
		 * 不推荐使用的 API。
		 * @see #armatures
		 * @version DragonBones 3.0
		 */
		public function get armatureDataList():Vector.<ArmatureData>
		{
			return _armatures;
		}
	}
}