package dragonBones.core
{
	public final class DragonBones
	{
		public static const ARMATURE_TYPE_ARMATURE:int = 0;
		public static const ARMATURE_TYPE_MOVIE_CLIP:int = 1;
		public static const ARMATURE_TYPE_STAGE:int = 2;
		
		public static const DISPLAY_TYPE_IMAGE:int = 0;
		public static const DISPLAY_TYPE_ARMATURE:int = 1;
		public static const DISPLAY_TYPE_MESH:int = 2;
		
		public static const BLEND_MODE_NORMAL:int = 0;
		public static const BLEND_MODE_ADD:int = 1;
		public static const BLEND_MODE_ALPHA:int = 2;
		public static const BLEND_MODE_DARKEN:int = 3;
		public static const BLEND_MODE_DIFFERENCE:int = 4;
		public static const BLEND_MODE_ERASE:int = 5;
		public static const BLEND_MODE_HARDLIGHT:int = 6;
		public static const BLEND_MODE_INVERT:int = 7;
		public static const BLEND_MODE_LAYER:int = 8;
		public static const BLEND_MODE_LIGHTEN:int = 9;
		public static const BLEND_MODE_MULTIPLY:int = 10;
		public static const BLEND_MODE_OVERLAY:int = 11;
		public static const BLEND_MODE_SCREEN:int = 12;
		public static const BLEND_MODE_SUBTRACT:int = 13;
		
		public static const EXTENSION_TYPE_FFD:int = 0;
		public static const EXTENSION_TYPE_ADJUST_COLOR_FILTER:int = 10;
		public static const EXTENSION_TYPE_BEVEL_FILTER:int = 11;
		public static const EXTENSION_TYPE_BLUR_FILTER:int = 12;
		public static const EXTENSION_TYPE_DROP_SHADOW_FILTER:int = 13;
		public static const EXTENSION_TYPE_GLOW_FILTER:int = 14;
		public static const EXTENSION_TYPE_GRADIENT_BEVEL_FILTER:int = 15;
		public static const EXTENSION_TYPE_GRADIENT_GLOW_FILTER:int = 16;
		
		public static const EVENT_TYPE_FRAME:int = 0;
		public static const EVENT_TYPE_SOUND:int = 1;
		
		public static const ACTION_TYPE_PLAY:int = 0;
		public static const ACTION_TYPE_STOP:int = 1;
		public static const ACTION_TYPE_GOTO_AND_PLAY:int = 2;
		public static const ACTION_TYPE_GOTO_AND_STOP:int = 3;
		public static const ACTION_TYPE_FADE_IN:int = 4;
		public static const ACTION_TYPE_FADE_OUT:int = 5;
		
		public static const ANGLE_TO_RADIAN:Number = Math.PI / 180;
		public static const RADIAN_TO_ANGLE:Number = 180 / Math.PI;
		
		public static const ABSTRACT_CLASS_ERROR:String = "Abstract class can not be instantiated.";
		public static const ABSTRACT_METHOD_ERROR:String = "Abstract method needs to be implemented in subclass.";
		
		public static const DATA_VERSION:String = "4.0";
		public static const PARENT_COORDINATE_DATA_VERSION:String = "3.0";
		public static const VERSION:String = "4.7";
	}
}