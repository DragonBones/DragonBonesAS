package dragonBones.objects
{
	import dragonBones.animation.WorldClock;
	import dragonBones.errors.UnknownDataError;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.TransformUtils;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.utils.ByteArray;
	
	use namespace dragonBones_internal;
	
	/** @private */
	public class XMLDataParser
	{
		private static const ANGLE_TO_RADIAN:Number = Math.PI / 180;
		private static const HALF_PI:Number = Math.PI * 0.5;
		
		private static var helpNode:Node = new Node();
		
		private static var _frameRate:uint;
		
		private static var _currentSkeletonData:SkeletonData;
		
		private static function checkSkeletonXMLVersion(skeletonXML:XML):void
		{
			var version:String = skeletonXML.attribute(ConstValues.A_VERSION);
			switch(version)
			{
				case ConstValues.VERSION_14:
					break;
				case ConstValues.VERSION:
					break;
				default:
					throw new Error("Nonsupport data version!");
			}
		}
		
		public static function getElementsByAttribute(xmlList:XMLList, attribute:String, value:String):XMLList
		{
			var result:XMLList = new XMLList();
			var length:uint = xmlList.length();
			for (var i:int = 0; i < length; i++ )
			{
				var xml:XML = xmlList[i];
				if (xml["@" + attribute].toString() == value)
				{
					result[result.length()] = xmlList[i];
				}
			}
			return result;
		}
		
		public static function compressData(skeletonXML:XML, textureAtlasXML:XML, byteArray:ByteArray):ByteArray 
		{
			var byteArrayCopy:ByteArray = new ByteArray();
			byteArrayCopy.writeBytes(byteArray);
			
			var xmlBytes:ByteArray = new ByteArray();
			xmlBytes.writeUTFBytes(textureAtlasXML.toXMLString());
			xmlBytes.compress();
			
			byteArrayCopy.position = byteArrayCopy.length;
			byteArrayCopy.writeBytes(xmlBytes);
			byteArrayCopy.writeInt(xmlBytes.length);
			
			xmlBytes.length = 0;
			xmlBytes.writeUTFBytes(skeletonXML.toXMLString());
			xmlBytes.compress();
			
			byteArrayCopy.position = byteArrayCopy.length;
			byteArrayCopy.writeBytes(xmlBytes);
			byteArrayCopy.writeInt(xmlBytes.length);
			
			return byteArrayCopy;
		}
		
		public static function decompressData(compressedByteArray:ByteArray):DecompressedData
		{
			var dataType:String = BytesType.getType(compressedByteArray);
			switch(dataType)
			{
				case BytesType.SWF:
				case BytesType.PNG:
				case BytesType.JPG:
					try 
					{
						compressedByteArray.position = compressedByteArray.length - 4;
						var strSize:int = compressedByteArray.readInt();
						var position:uint = compressedByteArray.length - 4 - strSize;
						
						var xmlBytes:ByteArray = new ByteArray();
						xmlBytes.writeBytes(compressedByteArray, position, strSize);
						xmlBytes.uncompress();
						compressedByteArray.length = position;
						
						var skeletonXML:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
						
						compressedByteArray.position = compressedByteArray.length - 4;
						strSize = compressedByteArray.readInt();
						position = compressedByteArray.length - 4 - strSize;
						
						xmlBytes.length = 0;
						xmlBytes.writeBytes(compressedByteArray, position, strSize);
						xmlBytes.uncompress();
						compressedByteArray.length = position;
						var textureAtlasXML:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
					}
					catch (e:Error)
					{
						throw new Error("Decompress error!");
					}
					
					var decompressedData:DecompressedData = new DecompressedData(
						skeletonXML, 
						textureAtlasXML, 
						compressedByteArray
					);
					return decompressedData;
				case BytesType.ZIP:
					throw new Error("Can not decompress zip!");
				default:
					throw new UnknownDataError();
			}
			return null;
		}
		
		public static function parseSkeletonData(skeletonXML:XML):SkeletonData
		{
			checkSkeletonXMLVersion(skeletonXML);
			
			_frameRate = int(skeletonXML.attribute(ConstValues.A_FRAME_RATE));
			WorldClock.defaultTimeLag = 1/_frameRate;
			
			var skeletonData:SkeletonData = new SkeletonData();
			skeletonData._name = skeletonXML.attribute(ConstValues.A_NAME);
			_currentSkeletonData = skeletonData;
			
			for each(var armatureXML:XML in skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE))
			{
				var armatureName:String = armatureXML.attribute(ConstValues.A_NAME);
				var armatureData:ArmatureData = skeletonData.getArmatureData(animationName);
				if(armatureData)
				{
					parseAramtureData(armatureXML, armatureData);
				}
				else
				{
					armatureData = new ArmatureData();
					parseAramtureData(armatureXML, armatureData);
					skeletonData.addArmatureData(armatureData, armatureName);
				}
			}
			
			for each(var animationXML:XML in skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION))
			{
				var animationName:String = animationXML.attribute(ConstValues.A_NAME);
				armatureData = skeletonData.getArmatureData(animationName);
				
				var animationData:AnimationData = skeletonData.getAnimationData(animationName);
				if(animationData)
				{
					parseAnimationData(
						animationXML, 
						animationData, 
						armatureData
					);
				}
				else
				{
					animationData = new AnimationData();
					parseAnimationData(
						animationXML, 
						animationData, 
						armatureData
					);
					skeletonData.addAnimationData(animationData, animationName);
				}
			}
			_currentSkeletonData = null;
			return skeletonData;
		}
		
		private static function parseAramtureData(armatureXML:XML, aramtureData:ArmatureData):void
		{
			var boneXMLList:XMLList = armatureXML.elements(ConstValues.BONE);
			for each(var boneXML:XML in boneXMLList)
			{
				var boneName:String = boneXML.attribute(ConstValues.A_NAME);
				var parentName:String = boneXML.attribute(ConstValues.A_PARENT);
				var parentXML:XML = getElementsByAttribute(boneXMLList, ConstValues.A_NAME, parentName)[0];
				var boneData:BoneData = aramtureData.getBoneData(boneName);
				if(boneData)
				{
					parseBoneData(boneXML, parentXML, boneData);
				}
				else
				{
					boneData = new BoneData();
					parseBoneData(boneXML, parentXML, boneData);
					aramtureData.addBoneData(boneData, boneName);
				}
				boneData._name = boneName;
			}
				
			aramtureData.updateBoneList();
		}
		
		dragonBones_internal static function parseBoneData(boneXML:XML, parentXML:XML, boneData:BoneData):void
		{
			parseNode(boneXML, boneData);
			var displayXMLList:XMLList = boneXML.elements(ConstValues.DISPLAY);
			var length:uint = displayXMLList.length();
			for(var i:int = 0;i < length;i ++)
			{
				var displayXML:XML = displayXMLList[i];
				var displayName:String = displayXML.attribute(ConstValues.A_NAME);
				boneData.addDisplayData(displayName);
				if(_currentSkeletonData)
				{
					_currentSkeletonData.addDisplayData(parseDisplayData(displayXML), displayName);
				}
			}
			
			if(parentXML)
			{
				boneData._parent = parentXML.attribute(ConstValues.A_NAME);
				parseNode(parentXML, helpNode);
				TransformUtils.transformPointWithParent(boneData, helpNode);
			}
			else
			{
				boneData._parent = null;
			}
		}
		
		private static function parseDisplayData(displayXML:XML):DisplayData
		{
			var displayData:DisplayData = new DisplayData();
			displayData._isArmature = Boolean(int(displayXML.attribute(ConstValues.A_IS_ARMATURE)));
			displayData.pivotX = int(displayXML.attribute(ConstValues.A_PIVOT_X));
			displayData.pivotY = int(displayXML.attribute(ConstValues.A_PIVOT_Y));
			return displayData;
		}
		
		dragonBones_internal static function parseAnimationData(animationXML:XML, animationData:AnimationData, armatureData:ArmatureData):void
		{
			for each(var movementXML:XML in animationXML.elements(ConstValues.MOVEMENT))
			{
				var movementName:String = movementXML.attribute(ConstValues.A_NAME);
				var movementData:MovementData = animationData.getMovementData(movementName);
				if(movementData)
				{
					parseMovementData(movementXML, armatureData, movementData);
				}
				else
				{
					movementData = new MovementData();
					var boneList:Vector.<String> = parseMovementData(movementXML, armatureData, movementData);
					animationData.addMovementData(movementData, movementName);
					animationData.addBoneList(boneList);
				}
			}
		}
		
		private static function parseMovementData(movementXML:XML, armatureData:ArmatureData, movementData:MovementData):Vector.<String>
		{
			var duration:int = int(movementXML.attribute(ConstValues.A_DURATION));
			
			movementData.setValues(
				(duration > 1)?(duration / _frameRate):(0),
				int(movementXML.attribute(ConstValues.A_DURATION_TO)) / _frameRate,
				int(movementXML.attribute(ConstValues.A_DURATION_TWEEN)) / _frameRate,
				Boolean(int(movementXML.attribute(ConstValues.A_LOOP)) == 1),
				Number(movementXML.attribute(ConstValues.A_TWEEN_EASING)[0])
			);
			
			var boneList:Vector.<String> = new Vector.<String>;
			var movementBoneXMLList:XMLList = movementXML.elements(ConstValues.BONE);
			for each(var movementBoneXML:XML in movementBoneXMLList)
			{
				var boneName:String = movementBoneXML.attribute(ConstValues.A_NAME);
				var boneData:BoneData = armatureData.getBoneData(boneName);
				var parentXML:XML = getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, boneData.parent)[0];
				var movementBoneData:MovementBoneData = movementData.getMovementBoneData(boneName);
				if(movementBoneData)
				{
					parseMovementBoneData(movementBoneXML, parentXML, boneData, movementBoneData);
				}
				else
				{
					movementBoneData = new MovementBoneData();
					parseMovementBoneData(movementBoneXML, parentXML, boneData, movementBoneData);
					movementData.addMovementBoneData(movementBoneData, boneName);
					boneList.push(boneName);
				}
			}
			
			var movementFrameXMLList:XMLList = movementXML.elements(ConstValues.FRAME);
			var length:uint = movementFrameXMLList.length();
			for(var i:int = 0;i < length;i ++)
			{
				var movementFrameXML:XML = movementFrameXMLList[i];
				var movementFrameData:MovementFrameData = movementData.getMovementFrameDataAt(i);
				if(movementFrameData)
				{
					parseMovementFrameData(movementFrameXML, movementFrameData);
				}
				else
				{
					movementFrameData = new MovementFrameData();
					parseMovementFrameData(movementFrameXML, movementFrameData)
					movementData.addMovementFrameData(movementFrameData);
				}
			}
			
			return boneList;
		}
		
		private static function parseMovementBoneData(movementBoneXML:XML, parentXML:XML, boneData:BoneData, movementBoneData:MovementBoneData):void
		{
			movementBoneData.setValues(
				Number(movementBoneXML.attribute(ConstValues.A_MOVEMENT_SCALE)),
				Number(movementBoneXML.attribute(ConstValues.A_MOVEMENT_DELAY))
			);
			
			if(parentXML)
			{
				var xmlList:XMLList = parentXML.elements(ConstValues.FRAME);
				var parentFrameXML:XML;
				var parentFrameCount:uint = xmlList.length();
				var i:uint = 0;
				var parentTotalDuration:uint = 0;
				var currentDuration:uint = 0;
			}
			
			var totalDuration:uint = 0;
			var frameXMLList:XMLList = movementBoneXML.elements(ConstValues.FRAME);
			var frameCount:uint = frameXMLList.length();
			for(var j:int = 0;j < frameCount;j ++)
			{
				var frameXML:XML = frameXMLList[j];
				if(parentXML)
				{
					while(i < parentFrameCount && (parentFrameXML?(totalDuration < parentTotalDuration || totalDuration >= parentTotalDuration + currentDuration):true))
					{
						parentFrameXML = xmlList[i];
						parentTotalDuration += currentDuration;
						currentDuration = int(parentFrameXML.attribute(ConstValues.A_DURATION));
						i++;
					}
					if(parentFrameXML)
					{
						var tweenFrameXML:XML = xmlList[i];
						var passedFrame:int = totalDuration - parentTotalDuration;
						if(tweenFrameXML && passedFrame > 0)
						{
							parentFrameXML = getTweenFrameXML(parentFrameXML, tweenFrameXML, passedFrame, currentDuration);
						}
					}
				}
				var frameData:FrameData = movementBoneData.getFrameDataAt(j);
				if(frameData)
				{
					parseFrameData(frameXML, parentFrameXML, boneData, frameData);
				}
				else
				{
					frameData = new FrameData();
					parseFrameData(frameXML, parentFrameXML, boneData, frameData);
					movementBoneData.addFrameData(frameData);
				}
				totalDuration += frameData.duration;
				frameData.duration /= _frameRate;
			}
		}
		
		private static function parseMovementFrameData(movementFrameXML:XML, movementFrameData:MovementFrameData):void
		{
			movementFrameData.setValues(
				Number(movementFrameXML.attribute(ConstValues.A_DURATION))/_frameRate,
				movementFrameXML.attribute(ConstValues.A_MOVEMENT),
				movementFrameXML.attribute(ConstValues.A_EVENT),
				movementFrameXML.attribute(ConstValues.A_SOUND)
			);
		}
	
		private static function parseFrameData(frameXML:XML, parentFrameXML:XML, boneData:BoneData, frameData:FrameData):void
		{
			parseNode(frameXML, frameData);
			frameData.duration = int(frameXML.attribute(ConstValues.A_DURATION));
			frameData.tweenEasing = Number(frameXML.attribute(ConstValues.A_TWEEN_EASING));
			frameData.tweenRotate = int(frameXML.attribute(ConstValues.A_TWEEN_ROTATE));
			frameData.displayIndex = int(frameXML.attribute(ConstValues.A_DISPLAY_INDEX));
			frameData.movement = String(frameXML.attribute(ConstValues.A_MOVEMENT));
				
			frameData.event = String(frameXML.attribute(ConstValues.A_EVENT));
			frameData.sound = String(frameXML.attribute(ConstValues.A_SOUND));
			frameData.soundEffect = String(frameXML.attribute(ConstValues.A_SOUND_EFFECT));
				
			if(parentFrameXML)
			{
				parseNode(parentFrameXML, helpNode);
				TransformUtils.transformPointWithParent(frameData, helpNode);
			}
			
			frameData.x -= boneData.x;
			frameData.y -= boneData.y;
			frameData.skewX -= boneData.skewX;
			frameData.skewY -= boneData.skewY;
			frameData.scaleX -= boneData.scaleX;
			frameData.scaleY -= boneData.scaleY;
			frameData.pivotX -= boneData.pivotX;
			frameData.pivotY -= boneData.pivotY;
			frameData.z -= boneData.z;
		}
		
		private static function parseNode(xml:XML, node:Node):void
		{
			node.x = Number(xml.attribute(ConstValues.A_X));
			node.y = Number(xml.attribute(ConstValues.A_Y));
			node.skewX = Number(xml.attribute(ConstValues.A_SKEW_X)) * ANGLE_TO_RADIAN;
			node.skewY = Number(xml.attribute(ConstValues.A_SKEW_Y)) * ANGLE_TO_RADIAN;
			node.scaleX = Number(xml.attribute(ConstValues.A_SCALE_X));
			node.scaleY = Number(xml.attribute(ConstValues.A_SCALE_Y));
			node.pivotX =  int(xml.attribute(ConstValues.A_PIVOT_X));
			node.pivotY =  int(xml.attribute(ConstValues.A_PIVOT_Y));
			node.z = int(xml.attribute(ConstValues.A_Z));
		}
		
		
		private static var _parentFrameXML:XML;
		private static var _from:FrameData = new FrameData();
		private static var _to:FrameData = new FrameData();
		private static var _tweenNode:TweenNode = new TweenNode();
		
		private static function getTweenFrameXML(parentFrameXML:XML, tweenFrameXML:XML, passedFrame:int, duration:uint):XML
		{
			if(!_parentFrameXML)
			{
				_parentFrameXML = parentFrameXML.copy();
			}
			
			var progress:Number = passedFrame / (duration + 1);
			
			parseNode(parentFrameXML, _from);
			parseNode(tweenFrameXML, _to);
			_tweenNode.subtract(_from, _to);
			
			_from.tweenEasing = Number(parentFrameXML.attribute(ConstValues.A_TWEEN_EASING));
			_to.tweenRotate = int(tweenFrameXML.attribute(ConstValues.A_TWEEN_ROTATE));
			
			if(!isNaN(_from.tweenEasing))
			{
				if (_from.tweenEasing > 0)
				{
					progress += (Math.sin(progress * HALF_PI) - progress) * _from.tweenEasing;
				}
				else
				{
					progress -= (1 - Math.cos(progress * HALF_PI) - progress) * _from.tweenEasing;
				}
			}
			_parentFrameXML[ConstValues.AT + ConstValues.A_X] = _from.x + progress * _tweenNode.x;
			_parentFrameXML[ConstValues.AT + ConstValues.A_Y] = _from.y + progress * _tweenNode.y;
			_parentFrameXML[ConstValues.AT + ConstValues.A_SCALE_X] = _from.scaleX + progress * _tweenNode.scaleX;
			_parentFrameXML[ConstValues.AT + ConstValues.A_SCALE_Y] = _from.scaleY + progress * _tweenNode.scaleY;
			_parentFrameXML[ConstValues.AT + ConstValues.A_SKEW_X] = (_from.skewX + progress * _tweenNode.skewX) / ANGLE_TO_RADIAN;
			_parentFrameXML[ConstValues.AT + ConstValues.A_SKEW_Y] = (_from.skewY + progress * _tweenNode.skewY) / ANGLE_TO_RADIAN;
			_parentFrameXML[ConstValues.AT + ConstValues.A_PIVOT_X] = _from.pivotX + progress * _tweenNode.pivotX;
			_parentFrameXML[ConstValues.AT + ConstValues.A_PIVOT_Y] = _from.pivotY + progress * _tweenNode.pivotY;
			return _parentFrameXML;
		}
	}
}