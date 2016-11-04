package dragonBones.parsers
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
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
	import dragonBones.objects.ZOrderFrameData;
	import dragonBones.objects.ZOrderTimelineData;
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
					return value; // Boolean(value);
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
				if (value == null || value == "NaN")
				{
					return defaultValue;
				}
				
				return value; // Number(value);
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
				return rawData[key]; // String(rawData[key]);
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
		 * @private
		 */
		protected function _parseArmature(rawData:Object, scale:Number):ArmatureData
		{
			const armature:ArmatureData = BaseObject.borrowObject(ArmatureData) as ArmatureData;
			armature.name = _getString(rawData, NAME, null);
			armature.frameRate = _getNumber(rawData, FRAME_RATE, this._data.frameRate) || this._data.frameRate;
			armature.scale = scale;
			
			if (TYPE in rawData && rawData[TYPE] is String) 
			{
				armature.type = _getArmatureType(rawData[TYPE]);
			} 
			else 
			{
				armature.type = _getNumber(rawData, TYPE, DragonBones.ARMATURE_TYPE_ARMATURE);
			}
			
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
				var zOrder:int = 0;
				for each (var slotObject:Object in rawData[SLOT])
				{
					armature.addSlot(_parseSlot(slotObject, zOrder++));
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
			
			if (
				(ACTIONS in rawData) ||
				(DEFAULT_ACTIONS in rawData)
			) 
			{
				_parseActionData(rawData, armature.actions, null, null);
			}
			
			if (this._isOldData && this._isGlobalTransform) // Support 2.x ~ 3.x data.
			{
				_globalToLocal(armature);
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
			bone.length = _getNumber(rawData, LENGTH, 0) * this._armature.scale;
			
			if (TRANSFORM in rawData)
			{
				_parseTransform(rawData[TRANSFORM], bone.transform);
			}
			
			if (this._isOldData) // Support 2.x ~ 3.x data.
			{
				bone.inheritScale = false;
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
				
				if (bone.chain > 0 && bone.parent && !bone.parent.ik)
				{
					bone.parent.ik = bone.ik;
					bone.parent.chainIndex = 0;
					bone.parent.chain = 0;
					bone.chainIndex = 1;
				}
				else
				{
					bone.chain = 0;
					bone.chainIndex = 0;
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function _parseSlot(rawData:Object, zOrder:int):SlotData
		{
			const slot:SlotData = BaseObject.borrowObject(SlotData) as SlotData;
			slot.name = _getString(rawData, NAME, null);
			slot.parent = this._armature.getBone(_getString(rawData, PARENT, null));
			slot.displayIndex = _getNumber(rawData, DISPLAY_INDEX, 0);
			slot.zOrder = _getNumber(rawData, Z, zOrder); // Support 2.x ~ 3.x data.
			
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
			
			if (
				(ACTIONS in rawData) ||
				(DEFAULT_ACTIONS in rawData)
			) 
			{
				this._parseActionData(rawData, slot.actions, null, null);
			}
			
			if (this._isOldData) // Support 2.x ~ 3.x data.
			{
				if (COLOR_TRANSFORM in rawData) 
				{
					slot.color = SlotData.generateColor();
					_parseColorTransform(rawData[COLOR_TRANSFORM], slot.color);
				} 
				else 
				{
					slot.color = SlotData.DEFAULT_COLOR;
				}
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
				var zOrder:int = 0;
				for each (var slotObject:Object in rawData[SLOT])
				{
					if (this._isOldData) // Support 2.x ~ 3.x data.
					{
						this._armature.addSlot(_parseSlot(slotObject, zOrder++));
					}
					
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
				
				this._slotDisplayDataSet = slotDisplayDataSet;
				
				for each (var displayObject:Object in displayObjectSet)
				{
					displayDataSet.push(_parseDisplay(displayObject));
				}
				
				displayDataSet.fixed = true;
				
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
			
			
			display.isRelativePivot = true;
			if (PIVOT in rawData)
			{
				const pivotObject:Object = rawData[PIVOT];
				display.pivot.x = _getNumber(pivotObject, X, 0);
				display.pivot.y = _getNumber(pivotObject, Y, 0);
			}
			else if (this._isOldData) // Support 2.x ~ 3.x data.
			{
				const transformObject:Object = rawData[TRANSFORM];
				display.isRelativePivot = false;
				display.pivot.x = _getNumber(transformObject, PIVOT_X, 0) * this._armature.scale;
				display.pivot.y = _getNumber(transformObject, PIVOT_Y, 0) * this._armature.scale;
			}
			else
			{
				display.pivot.x = 0.5;
				display.pivot.y = 0.5;
			}
			
			if (TRANSFORM in rawData)
			{
				_parseTransform(rawData[TRANSFORM], display.transform);
			}
			
			switch (display.type)
			{
				case DragonBones.DISPLAY_TYPE_IMAGE:
					break;
				
				case DragonBones.DISPLAY_TYPE_ARMATURE:
					break;
				
				case DragonBones.DISPLAY_TYPE_MESH:
					display.mesh = _parseMesh(rawData);
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
			
			const numVertices:uint = uint(rawVertices.length / 2);
			const numTriangles:uint = uint(rawTriangles.length / 3);
			
			const inverseBindPose:Vector.<Matrix> = new Vector.<Matrix>(this._armature.sortedBones.length, true);
			
			mesh.skinned = (WEIGHTS in rawData) && (rawData[WEIGHTS] as Array).length > 0;
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
				mesh.bones.fixed = false;
				mesh.inverseBindPose.fixed = false;
				
				if (SLOT_POSE in rawData)
				{
					const rawSlotPose:Array = rawData[SLOT_POSE];
					mesh.slotPose.a = rawSlotPose[0];
					mesh.slotPose.b = rawSlotPose[1];
					mesh.slotPose.c = rawSlotPose[2];
					mesh.slotPose.d = rawSlotPose[3];
					mesh.slotPose.tx = rawSlotPose[4] * this._armature.scale;
					mesh.slotPose.ty = rawSlotPose[5] * this._armature.scale;
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
						boneMatrix.tx = rawBonePose[i + 5] * this._armature.scale;
						boneMatrix.ty = rawBonePose[i + 6] * this._armature.scale;
						boneMatrix.invert();
					}
				}
			}
			
			var iW:uint = 0;
			
			for (i = 0, l = rawVertices.length; i < l; i += 2)
			{
				const iN:uint = i + 1;
				const vertexIndex:uint = i / 2;
				
				var x:Number = mesh.vertices[i] = rawVertices[i] * this._armature.scale;
				var y:Number = mesh.vertices[iN] = rawVertices[iN] * this._armature.scale;
				mesh.uvs[i] = rawUVs[i];
				mesh.uvs[iN] = rawUVs[iN];
				
				if (mesh.skinned)
				{
					const rawWeights:Array = rawData[WEIGHTS];
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
			animation.frameCount = Math.max(_getNumber(rawData, DURATION, 1), 1);
			animation.position = _getNumber(rawData, POSITION, 0) / this._armature.frameRate;
			animation.duration = animation.frameCount / this._armature.frameRate;
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
			
			
			if (Z_ORDER in rawData) 
			{
				animation.zOrderTimeline = BaseObject.borrowObject(ZOrderTimelineData) as ZOrderTimelineData;
				this._parseTimeline(rawData[Z_ORDER], animation.zOrderTimeline, _parseZOrderFrame);
			}
			
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
			
			if (this._isOldData) // Support 2.x ~ 3.x data.
			{
				this._isAutoTween = _getBoolean(rawData, AUTO_TWEEN, true);
				this._animationTweenEasing = _getNumber(rawData, TWEEN_EASING, 0) || 0;
				animation.playTimes = _getNumber(rawData, LOOP, 1);
				
				if (TIMELINE in rawData) 
				{
					const timelines:Array = rawData[TIMELINE];
					for (var i:uint = 0, l:uint = timelines.length; i < l; ++i) {
						animation.addBoneTimeline(_parseBoneTimeline(timelines[i]));
					}
					
					for (i = 0, l = timelines.length; i < l; ++i) {
						animation.addSlotTimeline(_parseSlotTimeline(timelines[i]));
					}
				}
			} 
			else 
			{
				this._isAutoTween = false;
				this._animationTweenEasing = 0;
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
					
					if (slot.color == SlotData.DEFAULT_COLOR)
					{
						slotFrame.color = SlotFrameData.DEFAULT_COLOR;
					}
					else
					{
						slotFrame.color = SlotFrameData.generateColor();
						slotFrame.color.alphaMultiplier = slot.color.alphaMultiplier;
						slotFrame.color.redMultiplier = slot.color.redMultiplier;
						slotFrame.color.greenMultiplier = slot.color.greenMultiplier;
						slotFrame.color.blueMultiplier = slot.color.blueMultiplier;
						slotFrame.color.alphaOffset = slot.color.alphaOffset;
						slotFrame.color.redOffset = slot.color.redOffset;
						slotFrame.color.greenOffset = slot.color.greenOffset;
						slotFrame.color.blueOffset = slot.color.blueOffset;
					}
					
					slotTimeline.frames.fixed = false;
					slotTimeline.frames[0] = slotFrame;
					slotTimeline.frames.fixed = true;
					animation.addSlotTimeline(slotTimeline);
					
					if (this._isOldData) // Support 2.x ~ 3.x data.
					{
						slotFrame.displayIndex = -1;
					}
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
					originTransform.copyFrom(frame.transform);
					frame.transform.identity();
					
					if (originTransform.scaleX == 0) 
					{
						originTransform.scaleX = 0.001;
						//frame.transform.scaleX = 0;
					}
					
					if (originTransform.scaleY == 0) 
					{
						originTransform.scaleY = 0.001;
						//frame.transform.scaleY = 0;
					}
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
			
			if (
				this._isOldData &&
				(
					(PIVOT_X in rawData) ||
					(PIVOT_Y in rawData)
				)
			)  // Support 2.x ~ 3.x data.
			{
				this._timelinePivot.x = _getNumber(rawData, PIVOT_X, 0);
				this._timelinePivot.y = _getNumber(rawData, PIVOT_Y, 0);
			} 
			else 
			{
				this._timelinePivot.x = 0;
				this._timelinePivot.y = 0;
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
			for (var i:uint = 0, l:uint = timeline.slot.displays.length; i < l; ++i)
			{
				const displayData:DisplayData = timeline.slot.displays[i];
				if (displayData.mesh && displayData.name == meshName)
				{
					timeline.displayIndex = i; // rawData[DISPLAY_INDEX];
					this._mesh = displayData.mesh;
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
			
			if (
				(ACTION in rawData) ||
				(ACTIONS in rawData)
			) 
			{
				_parseActionData(rawData, frame.actions, null, null);
			}
			
			if ((EVENT in rawData) || (SOUND in rawData))
			{
				_parseEventData(rawData, frame.events, null, null);
			}
			
			return frame;
		}
		
		/**
		 * @private
		 */
		protected function _parseZOrderFrame(rawData:Object, frameStart:uint, frameCount:uint):ZOrderFrameData 
		{
			const frame:ZOrderFrameData = BaseObject.borrowObject(ZOrderFrameData) as ZOrderFrameData;
			
			_parseFrame(rawData, frame, frameStart, frameCount);
			
			const zOrder:Array = rawData[Z_ORDER] as Array;
			if (zOrder && zOrder.length > 0) {
				const slotCount:uint = this._armature.sortedSlots.length;
				const unchanged:Vector.<int> = new Vector.<int>(slotCount - zOrder.length / 2);
				
				frame.zOrder.length = slotCount;
				for (var i:uint = 0, l:uint = slotCount; i < l; ++i) {
					frame.zOrder[i] = -1;
				}
				
				var originalIndex:int = 0;
				var unchangedIndex:int = 0;
				for (i = 0, l = zOrder.length; i < l; i += 2) 
				{
					const slotIndex:int = zOrder[i];
					const offset:int = zOrder[i + 1];
					
					while (originalIndex != slotIndex) 
					{
						unchanged[unchangedIndex++] = originalIndex++;
					}
					
					frame.zOrder[originalIndex + offset] = originalIndex++;
				}
				
				while (originalIndex < slotCount) 
				{
					unchanged[unchangedIndex++] = originalIndex++;
				}
				
				i = slotCount;
				while (i--) 
				{
					if (frame.zOrder[i] == -1) 
					{
						frame.zOrder[i] = unchanged[--unchangedIndex];
					}
				}
			}
			
			return frame;
		}
		
		/**
		 * @private
		 */
		protected function _parseBoneFrame(rawData:Object, frameStart:uint, frameCount:uint):BoneFrameData
		{
			const frame:BoneFrameData = BaseObject.borrowObject(BoneFrameData) as BoneFrameData;
			frame.tweenRotate = _getNumber(rawData, TWEEN_ROTATE, 0);
			frame.tweenScale = _getBoolean(rawData, TWEEN_SCALE, true);
			
			_parseTweenFrame(rawData, frame, frameStart, frameCount);
			
			if (TRANSFORM in rawData)
			{
				const transformObject:Object = rawData[TRANSFORM];
				_parseTransform(rawData[TRANSFORM], frame.transform);
				
				if (this._isOldData) // Support 2.x ~ 3.x data.
				{
					this._helpPoint.x = this._timelinePivot.x + _getNumber(transformObject, PIVOT_X, 0);
					this._helpPoint.y = this._timelinePivot.y + _getNumber(transformObject, PIVOT_Y, 0);
					frame.transform.toMatrix(this._helpMatrix);
					Transform.transformPoint(this._helpMatrix, this._helpPoint.x, this._helpPoint.y, this._helpPoint, true);
					frame.transform.x += this._helpPoint.x;
					frame.transform.y += this._helpPoint.y;
				}
			}
			
			const bone:BoneData = (this._timeline as BoneTimelineData).bone;
			
			if (
				(ACTION in rawData) ||
				(ACTIONS in rawData)
			) 
			{
				const slot:SlotData = this._armature.getSlot(bone.name);
				const actions:Vector.<ActionData> = new Vector.<ActionData>();
				_parseActionData(rawData, actions, bone, slot);
				
				this._mergeFrameToAnimationTimeline(frame.position, actions, null); // Merge actions and events to animation timeline.
			}
			
			if ((EVENT in rawData) || (SOUND in rawData))
			{
				const events:Vector.<EventData> = new Vector.<EventData>();
				_parseEventData(rawData, events, bone, null);
				
				this._mergeFrameToAnimationTimeline(frame.position, null, events); // Merge actions and events to animation timeline.
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
			
			_parseTweenFrame(rawData, frame, frameStart, frameCount);
			
			if (
				(COLOR in rawData) ||
				(COLOR_TRANSFORM in rawData)
			)
			{ // Support 2.x ~ 3.x data. (colorTransform key)
				frame.color = SlotFrameData.generateColor();
				_parseColorTransform(rawData[COLOR] || rawData[COLOR_TRANSFORM], frame.color);
			}
			else
			{
				frame.color = SlotFrameData.DEFAULT_COLOR;
			}
			
			if (this._isOldData) // Support 2.x ~ 3.x data.
			{
				if (_getBoolean(rawData, HIDE, false)) 
				{
					frame.displayIndex = -1;
				}
			} 
			else if (
				(ACTION in rawData) ||
				(ACTIONS in rawData)
			) 
			{
				const slot:SlotData = (this._timeline as SlotTimelineData).slot;
				const actions:Vector.<ActionData> = new Vector.<ActionData>();
				_parseActionData(rawData, actions, slot.parent, slot);
				
				this._mergeFrameToAnimationTimeline(frame.position, actions, null); // Merge actions and events to animation timeline.
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
			
			frame.tweens.fixed = false
			
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
					x = rawVertices[i - offset] * this._armature.scale;
					y = rawVertices[i + 1 - offset] * this._armature.scale;
				}
				
				if (this._mesh.skinned)
				{
					Transform.transformPoint(this._mesh.slotPose, x, y, _helpPoint, true);
					x = _helpPoint.x;
					y = _helpPoint.y;
					
					const boneIndices:Vector.<uint> = this._mesh.boneIndices[i / 2];
					for (var iB:uint = 0, lB:uint = boneIndices.length; iB < lB; ++iB)
					{
						const boneIndex:uint = boneIndices[iB];
						Transform.transformPoint(this._mesh.inverseBindPose[boneIndex], x, y, _helpPoint, true);
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
			
			if (frame.duration > 0)
			{
				if (TWEEN_EASING in rawData)
				{
					frame.tweenEasing = _getNumber(rawData, TWEEN_EASING, DragonBones.NO_TWEEN);
				}
				else if (this._isOldData) // Support 2.x ~ 3.x data.
				{
					frame.tweenEasing = this._isAutoTween ? this._animationTweenEasing : DragonBones.NO_TWEEN;
				}
				else
				{
					frame.tweenEasing = DragonBones.NO_TWEEN;
				}
				
				if (this._isOldData && this._animation.scale == 1 && this._timeline.scale == 1 && frame.duration * this._armature.frameRate < 2) // Support 2.x ~ 3.x data.
				{
					frame.tweenEasing = DragonBones.NO_TWEEN;
				}
				
				if (CURVE in rawData)
				{
					frame.curve = TweenFrameData.samplingCurve(rawData[CURVE], frameCount);
				}
			}
			else
			{
				frame.tweenEasing = DragonBones.NO_TWEEN;
				frame.curve = null;
			}
		}
		
		protected function _parseFrame(rawData:Object, frame:FrameData, frameStart:uint, frameCount:uint):void
		{
			frame.position = frameStart / this._armature.frameRate;
			frame.duration = frameCount / this._armature.frameRate;
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
						
						for (var i:uint = 0, iW:uint = 0, l:uint = timeline.frames.length; i < l; ++i)
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
									
									if (this._isOldData) // Support 2.x ~ 3.x data.
									{
										if (prevFrame is TweenFrameData && frameObject[DISPLAY_INDEX] == -1) 
										{
											(prevFrame as TweenFrameData).tweenEasing = DragonBones.NO_TWEEN;
										}
									}
								}
								
								prevFrame = frame;
							}
							
							timeline.frames[i] = frame;
						}
						
						frame.duration = this._animation.duration - frame.position; // Modify last frame duration
						
						frame = timeline.frames[0];
						prevFrame.next = frame;
						frame.prev = prevFrame;
						
						if (this._isOldData) // Support 2.x ~ 3.x data.
						{
							if (prevFrame is TweenFrameData && rawFrames[0][DISPLAY_INDEX] == -1) 
							{
								(prevFrame as TweenFrameData).tweenEasing = DragonBones.NO_TWEEN;
							}
						}
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
			const actionsObject:* = rawData[ACTION] || rawData[ACTIONS] || rawData[DEFAULT_ACTIONS];
			
			actions.fixed = false;
			
			if (actionsObject is String)
			{
				const actionDataA:ActionData = BaseObject.borrowObject(ActionData) as ActionData;
				actionDataA.type = DragonBones.ACTION_TYPE_FADE_IN;
				actionDataA.data = [actionsObject, -1, -1];
				actionDataA.bone = bone;
				actionDataA.slot = slot;
				actions.push(actionDataA);
			}
			else if (actionsObject is Array)
			{
				for (var i:uint = 0, l:uint = actionsObject.length; i < l; ++i) 
				{
					const actionObject:* = actionsObject[i];
					const isArray:Boolean = actionObject is Array;
					const actionDataB:ActionData = BaseObject.borrowObject(ActionData) as ActionData;
					const animationName:String = isArray? _getParameter(actionObject, 1, null): _getString(actionObject, "gotoAndPlay", null);
					
					if (isArray) 
					{
						const actionType:String = actionObject[0];
						if (actionType is String) 
						{
							actionDataB.type = _getActionType(actionType);
						} 
						else 
						{
							actionDataB.type = _getParameter(actionObject, 0, DragonBones.ACTION_TYPE_FADE_IN);
						}
					} 
					else 
					{
						actionDataB.type = DragonBones.ACTION_TYPE_GOTO_AND_PLAY;
					}
					
					switch (actionDataB.type)
					{
						case DragonBones.ACTION_TYPE_PLAY:
							actionDataB.data = [
								animationName, // animationName
								isArray? _getParameter(actionObject, 2, -1): -1, // playTimes
							];
							break;
						
						case DragonBones.ACTION_TYPE_STOP:
							actionDataB.data = [
								animationName, // animationName
							];
							break;
						
						case DragonBones.ACTION_TYPE_GOTO_AND_PLAY:
							actionDataB.data = [
								animationName, // animationName
								isArray? _getParameter(actionObject, 2, 0): 0, // time
								isArray? _getParameter(actionObject, 3, -1): -1 // playTimes
							];
							break;
						
						case DragonBones.ACTION_TYPE_GOTO_AND_STOP:
							actionDataB.data = [
								animationName, // animationName
								isArray? _getParameter(actionObject, 2, 0): 0, // time
							];
							break;
						
						case DragonBones.ACTION_TYPE_FADE_IN:
							actionDataB.data = [
								animationName, // animationName
								isArray? _getParameter(actionObject, 2, -1): -1, // fadeInTime
								isArray? _getParameter(actionObject, 3, -1): -1 // playTimes
							];
							break;
						
						case DragonBones.ACTION_TYPE_FADE_OUT:
							actionDataB.data = [
								animationName, // animationName
								isArray? _getParameter(actionObject, 2, 0): 0 // fadeOutTime
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
			transform.x = _getNumber(rawData, X, 0) * this._armature.scale;
			transform.y = _getNumber(rawData, Y, 0) * this._armature.scale;
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
		 * @inheritDoc
		 */
		override public function parseDragonBonesData(rawData:*, scale:Number = 1):DragonBonesData
		{
			if (rawData)
			{
				const version:String = _getString(rawData, VERSION, null);
				this._isOldData = version == DATA_VERSION_2_3 || version == DATA_VERSION_3_0;
				if (this._isOldData) 
				{
					this._isGlobalTransform = _getBoolean(rawData, IS_GLOBAL, true);
				} 
				else 
				{
					this._isGlobalTransform = false;
				}
				
				if (version == DATA_VERSION || version == DATA_VERSION_4_0 || this._isOldData)
				{
					const data:DragonBonesData = BaseObject.borrowObject(DragonBonesData) as DragonBonesData;
					data.name = _getString(rawData, NAME, null);
					data.frameRate = _getNumber(rawData, FRAME_RATE, 24) || 24;
					
					if (ARMATURE in rawData)
					{
						this._data = data;
						
						for each (var armatureObject:Object in rawData[ARMATURE])
						{
							data.addArmature(_parseArmature(armatureObject, scale));
						}
						
						this._data = null;
					}
					
					return data;
				}
				else
				{
					throw new Error("Nonsupport data version.");
				}
			}
			else
			{
				throw new ArgumentError();
			}
			
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function parseTextureAtlasData(rawData:*, textureAtlasData:TextureAtlasData, scale:Number = 0, rawScale:Number = 0):void
		{
			if (rawData)
			{
				// format
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
				
				scale = 1 / (rawScale > 0? rawScale: scale);
				
				if (SUB_TEXTURE in rawData)
				{
					for each (var textureObject:Object in rawData[SUB_TEXTURE])
					{
 						const textureData:TextureData = textureAtlasData.generateTexture();
   						textureData.name = _getString(textureObject, NAME, null);
						textureData.rotated = _getBoolean(textureObject, ROTATED, false);
						textureData.region.x = _getNumber(textureObject, X, 0) * scale;
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
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * @private
		 */
		private static var _instance:ObjectDataParser = null;
		
		/**
		 * @deprecated
		 * @see dragonBones.factories.BaseFactory#parseTextureAtlasData()
		 * @see dragonBones.factories.BaseFactory#parseDragonBonesData()
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