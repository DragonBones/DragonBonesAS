package dragonBones.objects
{
	import dragonBones.animation.Tween;
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
		
		private static var _frameRate:uint;
		private static var _currentSkeletonData:SkeletonData;
		private static var _helpNode:Node = new Node();
		private static var _helpFrameData:FrameData = new FrameData();
		
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
				if (xml.@[attribute].toString() == value)
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
					parseArmatureData(armatureXML, armatureData);
				}
				else
				{
					armatureData = new ArmatureData();
					parseArmatureData(armatureXML, armatureData);
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
				//
				animationData._boneList = armatureData.boneList;
			}
			_currentSkeletonData = null;
			return skeletonData;
		}
		
		private static function parseArmatureData(armatureXML:XML, armatureData:ArmatureData):void
		{
			var boneXMLList:XMLList = armatureXML.elements(ConstValues.BONE);
			for each(var boneXML:XML in boneXMLList)
			{
				var boneName:String = boneXML.attribute(ConstValues.A_NAME);
				var parentName:String = boneXML.attribute(ConstValues.A_PARENT);
				var parentXML:XML = getElementsByAttribute(boneXMLList, ConstValues.A_NAME, parentName)[0];
				var boneData:BoneData = armatureData.getBoneData(boneName);
				if(boneData)
				{
					parseBoneData(boneXML, parentXML, boneData);
				}
				else
				{
					boneData = new BoneData();
					parseBoneData(boneXML, parentXML, boneData);
					armatureData.addBoneData(boneData, boneName);
				}
				boneData._name = boneName;
			}
			
			armatureData.updateBoneList();
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
				parseNode(parentXML, _helpNode);
				TransformUtils.transformPointWithParent(boneData, _helpNode);
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
					parseMovementData(movementXML, armatureData, movementData);
					animationData.addMovementData(movementData, movementName);
				}
			}
		}
		
		private static function parseMovementData(movementXML:XML, armatureData:ArmatureData, movementData:MovementData):void
		{
			var duration:int = int(movementXML.attribute(ConstValues.A_DURATION));
			
			movementData.setValues(
				(duration > 1)?(duration / _frameRate):(0),
				int(movementXML.attribute(ConstValues.A_DURATION_TO)) / _frameRate,
				int(movementXML.attribute(ConstValues.A_DURATION_TWEEN)) / _frameRate,
				Boolean(int(movementXML.attribute(ConstValues.A_LOOP)) == 1),
				Number(movementXML.attribute(ConstValues.A_TWEEN_EASING)[0])
			);
			
			var movementBoneXMLList:XMLList = movementXML.elements(ConstValues.BONE);
			for each(var movementBoneXML:XML in movementBoneXMLList)
			{
				var boneName:String = movementBoneXML.attribute(ConstValues.A_NAME);
				var boneData:BoneData = armatureData.getBoneData(boneName);
				var parentMovementBoneXML:XML = getElementsByAttribute(movementBoneXMLList, ConstValues.A_NAME, boneData.parent)[0];
				var movementBoneData:MovementBoneData = movementData.getMovementBoneData(boneName);
				if(movementBoneXML)
				{
					if(movementBoneData)
					{
						parseMovementBoneData(movementBoneXML, parentMovementBoneXML, boneData, movementBoneData);
					}
					else
					{
						movementBoneData = new MovementBoneData();
						parseMovementBoneData(movementBoneXML, parentMovementBoneXML, boneData, movementBoneData);
						movementData.addMovementBoneData(movementBoneData, boneName);
					}
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
		}
		
		private static function parseMovementBoneData(movementBoneXML:XML, parentMovementBoneXML:XML, boneData:BoneData, movementBoneData:MovementBoneData):void
		{
			movementBoneData.setValues(
				Number(movementBoneXML.attribute(ConstValues.A_MOVEMENT_SCALE)),
				Number(movementBoneXML.attribute(ConstValues.A_MOVEMENT_DELAY))
			);
			
			var i:uint = 0;
			var parentTotalDuration:uint = 0;
			var totalDuration:uint = 0;
			var currentDuration:uint = 0;
			if(parentMovementBoneXML)
			{
				var parentFrameXMLList:XMLList = parentMovementBoneXML.elements(ConstValues.FRAME);
				var parentFrameCount:uint = parentFrameXMLList.length();
				var parentFrameXML:XML;
			}
			
			
			var frameXMLList:XMLList = movementBoneXML.elements(ConstValues.FRAME);
			var frameCount:uint = frameXMLList.length();
			for(var j:int = 0;j < frameCount;j ++)
			{
				var frameXML:XML = frameXMLList[j];
				var frameData:FrameData = movementBoneData.getFrameDataAt(j);
				if(frameData)
				{
					parseFrameData(frameXML, frameData);
				}
				else
				{
					frameData = new FrameData();
					parseFrameData(frameXML, frameData);
					movementBoneData.addFrameData(frameData);
				}
				
				if(parentMovementBoneXML)
				{
					while(i < parentFrameCount && (parentFrameXML?(totalDuration < parentTotalDuration || totalDuration >= parentTotalDuration + currentDuration):true))
					{
						parentFrameXML = parentFrameXMLList[i];
						parentTotalDuration += currentDuration;
						currentDuration = int(parentFrameXML.attribute(ConstValues.A_DURATION));
						i++;
					}
					
					parseFrameData(parentFrameXML, _helpFrameData);
					
					var tweenFrameXML:XML = parentFrameXMLList[i];
					var progress:Number;
					if(tweenFrameXML)
					{
						progress = (totalDuration - parentTotalDuration) / currentDuration;
					}
					else
					{
						tweenFrameXML = parentFrameXML;
						progress = 0;
					}
					parseNode(tweenFrameXML, _helpNode);
					var parentNode:Node = TransformUtils.getTweenNode(_helpFrameData, _helpNode, progress, _helpFrameData.tweenEasing);
					TransformUtils.transformPointWithParent(frameData, parentNode);
				}
				totalDuration += int(frameXML.attribute(ConstValues.A_DURATION));
				
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
		}
		
		private static function parseMovementFrameData(movementFrameXML:XML, movementFrameData:MovementFrameData):void
		{
			movementFrameData.setValues(
				Number(movementFrameXML.attribute(ConstValues.A_DURATION)) / _frameRate,
				movementFrameXML.attribute(ConstValues.A_MOVEMENT),
				movementFrameXML.attribute(ConstValues.A_EVENT),
				movementFrameXML.attribute(ConstValues.A_SOUND)
			);
		}
	
		dragonBones_internal static function parseFrameData(frameXML:XML, frameData:FrameData):void
		{
			parseNode(frameXML, frameData);
			frameData.duration = int(frameXML.attribute(ConstValues.A_DURATION)) / _frameRate;
			frameData.tweenEasing = Number(frameXML.attribute(ConstValues.A_TWEEN_EASING));
			frameData.tweenRotate = int(frameXML.attribute(ConstValues.A_TWEEN_ROTATE));
			frameData.displayIndex = int(frameXML.attribute(ConstValues.A_DISPLAY_INDEX));
			frameData.movement = String(frameXML.attribute(ConstValues.A_MOVEMENT));
				
			frameData.event = String(frameXML.attribute(ConstValues.A_EVENT));
			frameData.sound = String(frameXML.attribute(ConstValues.A_SOUND));
			frameData.soundEffect = String(frameXML.attribute(ConstValues.A_SOUND_EFFECT));
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
	}
}