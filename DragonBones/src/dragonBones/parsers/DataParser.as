package dragonBones.parsers
{
	import flash.geom.Point;
	
	import dragonBones.core.DragonBones;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DragonBonesData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.objects.TimelineData;
	import dragonBones.textures.TextureAtlasData;
	
	/**
	 * @private
	 */
	public class DataParser
	{
		protected static const TEXTURE_ATLAS:String = "TextureAtlas";
		protected static const SUB_TEXTURE:String = "SubTexture";
		protected static const IMAGE_PATH:String = "imagePath";
		protected static const WIDTH:String = "width";
		protected static const HEIGHT:String = "height";
		protected static const ROTATED:String = "rotated";
		protected static const FRAME_X:String = "frameX";
		protected static const FRAME_Y:String = "frameY";
		protected static const FRAME_WIDTH:String = "frameWidth";
		protected static const FRAME_HEIGHT:String = "frameHeight";
		
		protected static const DRADON_BONES:String = "dragonBones";
		protected static const ARMATURE:String = "armature";
		protected static const BONE:String = "bone";
		protected static const IK:String = "ik";
		protected static const SLOT:String = "slot";
		protected static const SKIN:String = "skin";
		protected static const DISPLAY:String = "display";
		protected static const ANIMATION:String = "animation";
		protected static const FFD:String = "ffd";
		protected static const FRAME:String = "frame";
		
		protected static const PIVOT:String = "pivot";
		protected static const TRANSFORM:String = "transform";
		protected static const COLOR:String = "color";
		protected static const FILTER:String = "filter";
		
		protected static const VERSION:String = "version";
		protected static const IS_GLOBAL:String = "isGlobal";
		protected static const FRAME_RATE:String = "frameRate";
		protected static const TYPE:String = "type";
		protected static const NAME:String = "name";
		protected static const PARENT:String = "parent";
		protected static const LENGTH:String = "length";
		protected static const DATA:String = "data";
		protected static const DISPLAY_INDEX:String = "displayIndex";
		protected static const Z_ORDER:String = "z";
		protected static const BLEND_MODE:String = "blendMode";
		protected static const INHERIT_TRANSLATION:String = "inheritTranslation";
		protected static const INHERIT_ROTATION:String = "inheritRotation";
		protected static const INHERIT_SCALE:String = "inheritScale";
		protected static const TARGET:String = "target";
		protected static const BEND_POSITIVE:String = "bendPositive";
		protected static const CHAIN:String = "chain";
		protected static const WEIGHT:String = "weight";
		
		protected static const FADE_IN_TIME:String = "fadeInTime";
		protected static const PLAY_TIMES:String = "playTimes";
		protected static const SCALE:String = "scale";
		protected static const OFFSET:String = "offset";
		protected static const POSITION:String = "position";
		protected static const DURATION:String = "duration";
		protected static const TWEEN_EASING:String = "tweenEasing";
		protected static const TWEEN_ROTATE:String = "tweenRotate";
		protected static const TWEEN_SCALE:String = "tweenScale";
		protected static const CURVE:String = "curve";
		protected static const EVENT:String = "event";
		protected static const SOUND:String = "sound";
		protected static const ACTION:String = "action";
		protected static const ACTIONS:String = "actions";
		
		protected static const X:String = "x";
		protected static const Y:String = "y";
		protected static const SKEW_X:String = "skX";
		protected static const SKEW_Y:String = "skY";
		protected static const SCALE_X:String = "scX";
		protected static const SCALE_Y:String = "scY";
		
		protected static const ALPHA_OFFSET:String = "aO";
		protected static const RED_OFFSET:String = "rO";
		protected static const GREEN_OFFSET:String = "gO";
		protected static const BLUE_OFFSET:String = "bO";
		protected static const ALPHA_MULTIPLIER:String = "aM";
		protected static const RED_MULTIPLIER:String = "rM";
		protected static const GREEN_MULTIPLIER:String = "gM";
		protected static const BLUE_MULTIPLIER:String = "bM";
		
		protected static const UVS:String = "uvs";
		protected static const VERTICES:String = "vertices";
		protected static const TRIANGLES:String = "triangles";
		protected static const WEIGHTS:String = "weights";
		protected static const SLOT_POSE:String = "slotPose";
		protected static const BONE_POSE:String = "bonePose";
		
		protected static const TWEEN:String = "tween";
		protected static const KEY:String = "key";
		
		protected static const PIVOT_X:String = "pX";
		protected static const PIVOT_Y:String = "pY";
		
		protected static const RECTANGLE:String = "rectangle";
		protected static const ELLIPSE:String = "ellipse";
		
		protected static function _getArmatureType(value:String):int
		{
			switch (value.toLowerCase())
			{
				case "stage":
					return DragonBones.ARMATURE_TYPE_STAGE;
					
				case "armature":
					return DragonBones.ARMATURE_TYPE_ARMATURE;
					
				case "movieClip":
					return DragonBones.ARMATURE_TYPE_MOVIE_CLIP;
					
				default:
					return DragonBones.ARMATURE_TYPE_ARMATURE;
			}
		}
		
		protected static function _getDisplayType(value:String):int
		{
			switch (value.toLowerCase())
			{
				case "image":
					return DragonBones.DISPLAY_TYPE_IMAGE;
					
				case "armature":
					return DragonBones.DISPLAY_TYPE_ARMATURE;
					
				case "mesh":
					return DragonBones.DISPLAY_TYPE_MESH;
					
				default:
					return DragonBones.DISPLAY_TYPE_IMAGE;
			}
		}
		
		protected static function _getBlendMode(value:String):int 
		{
			switch (value.toLowerCase()) 
			{
				case "normal":
					return DragonBones.BLEND_MODE_NORMAL;
					
				case "add":
					return DragonBones.BLEND_MODE_ADD;
					
				case "alpha":
					return DragonBones.BLEND_MODE_ALPHA;
					
				case "darken":
					return DragonBones.BLEND_MODE_DARKEN;
					
				case "difference":
					return DragonBones.BLEND_MODE_DIFFERENCE;
					
				case "erase":
					return DragonBones.BLEND_MODE_ERASE;
					
				case "hardlight":
					return DragonBones.BLEND_MODE_HARDLIGHT;
					
				case "invert":
					return DragonBones.BLEND_MODE_INVERT;
					
				case "layer":
					return DragonBones.BLEND_MODE_LAYER;
					
				case "lighten":
					return DragonBones.BLEND_MODE_LIGHTEN;
					
				case "multiply":
					return DragonBones.BLEND_MODE_MULTIPLY;
					
				case "overlay":
					return DragonBones.BLEND_MODE_OVERLAY;
					
				case "screen":
					return DragonBones.BLEND_MODE_SCREEN;
					
				case "subtract":
					return DragonBones.BLEND_MODE_SUBTRACT;
					
				default:
					return DragonBones.BLEND_MODE_NORMAL;
			}
		}
		
		protected static function _getActionType(value:String):int
		{
			switch (value.toLowerCase())
			{
				case "play":
					return DragonBones.ACTION_TYPE_PLAY;
					
				case "stop":
					return DragonBones.ACTION_TYPE_STOP;
					
				case "gotoAndPlay":
					return DragonBones.ACTION_TYPE_GOTO_AND_PLAY;
					
				case "gotoAndStop":
					return DragonBones.ACTION_TYPE_GOTO_AND_STOP;
					
				case "fadeIn":
					return DragonBones.ACTION_TYPE_FADE_IN;
					
				case "fadeOut":
					return DragonBones.ACTION_TYPE_FADE_OUT;
					
				default:
					return DragonBones.ACTION_TYPE_FADE_IN;
			}
		}
		
		protected var _data:DragonBonesData = null;
		protected var _armature:ArmatureData = null;
		protected var _skin:SkinData = null;
		protected var _slotDisplayDataSet:SlotDisplayDataSet = null;
		protected var _mesh:MeshData = null;
		protected var _animation:AnimationData = null;
		protected var _timeline:TimelineData = null;
		
		protected const _helpPoint:Point = new Point();
		protected const _rawBones:Vector.<BoneData> = new Vector.<BoneData>();
		
		/** 
		 * @private 
		 */
		public function DataParser(self:DataParser)
		{
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		public function parseTextureAtlasData(rawData:*, textureAtlasData:TextureAtlasData, scale:Number = 0, rawScale:Number = 0):TextureAtlasData
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
			return null;
		}
		
		public function parseDragonBonesData(rawData:*):DragonBonesData
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
			return null;
		}
	}
}