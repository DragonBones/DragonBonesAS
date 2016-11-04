package dragonBones.parsers
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import dragonBones.animation.TweenTimelineState;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.geom.Transform;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.AnimationFrameData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.BoneFrameData;
	import dragonBones.objects.BoneTimelineData;
	import dragonBones.objects.DragonBonesData;
	import dragonBones.objects.EventData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.objects.TimelineData;
	import dragonBones.textures.TextureAtlasData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public class DataParser
	{
		protected static const DATA_VERSION_2_3:String = "2.3";
		protected static const DATA_VERSION_3_0:String = "3.0";
		protected static const DATA_VERSION_4_0:String = "4.0";
		protected static const DATA_VERSION:String = "4.5";
		
		protected static const TEXTURE_ATLAS:String = "TextureAtlas";
		protected static const SUB_TEXTURE:String = "SubTexture";
		protected static const FORMAT:String = "format";
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
		protected static const Z_ORDER:String = "zOrder";
		protected static const FFD:String = "ffd";
		protected static const FRAME:String = "frame";
		
		protected static const PIVOT:String = "pivot";
		protected static const TRANSFORM:String = "transform";
		protected static const AABB:String = "aabb";
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
		protected static const DEFAULT_ACTIONS:String = "defaultActions";
		
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
		
		protected static const COLOR_TRANSFORM:String = "colorTransform";
		protected static const TIMELINE:String = "timeline";
		protected static const PIVOT_X:String = "pX";
		protected static const PIVOT_Y:String = "pY";
		protected static const Z:String = "z";
		protected static const LOOP:String = "loop";
		protected static const AUTO_TWEEN:String = "autoTween";
		protected static const HIDE:String = "hide";
		
		protected static function _getArmatureType(value:String):int
		{
			switch (value.toLowerCase())
			{
				case "stage":
					return DragonBones.ARMATURE_TYPE_STAGE;
					
				case "armature":
					return DragonBones.ARMATURE_TYPE_ARMATURE;
					
				case "movieclip":
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
					
				case "gotoandplay":
					return DragonBones.ACTION_TYPE_GOTO_AND_PLAY;
					
				case "gotoandstop":
					return DragonBones.ACTION_TYPE_GOTO_AND_STOP;
					
				case "fadein":
					return DragonBones.ACTION_TYPE_FADE_IN;
					
				case "fadeout":
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
		
		protected var _isOldData:Boolean = false;
		protected var _isGlobalTransform:Boolean = false;
		protected var _isAutoTween:Boolean = false;
		protected var _animationTweenEasing:Number = 0;
		protected const _timelinePivot:Point = new Point();
		
		protected const _helpPoint:Point = new Point();
		protected const _helpTransformA:Transform = new Transform();
		protected const _helpTransformB:Transform = new Transform();
		protected const _helpMatrix:Matrix = new Matrix();
		protected const _rawBones:Vector.<BoneData> = new Vector.<BoneData>();
		
		public function DataParser(self:DataParser)
		{
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		/** 
		 * @private 
		 */
		public function parseDragonBonesData(rawData:*, scale:Number = 1):DragonBonesData
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
			return null;
		}
		
		/** 
		 * @private 
		 */
		public function parseTextureAtlasData(rawData:*, textureAtlasData:TextureAtlasData, scale:Number = 0, rawScale:Number = 0):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		private function _getTimelineFrameMatrix(animation:AnimationData, timeline:BoneTimelineData, position:Number, transform:Transform):void 
		{
			const frameIndex:uint = uint(position * animation.frameCount / animation.duration);
			if (timeline.frames.length == 1 || frameIndex >= timeline.frames.length) 
			{
				transform.copyFrom((timeline.frames[0] as BoneFrameData).transform);
			} 
			else 
			{
				const frame:BoneFrameData = timeline.frames[frameIndex] as BoneFrameData;
				var tweenProgress:Number = 0;
				
				if (frame.tweenEasing != DragonBones.NO_TWEEN) 
				{
					tweenProgress = (position - frame.position) / frame.duration;
					if (frame.tweenEasing != 0) 
					{
						tweenProgress = TweenTimelineState._getEasingValue(tweenProgress, frame.tweenEasing);
					}
				}
				else if (frame.curve) 
				{
					tweenProgress = (position - frame.position) / frame.duration;
					tweenProgress = TweenTimelineState._getCurveEasingValue(tweenProgress, frame.curve);
				}
				
				const nextFrame:BoneFrameData = frame.next as BoneFrameData;
				
				transform.x = nextFrame.transform.x - frame.transform.x;
				transform.y = nextFrame.transform.y - frame.transform.y;
				transform.skewX = Transform.normalizeRadian(nextFrame.transform.skewX - frame.transform.skewX);
				transform.skewY = Transform.normalizeRadian(nextFrame.transform.skewY - frame.transform.skewY);
				transform.scaleX = nextFrame.transform.scaleX - frame.transform.scaleX;
				transform.scaleY = nextFrame.transform.scaleY - frame.transform.scaleY;
				
				transform.x = frame.transform.x + transform.x * tweenProgress;
				transform.y = frame.transform.y + transform.y * tweenProgress;
				transform.skewX = frame.transform.skewX + transform.skewX * tweenProgress;
				transform.skewY = frame.transform.skewY + transform.skewY * tweenProgress;
				transform.scaleX = frame.transform.scaleX + transform.scaleX * tweenProgress;
				transform.scaleY = frame.transform.scaleY + transform.scaleY * tweenProgress;
			}
			
			transform.add(timeline.originTransform);
		}
		
		protected function _globalToLocal(armature:ArmatureData):void // Support 2.x ~ 3.x data.
		{
			const keyFrames:Vector.<BoneFrameData> = new Vector.<BoneFrameData>();
			const bones:Vector.<BoneData> = armature.sortedBones.concat().reverse();
			
			for (var i:uint = 0, l:uint = bones.length; i < l; ++i)
			{
				const bone:BoneData = bones[i];
				if (bone.parent) 
				{
					bone.parent.transform.toMatrix(_helpMatrix);
					_helpMatrix.invert();
					Transform.transformPoint(_helpMatrix, bone.transform.x, bone.transform.y, _helpPoint);
					bone.transform.x = _helpPoint.x;
					bone.transform.y = _helpPoint.y;
					bone.transform.rotation -= bone.parent.transform.rotation;
				}
				
				var frame:BoneFrameData = null;
				for each (var animation:AnimationData in armature.animations) 
				{
					const timeline:BoneTimelineData = animation.getBoneTimeline(bone.name);
					
					if (!timeline)
					{
						continue;	
					}
					
					const parentTimeline:BoneTimelineData = bone.parent? animation.getBoneTimeline(bone.parent.name): null;
					_helpTransformB.copyFrom(timeline.originTransform);
					keyFrames.length = 0;
					
					for (var j:uint = 0, lJ:uint = timeline.frames.length; j < lJ; ++j) 
					{
						frame = timeline.frames[j] as BoneFrameData;
						
						if (keyFrames.indexOf(frame) >= 0) 
						{
							continue;
						}
						
						keyFrames.push(frame);
						
						if (parentTimeline)
						{
							_getTimelineFrameMatrix(animation, parentTimeline, frame.position, _helpTransformA);
							frame.transform.add(_helpTransformB);
							_helpTransformA.toMatrix(_helpMatrix);
							_helpMatrix.invert();
							Transform.transformPoint(_helpMatrix, frame.transform.x, frame.transform.y, _helpPoint);
							frame.transform.x = _helpPoint.x;
							frame.transform.y = _helpPoint.y;
							frame.transform.rotation -= _helpTransformA.rotation;
						} 
						else 
						{
							frame.transform.add(_helpTransformB);
						}
						
						frame.transform.minus(bone.transform);
						
						if (j == 0) 
						{
							timeline.originTransform.copyFrom(frame.transform);
							frame.transform.identity();
						} 
						else 
						{
							frame.transform.minus(timeline.originTransform);
						}
					}
				}
			}
		}
		
		protected function _mergeFrameToAnimationTimeline(framePositon:Number, actions:Vector.<ActionData>, events:Vector.<EventData>):void 
		{
			const frameStart:uint = Math.floor(framePositon * this._armature.frameRate); // uint()
			const frames:Vector.<FrameData> = this._animation.frames;
			
			frames.fixed = false;
			
			if (frames.length == 0) {
				const startFrame:AnimationFrameData = BaseObject.borrowObject(AnimationFrameData) as AnimationFrameData; // Add start frame.
				startFrame.position = 0;
				
				if (this._animation.frameCount > 1) {
					frames.length = this._animation.frameCount + 1; // One more count for zero duration frame.
					
					const endFrame:AnimationFrameData = BaseObject.borrowObject(AnimationFrameData) as AnimationFrameData; // Add end frame to keep animation timeline has two different frames atleast.
					endFrame.position = this._animation.frameCount / this._armature.frameRate;
					
					frames[0] = startFrame;
					frames[this._animation.frameCount] = endFrame;
				}
			}
			
			var i:uint = 0, l:uint = 0;
			var insertedFrame:AnimationFrameData = null;
			const replacedFrame:AnimationFrameData = frames.length? frames[frameStart] as AnimationFrameData: null;
			
			if (replacedFrame && (frameStart == 0 || frames[frameStart - 1] == replacedFrame.prev)) // Key frame.
			{
				insertedFrame = replacedFrame;
			} 
			else 
			{
				insertedFrame = BaseObject.borrowObject(AnimationFrameData) as AnimationFrameData; // Create frame.
				insertedFrame.position = frameStart / this._armature.frameRate;
				frames[frameStart] = insertedFrame;
				
				for (i = frameStart + 1, l = frames.length; i < l; ++i) // Clear replaced frame.
				{
					if (replacedFrame && frames[i] == replacedFrame) 
					{
						frames[i] = null;
					}
				}
			}
			
			if (actions) // Merge actions.
			{
				insertedFrame.actions.fixed = false;
				
				for (i = 0, l = actions.length; i < l; ++i) 
				{
					insertedFrame.actions.push(actions[i]);
				}
				
				insertedFrame.actions.fixed = true;
			}
			
			if (events) // Merge events.
			{
				insertedFrame.events.fixed = false;
				
				for (i = 0, l = events.length; i < l; ++i) 
				{
					insertedFrame.events.push(events[i]);
				}
				
				insertedFrame.events.fixed = true;
			}
			
			// Modify frame link and duration.
			var prevFrame:AnimationFrameData = null;
			var nextFrame:AnimationFrameData = null;
			for (i = 0, l = frames.length; i < l; ++i) 
			{
				const currentFrame:AnimationFrameData = frames[i] as AnimationFrameData;
				if (currentFrame && nextFrame != currentFrame) 
				{
					nextFrame = currentFrame;
					
					if (prevFrame) 
					{
						nextFrame.prev = prevFrame;
						prevFrame.next = nextFrame;
						prevFrame.duration = nextFrame.position - prevFrame.position;
					}
					
					prevFrame = nextFrame;
				} 
				else 
				{
					frames[i] = prevFrame;
				}
			}
			
			nextFrame.duration = this._animation.duration - nextFrame.position;
			
			nextFrame = frames[0] as AnimationFrameData;
			prevFrame.next = nextFrame;
			nextFrame.prev = prevFrame;
			
			frames.fixed = true;
		}
	}
}