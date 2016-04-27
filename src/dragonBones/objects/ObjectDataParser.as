package dragonBones.objects
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.DragonBonesData;
	import dragonBones.objects.Frame;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.Timeline;
	import dragonBones.objects.TransformFrame;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.textures.TextureData;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.DBDataUtil;
	import dragonBones.utils.TransformUtil;
	
	use namespace dragonBones_internal;
	
	public final class ObjectDataParser
	{
		private static var tempDragonBonesData:DragonBonesData;
		
		public static function parseTextureAtlasData(rawData:Object, scale:Number = 1):Object
		{
			var textureAtlasData:Object = {};
			textureAtlasData.__name = rawData[ConstValues.A_NAME];
			var subTextureFrame:Rectangle;
			for each (var subTextureObject:Object in rawData[ConstValues.SUB_TEXTURE])
			{
				var subTextureName:String = subTextureObject[ConstValues.A_NAME];
				var subTextureRegion:Rectangle = new Rectangle();
				subTextureRegion.x = int(subTextureObject[ConstValues.A_X]) / scale;
				subTextureRegion.y = int(subTextureObject[ConstValues.A_Y]) / scale;
				subTextureRegion.width = int(subTextureObject[ConstValues.A_WIDTH]) / scale;
				subTextureRegion.height = int(subTextureObject[ConstValues.A_HEIGHT]) / scale;
				
				var rotated:Boolean = subTextureObject[ConstValues.A_ROTATED] == "true";
				
				var frameWidth:Number = int(subTextureObject[ConstValues.A_FRAME_WIDTH]) / scale;
				var frameHeight:Number = int(subTextureObject[ConstValues.A_FRAME_HEIGHT]) / scale;
				
				if(frameWidth > 0 && frameHeight > 0)
				{
					subTextureFrame = new Rectangle();
					subTextureFrame.x = int(subTextureObject[ConstValues.A_FRAME_X]) / scale;
					subTextureFrame.y = int(subTextureObject[ConstValues.A_FRAME_Y]) / scale;
					subTextureFrame.width = frameWidth;
					subTextureFrame.height = frameHeight;
				}
				else
				{
					subTextureFrame = null;
				}
				
				textureAtlasData[subTextureName] = new TextureData(subTextureRegion, subTextureFrame, rotated);
			}
			
			return textureAtlasData;
		}
		
		private static const _rawBones:Vector.<BoneData> = new Vector.<BoneData>();
		private static var _armatureData:ArmatureData = null;
		private static var _skinData:SkinData = null;
		private static var _skinSlotData:SlotData = null;
		private static var _meshData:MeshData = null;
		private static var _displayIndex:uint = 0;
		
		public static function parseDragonBonesData(rawDataToParse:Object):DragonBonesData
		{
			if(!rawDataToParse)
			{
				throw new ArgumentError();
			}
			
			var version:String = rawDataToParse[ConstValues.A_VERSION];
			switch (version)
			{
				case "2.3":
				case "3.0":
					return Object3DataParser.parseSkeletonData(rawDataToParse);
					break;
				case DragonBones.DATA_VERSION:
				case DragonBones.DATA_VERSION_4_5:
					break;
				
				default:
					throw new Error("Nonsupport version!");
			}
			
			var frameRate:uint = int(rawDataToParse[ConstValues.A_FRAME_RATE]);
			
			var outputDragonBonesData:DragonBonesData =  new DragonBonesData();
			outputDragonBonesData.version = Number(version);
			outputDragonBonesData.name = rawDataToParse[ConstValues.A_NAME];
			outputDragonBonesData.isGlobalData = rawDataToParse[ConstValues.A_IS_GLOBAL] == "0" ? false : true;
			tempDragonBonesData = outputDragonBonesData;
			
			for each(var armatureObject:Object in rawDataToParse[ConstValues.ARMATURE])
			{
				outputDragonBonesData.addArmatureData(parseArmatureData(armatureObject, frameRate));
			}
			
			tempDragonBonesData = null;
			
			return outputDragonBonesData;
		}
		
		private static function parseArmatureData(armatureDataToParse:Object, frameRate:uint):ArmatureData
		{
			var outputArmatureData:ArmatureData = new ArmatureData();
			outputArmatureData.name = armatureDataToParse[ConstValues.A_NAME];
			_armatureData = outputArmatureData;
			
			var actions:Array = armatureDataToParse[ConstValues.A_DEFAULT_ACTIONS];
			if (actions && actions.length == 1)
			{
				outputArmatureData.defaultAnimation = actions[0][ConstValues.A_GOTOANDPLAY];
			}
			
			outputArmatureData.frameRate = armatureDataToParse[ConstValues.A_FRAME_RATE];
			if (isNaN(outputArmatureData.frameRate) || outputArmatureData.frameRate <= 0)
			{
				outputArmatureData.frameRate = frameRate;
			}
			frameRate = outputArmatureData.frameRate;
			
			_rawBones.length = 0;
			for each (var boneObject:Object in armatureDataToParse[ConstValues.BONE])
			{
				outputArmatureData.addBoneData(parseBoneData(boneObject));
			}
			
			outputArmatureData.sortBoneDataList();
			
			for each (var ikObject:Object in armatureDataToParse[ConstValues.IK])
			{
				outputArmatureData.addIKData(parseIKData(ikObject));
			}
			
			for each(var slotObject:Object in armatureDataToParse[ConstValues.SLOT])
			{
				outputArmatureData.addSlotData(parseSlotData(slotObject));
			}
			
			for each(var skinObject:Object in armatureDataToParse[ConstValues.SKIN])
			{
				outputArmatureData.addSkinData(parseSkinData(skinObject));
			}
			
			if(tempDragonBonesData.isGlobalData)
			{
				DBDataUtil.transformArmatureData(outputArmatureData);
			}
			
			for each (var animationObject:Object in armatureDataToParse[ConstValues.ANIMATION])
			{
				var animationData:AnimationData = parseAnimationData(animationObject, frameRate);
				DBDataUtil.addHideTimeline(animationData, outputArmatureData, true);
				DBDataUtil.transformAnimationData(animationData, outputArmatureData, tempDragonBonesData.isGlobalData);
				outputArmatureData.addAnimationData(animationData);
			}
			
			return outputArmatureData;
		}
		
		//把bone的初始transform解析并返回
		private static function parseBoneData(boneObject:Object):BoneData
		{
			var boneData:BoneData = new BoneData();
			_rawBones.push(boneData);
			boneData.name = boneObject[ConstValues.A_NAME];
			boneData.parent = boneObject[ConstValues.A_PARENT];
			boneData.length = Number(boneObject[ConstValues.A_LENGTH]);
			boneData.inheritRotation = getBoolean(boneObject, ConstValues.A_INHERIT_ROTATION, true);
			boneData.inheritScale = getBoolean(boneObject, ConstValues.A_INHERIT_SCALE, true);
			
			parseTransform(boneObject[ConstValues.TRANSFORM], boneData.transform);
			if(tempDragonBonesData.isGlobalData)//绝对数据
			{
				boneData.global.copy(boneData.transform);
			}
			return boneData;
		}
		private static function parseIKData(ikObject:Object):IKData
		{
			var ikData:IKData = new IKData();
			ikData.name = ikObject[ConstValues.A_NAME];
			ikData.target = ikObject[ConstValues.A_TARGET];
			if(ikObject.hasOwnProperty(ConstValues.A_WEIGHT)){
				ikData.weight = Number(ikObject[ConstValues.A_WEIGHT]);
			}else{
				ikData.weight = 1;
			}
			ikData.bendPositive = getBoolean(ikObject, ConstValues.A_BENDPOSITIVE, true);
			if(ikObject.hasOwnProperty(ConstValues.A_CHAIN)){
				ikData.chain = ikObject[ConstValues.A_CHAIN];
			}else{
				ikData.chain = 0;
			}
			ikData.bones = ikObject[ConstValues.A_BONES];
			return ikData;
		}
		
		private static function parseSkinData(skinObject:Object):SkinData
		{
			var skinData:SkinData = new SkinData();
			skinData.name = skinObject[ConstValues.A_NAME];
			_skinData = skinData;
			
			for each(var slotObject:Object in skinObject[ConstValues.SLOT])
			{
				skinData.addSlotData(parseSlotDisplayData(slotObject));
			}
			
			return skinData;
		}
		
		private static function parseSlotDisplayData(slotObject:Object):SlotData
		{
			var slotData:SlotData = new SlotData();
			slotData.name = slotObject[ConstValues.A_NAME];
			_skinSlotData = slotData;
			_displayIndex = 0;
			for each (var displayObject:Object in slotObject[ConstValues.DISPLAY])
			{
				slotData.addDisplayData(parseDisplayData(displayObject));
				_displayIndex ++;
			}
			
			return slotData;
		}
		
		private static function parseSlotData(slotObject:Object):SlotData
		{
			var slotData:SlotData = new SlotData();
			var actions:Array = slotObject[ConstValues.A_ACTIONS];
			if (actions && actions.length == 1)
			{
				slotData.gotoAndPlay = actions[0][ConstValues.A_GOTOANDPLAY];
			}
			slotData.name = slotObject[ConstValues.A_NAME];
			slotData.parent = slotObject[ConstValues.A_PARENT];
			slotData.zOrder = getNumber(slotObject, ConstValues.A_Z_ORDER, 0) || 0;
			slotData.blendMode = slotObject[ConstValues.A_BLENDMODE];
			slotData.displayIndex = slotObject[ConstValues.A_DISPLAY_INDEX];
			//for each(var displayObject:Object in slotObject[ConstValues.DISPLAY])
			//{
				//slotData.addDisplayData(parseDisplayData(displayObject));
			//}
			
			return slotData;
		}
		
		private static function parseDisplayData(displayObject:Object):DisplayData
		{
			var displayData:DisplayData;
			
			if (displayObject[ConstValues.A_TYPE] == ConstValues.MESH)
			{
				displayData = parseMeshData(displayObject);
			}
			else
			{
				displayData = new DisplayData();
				displayData.name = displayObject[ConstValues.A_NAME];
				displayData.type = displayObject[ConstValues.A_TYPE];
				parseTransform(displayObject[ConstValues.TRANSFORM], displayData.transform, displayData.pivot);
				displayData.pivot.x = NaN;
				displayData.pivot.y = NaN;
				if(tempDragonBonesData!=null)
				{
					tempDragonBonesData.addDisplayData(displayData);
				}
			}
			return displayData;
		}
		
		private static function parseMeshData(meshObject:Object):MeshData
		{
			var meshData:MeshData = new MeshData();
			meshData.name = meshObject[ConstValues.A_NAME];
			meshData.type = meshObject[ConstValues.A_TYPE];
			parseTransform(meshObject[ConstValues.TRANSFORM], meshData.transform, meshData.pivot);
			meshData.pivot.x = NaN;
			meshData.pivot.y = NaN;
			
			const rawUVs:Array = meshObject.uvs;
			const rawTriangles:Array = meshObject.triangles;
			const rawWeights:Array = meshObject.weights;
			const rawVertices:Array = meshObject.vertices;
			const rawBonePose:Array = meshObject.bonePose;
			
			if (meshObject.slotPose)
			{
				meshData.slotPose.a = meshObject.slotPose[0];
				meshData.slotPose.b = meshObject.slotPose[1];
				meshData.slotPose.c = meshObject.slotPose[2];
				meshData.slotPose.d = meshObject.slotPose[3];
				meshData.slotPose.tx = meshObject.slotPose[4];
				meshData.slotPose.ty = meshObject.slotPose[5];
			}
			
			meshData.skinned = rawWeights && rawWeights.length;
			meshData.numVertex = rawUVs.length / 2;
			meshData.numTriangle = rawTriangles.length / 3;
			meshData.vertices.fixed = false;
			meshData.vertices.length = meshData.numVertex;
			meshData.vertices.fixed = true;
			meshData.triangles.fixed = false;
			meshData.triangles.length = meshData.numTriangle * 3;
			meshData.triangles.fixed = true;
			
			var l:uint = 0;
			var i:uint = 0;
			var iW:uint = 0;
			var boneIndex:int = 0;
			var boneMatrix:Matrix = null;
			var boneData:BoneData = null;
			var inverseBindPose:Vector.<Matrix> = new Vector.<Matrix>(_armatureData.boneDataList.length, true);
			
			_skinData.hasMesh = true;
			
			if (meshData.skinned)
			{
				meshData.vertexBones.fixed = false;
				meshData.vertexBones.length = meshData.numVertex;
				meshData.vertexBones.fixed = true;
				if (rawBonePose)
				{
					for (i = 0, l = rawBonePose.length; i < l; i += 7)
					{
						boneIndex = _armatureData.boneDataList.indexOf(_rawBones[rawBonePose[i]]);
						boneMatrix = new Matrix();
						boneMatrix.a = rawBonePose[i + 1];
						boneMatrix.b = rawBonePose[i + 2];
						boneMatrix.c = rawBonePose[i + 3];
						boneMatrix.d = rawBonePose[i + 4];
						boneMatrix.tx = rawBonePose[i + 5];
						boneMatrix.ty = rawBonePose[i + 6];
						boneMatrix.invert();
						inverseBindPose[boneIndex] = boneMatrix;
					}
				}
			}
			
			for (i = 0, l = rawUVs.length; i < l; i += 2)
			{
				const iN:uint = i + 1;
				const vertexIndex:uint = i * 0.5;
				const vertexData:VertexData = meshData.vertices[vertexIndex] = new VertexData();
				vertexData.u = rawUVs[i];
				vertexData.v = rawUVs[iN];
				vertexData.x = rawVertices[i];
				vertexData.y = rawVertices[iN];
				if (meshData.skinned)
				{
					const vertexBoneData:VertexBoneData = meshData.vertexBones[vertexIndex] = new VertexBoneData();
					vertexData.copyFrom(meshData.slotPose.transformPoint(vertexData));
					
					for (var j:uint = iW + 1, lJ:uint = iW + 1 + rawWeights[iW] * 2; j < lJ; j += 2)
					{
						boneData = _rawBones[rawWeights[j]];
						boneIndex = meshData.bones.indexOf(boneData);
						if (boneIndex < 0)
						{
							boneIndex = meshData.bones.length;
							meshData.bones[boneIndex] = boneData;
						}
						
						const vertexBonePoint:Point = new Point(vertexData.x, vertexData.y);
						vertexBoneData.indices.push(boneIndex);
						vertexBoneData.weights.push(rawWeights[j + 1]);
						vertexBoneData.vertices.push(vertexBonePoint);
						
						if (meshData.inverseBindPose.length <= boneIndex)
						{
							meshData.inverseBindPose.length = boneIndex + 1;
						}
						
						boneMatrix = meshData.inverseBindPose[boneIndex];
						if (!boneMatrix)
						{
							boneMatrix = inverseBindPose[_armatureData.boneDataList.indexOf(boneData)];
							meshData.inverseBindPose[boneIndex] = boneMatrix;
						}

						if (boneMatrix)
						{
							vertexBonePoint.copyFrom(boneMatrix.transformPoint(vertexBonePoint));
						}
						
						iW = j + 2;
					}
				}
			}
			
			meshData.bones.fixed = true;
			meshData.inverseBindPose.fixed = true;
			
			for (i = 0, l = rawTriangles.length; i < l; ++i)
			{
				meshData.triangles[i] = rawTriangles[i];
			}
			
			return meshData;
			
		}
		/** @private */
		dragonBones_internal static function parseAnimationData(animationObject:Object, frameRate:uint):AnimationData
		{
			var animationData:AnimationData = new AnimationData();
			animationData.name = animationObject[ConstValues.A_NAME];
			animationData.frameRate = frameRate;
			animationData.duration = Math.ceil((Number(animationObject[ConstValues.A_DURATION]) || 1) * 1000 / frameRate);
			animationData.playTimes = int(getNumber(animationObject, ConstValues.A_PLAY_TIMES, 1));
			animationData.fadeTime = getNumber(animationObject, ConstValues.A_FADE_IN_TIME, 0) || 0;
			animationData.scale = getNumber(animationObject, ConstValues.A_SCALE, 1) || 0;
			//use frame tweenEase, NaN
			//overwrite frame tweenEase, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
			animationData.tweenEasing = getNumber(animationObject, ConstValues.A_TWEEN_EASING, NaN);
			animationData.autoTween = getBoolean(animationObject, ConstValues.A_AUTO_TWEEN, true);
			
			for each(var frameObject:Object in animationObject[ConstValues.FRAME])
			{
				var frame:Frame = parseTransformFrame(frameObject, frameRate);
				animationData.addFrame(frame);
			}
			
			parseTimeline(animationObject, animationData);
			
			var lastFrameDuration:int = animationData.duration;
			for each(var timelineObject:Object in animationObject[ConstValues.BONE])
			{
				var timeline:TransformTimeline = parseTransformTimeline(timelineObject, animationData.duration, frameRate);
				if (timeline.frameList.length > 0)
				{
					lastFrameDuration = Math.min(lastFrameDuration, timeline.frameList[timeline.frameList.length - 1].duration);
					animationData.addTimeline(timeline);
				}
				
			}
			
			for each(var slotTimelineObject:Object in animationObject[ConstValues.SLOT])
			{
				var slotTimeline:SlotTimeline = parseSlotTimeline(slotTimelineObject, animationData.duration, frameRate);
				if (slotTimeline.frameList.length > 0)
				{
					lastFrameDuration = Math.min(lastFrameDuration, slotTimeline.frameList[slotTimeline.frameList.length - 1].duration);
					animationData.addSlotTimeline(slotTimeline);
				}
			}
			
			for each( var ffdTimelineObject:Object in animationObject[ConstValues.FFD])
			{
				var ffdTimeline:FFDTimeline = parseFFDTimeline(ffdTimelineObject, animationData.duration, frameRate);
				animationData.addFFDTimeline(ffdTimeline);
			}
			
			if(animationData.frameList.length > 0)
			{
				lastFrameDuration = Math.min(lastFrameDuration, animationData.frameList[animationData.frameList.length - 1].duration);
			}
			//取得timeline中最小的lastFrameDuration并保存
			animationData.lastFrameDuration = lastFrameDuration;
			
			return animationData;
		}
		
		private static function parseTransformTimeline(timelineObject:Object, duration:int, frameRate:uint):TransformTimeline
		{
			var outputTimeline:TransformTimeline = new TransformTimeline();
			outputTimeline.name = timelineObject[ConstValues.A_NAME];
			outputTimeline.scale = getNumber(timelineObject, ConstValues.A_SCALE, 1) || 0;
			outputTimeline.offset = getNumber(timelineObject, ConstValues.A_OFFSET, 0) || 0;
			outputTimeline.originPivot.x = getNumber(timelineObject, ConstValues.A_PIVOT_X, 0) || 0;
			outputTimeline.originPivot.y = getNumber(timelineObject, ConstValues.A_PIVOT_Y, 0) || 0;
			outputTimeline.duration = duration;
			
			for each(var frameObject:Object in timelineObject[ConstValues.FRAME])
			{
				var frame:TransformFrame = parseTransformFrame(frameObject, frameRate);
				outputTimeline.addFrame(frame);
			}
			
			parseTimeline(timelineObject, outputTimeline);
			
			return outputTimeline;
		}
		
		private static function parseSlotTimeline(timelineObject:Object, duration:int, frameRate:uint):SlotTimeline
		{
			var timeline:SlotTimeline = new SlotTimeline();
			timeline.name = timelineObject[ConstValues.A_NAME];
			timeline.scale = getNumber(timelineObject, ConstValues.A_SCALE, 1) || 0;
			timeline.offset = getNumber(timelineObject, ConstValues.A_OFFSET, 0) || 0;
			//timeline.originPivot.x = getNumber(timelineXML, ConstValues.A_PIVOT_X, 0) || 0;
			//timeline.originPivot.y = getNumber(timelineXML, ConstValues.A_PIVOT_Y, 0) || 0;
			timeline.duration = duration;
			
			for each(var frameObject:Object in timelineObject[ConstValues.FRAME])
			{
				var frame:SlotFrame = parseSlotFrame(frameObject, frameRate);
				timeline.addFrame(frame);
			}
			
			parseTimeline(timelineObject, timeline);
			
			return timeline;
		}
		
		private static function parseFFDTimeline(timelineObject:Object, duration:int, frameRate:uint):FFDTimeline
		{
			var timeline:FFDTimeline = new FFDTimeline();
			
			timeline.skin = timelineObject[ConstValues.SKIN];
			timeline.name = timelineObject[ConstValues.SLOT]; // timelineObject[ConstValues.A_NAME];
			
			var skinData:SkinData = _armatureData.getSkinData(timeline.skin);
			var slotData:SlotData = skinData.getSlotData(timeline.name);
			var meshData:MeshData = slotData.getDisplayData(timelineObject[ConstValues.A_NAME]) as MeshData;
			timeline.displayIndex = slotData.displayDataList.indexOf(meshData); // timelineObject[ConstValues.A_DISPLAY_INDEX];
			
			timeline.scale = getNumber(timelineObject, ConstValues.A_SCALE, 1) || 0;
			timeline.offset = getNumber(timelineObject, ConstValues.A_OFFSET, 0) || 0;
			timeline.duration = duration;
			
			var helpPoint:Point = new Point();
			for each (var frameObject:Object in timelineObject[ConstValues.FRAME])
			{
				var frame:FFDFrame = parseFFDFrame(frameObject, frameRate);
				if (meshData.skinned)
				{
					var vertices:Vector.<Number> = new Vector.<Number>();
					for (var i:uint = 0, l:uint = frame.vertices.length; i < l; i += 2)
					{
						const vertexBoneData:VertexBoneData = meshData.vertexBones[i / 2];
						helpPoint.x = frame.vertices[i];
						helpPoint.y = frame.vertices[i + 1];
						var result:Point = meshData.slotPose.deltaTransformPoint(helpPoint);
						for each (var boneIndex:uint in vertexBoneData.indices)
						{
							helpPoint = meshData.inverseBindPose[boneIndex].deltaTransformPoint(result);
							vertices.push(helpPoint.x, helpPoint.y);
						}
					}
					
					vertices.fixed = true;
					frame.vertices = vertices;
				}
				
				timeline.addFrame(frame);
			}
			
			parseTimeline(timelineObject, timeline);
			
			return timeline;
		}
		
		private static function parseMainFrame(frameObject:Object, frameRate:uint):Frame
		{
			var frame:Frame = new Frame();
			parseFrame(frameObject, frame, frameRate);
			return frame;
		}
		
		private static function parseTransformFrame(frameObject:Object, frameRate:uint):TransformFrame
		{
			var outputFrame:TransformFrame = new TransformFrame();
			parseFrame(frameObject, outputFrame, frameRate);
			
			outputFrame.visible = !getBoolean(frameObject, ConstValues.A_HIDE, false);
			
			//NaN:no tween, 10:auto tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
			outputFrame.tweenEasing = getNumber(frameObject, ConstValues.A_TWEEN_EASING, 10);
			outputFrame.tweenRotate = int(getNumber(frameObject, ConstValues.A_TWEEN_ROTATE, 0));
			outputFrame.tweenScale = getBoolean(frameObject, ConstValues.A_TWEEN_SCALE, true);
//			outputFrame.displayIndex = int(getNumber(frameObject, ConstValues.A_DISPLAY_INDEX, 0));
			
			parseTransform(frameObject[ConstValues.TRANSFORM], outputFrame.transform, outputFrame.pivot);
			if(tempDragonBonesData.isGlobalData)//绝对数据
			{
				outputFrame.global.copy(outputFrame.transform);
			}
			
			outputFrame.scaleOffset.x = getNumber(frameObject, ConstValues.A_SCALE_X_OFFSET, 0) || 0;
			outputFrame.scaleOffset.y = getNumber(frameObject, ConstValues.A_SCALE_Y_OFFSET, 0) || 0;
			return outputFrame;
		}
		
		private static function parseSlotFrame(frameObject:Object, frameRate:uint):SlotFrame
		{
			var frame:SlotFrame = new SlotFrame();
			parseFrame(frameObject, frame, frameRate);
			
			frame.visible = !getBoolean(frameObject, ConstValues.A_HIDE, false);
			
			//NaN:no tween, 10:auto tween, [-1, 0):ease in, 0:line easing, (0, 1]:ease out, (1, 2]:ease in out
			frame.tweenEasing = getNumber(frameObject, ConstValues.A_TWEEN_EASING, 10);
			frame.displayIndex = int(getNumber(frameObject, ConstValues.A_DISPLAY_INDEX, 0));
			
			var actions:Array = frameObject[ConstValues.A_ACTIONS];
			if (actions && actions.length == 1)
			{
				frame.gotoAndPlay = actions[0][ConstValues.A_GOTOANDPLAY];
			}
			
			//如果为NaN，则说明没有改变过zOrder
			frame.zOrder = getNumber(frameObject, ConstValues.A_Z_ORDER, tempDragonBonesData.isGlobalData ? NaN:0);
			
			var colorTransformObject:Object = frameObject[ConstValues.COLOR];
			if(colorTransformObject)
			{
				frame.color = new ColorTransform();
				parseColorTransform(colorTransformObject, frame.color);
			}
			
			return frame;
		}
		
		private static function parseFFDFrame(frameObject:Object, frameRate:uint):FFDFrame
		{
			var frame:FFDFrame = new FFDFrame();
			parseFrame(frameObject, frame, frameRate);
			
			frame.tweenEasing = getNumber(frameObject, ConstValues.A_TWEEN_EASING, 10);
			frame.offset = frameObject[ConstValues.A_OFFSET] || 0;
			
			var arr:Array = frameObject[ConstValues.A_VERTICES];
			var vertices:Vector.<Number> = new Vector.<Number>();
			if (arr)
			{
				for (var i:int = 0, len:int = arr.length; i < len; i++)
				{
					vertices.push(arr[i]);
				}
			}
			frame.vertices = vertices;
			
			return frame;
		}
		
		private static function parseTimeline(timelineObject:Object, outputTimeline:Timeline):void
		{
			var position:int = 0;
			var frame:Frame;
			for each(frame in outputTimeline.frameList)
			{
				frame.position = position;
				position += frame.duration;
			}
			//防止duration计算有误差
			if(frame)
			{
				frame.duration = outputTimeline.duration - frame.position;
			}
		}
		
		private static function parseFrame(frameObject:Object, outputFrame:Frame, frameRate:uint):void
		{
			outputFrame.duration = Math.round((Number(frameObject[ConstValues.A_DURATION])) * 1000 / frameRate);
			outputFrame.action = frameObject[ConstValues.A_ACTION];
			outputFrame.event = frameObject[ConstValues.A_EVENT];
			outputFrame.sound = frameObject[ConstValues.A_SOUND];
			if (frameObject[ConstValues.A_CURVE] != null && frameObject[ConstValues.A_CURVE].length == 4)
			{
				outputFrame.curve = new CurveData();
				outputFrame.curve.pointList = [new Point(frameObject[ConstValues.A_CURVE][0], frameObject[ConstValues.A_CURVE][1]), new Point(frameObject[ConstValues.A_CURVE][2], frameObject[ConstValues.A_CURVE][3])];
			}
		}
		
		private static function parseTransform(transformObject:Object, transform:DBTransform, pivot:Point = null):void
		{
			if(transformObject)
			{
				if(transform)
				{
					transform.x = getNumber(transformObject,ConstValues.A_X,0) || 0;
					transform.y = getNumber(transformObject,ConstValues.A_Y,0) || 0;
					transform.skewX = getNumber(transformObject,ConstValues.A_SKEW_X,0) * ConstValues.ANGLE_TO_RADIAN || 0;
					transform.skewY = getNumber(transformObject,ConstValues.A_SKEW_Y,0) * ConstValues.ANGLE_TO_RADIAN || 0;
					transform.scaleX = getNumber(transformObject, ConstValues.A_SCALE_X, 1) || 0;
					transform.scaleY = getNumber(transformObject, ConstValues.A_SCALE_Y, 1) || 0;
				}
				if(pivot)
				{
					pivot.x = getNumber(transformObject,ConstValues.A_PIVOT_X,0) || 0;
					pivot.y = getNumber(transformObject,ConstValues.A_PIVOT_Y,0) || 0;
				}
			}
		}
		
		private static function parseColorTransform(colorTransformObject:Object, colorTransform:ColorTransform):void
		{
			if(colorTransformObject)
			{
				if(colorTransform)
				{
					colorTransform.alphaOffset = int(colorTransformObject[ConstValues.A_ALPHA_OFFSET]);
					colorTransform.redOffset = int(colorTransformObject[ConstValues.A_RED_OFFSET]);
					colorTransform.greenOffset = int(colorTransformObject[ConstValues.A_GREEN_OFFSET]);
					colorTransform.blueOffset = int(colorTransformObject[ConstValues.A_BLUE_OFFSET]);
					
					colorTransform.alphaMultiplier = int(getNumber(colorTransformObject, ConstValues.A_ALPHA_MULTIPLIER,100)) * 0.01;
					colorTransform.redMultiplier = int(getNumber(colorTransformObject,ConstValues.A_RED_MULTIPLIER,100)) * 0.01;
					colorTransform.greenMultiplier = int(getNumber(colorTransformObject,ConstValues.A_GREEN_MULTIPLIER,100)) * 0.01;
					colorTransform.blueMultiplier = int(getNumber(colorTransformObject,ConstValues.A_BLUE_MULTIPLIER,100)) * 0.01;
				}
			}
		}
		
		private static function getBoolean(data:Object, key:String, defaultValue:Boolean):Boolean
		{
			if(data && key in data)
			{
				switch(String(data[key]))
				{
					case "0":
					case "NaN":
					case "":
					case "false":
					case "null":
					case "undefined":
						return false;
						
					case "1":
					case "true":
					default:
						return true;
				}
			}
			return defaultValue;
		}
		
		private static function getNumber(data:Object, key:String, defaultValue:Number):Number
		{
			if(data && key in data)
			{
				switch(String(data[key]))
				{
					case "NaN":
					case "":
					case "false":
					case "null":
					case "undefined":
						return NaN;
						
					default:
						return Number(data[key]);
				}
			}
			return defaultValue;
		}
	}
}