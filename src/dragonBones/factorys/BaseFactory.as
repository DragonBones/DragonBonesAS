package dragonBones.factorys
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.display.NativeDisplayBridge;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DecompressedData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.SubTextureData;
	import dragonBones.objects.TextureAtlasData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	use namespace dragonBones_internal;
	
	/** Dispatched when the textureData init completed. */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * A object managing the set of armature resources for the tranditional DisplayList. It parses the raw data, stores the armature resources and creates armature instrances.
	 * @see dragonBones.Armature
	 */
	public class BaseFactory extends EventDispatcher
	{
		private static var _helpMatirx:Matrix = new Matrix();
		private static var _loaderContext:LoaderContext = new LoaderContext(false);
		
		/** @private */
		public static function getTextureDisplay(textureAtlasData:TextureAtlasData, fullName:String, pivotX:int, pivotY:int):Object
		{
			if (textureAtlasData.movieClip)
			{
				var movieClip:MovieClip = textureAtlasData.movieClip;
				movieClip.gotoAndStop(movieClip.totalFrames);
				movieClip.gotoAndStop(fullName);
				if (movieClip.numChildren > 0)
				{
					try
					{
						var displaySWF:Object = movieClip.getChildAt(0);
						displaySWF.x = 0;
						displaySWF.y = 0;
						return displaySWF;
					}
					catch(e:Error)
					{
						throw "Can not get the movie clip, please make sure the version of the resource compatible with app version!";
					}
				}
			}
			else if(textureAtlasData.bitmapData)
			{
				var subTextureData:SubTextureData = textureAtlasData.getSubTextureData(fullName);
				if (subTextureData)
				{
					var displayShape:Shape = new Shape();
					//1.4
					var pivotX:int = pivotX || subTextureData.pivotX;
					var pivotY:int = pivotY || subTextureData.pivotY;
					_helpMatirx.tx = -subTextureData.x - pivotX;
					_helpMatirx.ty = -subTextureData.y - pivotY;
					
					displayShape.graphics.beginBitmapFill(textureAtlasData.bitmapData, _helpMatirx, false);
					displayShape.graphics.drawRect(-pivotX, -pivotY, subTextureData.width, subTextureData.height);
					return displayShape;
				}
			}
			return null;
		}
		
		protected var _skeletonDataDic:Object;
		protected var _textureAtlasDataDic:Object;
		protected var _loaderDic:Object;
		
		protected var _textureAtlasData:TextureAtlasData;
		
		/**
		 * Creates a new <code>BaseFactory</code>
		 *
		 */
		public function BaseFactory()
		{
			super();
			_skeletonDataDic = {};
			_textureAtlasDataDic = {};
			_loaderDic = {};
		}
		
		/**
		 * Pareses the raw data.
		 * @param	bytes Represents the raw data for the whole skeleton system.
		 */
		public function parseData(bytes:ByteArray, skeletonName:String = null):void
		{
			var decompressedData:DecompressedData = XMLDataParser.decompressData(bytes);
			
			var skeletonData:SkeletonData = XMLDataParser.parseSkeletonData(decompressedData.skeletonXML);
			addSkeletonData(skeletonData, skeletonName);
			
			var textureAtlasData:TextureAtlasData = XMLDataParser.parseTextureAtlasData(decompressedData.textureAtlasXML);
			addTextureAtlasData(textureAtlasData, skeletonName);
			
			var loader:Loader = new Loader();
			_loaderContext.allowCodeImport = true;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			loader.loadBytes(decompressedData.textureBytes, _loaderContext);
			_loaderDic[skeletonName] = loader;
			decompressedData.dispose();
		}
		
		public function getSkeletonData(name:String):SkeletonData
		{
			return _skeletonDataDic[name];
		}
		
		public function addSkeletonData(skeletonData:SkeletonData, name:String = null):void
		{
			name = name || skeletonData.name;
			if(name)
			{
				_skeletonDataDic[name] = skeletonData;
			}
		}
		
		public function removeSkeletonData(name:String):void
		{
			delete _skeletonDataDic[name];
		}
		
		public function getTextureAtlasData(name:String):TextureAtlasData
		{
			return _textureAtlasDataDic[name];
		}
		
		public function addTextureAtlasData(textureAtlasData:TextureAtlasData, name:String = null):void
		{
			name = name || textureAtlasData.name;
			if(name)
			{
				_textureAtlasDataDic[name] = textureAtlasData;
			}
		}
		
		public function removeTextureAtlasData(name:String):void
		{
			delete _textureAtlasDataDic[name];
		}
		
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose():void
		{
			for each(var skeletonData:SkeletonData in _skeletonDataDic)
			{
				skeletonData.dispose();
			}
			for each(var textureAtlasData:TextureAtlasData in _textureAtlasDataDic)
			{
				textureAtlasData.dispose();
			}
			_skeletonDataDic = null;
			_textureAtlasDataDic = null;
			
			_loaderDic = null;
		}
		
		/**
		 * Builds a new armature by name
		 * @param	armatureName
		 * @return
		 */
		public function buildArmature(armatureName:String, animationName:String = null, skeletonName:String = null, textureAtlasName:String = null):Armature
		{
			var armatureData:ArmatureData;
			var skeletonData:SkeletonData;
			if(skeletonName)
			{
				skeletonData = _skeletonDataDic[skeletonName];
				if(skeletonData)
				{
					armatureData = skeletonData.getArmatureData(armatureName);
				}
			}
			else
			{
				for (skeletonName in _skeletonDataDic)
				{
					skeletonData = _skeletonDataDic[skeletonName];
					armatureData = skeletonData.getArmatureData(armatureName);
					if(armatureData)
					{
						break;
					}
				}
			}
			if(!armatureData)
			{
				return null;
			}
			
			_textureAtlasData = _textureAtlasDataDic[textureAtlasName || skeletonName];
			
			var animationData:AnimationData = skeletonData.getAnimationData(animationName || armatureName);
			var armature:Armature = generateArmature();
			armature.name = armatureName;
			armature.animation.setData(animationData);
			var boneList:Vector.<String> = armatureData.boneList;
			for each(var boneName:String in boneList)
			{
				var boneData:BoneData = armatureData.getBoneData(boneName);
				if(boneData)
				{
					var bone:Bone = buildBone(boneData);
					armature.addBone(bone, boneData.parent);
				}
			}
			armature.update();
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
			
			var displayData:DisplayData;
			for(var i:int = boneData.totalDisplays - 1;i >= 0;i --)
			{
				displayData = boneData.getDisplayDataAt(i);
				bone.changeDisplay(i);
				if (displayData.isArmature)
				{
					var childArmature:Armature = buildArmature(displayData.name);
					if(childArmature)
					{
						childArmature.animation.play();
						bone.display = childArmature;
					}
				}
				else
				{
					bone.display = getBoneTextureDisplay(displayData.name, displayData.pivotX, displayData.pivotY);
				}
			}
			return bone;
		}
		
		protected function getBoneTextureDisplay(textureName:String, pivotX:int, pivotY:int):Object
		{
			return getTextureDisplay(_textureAtlasData, textureName, pivotX, pivotY);
		}
		
		protected function generateBone():Bone
		{
			var bone:Bone = new Bone(new NativeDisplayBridge());
			return bone;
		}
		
		private function loaderCompleteHandler(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			var loader:Loader = e.target.loader;
			var content:Object = e.target.content;
			loader.unloadAndStop();
			
			for(var skeletonName:String in _loaderDic)
			{
				var eachLoader:Loader = _loaderDic[skeletonName];
				if(eachLoader == loader)
				{
					delete _loaderDic[skeletonName];
					break;
				}
				eachLoader = null;
			}
			
			if(eachLoader)
			{
				var textureAtlasData:TextureAtlasData = _textureAtlasDataDic[skeletonName];
				if (content is Bitmap)
				{
					textureAtlasData.bitmapData = (content as Bitmap).bitmapData;
				}
				else if (content is Sprite)
				{
					textureAtlasData.movieClip = (content as Sprite).getChildAt(0) as MovieClip;
					textureAtlasData.movieClip.stop();
				}
				completeHandler(skeletonName);
			}
		}
		
		private function completeHandler(skeletonName:String):void
		{
			if(hasEventListener(Event.COMPLETE))
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
	}
}