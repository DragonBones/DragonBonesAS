package dragonBones.core
{
	public final class DragonBones
	{
		/**
		 * @private
		 */
		public static const PI_D:Number = Math.PI * 2.0;
		/**
		 * @private
		 */
		public static const PI_H:Number = Math.PI / 2.0;
		/**
		 * @private
		 */
		public static const PI_Q:Number = Math.PI / 4.0;
		/**
		 * @private
		 */
		public static const ANGLE_TO_RADIAN:Number = Math.PI / 180.0;
		/**
		 * @private
		 */
		public static const RADIAN_TO_ANGLE:Number = 180.0 / Math.PI;
		/**
		 * @private
		 */
		public static const SECOND_TO_MILLISECOND:Number = 1000.0;
		/**
		 * @private
		 */
		public static const NO_TWEEN:Number = 100.0;
		/**
		 * @private
		 */
		public static const ABSTRACT_CLASS_ERROR:String = "Abstract class can not be instantiated.";
		/**
		 * @private
		 */
		public static const ABSTRACT_METHOD_ERROR:String = "Abstract method needs to be implemented in subclass.";
		
		public static const VERSION:String = "5.0.0";
		/**
		 * @private
		 */
		public static var debugDraw:Boolean = false;
	}
}