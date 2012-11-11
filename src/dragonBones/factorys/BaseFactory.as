package dragonBones.factorys 
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.display.NativeDisplayBridge;
	import dragonBones.display.PivotBitmap;
	import dragonBones.events.Event;
	import dragonBones.events.EventDispatcher;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.Node;
	import dragonBones.objects.SkeletonAndTextureRawData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.TextureData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.dragonBones_internal;
	import dragonBones.utils.uncompressionData;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	use namespace dragonBones_internal;
	
	/** Dispatched when the textureData init completed. */
	[Event(name="textureComplete", type="dragonBones.events.Event")]
	
	/**
	 *
	 * @author Akdcl
	 */
	public class BaseFactory extends EventDispatcher 
	{
		public static function getTextureDisplay(textureData:TextureData, fullName:String):Object 
		{
			var clip:MovieClip = textureData.clip;
			if (clip) 
			{
				clip.gotoAndStop(clip.totalFrames);
				clip.gotoAndStop(fullName);
				if (clip.numChildren > 0) 
				{
					try
					{
						var displaySWF:Object = clip.getChildAt(0);
						displaySWF.x = 0;
						displaySWF.y = 0;
						return displaySWF;
					}
					catch(e:Error)
					{
						trace("can not get the clip, please make sure the version of the resource compatible with app version！");
					}
				}
			}
			else if(textureData.bitmap)
			{
				var subTextureXML:XML = textureData.getSubTextureXML(fullName);
				if (subTextureXML) 
				{
					var rect:Rectangle = new Rectangle(
						int(subTextureXML.attribute(ConstValues.A_X)),
						int(subTextureXML.attribute(ConstValues.A_Y)),
						int(subTextureXML.attribute(ConstValues.A_WIDTH)),
						int(subTextureXML.attribute(ConstValues.A_HEIGHT))
					);
					var displayBitmap:PivotBitmap = new PivotBitmap(textureData.bitmap.bitmapData);
					displayBitmap.smoothing = true;
					displayBitmap.scrollRect = rect;
					displayBitmap.pivotX = int(subTextureXML.attribute(ConstValues.A_PIVOT_X));
					displayBitmap.pivotY = int(subTextureXML.attribute(ConstValues.A_PIVOT_Y));
					return displayBitmap;
				}
			}
			return null;
		}
		
		protected var _skeletonData:SkeletonData;
		public function get skeletonData():SkeletonData
		{
			return _skeletonData;
		}
		public function set skeletonData(value:SkeletonData):void 
		{
			_skeletonData = value;
		}
		
		protected var _textureData:TextureData;
		public function get textureData():TextureData 
		{
			return _textureData;
		}
		public function set textureData(value:TextureData):void 
		{
			if(_textureData)
			{
				_textureData.removeEventListener(Event.TEXTURE_COMPLETE, textureCompleteHandler);
			}
			_textureData = value;
			if(_textureData)
			{
				_textureData.addEventListener(Event.TEXTURE_COMPLETE, textureCompleteHandler);
			}
		}
		
		public function BaseFactory() 
		{
			super();
		}
		
		public function parseData(bytes:ByteArray, completeCallback:Function = null):void
		{
			var sat:SkeletonAndTextureRawData = uncompressionData(bytes);
			skeletonData = XMLDataParser.parseSkeletonData(sat.skeletonXML);
			textureData = new TextureData(sat.textureAtlasXML, sat.textureBytes, completeCallback);
			sat.dispose();
		}
		
		public function dispose():void
		{
			removeEventListeners();
			skeletonData = null;
			textureData = null;
		}
		
		public function buildArmature(armatureName:String):Armature 
		{
			var armatureData:ArmatureData = skeletonData.getArmatureData(armatureName);
			if(!armatureData)
			{
				return null;
			}
			var animationData:AnimationData = skeletonData.getAnimationData(armatureName);
			var armature:Armature = generateArmature();
			armature.name = armatureName;
			if (armature) 
			{
				armature.animation.setData(animationData);
				var boneList:Array = armatureData.boneList;
				for each(var boneName:String in boneList) 
				{
					var boneData:BoneData = armatureData.getBoneData(boneName);
					var bone:Bone = buildBone(boneData);
					if(bone)
					{
						armature.addBone(bone, boneData.parent);
					}
				}
			}
			return armature;
		}
		
		protected function generateArmature():Armature 
		{
			var display:Sprite = new Sprite();
			var armature:Armature = new Armature(display);
			return armature;
		}
		
		protected function buildBone(boneData:BoneData):Bone
		{
			var bone:Bone = generateBone();
			bone.origin.copy(boneData);
			bone.name = boneData.name;
			
			var length:uint = boneData.displayLength;
			var displayData:DisplayData;
			for(var i:int = length - 1;i >=0;i --)
			{
				displayData = boneData.getDisplayDataAt(i);
				bone.changeDisplay(i);
				if (displayData.isArmature) 
				{
					var childArmature:Armature = buildArmature(displayData.name);
					childArmature.animation.play();
					bone.display = childArmature;
				}
				else 
				{
					bone.display = getBoneTextureDisplay(displayData.name);
				}
			}
			return bone;
		}
		
		protected function getBoneTextureDisplay(textureName:String):Object
		{
			return getTextureDisplay(_textureData, textureName);
		}
		
		protected function generateBone():Bone 
		{
			var bone:Bone = new Bone(new NativeDisplayBridge());
			return bone;
		}
		
		private function textureCompleteHandler(e:Event):void
		{
			dispatchEvent(e);
		}
	}
}