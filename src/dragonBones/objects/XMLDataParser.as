package dragonBones.objects
{
	/**
	* Copyright 2012-2013. DragonBones. All Rights Reserved.
	* @playerversion Flash 10.0, Flash 10
	* @langversion 3.0
	* @version 2.0
	*/
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.DBDataUtils;
	
	import flash.geom.ColorTransform;
	import flash.utils.ByteArray;

	use namespace dragonBones_internal;
	
	/**
	 * The XMLDataParser class creates and parses xml data from dragonBones generated maps.
	 */
	public class XMLDataParser
	{
		private static const ANGLE_TO_RADIAN:Number = Math.PI / 180;
		
		private static function checkVersion(xml:XML):void
		{
			var version:String = xml.@[ConstValues.A_VERSION];
			switch (version)
			{
				case "1.5":
				case "2.0":
				case "2.1":
				case "2.1.1":
				case "2.1.2":
				case "2.2":
					break;
				case DragonBones.DATA_VERSION:
					break;
				default: 
					throw new Error("Nonsupport version!");
			}
		}
		/**
		 * Compress all data into a ByteArray for serialization.
		 * @param	xml The DragonBones data.
		 * @param	textureAtlasXML The TextureAtlas data.
		 * @param	byteArray The ByteArray representing the map.
		 * @return ByteArray. A DragonBones compatible ByteArray.
		 */
		public static function compressData(xml:XML, textureAtlasXML:XML, byteArray:ByteArray):ByteArray
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
			xmlBytes.writeUTFBytes(xml.toXMLString());
			xmlBytes.compress();
			
			byteArrayCopy.position = byteArrayCopy.length;
			byteArrayCopy.writeBytes(xmlBytes);
			byteArrayCopy.writeInt(xmlBytes.length);
			
			return byteArrayCopy;
		}
		/**
		 * Decompress a compatible DragonBones data.
		 * @param	compressedByteArray The ByteArray to decompress.
		 * @return A DecompressedData instance.
		 */
		public static function decompressData(byteArray:ByteArray):DecompressedData
		{
			var dataType:String = BytesType.getType(byteArray);
			switch (dataType)
			{
				case BytesType.SWF: 
				case BytesType.PNG: 
				case BytesType.JPG: 
				case BytesType.ATF: 
					try
					{
						byteArray.position = byteArray.length - 4;
						var strSize:int = byteArray.readInt();
						var position:uint = byteArray.length - 4 - strSize;
						
						var xmlBytes:ByteArray = new ByteArray();
						xmlBytes.writeBytes(byteArray, position, strSize);
						xmlBytes.uncompress();
						byteArray.length = position;
						
						var xml:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
						
						byteArray.position = byteArray.length - 4;
						strSize = byteArray.readInt();
						position = byteArray.length - 4 - strSize;
						
						xmlBytes.length = 0;
						xmlBytes.writeBytes(byteArray, position, strSize);
						xmlBytes.uncompress();
						byteArray.length = position;
						var textureAtlasXML:XML = XML(xmlBytes.readUTFBytes(xmlBytes.length));
					}
					catch (e:Error)
					{
						throw new Error("Data error!");
					}
					var decompressedData:DecompressedData = new DecompressedData(xml, textureAtlasXML, byteArray);
					decompressedData.dataType = dataType;
					return decompressedData;
				case BytesType.ZIP:
					throw new Error("Can not decompress zip!");
				default: 
					throw new Error("Nonsupport data!");
			}
			return null;
		}
		
		/**
		 * Parse the SkeletonData.
		 * @param	xml The SkeletonData xml to parse.
		 * @return A SkeletonData instance.
		 */
		public static function parseSkeletonData(xml:XML):SkeletonData
		{
			checkVersion(xml);
			var frameRate:uint = int(xml.@[ConstValues.A_FRAME_RATE]);
			
			var data:SkeletonData = new SkeletonData();
			data.name = xml.@[ConstValues.A_NAME];
			
			var armatureXMLList:XMLList = xml[ConstValues.ARMATURES][ConstValues.ARMATURE];
			var length:int = armatureXMLList.length();
			for(var i:int = 0;i< length; i ++)
			{
				data.addArmatureData(parseArmatureData(armatureXMLList[i], data));
			}
			
			var animationsXMLList:XMLList = xml[ConstValues.ANIMATIONS][ConstValues.ANIMATION];
			length = animationsXMLList.length();
			for(i = 0;i< length; i ++)
			{
				var animationsXML:XML = animationsXMLList[i];
				var armatureData:ArmatureData = data.getArmatureData(animationsXML.@[ConstValues.A_NAME]);
				if(armatureData)
				{
					var animationXMLList:XMLList = animationsXML[ConstValues.MOVEMENT];
					for each(var animationXML:XML in animationXMLList)
					{
						armatureData.addAnimationData(parseAnimationData(animationXML, armatureData, frameRate));
					}
					
				}
			}
			
			return data;
		}
		
		private static function parseArmatureData(armatureXML:XML, skeletonData:SkeletonData):ArmatureData
		{
			var armatureData:ArmatureData = new ArmatureData();
			armatureData.name = armatureXML.@[ConstValues.A_NAME];
			
			var boneXMLList:XMLList = armatureXML[ConstValues.BONE];
			var i:int = boneXMLList.length();
			while(i --)
			{
				armatureData.addBoneData(parseBoneData(boneXMLList[i]));
			}
			
			armatureData.addSkinData(parseSkinData(armatureXML, skeletonData));
			
			DBDataUtils.transformArmatureData(armatureData);
			armatureData.sortBoneDataList();
			return armatureData;
		}
		
		private static function parseBoneData(boneXML:XML):BoneData
		{
			var boneData:BoneData = new BoneData();
			boneData.name = boneXML.@[ConstValues.A_NAME];
			boneData.parent = boneXML.@[ConstValues.A_PARENT];
			
			boneData.global.x = boneData.transform.x = Number(boneXML.@[ConstValues.A_X]);
			boneData.global.y = boneData.transform.y = Number(boneXML.@[ConstValues.A_Y]);
			
			boneData.global.skewX = boneData.transform.skewX = Number(boneXML.@[ConstValues.A_SKEW_X]) * ANGLE_TO_RADIAN;
			boneData.global.skewY = boneData.transform.skewY = Number(boneXML.@[ConstValues.A_SKEW_Y]) * ANGLE_TO_RADIAN;
			
			boneData.global.scaleX = boneData.transform.scaleX = Number(boneXML.@[ConstValues.A_SCALE_X]);
			boneData.global.scaleY = boneData.transform.scaleY = Number(boneXML.@[ConstValues.A_SCALE_Y]);
			
			boneData.pivot.x = -Number(boneXML.@[ConstValues.A_PIVOT_X]);
			boneData.pivot.y = -Number(boneXML.@[ConstValues.A_PIVOT_Y]);
			
			return boneData;
		}
		
		private static function parseSkinData(armatureXML:XML, skeletonData:SkeletonData):SkinData
		{
			var skinData:SkinData = new SkinData();
			//skinData.name
			var boneXMLList:XMLList = armatureXML[ConstValues.BONE];
			for each(var boneXML:XML in boneXMLList)
			{
				var slotData:SlotData = new SlotData();
				skinData.addSlotData(slotData);
				slotData.name = boneXML.@[ConstValues.A_NAME];
				slotData.parent = boneXML.@[ConstValues.A_NAME];
				slotData.zOrder = boneXML.@[ConstValues.A_Z];
				var displayXMLList:XMLList = boneXML[ConstValues.DISPLAY];
				for each(var displayXML:XML in displayXMLList)
				{
					var displayData:DisplayData = new DisplayData();
					slotData.addDisplayData(displayData);
					displayData.name = displayXML.@[ConstValues.A_NAME];
					
					if(displayXML.@[ConstValues.A_IS_ARMATURE] == "1")
					{
						displayData.type = DisplayData.ARMATURE;
					}
					else
					{
						displayData.type = DisplayData.IMAGE;
					}
					//
					displayData.transform.x = -Number(boneXML.@[ConstValues.A_PIVOT_X]);
					displayData.transform.y = -Number(boneXML.@[ConstValues.A_PIVOT_Y]);
					displayData.transform.scaleX = 1;
					displayData.transform.scaleY = 1;
					displayData.transform.skewX = 0;
					displayData.transform.skewY = 0;
					
					skeletonData.addSubTexturePivot(
						Number(displayXML.@[ConstValues.A_PIVOT_X]), 
						Number(displayXML.@[ConstValues.A_PIVOT_Y]), 
						displayData.name
					);
					
					displayData.pivot = skeletonData.getSubTexturePivot(displayData.name);
				}
			}
			
			return skinData;
		}
		
		/** @private */
		dragonBones_internal static function parseAnimationData(animationXML:XML, armatureData:ArmatureData, frameRate:uint):AnimationData
		{
			var animationData:AnimationData = new AnimationData();
			animationData.name = animationXML.@[ConstValues.A_NAME];
			animationData.frameRate = frameRate;
			animationData.loop = int(animationXML.@[ConstValues.A_LOOP]) == 1?0:1;
			animationData.fadeTime = Number(animationXML.@[ConstValues.A_DURATION_TO]) / frameRate;
			animationData.duration = Number(animationXML.@[ConstValues.A_DURATION])/ frameRate;
			var durationTween:Number = Number(animationXML.@[ConstValues.A_DURATION_TWEEN][0]);
			if(isNaN(durationTween))
			{
				animationData.scale = 1;
			}
			else
			{
				animationData.scale = durationTween / frameRate / animationData.duration;
			}
			animationData.tweenEasing = Number(animationXML.@[ConstValues.A_TWEEN_EASING][0]);
			
			parseTimeline(animationXML, animationData, parseMainFrame, frameRate);
			
			var timelineXMLList:XMLList = animationXML[ConstValues.BONE];
			var i:int = timelineXMLList.length();
			
			var timelineXML:XML;
			var timelineName:String;
			var durationScale:Number;
			var durationOffset:Number;
			var timeline:TransformTimeline;
			
			while(i --)
			{
				timelineXML = timelineXMLList[i];
				timelineName = timelineXML.@[ConstValues.A_NAME];
				durationScale = Number(timelineXML.@[ConstValues.A_MOVEMENT_SCALE]);
				durationOffset = Number(timelineXML.@[ConstValues.A_MOVEMENT_DELAY]);
				
				timeline = new TransformTimeline();
				timeline.duration = animationData.duration;
				timeline.scale = durationScale;
				timeline.offset = durationOffset;
				parseTimeline(timelineXML, timeline, parseTransformFrame, frameRate);
				animationData.addTimeline(timeline, timelineName);
			}
			
			DBDataUtils.addHideTimeline(animationData, armatureData);
			DBDataUtils.transformAnimationData(animationData, armatureData);
			
			return animationData;
		}
		
		private static function parseTimeline(timelineXML:XML, timeline:Timeline, frameParser:Function, frameRate:uint):void
		{
			var position:Number = 0;
			var frameXMLList:XMLList = timelineXML[ConstValues.FRAME];
			var frame:Frame;
			for each(var frameXML:XML in frameXMLList)
			{
				frame = frameParser(frameXML, frameRate);
				frame.position = position;
				timeline.addFrame(frame);
				position += frame.duration;
			}
		}
		
		private static function parseFrame(frameXML:XML, frame:Frame, frameRate:uint):void
		{
			frame.duration = Number(frameXML.@[ConstValues.A_DURATION]) / frameRate;
			frame.action = frameXML.@[ConstValues.A_MOVEMENT];
			frame.event = frameXML.@[ConstValues.A_EVENT];
			frame.sound = frameXML.@[ConstValues.A_SOUND];
		}
		
		private static function parseMainFrame(frameXML:XML, frameRate:uint):Frame
		{
			var frame:Frame = new Frame();
			parseFrame(frameXML, frame, frameRate);
			return frame;
		}
		
		private static function parseTransformFrame(frameXML:XML, frameRate:uint):TransformFrame
		{
			var frame:TransformFrame = new TransformFrame();
			parseFrame(frameXML, frame, frameRate);
			
			frame.visible = Boolean(frameXML.@[ConstValues.A_VISIBLE] != "0");
			frame.tweenEasing = Number(frameXML.@[ConstValues.A_TWEEN_EASING]);
			frame.tweenRotate = Number(frameXML.@[ConstValues.A_TWEEN_ROTATE]);
			frame.displayIndex = Number(frameXML.@[ConstValues.A_DISPLAY_INDEX]);
			frame.zOrder = Number(frameXML.@[ConstValues.A_Z]);
			
			frame.global.x = 
				frame.transform.x = Number(frameXML.@[ConstValues.A_X]);
			
			frame.global.y = 
				frame.transform.y =  Number(frameXML.@[ConstValues.A_Y]);
			
			frame.global.skewX = 
				frame.transform.skewX = Number(frameXML.@[ConstValues.A_SKEW_X]) * ANGLE_TO_RADIAN;
			
			frame.global.skewY = 
				frame.transform.skewY = Number(frameXML.@[ConstValues.A_SKEW_Y]) * ANGLE_TO_RADIAN;
			
			frame.global.scaleX = 
				frame.transform.scaleX = Number(frameXML.@[ConstValues.A_SCALE_X]);
			
			frame.global.scaleY = 
				frame.transform.scaleY = Number(frameXML.@[ConstValues.A_SCALE_Y]);
			
			frame.pivot.x = -Number(frameXML.@[ConstValues.A_PIVOT_X]);
			frame.pivot.y = -Number(frameXML.@[ConstValues.A_PIVOT_Y]);
			
			var colorTransformXML:XML = frameXML[ConstValues.COLOR_TRANSFORM][0];
			if(colorTransformXML)
			{
				frame.color = new ColorTransform();
				frame.color.alphaOffset = Number(colorTransformXML.@[ConstValues.A_ALPHA]);
				frame.color.redOffset = Number(colorTransformXML.@[ConstValues.A_RED]);
				frame.color.greenOffset = Number(colorTransformXML.@[ConstValues.A_GREEN]);
				frame.color.blueOffset = Number(colorTransformXML.@[ConstValues.A_BLUE]);
				
				frame.color.alphaMultiplier = Number(colorTransformXML.@[ConstValues.A_ALPHA_MULTIPLIER]) * 0.01;
				frame.color.redMultiplier = Number(colorTransformXML.@[ConstValues.A_RED_MULTIPLIER]) * 0.01;
				frame.color.greenMultiplier = Number(colorTransformXML.@[ConstValues.A_GREEN_MULTIPLIER]) * 0.01;
				frame.color.blueMultiplier = Number(colorTransformXML.@[ConstValues.A_BLUE_MULTIPLIER]) * 0.01;
			}
			
			return frame;
		}
	}
}