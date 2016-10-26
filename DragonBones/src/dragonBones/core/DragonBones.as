package dragonBones.core
{
	public final class DragonBones
	{
		/**
		 * @private
		 */
		public static const ARMATURE_TYPE_ARMATURE:int = 0;
		/**
		 * @private
		 */
		public static const ARMATURE_TYPE_MOVIE_CLIP:int = 1;
		/**
		 * @private
		 */
		public static const ARMATURE_TYPE_STAGE:int = 2;
		
		/**
		 * @private
		 */
		public static const DISPLAY_TYPE_IMAGE:int = 0;
		/**
		 * @private
		 */
		public static const DISPLAY_TYPE_ARMATURE:int = 1;
		/**
		 * @private
		 */
		public static const DISPLAY_TYPE_MESH:int = 2;
		
		/**
		 * @private
		 */
		public static const BLEND_MODE_NORMAL:int = 0;
		/**
		 * @private
		 */
		public static const BLEND_MODE_ADD:int = 1;
		/**
		 * @private
		 */
		public static const BLEND_MODE_ALPHA:int = 2;
		/**
		 * @private
		 */
		public static const BLEND_MODE_DARKEN:int = 3;
		/**
		 * @private
		 */
		public static const BLEND_MODE_DIFFERENCE:int = 4;
		/**
		 * @private
		 */
		public static const BLEND_MODE_ERASE:int = 5;
		/**
		 * @private
		 */
		public static const BLEND_MODE_HARDLIGHT:int = 6;
		/**
		 * @private
		 */
		public static const BLEND_MODE_INVERT:int = 7;
		/**
		 * @private
		 */
		public static const BLEND_MODE_LAYER:int = 8;
		/**
		 * @private
		 */
		public static const BLEND_MODE_LIGHTEN:int = 9;
		/**
		 * @private
		 */
		public static const BLEND_MODE_MULTIPLY:int = 10;
		/**
		 * @private
		 */
		public static const BLEND_MODE_OVERLAY:int = 11;
		/**
		 * @private
		 */
		public static const BLEND_MODE_SCREEN:int = 12;
		/**
		 * @private
		 */
		public static const BLEND_MODE_SUBTRACT:int = 13;
		
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_FFD:int = 0;
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_ADJUST_COLOR_FILTER:int = 10;
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_BEVEL_FILTER:int = 11;
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_BLUR_FILTER:int = 12;
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_DROP_SHADOW_FILTER:int = 13;
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_GLOW_FILTER:int = 14;
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_GRADIENT_BEVEL_FILTER:int = 15;
		/**
		 * @private
		 */
		public static const EXTENSION_TYPE_GRADIENT_GLOW_FILTER:int = 16;
		
		/**
		 * @private
		 */
		public static const EVENT_TYPE_FRAME:int = 10;
		/**
		 * @private
		 */
		public static const EVENT_TYPE_SOUND:int = 11;
		
		/**
		 * @private
		 */
		public static const ACTION_TYPE_PLAY:int = 0;
		/**
		 * @private
		 */
		public static const ACTION_TYPE_STOP:int = 1;
		/**
		 * @private
		 */
		public static const ACTION_TYPE_GOTO_AND_PLAY:int = 2;
		/**
		 * @private
		 */
		public static const ACTION_TYPE_GOTO_AND_STOP:int = 3;
		/**
		 * @private
		 */
		public static const ACTION_TYPE_FADE_IN:int = 4;
		/**
		 * @private
		 */
		public static const ACTION_TYPE_FADE_OUT:int = 5;
		
		/**
		 * @private
		 */
		public static const PI_D:Number = Math.PI * 2;
		/**
		 * @private
		 */
		public static const PI_H:Number = Math.PI / 2;
		/**
		 * @private
		 */
		public static const PI_Q:Number = Math.PI / 4;
		/**
		 * @private
		 */
		public static const ANGLE_TO_RADIAN:Number = Math.PI / 180;
		/**
		 * @private
		 */
		public static const RADIAN_TO_ANGLE:Number = 180 / Math.PI;
		/**
		 * @private
		 */
		public static const SECOND_TO_MILLISECOND:Number = 1000;
		/**
		 * @private
		 */
		public static const NO_TWEEN:Number = 100;
		/**
		 * @private
		 */
		public static const ABSTRACT_CLASS_ERROR:String = "Abstract class can not be instantiated.";
		/**
		 * @private
		 */
		public static const ABSTRACT_METHOD_ERROR:String = "Abstract method needs to be implemented in subclass.";
		
		public static const VERSION:String = "4.7.2";
		
		/**
		 * @private
		 */
		public static var debug:Boolean = false;
		
		/**
		 * @private
		 */
		public static var debugDraw:Boolean = false;
	}
}