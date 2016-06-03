package dragonBones.parsers
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.geom.Transform;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.AnimationFrameData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.BoneFrameData;
	import dragonBones.objects.BoneTimelineData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.DragonBonesData;
	import dragonBones.objects.EventData;
	import dragonBones.objects.ExtensionFrameData;
	import dragonBones.objects.FFDTimelineData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.objects.SlotFrameData;
	import dragonBones.objects.SlotTimelineData;
	import dragonBones.objects.TimelineData;
	import dragonBones.objects.TweenFrameData;
	import dragonBones.textures.TextureAtlasData;
	import dragonBones.textures.TextureData;
	
	/**
	 * 
	 */
	public class ObjectDataParser extends DataParser
	{
		/**
		 * @private
		 */
		[inline]
		protected static function _getBoolean(rawData:Object, key:String, defaultValue:Boolean):Boolean
		{
			if (key in rawData)
			{
				const value:* = rawData[key];
				if (value is Boolean || value is Number)
				{
					return value;
				}
				else if (value is String)
				{
					switch(value)
					{
						case "0":
						case "NaN":
						case "":
						case "false":
						case "null":
						case "undefined":
							return false;
							
						default:
							return true;
					}
				}
				else 
				{
					return value;
				}
			}
			
			return defaultValue;
		}
		
		/**
		 * @private
		 */
		[inline]
		protected static function _getNumber(rawData:Object, key:String, defaultValue:Number):Number
		{
			if (key in rawData)
			{
				const value:* = rawData[key];
				return value == null? defaultValue: value;
			}
			
			return defaultValue;
		}
		
		/**
		 * @private
		 */
		[inline]
		protected static function _getString(rawData:Object, key:String, defaultValue:String):String
		{
			if (key in rawData)
			{
				return rawData[key];
			}
			
			return defaultValue;
		}
		
		/**
		 * @private
		 */
		[inline]
		protected static function _getParameter(rawData:Array, index:uint, defaultValue:*):*
		{
			if (rawData.length > index)
			{
				return rawData[index];
			}
			
			return defaultValue;
		}
		
		/**
		 * @private
		 */
		public function ObjectDataParser()
		{
			super(this);
		}
		
		/**
		 * 
		 */
		override public function parseTextureAtlasData(rawData:*, textureAtlasData:TextureAtlasData, scale:Number = 0, rawScale:Number = 0):TextureAtlasData
		{
			if (!rawData)
			{
				throw new ArgumentError();
			}
			
			if (rawData is String)
			{
				rawData = JSON.parse(rawData);
			}
			
			textureAtlasData.name = _getString(rawData, NAME, null);
			textureAtlasData.imagePath = _getString(rawData, IMAGE_PATH, null);
			if (scale > 0)
			{
				textureAtlasData.scale = scale;
			}
			else
			{
				scale = textureAtlasData.scale = _getNumber(rawData, SCALE, textureAtlasData.scale);
			}
			
			scale = 1 / scale;
			
			if (rawScale > 0)
			{
				textureAtlasData.modifyScale = scale * rawScale;
				scale *= textureAtlasData.modifyScale;
			}
			else
			{
				textureAtlasData.modifyScale = 1;
			}
			
			if (SUB_TEXTURE in rawData)
			{
				for each (var textureObject:Object in rawData[SUB_TEXTURE])
				{
					const textureData:TextureData = textureAtlasData.generateTexture();
					textureData.name = _getString(textureObject, NAME, null);
					textureData.rotated = _getBoolean(textureObject, ROTATED, false);
					textureData.region.x = _getNumber(textureObject, X, 0) * scale ;
					textureData.region.y = _getNumber(textureObject, Y, 0) * scale;
					textureData.region.width = _getNumber(textureObject, WIDTH, 0) * scale;
					textureData.region.height = _getNumber(textureObject, HEIGHT, 0) * scale;
					
					const frameWidth:Number = _getNumber(textureObject, FRAME_WIDTH, -1);
					const frameHeight:Number = _getNumber(textureObject, FRAME_HEIGHT, -1);
					if (frameWidth > 0 && frameHeight > 0)
					{
						textureData.frame = TextureData.generateRectangle();
						textureData.frame.x = _getNumber(textureObject, FRAME_X, 0) * scale;
						textureData.frame.y = _getNumber(textureObject, FRAME_Y, 0) * scale;
						textureData.frame.width = frameWidth * scale;
						textureData.frame.height = frameHeight * scale;
					}
					
					textureAtlasData.addTexture(textureData);
				}
			}
			
			return textureAtlasData;
		}
		
		/**
		 * 
		 */
		override public function parseDragonBonesData(rawData:*):DragonBonesData
		{
			if (!rawData)
			{
				throw new ArgumentError();
			}
			
			if (rawData is String)
			{
				rawData = JSON.parse(rawData);
			}
			
			const version:String = _getString(rawData, VERSION, null);
			
			/*
			switch (version)
			{
				case "2.3":
				//Update2_3To3_0.format(rawData);
				break;
				
				case DragonBones.DATA_VERSION:
				break;
				
				default:
				throw new Error("Nonsupport version!");
			}
			*/
			
			const data:DragonBonesData = BaseObject.borrowObject(DragonBonesData) as DragonBonesData;
			data.name = _getString(rawData, NAME, null);
			data.frameRate = _getNumber(rawData, FRAME_RATE, 24);
			
			if (ARMATURE in rawData)
			{
				this._data = data;
				
				for each (var armatureObject:Object in rawData[ARMATURE])
				{
					data.addArmature(_parseArmature(armatureObject));
				}
				
				this._data = null;
			}
			
			return data;
		}
		
		/**
		 * @private
		 */
		protected function _parseArmature(rawData:Object):ArmatureData
		{
			const armature:ArmatureData = BaseObject.borrowObject(ArmatureData) as ArmatureData;
			armature.name = _getString(rawData, NAME, null);
			armature.frameRate = _getNumber(rawData, FRAME_RATE, this._data.frameRate);
			
			this._armature = armature;
			this._rawBones.length = 0;
			
			if (BONE in rawData)
			{
				for each (var boneObject:Object in rawData[BONE])
				{
					const bone:BoneData = _parseBone(boneObject);
					armature.addBone(bone, _getString(boneObject, PARENT, null));
					this._rawBones.push(bone);
				}
			}
			
			if (IK in rawData)
			{
				for each (var ikObject:Object in rawData[IK])
				{
					_parseIK(ikObject);
				}
			}
			
			if (SLOT in rawData)
			{
				for each (var slotObject:Object in rawData[SLOT])
				{
					armature.addSlot(_parseSlot(slotObject));
				}
			}
			
			if (SKIN in rawData)
			{
				for each (var skinObject:Object in rawData[SKIN])
				{
					armature.addSkin(_parseSkin(skinObject));
				}
			}
			
			if (ANIMATION in rawData)
			{
				for each (var animationObject:Object in rawData[ANIMATION])
				{
					armature.addAnimation(_parseAnimation(animationObject));
				}
			}
			
			this._armature = null;
			this._rawBones.length = 0;
			
			return armature;
		}
		
		/**
		 * @private
		 */
		protected function _parseBone(rawData:Object):BoneData
		{
			const bone:BoneData = BaseObject.borrowObject(BoneData) as BoneData;
			bone.name = _getString(rawData, NAME, null);
			bone.inheritTranslation = _getBoolean(rawData, INHERIT_TRANSLATION, true);
			bone.inheritRotation = _getBoolean(rawData, INHERIT_ROTATION, true);
			bone.inheritScale = _getBoolean(rawData, INHERIT_SCALE, true);
			bone.length = _getNumber(rawData, LENGTH, 0);
			
			if (TRANSFORM in rawData)
			{
				_parseTransform(rawData[TRANSFORM], bone.transform);
			}
			
			return bone;
		}
		
		/**
		 * @private
		 */
		protected function _parseIK(rawData:Object):void
		{
			const bone:BoneData = this._armature.getBone(_getString(rawData, (BONE in rawData)? BONE: NAME, null));
			if (bone)
			{
				bone.ik = this._armature.getBone(_getString(rawData, TARGET, null));
				bone.bendPositive = _getBoolean(rawData, BEND_POSITIVE, true);
				bone.chain = _getNumber(rawData, CHAIN, 0);
				bone.weight = _getNumber(rawData, WEIGHT, 1);
			}
		}
		
		/**
		 * @private
		 */
		protected function _parseSlot(rawData:Object):SlotData
		{
			const slot:SlotData = BaseObject.borrowObject(SlotData) as SlotData;
			slot.name = _getString(rawData, NAME, null);
			slot.parent = this._armature.getBone(_getString(rawData, PARENT, null));
			slot.displayIndex = _getNumber(rawData, DISPLAY_INDEX, 0);
			slot.zOrder = _getNumber(rawData, Z_ORDER, this._armature.sortedSlots.length); // 如果未标识 zOrder 则使用队列顺序
			
			if (COLOR in rawData)
			{
				slot.color = SlotData.generateColor();
				_parseColorTransform(rawData[COLOR], slot.color);
			}
			else
			{
				slot.color = SlotData.DEFAULT_COLOR;
			}
			
			if (BLEND_MODE in rawData && rawData[BLEND_MODE] is String)
			{
				
				slot.blendMode = _getBlendMode(rawData[BLEND_MODE]);
			}
			else
			{
				slot.blendMode = _getNumber(rawData, BLEND_MODE, DragonBones.BLEND_MODE_NORMAL);
			}
			
			return slot;
		}
		
		/**
		 * @private
		 */
		protected function _parseSkin(rawData:Object):SkinData
		{
			const skin:SkinData = BaseObject.borrowObject(SkinData) as SkinData;
			skin.name = _getString(rawData, NAME, "__default") || "__default";
			
			if (SLOT in rawData)
			{
				this._skin = skin;
				
				for each (var slotObject:Object in rawData[SLOT])
				{
					skin.addSlot(_parseSlotDisplaySet(slotObject));
				}
				
				this._skin = null;
			}
			
			return skin;
		}
		
		/**
		 * @private
		 */
		protected function _parseSlotDisplaySet(rawData:Object):SlotDisplayDataSet
		{
			const slotDisplayDataSet:SlotDisplayDataSet = BaseObject.borrowObject(SlotDisplayDataSet) as SlotDisplayDataSet;
			slotDisplayDataSet.slot = this._armature.getSlot(_getString(rawData, NAME, null));
			
			if (DISPLAY in rawData)
			{
				const displayObjectSet:Array = rawData[DISPLAY];
				const displayDataSet:Vector.<DisplayData> = slotDisplayDataSet.displays;
				displayDataSet.fixed = false;
				displayDataSet.length = displayObjectSet.length;
				displayDataSet.fixed = true;
				
				this._slotDisplayDataSet = slotDisplayDataSet;
				
				var displayIndex:uint = 0;
				for each (var displayObject:Object in displayObjectSet)
				{
					displayDataSet[displayIndex++] = _parseDisplay(displayObject);
				}
				
				this._slotDisplayDataSet = null;
			}
			
			return slotDisplayDataSet;
		}
		
		/**
		 * @private
		 */
		protected function _parseDisplay(rawData:Object):DisplayData
		{
			const display:DisplayData = BaseObject.borrowObject(DisplayData) as DisplayData;
			display.name = _getString(rawData, NAME, null);
			
			if (TYPE in rawData && rawData[TYPE] is String)
			{
				
				display.type = _getDisplayType(rawData[TYPE]);
			}
			else
			{
				display.type = _getNumber(rawData, TYPE, DragonBones.DISPLAY_TYPE_IMAGE);
			}
			
			const transformObject:Object = rawData[TRANSFORM];
			
			display.isRelativePivot = true;
			if (PIVOT in rawData)
			{
				const pivotObject:Object = rawData[PIVOT];
				display.pivot.x = _getNumber(pivotObject, X, 0);
				display.pivot.y = _getNumber(pivotObject, Y, 0);
			}
			else
			{
				if (transformObject && ((PIVOT_X in transformObject) || (PIVOT_Y in transformObject)))
				{
					display.isRelativePivot = false;
					display.pivot.x = _getNumber(transformObject, PIVOT_X, 0);
					display.pivot.y = _getNumber(transformObject, PIVOT_Y, 0);
				}
				
				if (display.isRelativePivot)
				{
					display.pivot.x = 0.5;
					display.pivot.y = 0.5;
				}
			}
			
			if (transformObject)
			{
				_parseTransform(transformObject, display.transform);
			}
			
			switch (display.type)
			{
				case DragonBones.DISPLAY_TYPE_IMAGE:
					break;
				
				case DragonBones.DISPLAY_TYPE_ARMATURE:
					break;
				
				case DragonBones.DISPLAY_TYPE_MESH:
					trace(display.name);
					display.meshData = _parseMesh(rawData);
					break;
				
				default:
					throw new Error("Unknown display type");
					break;
			}
			
			return display;
		}
		
		/**
		 * @private
		 */
		protected function _parseMesh(rawData:Object):MeshData
		{
			const mesh:MeshData = BaseObject.borrowObject(MeshData) as MeshData;
			
			const rawVertices:Array = rawData[VERTICES];
			const rawUVs:Array = rawData[UVS];
			const rawTriangles:Array = rawData[TRIANGLES];
			const rawWeights:Array = rawData[WEIGHTS];
			
			const numVertices:uint = uint(rawVertices.length / 2);
			const numTriangles:uint = uint(rawTriangles.length / 3);
			
			const inverseBindPose:Vector.<Matrix> = new Vector.<Matrix>(this._armature.sortedBones.length, true);
			
			mesh.skinned = rawWeights && rawWeights.length;
			mesh.uvs.fixed = false;
			mesh.uvs.length = numVertices * 2;
			mesh.uvs.fixed = true;
			mesh.vertices.fixed = false;
			mesh.vertices.length = numVertices * 2;
			mesh.vertices.fixed = true;
			mesh.vertexIndices.fixed = false;
			mesh.vertexIndices.length = numTriangles * 3;
			mesh.vertexIndices.fixed = true;
			
			var l:uint = 0;
			var i:uint = 0;
			
			if (mesh.skinned)
			{
				mesh.boneIndices.fixed = false;
				mesh.boneIndices.length = numVertices;
				mesh.boneIndices.fixed = true;
				mesh.weights.fixed = false;
				mesh.weights.length = numVertices;
				mesh.weights.fixed = true;
				mesh.boneVertices.fixed = false;
				mesh.boneVertices.length = numVertices;
				mesh.boneVertices.fixed = true;
				
				if (SLOT_POSE in rawData)
				{
					const rawSlotPose:Array = rawData[SLOT_POSE];
					mesh.slotPose = new Matrix();
					mesh.slotPose.a = rawSlotPose[0];
					mesh.slotPose.b = rawSlotPose[1];
					mesh.slotPose.c = rawSlotPose[2];
					mesh.slotPose.d = rawSlotPose[3];
					mesh.slotPose.tx = rawSlotPose[4];
					mesh.slotPose.ty = rawSlotPose[5];
				}
				
				if (BONE_POSE in rawData)
				{
					const rawBonePose:Array = rawData[BONE_POSE];
					for (i = 0, l = rawBonePose.length; i < l; i += 7)
					{
						//const rawBoneIndex:uint = rawBonePose[i];
						const boneMatrix:Matrix = inverseBindPose[rawBonePose[i]] = new Matrix();
						boneMatrix.a = rawBonePose[i + 1];
						boneMatrix.b = rawBonePose[i + 2];
						boneMatrix.c = rawBonePose[i + 3];
						boneMatrix.d = rawBonePose[i + 4];
						boneMatrix.tx = rawBonePose[i + 5];
						boneMatrix.ty = rawBonePose[i + 6];
						boneMatrix.invert();
					}
				}
			}
			
			var iW:uint = 0;
			
			for (i = 0, l = rawVertices.length; i < l; i += 2)
			{
				const iN:uint = i + 1;
				const vertexIndex:uint = uint(i / 2);
				
				var x:Number = mesh.vertices[i] = rawVertices[i];
				var y:Number = mesh.vertices[iN] = rawVertices[iN];
				mesh.uvs[i] = rawUVs[i];
				mesh.uvs[iN] = rawUVs[iN];
				
				if (mesh.skinned)
				{
					const numBones:uint = rawWeights[iW];
					const indices:Vector.<uint> = mesh.boneIndices[vertexIndex] = new Vector.<uint>(numBones, true);
					const weights:Vector.<Number> = mesh.weights[vertexIndex] = new Vector.<Number>(numBones, true);
					const boneVertices:Vector.<Number> = mesh.boneVertices[vertexIndex] = new Vector.<Number>(numBones * 2, true);
					
					Transform.transformPoint(mesh.slotPose, x, y, _helpPoint);
					x = mesh.vertices[i] = _helpPoint.x;
					y = mesh.vertices[iN] = _helpPoint.y;
					
					for (var iB:uint = 0; iB < numBones; ++iB)
					{
						const iI:uint = iW + 1 + iB * 2;
						const rawBoneIndex:uint = rawWeights[iI];
						const boneData:BoneData = _rawBones[rawBoneIndex];
						
						var boneIndex:int = mesh.bones.indexOf(boneData);
						if (boneIndex < 0)
						{
							boneIndex = mesh.bones.length;
							mesh.bones[boneIndex] = boneData;
							mesh.inverseBindPose[boneIndex] = inverseBindPose[rawBoneIndex];
						}
						
						Transform.transformPoint(mesh.inverseBindPose[boneIndex], x, y, _helpPoint);
						
						indices[iB] = boneIndex;
						weights[iB] = rawWeights[iI + 1];
						boneVertices[iB * 2] = _helpPoint.x;
						boneVertices[iB * 2 + 1] = _helpPoint.y;
					}
					
					iW += numBones * 2 + 1;
					
					indices.fixed = true;
					weights.fixed = true;
					boneVertices.fixed = true;
				}
			}
			
			mesh.bones.fixed = true;
			mesh.inverseBindPose.fixed = true;
			
			for (i = 0, l = rawTriangles.length; i < l; ++i)
			{
				mesh.vertexIndices[i] = rawTriangles[i];
			}
			
			return mesh;
		}
		
		/**
		 * @private
		 */
		protected function _parseAnimation(rawData:Object):AnimationData
		{
			const animation:AnimationData = BaseObject.borrowObject(AnimationData) as AnimationData;
			animation.name = _getString(rawData, NAME, "__default") || "__default";
			animation.frameCount = _getNumber(rawData, DURATION, 1);
			animation.position = _getNumber(rawData, POSITION, 0) * 1000000 / this._armature.frameRate; // floor
			animation.duration = animation.frameCount * 1000000 / this._armature.frameRate; // floor
			animation.playTimes = _getNumber(rawData, PLAY_TIMES, 1);
			animation.fadeInTime = _getNumber(rawData, FADE_IN_TIME, 0);
			
			this._animation = animation;
			
			const animationName:String = _getString(rawData, ANIMATION, null);
			if (animationName)
			{
				animation.animation = this._armature.getAnimation(animationName);
				if (!animation.animation)
				{
					//
				}
				
				return animation;
			}
			
			_parseTimeline(rawData, animation, _parseAnimationFrame);
			
			if (BONE in rawData)
			{
				for each (var boneTimelineObject:Object in rawData[BONE])
				{
					animation.addBoneTimeline(_parseBoneTimeline(boneTimelineObject));
				}
			}
			
			if (SLOT in rawData)
			{
				for each (var slotTimelineObject:Object in rawData[SLOT])
				{
					animation.addSlotTimeline(_parseSlotTimeline(slotTimelineObject));
				}
				
			}
			
			if (FFD in rawData)
			{
				for each (var ffdTimelineObject:Object in rawData[FFD])
				{
					animation.addFFDTimeline(_parseFFDTimeline(ffdTimelineObject));
				}
			}
			
			for each (var bone:BoneData in this._armature.bones)
			{
				if (!animation.getBoneTimeline(bone.name))  // Add default bone timeline for cache if do not have one.
				{
					const boneTimeline:BoneTimelineData = BaseObject.borrowObject(BoneTimelineData) as BoneTimelineData;
					const boneFrame:BoneFrameData = BaseObject.borrowObject(BoneFrameData) as BoneFrameData;
					boneTimeline.bone = bone;
					boneTimeline.frames.fixed = false;
					boneTimeline.frames[0] = boneFrame;
					boneTimeline.frames.fixed = true;
					animation.addBoneTimeline(boneTimeline);
				}
			}
			
			for each (var slot:SlotData in this._armature.slots)
			{
				if (!animation.getSlotTimeline(slot.name)) // Add default slot timeline for cache if do not have one.
				{
					const slotTimeline:SlotTimelineData = BaseObject.borrowObject(SlotTimelineData) as SlotTimelineData;
					const slotFrame:SlotFrameData = BaseObject.borrowObject(SlotFrameData) as SlotFrameData;
					slotTimeline.slot = slot;
					slotFrame.displayIndex = slot.displayIndex;
					//slotFrame.zOrder = -2;
					slotFrame.color = SlotFrameData.DEFAULT_COLOR;
					slotTimeline.frames.fixed = false;
					slotTimeline.frames[0] = slotFrame;
					slotTimeline.frames.fixed = true;
					animation.addSlotTimeline(slotTimeline);
				}
			}
			
			this._animation = null;
			
			return animation;
		}
		
		/**
		 * @private
		 */
		protected function _parseBoneTimeline(rawData:Object):BoneTimelineData
		{
			const timeline:BoneTimelineData = BaseObject.borrowObject(BoneTimelineData) as BoneTimelineData;
			timeline.bone = this._armature.getBone(_getString(rawData, NAME, null));
			
			_parseTimeline(rawData, timeline, _parseBoneFrame);
			
			const originTransform:Transform = timeline.originTransform;
			var prevFrame:BoneFrameData = null;
			
			for each (var frame:BoneFrameData in timeline.frames)
			{
				if (!prevFrame)
				{
					originTransform.copy(frame.transform);
					frame.transform.identity();
				}
				else if (prevFrame != frame)
				{
					frame.transform.minus(originTransform);
				}
				
				prevFrame = frame;
			}
			
			if (timeline.scale != 1 || timeline.offset != 0)
			{
				this._animation.hasAsynchronyTimeline = true;
			}
			
			return timeline;
		}
		
		/**
		 * @private
		 */
		protected function _parseSlotTimeline(rawData:Object):SlotTimelineData
		{
			const timeline:SlotTimelineData = BaseObject.borrowObject(SlotTimelineData) as SlotTimelineData;
			timeline.slot = this._armature.getSlot(_getString(rawData, NAME, null));
			
			_parseTimeline(rawData, timeline, _parseSlotFrame);
			
			if (timeline.scale != 1 || timeline.offset != 0)
			{
				this._animation.hasAsynchronyTimeline = true;
			}
			
			return timeline;
		}
		
		/**
		 * @private
		 */
		protected function _parseFFDTimeline(rawData:Object):FFDTimelineData
		{
			const timeline:FFDTimelineData = BaseObject.borrowObject(FFDTimelineData) as FFDTimelineData;
			timeline.skin = this._armature.getSkin(_getString(rawData, SKIN, null));
			timeline.slot = timeline.skin.getSlot(_getString(rawData, SLOT, null)); // NAME;
			
			const meshName:String = _getString(rawData, NAME, null);
			for (var i:uint = 0, l:uint = timeline.slot.displays.length ; i < l; ++i)
			{
				const displayData:DisplayData = timeline.slot.displays[i];
				if (displayData.meshData && displayData.name == meshName)
				{
					timeline.displayIndex = i; // rawData[DISPLAY_INDEX];
					this._mesh = displayData.meshData;
					break;
				}
			}
			
			_parseTimeline(rawData, timeline, _parseFFDFrame);
			
			this._mesh = null;
			
			return timeline;
		}
		
		/**
		 * @private
		 */
		protected function _parseAnimationFrame(rawData:Object, frameStart:uint, frameCount:uint):AnimationFrameData
		{
			const frame:AnimationFrameData = BaseObject.borrowObject(AnimationFrameData) as AnimationFrameData;
			
			_parseFrame(rawData, frame, frameStart, frameCount);
			
			if (ACTION in rawData)
			{
				_parseActionData(rawData, frame.actions, null, null);
			}
			
			if ((SOUND in rawData) || (EVENT in rawData))
			{
				_parseEventData(rawData, frame.events, null, null);
			}
			
			return frame;
		}
		
		/**
		 * @private
		 */
		protected function _parseBoneFrame(rawData:Object, frameStart:uint, frameCount:uint):BoneFrameData
		{
			const frame:BoneFrameData = BaseObject.borrowObject(BoneFrameData) as BoneFrameData;
			frame.parent = this._armature.getBone(_getString(rawData, PARENT, null));
			frame.tweenRotate = _getNumber(rawData, TWEEN_ROTATE, 0);
			frame.tweenScale = _getBoolean(rawData, TWEEN_SCALE, true);
			
			_parseTweenFrame(rawData, frame, frameStart, frameCount);
			
			if (ACTION in rawData)
			{
				const bone:BoneData = (this._timeline as BoneTimelineData).bone;
				const slot:SlotData = this._armature.getSlot(bone.name);
				if (slot)
				{
					if (this._animation.frames.length < this._animation.frameCount + 1)
					{
						this._animation.frames.fixed = false;
						
						for (var i:uint = this._animation.frames.length, l:uint = this._animation.frameCount + 1; i < l; ++i)
						{
							if (i == 0)
							{
								this._animation.frames[i] = _parseAnimationFrame({}, 0, this._animation.frameCount);
								this._animation.frames[i].prev = this._animation.frames[i];
								this._animation.frames[i].next = this._animation.frames[i];
							}
							else
							{
								this._animation.frames[i] = this._animation.frames[i - 1];
							}
						}
						
						this._animation.frames.fixed = true;
					}
					
					this._animation.frames[i] = _parseAnimationFrame({}, 0, this._animation.frameCount);
					
					this._animation.frames.length = 0;
					//_parseActionData(rawData, frame.actions, null, slot);
				}
			}
			
			/*
			frame.sound = frameObject[A_SOUND];
			frame.event = frameObject[A_EVENT];
			frame.data = frameObject[A_DATA];
			*/
			
			if (TRANSFORM in rawData)
			{
				_parseTransform(rawData[TRANSFORM], frame.transform);
			}
			
			return frame;
		}
		
		/**
		 * @private
		 */
		protected function _parseSlotFrame(rawData:Object, frameStart:uint, frameCount:uint):SlotFrameData
		{
			const frame:SlotFrameData = BaseObject.borrowObject(SlotFrameData) as SlotFrameData;
			frame.displayIndex = _getNumber(rawData, DISPLAY_INDEX, 0);
			//frame.zOrder = _getNumber(rawData, Z_ORDER, -1); // TODO
			
			_parseTweenFrame(rawData, frame, frameStart, frameCount);
			
			if (COLOR in rawData)
			{
				frame.color = SlotFrameData.generateColor();
				_parseColorTransform(rawData[COLOR], frame.color);
			}
			else
			{
				frame.color = SlotFrameData.DEFAULT_COLOR;
			}
			
			return frame;
		}
		
		/**
		 * @private
		 */
		protected function _parseFFDFrame(rawData:Object, frameStart:uint, frameCount:uint):ExtensionFrameData
		{
			const frame:ExtensionFrameData = BaseObject.borrowObject(ExtensionFrameData) as ExtensionFrameData;
			frame.type = _getNumber(rawData, TYPE, DragonBones.EXTENSION_TYPE_FFD);
			
			_parseTweenFrame(rawData, frame, frameStart, frameCount);
			
			frame.tweens.fixed = false;
			frame.tweens.length = 0;
			
			const rawVertices:Array = rawData[VERTICES];
			const offset:uint = _getNumber(rawData, OFFSET, 0);
			var x:Number = 0;
			var y:Number = 0;
			for (var i:uint = 0, l:uint = this._mesh.vertices.length ; i < l; i += 2)
			{
				if (!rawVertices || i < offset || i - offset >= rawVertices.length)
				{
					x = 0;
					y = 0;
				}
				else
				{
					x = rawVertices[i - offset];
					y = rawVertices[i + 1 - offset];
				}
				
				if (this._mesh.skinned)
				{
					Transform.transformPoint(this._mesh.slotPose, x, y, _helpPoint, true);
					x = _helpPoint.x;
					y = _helpPoint.y;
					
					const boneIndices:Vector.<uint> = this._mesh.boneIndices[i / 2];
					for (var iB:uint = 0, lB:uint = boneIndices.length; iB < lB; ++iB)
					{
						Transform.transformPoint(this._mesh.inverseBindPose[boneIndices[iB]], x, y, _helpPoint, true);
						frame.tweens.push(_helpPoint.x, _helpPoint.y);
					}
				}
				else
				{
					frame.tweens.push(x, y);
				}
			}
			
			frame.tweens.fixed = true;
			
			return frame;
		}
		
		/**
		 * @private
		 */
		protected function _parseTweenFrame(rawData:Object, frame:TweenFrameData, frameStart:uint, frameCount:uint):void
		{
			_parseFrame(rawData, frame, frameStart, frameCount);
			
			frame.tweenEasing = _getNumber(rawData, TWEEN_EASING, TweenFrameData.NO_TWEEN);
			
			if (CURVE in rawData)
			{
				frame.curve = TweenFrameData.samplingCurve(rawData[CURVE], frameCount);
			}
		}
		
		protected function _parseFrame(rawData:Object, frame:FrameData, frameStart:uint, frameCount:uint):void
		{
			frame.position = frameStart * 1000000 / this._armature.frameRate;
			frame.duration = frameCount * 1000000 / this._armature.frameRate;
		}
		
		/**
		 * @private
		 */
		protected function _parseTimeline(rawData:Object, timeline:TimelineData, frameParser:Function):void
		{
			timeline.scale = _getNumber(rawData, SCALE, 1);
			timeline.offset = _getNumber(rawData, OFFSET, 0);
			
			this._timeline = timeline;
			
			if (FRAME in rawData)
			{
				const rawFrames:Array = rawData[FRAME];
				if (rawFrames.length)
				{
					timeline.frames.fixed = false;
					
					if (rawFrames.length == 1)
					{
						timeline.frames.length = 1;
						timeline.frames[0] = frameParser(rawFrames[0], 0, _getNumber(rawFrames[0], DURATION, 1));
					}
					else
					{
						timeline.frames.length = this._animation.frameCount + 1;
						
						var frameStart:uint = 0;
						var frameCount:uint = 0;
						var frame:FrameData = null;
						var prevFrame:FrameData = null;
						
						for (var i:uint = 0, iW:uint = 0, l:uint = this._animation.frameCount + 1; i < l; ++i)
						{
							if (frameStart + frameCount <= i && iW < rawFrames.length)
							{
								const frameObject:Object = rawFrames[iW++];
								frameStart = i;
								frameCount = _getNumber(frameObject, DURATION, 1);
								frame = frameParser(frameObject, frameStart, frameCount);
								
								if (prevFrame)
								{
									prevFrame.next = frame;
									frame.prev = prevFrame;
								}
								
								prevFrame = frame;
							}
							
							timeline.frames[i] = frame;
						}
						
						frame.duration = this._animation.duration - frame.position; // Modify last frame duration
						
						frame = timeline.frames[0];
						prevFrame.next = frame;
						frame.prev = prevFrame;
					}
					
					timeline.frames.fixed = true;
				}
			}
			
			this._timeline = null;
		}
		
		/**
		 * @private
		 */
		protected function _parseActionData(rawData:Object, actions:Vector.<ActionData>, bone:BoneData, slot:SlotData):void
		{
			const actionsObject:* = rawData[ACTION];
			
			actions.fixed = false;
			
			if (actionsObject is String)
			{
				const actionDataA:ActionData = BaseObject.borrowObject(ActionData) as ActionData;
				actionDataA.type = DragonBones.ACTION_TYPE_FADE_IN;
				actionDataA.params = [actionsObject];
				actionDataA.bone = bone;
				actionDataA.slot = slot;
				actions[0] = actionDataA;
			}
			else if (actionsObject is Array)
			{
				for each (var actionObject:Array in actionsObject)
				{
					const actionDataB:ActionData = BaseObject.borrowObject(ActionData) as ActionData;
					const actionType:* = _getParameter(actionObject, 0, DragonBones.ACTION_TYPE_FADE_IN);
					if (actionType is String)
					{
						actionDataB.type = _getActionType(actionType);
					}
					else
					{
						actionDataB.type = actionType;
					}
					
					switch (actionDataB.type)
					{
						case DragonBones.ACTION_TYPE_PLAY:
							actionDataA.params = [
								_getParameter(actionObject, 1, null), // animationName
								_getParameter(actionObject, 2, -1), // playTimes
							];
							break;
						
						case DragonBones.ACTION_TYPE_STOP:
							actionDataA.params = [
								_getParameter(actionObject, 1, null) // animation
							];
							break;
						
						case DragonBones.ACTION_TYPE_GOTO_AND_PLAY:
							actionDataA.params = [
								_getParameter(actionObject, 1, null), // animationName
								_getParameter(actionObject, 2, 0), // time
								_getParameter(actionObject, 3, -1) // playTimes
							];
							break;
						
						case DragonBones.ACTION_TYPE_GOTO_AND_STOP:
							actionDataA.params = [
								_getParameter(actionObject, 1, null), // animationName
								_getParameter(actionObject, 2, 0), // time
							];
							break;
						
						case DragonBones.ACTION_TYPE_FADE_IN:
							actionDataA.params = [
								_getParameter(actionObject, 1, null), // animationName
								_getParameter(actionObject, 2, -1), // playTimes
								_getParameter(actionObject, 3, 0) // fadeInTime
							];
							break;
						
						case DragonBones.ACTION_TYPE_FADE_OUT:
							actionDataA.params = [
								_getParameter(actionObject, 1, null), // animationName
								_getParameter(actionObject, 2, 0) // fadeOutTime
							];
							break;
					}
					
					actionDataB.bone = bone;
					actionDataB.slot = slot;
					actions.push(actionDataB);
				}
			}
			
			actions.fixed = true;
		}
		
		/**
		 * @private
		 */
		protected function _parseEventData(rawData:Object, events:Vector.<EventData>, bone:BoneData, slot:SlotData):void
		{
			events.fixed = false;
			
			if (SOUND in rawData)
			{
				const soundEventData:EventData = BaseObject.borrowObject(EventData) as EventData;
				soundEventData.type = DragonBones.EVENT_TYPE_SOUND;
				soundEventData.name = rawData[SOUND];
				soundEventData.bone = bone;
				soundEventData.slot = slot;
				events.push(soundEventData);
			}
			
			if (EVENT in rawData)
			{
				const eventData:EventData = BaseObject.borrowObject(EventData) as EventData;
				eventData.type = DragonBones.EVENT_TYPE_FRAME;
				eventData.name = rawData[EVENT];
				eventData.bone = bone;
				eventData.slot = slot;
				
				if (DATA in rawData)
				{
					eventData.data = rawData[DATA];
				}
				
				events.push(eventData);
			}
			
			events.fixed = true;
		}
		
		/**
		 * @private
		 */
		protected function _parseTransform(rawData:Object, transform:Transform):void
		{
			transform.x = _getNumber(rawData, X, 0);
			transform.y = _getNumber(rawData, Y, 0);
			transform.skewX = _getNumber(rawData, SKEW_X, 0) * DragonBones.ANGLE_TO_RADIAN;
			transform.skewY = _getNumber(rawData, SKEW_Y, 0) * DragonBones.ANGLE_TO_RADIAN;
			transform.scaleX = _getNumber(rawData, SCALE_X, 1);
			transform.scaleY = _getNumber(rawData, SCALE_Y, 1);
		}
		
		/**
		 * @private
		 */
		protected function _parseColorTransform(rawData:Object, color:ColorTransform):void
		{
			color.alphaMultiplier = _getNumber(rawData, ALPHA_MULTIPLIER, 100) * 0.01;
			color.redMultiplier = _getNumber(rawData, RED_MULTIPLIER, 100) * 0.01;
			color.greenMultiplier = _getNumber(rawData, GREEN_MULTIPLIER, 100) * 0.01;
			color.blueMultiplier = _getNumber(rawData, BLUE_MULTIPLIER, 100) * 0.01;
			color.alphaOffset = _getNumber(rawData, ALPHA_OFFSET, 0);
			color.redOffset = _getNumber(rawData, RED_OFFSET, 0);
			color.greenOffset = _getNumber(rawData, GREEN_OFFSET, 0);
			color.blueOffset = _getNumber(rawData, BLUE_OFFSET, 0);
		}
		
		/**
		 * @private
		 */
		private static var _instance:ObjectDataParser = null;
		
		/**
		 * 
		 */
		public static function getInstance():ObjectDataParser
		{
			if (!_instance)
			{
				_instance = new ObjectDataParser();
			}
			
			return _instance;
		}
	}
}