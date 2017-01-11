package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * 自定义数据。
	 * @version DragonBones 5.0
	 */
	public final class CustomData extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 自定义整数。
		 * @version DragonBones 5.0
		 */
		public const ints: Vector.<Number> = new Vector.<Number>();
		/**
		 * @language zh_CN
		 * 自定义浮点数。
		 * @version DragonBones 5.0
		 */
		public const floats: Vector.<Number> = new Vector.<Number>();
		/**
		 * @language zh_CN
		 * 自定义字符串。
		 * @version DragonBones 5.0
		 */
		public const strings: Vector.<String> = new Vector.<String>();
		/**
		 * @private
		 */
		public function CustomData()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear(): void {
			ints.length = 0;
			floats.length = 0;
			strings.length = 0;
		}
		/**
		 * @language zh_CN
		 * 获取自定义整数。
		 * @version DragonBones 5.0
		 */
		public function getInt(index: Number = 0): Number 
		{
			return index >= 0 && index < ints.length ? ints[index] : 0;
		}
		/**
		 * @language zh_CN
		 * 获取自定义浮点数。
		 * @version DragonBones 5.0
		 */
		public function getFloat(index: Number = 0): Number 
		{
			return index >= 0 && index < floats.length ? floats[index] : 0;
		}
		/**
		 * @language zh_CN
		 * 获取自定义字符串。
		 * @version DragonBones 5.0
		 */
		public function getString(index: Number = 0): String 
		{
			return index >= 0 && index < strings.length ? strings[index] : null;
		}
	}
}