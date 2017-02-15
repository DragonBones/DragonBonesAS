package dragonBones
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import dragonBones.core.DragonBones;
	import dragonBones.core.TransformObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.BlendMode;
	import dragonBones.geom.Transform;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.BoundingBoxData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SkinSlotData;
	import dragonBones.objects.SlotData;
	import dragonBones.textures.TextureData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 插槽，附着在骨骼上，控制显示对象的显示状态和属性。
	 * 一个骨骼上可以包含多个插槽。
	 * 一个插槽中可以包含多个显示对象，同一时间只能显示其中的一个显示对象，但可以在动画播放的过程中切换显示对象实现帧动画。
	 * 显示对象可以是普通的图片纹理，也可以是子骨架的显示容器，网格显示对象，还可以是自定义的其他显示对象。
	 * @see dragonBones.Armature
	 * @see dragonBones.Bone
	 * @see dragonBones.objects.SlotData
	 * @version DragonBones 3.0
	 */
	public class Slot extends TransformObject
	{
		/**
		 * @private
		 */
		protected static const _helpPoint:Point = new Point();
		/**
		 * @private
		 */
		protected static const _helpMatrix:Matrix = new Matrix();
		/**
		 * @language zh_CN
         * 显示对象受到控制的动画状态或混合组名称，设置为 null 则表示受所有的动画状态控制。
         * @default null
		 * @see dragonBones.animation.AnimationState#displayControl
		 * @see dragonBones.animation.AnimationState#name
		 * @see dragonBones.animation.AnimationState#group
		 * @version DragonBones 4.5
		 */
		public var displayController:String;
		/**
		 * @private
		 */
		protected var _displayDirty:Boolean;
		/**
		 * @private
		 */
		protected var _zOrderDirty:Boolean;
		/**
		 * @private
		 */
		protected var _blendModeDirty:Boolean;
		/**
		 * @private
		 */
		dragonBones_internal var _colorDirty:Boolean;
		/**
		 * @private
		 */
		dragonBones_internal var _meshDirty:Boolean;
		/**
		 * @private
		 */
		protected var _originalDirty:Boolean;
		/**
		 * @private
		 */
		protected var _transformDirty:Boolean;
		/**
		 * @private
		 */
		protected var _updateState:int;
		/**
		 * @private
		 */
		protected var _blendMode:int;
		/**
		 * @private
		 */
		protected var _displayIndex:int;
		/**
		 * @private
		 */
		dragonBones_internal var _zOrder:int;
		/**
		 * @private
		 */
		protected var _cachedFrameIndex:int;
		/**
		 * @private
		 */
		dragonBones_internal var _pivotX:Number;
		/**
		 * @private
		 */
		dragonBones_internal var _pivotY:Number;
		/**
		 * @private
		 */
		protected const _localMatrix:Matrix = new Matrix();
		/**
		 * @private
		 */
		dragonBones_internal const _colorTransform:ColorTransform = new ColorTransform();
		/**
		 * @private
		 */
		dragonBones_internal const _ffdVertices:Vector.<Number> = new Vector.<Number>();
		/**
		 * @private
		 */
		protected const _displayList:Vector.<Object> = new Vector.<Object>();
		/**
		 * @private
		 */
		dragonBones_internal const _textureDatas:Vector.<TextureData> = new Vector.<TextureData>();
		/**
		 * @private
		 */
		dragonBones_internal const _replacedDisplayDatas:Vector.<DisplayData> = new Vector.<DisplayData>();
		/**
		 * @private
		 */
		protected const _meshBones:Vector.<Bone> = new Vector.<Bone>();
		/**
		 * @private
		 */
		protected var _skinSlotData:SkinSlotData;
		/**
		 * @private
		 */
		protected var _displayData:DisplayData;
		/**
		 * @private
		 */
		protected var _replacedDisplayData:DisplayData;
		/**
		 * @private
		 */
		protected var _textureData:TextureData;
		/**
		 * @private
		 */
		dragonBones_internal var _meshData:MeshData;
		/**
		 * @private
		 */
		protected var _boundingBoxData:BoundingBoxData;
		/**
		 * @private
		 */
		protected var _rawDisplay:Object;
		/**
		 * @private
		 */
		protected var _meshDisplay:Object;
		/**
		 * @private
		 */
		protected var _display:Object;
		/**
		 * @private
		 */
		dragonBones_internal var _childArmature:Armature;
		/**
		 * @private BoneTimelineState
		 */
		dragonBones_internal var _cachedFrameIndices:Vector.<int>;
		/**
		 * @private
		 */
		public function Slot(self:Slot)
		{
			super(self);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			const disposeDisplayList:Vector.<Object> = new Vector.<Object>();
			for (var i:uint = 0, l:uint = _displayList.length; i < l; ++i) 
			{
				var eachDisplay:Object = _displayList[i];
				if (
					eachDisplay != _rawDisplay && eachDisplay != _meshDisplay &&
					disposeDisplayList.indexOf(eachDisplay) < 0
				)
				{
					disposeDisplayList.push(eachDisplay);
				}
			}
			
			for (i = 0, l = disposeDisplayList.length; i < l; ++i) 
			{
				eachDisplay = disposeDisplayList[i];
				if (eachDisplay is Armature)
				{
					(eachDisplay as Armature).dispose();
				}
				else
				{
					_disposeDisplay(eachDisplay);
				}
			}
			
			if (_meshDisplay && _meshDisplay != _rawDisplay)
			{
				_disposeDisplay(_meshDisplay);
			}
			
			if (_rawDisplay)
			{
				_disposeDisplay(_rawDisplay);
			}
			
			displayController = null;
			
			_displayDirty = false;
			_zOrderDirty = false;
			_blendModeDirty = false;
			_colorDirty = false;
			_meshDirty = false;
			_originalDirty = false;
			_transformDirty = false;
			_updateState = -1;
			_blendMode = BlendMode.Normal;
			_displayIndex = -1;
			_zOrder = 0;
			_pivotX = 0.0;
			_pivotY = 0.0;
			_localMatrix.identity();
			_colorTransform.alphaMultiplier = 1.0;
			_colorTransform.redMultiplier = 1.0;
			_colorTransform.greenMultiplier = 1.0;
			_colorTransform.blueMultiplier = 1.0;
			_colorTransform.alphaOffset = 0;
			_colorTransform.redOffset = 0;
			_colorTransform.greenOffset = 0;
			_colorTransform.blueOffset = 0;
			_ffdVertices.length = 0;
			_displayList.length = 0;
			_textureDatas.length = 0;
			_replacedDisplayDatas.length = 0;
			_meshBones.length = 0;
			_skinSlotData = null;
			_displayData = null;
			_replacedDisplayData = null;
			_textureData = null;
			_meshData = null;
			_boundingBoxData = null;
			_rawDisplay = null;
			_meshDisplay = null;
			_display = null;
			_childArmature = null;
			_cachedFrameIndices = null;
		}
		/**
		 * @private
		 */
		protected function _initDisplay(value:Object):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _disposeDisplay(value:Object):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _onUpdateDisplay():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _addDisplay():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _replaceDisplay(value:Object):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _removeDisplay():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _updateZOrder():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		dragonBones_internal function _updateVisible():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _updateBlendMode():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _updateColor():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _updateFilters():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _updateFrame():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _updateMesh():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _updateTransform(isSkinnedMesh: Boolean):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		/**
		 * @private
		 */
		protected function _isMeshBonesUpdate():Boolean
		{
			for (var i:uint = 0, l:uint = _meshBones.length; i < l; ++i)
			{
				if (_meshBones[i]._transformDirty != 0)
				{
					return true;
				}
			}
			
			return false;
		}
		/**
		 * @private
		 */
		protected function _updateDisplayData(): void 
		{
			const prevDisplayData:DisplayData = _displayData;
			const prevReplaceDisplayData:DisplayData = _replacedDisplayData;
			const prevTextureData:TextureData = _textureData;
			const prevMeshData:MeshData = _meshData;
			const currentDisplay:Object = _displayIndex >= 0 && _displayIndex < _displayList.length ? _displayList[_displayIndex] : null;
			
			if (_displayIndex >= 0 && _displayIndex < _skinSlotData.displays.length) 
			{
				_displayData = _skinSlotData.displays[_displayIndex];
			}
			else 
			{
				_displayData = null;
			}
			
			if (_displayIndex >= 0 && _displayIndex < _replacedDisplayDatas.length) 
			{
				_replacedDisplayData = _replacedDisplayDatas[_displayIndex];
			}
			else 
			{
				_replacedDisplayData = null;
			}
			
			if (_displayData !== prevDisplayData || _replacedDisplayData !== prevReplaceDisplayData || _display !== currentDisplay) 
			{
				const currentDisplayData:DisplayData = _replacedDisplayData ? _replacedDisplayData : _displayData;
				if (currentDisplayData && (currentDisplay === _rawDisplay || currentDisplay === _meshDisplay)) 
				{
					if (_replacedDisplayData != null)
					{
						_textureData = _replacedDisplayData.texture;
					}
					else if (_displayIndex < _textureDatas.length && _textureDatas[_displayIndex] != null)
					{
						_textureData = _textureDatas[_displayIndex];
					}
					else
					{
						_textureData = _displayData.texture;
					}
					
					if (currentDisplay === _meshDisplay) 
					{
						if (_replacedDisplayData && _replacedDisplayData.mesh) 
						{
							_meshData = _replacedDisplayData.mesh;
						}
						else 
						{
							_meshData = _displayData.mesh;
						}
					}
					else 
					{
						_meshData = null;
					}
					
					// Update pivot offset.
					if (_meshData) 
					{
						_pivotX = 0.0;
						_pivotY = 0.0;
					}
					else if (_textureData) 
					{
						const scale:Number = _armature.armatureData.scale;
						_pivotX = currentDisplayData.pivot.x;
						_pivotY = currentDisplayData.pivot.y;
						
						if (currentDisplayData.isRelativePivot) 
						{
							const rect:Rectangle = _textureData.frame ? _textureData.frame : _textureData.region;
							var width:Number = rect.width * scale;
							var height:Number = rect.height * scale;
							
							if (_textureData.rotated) 
							{
								width = rect.height;
								height = rect.width;
							}
							
							_pivotX *= width;
							_pivotY *= height;
						}
						
						if (_textureData.frame) 
						{
							_pivotX += _textureData.frame.x * scale;
							_pivotY += _textureData.frame.y * scale;
						}
					}
					else 
					{
						_pivotX = 0.0;
						_pivotY = 0.0;
					}
					
					if (
						_displayData && currentDisplayData !== _displayData &&
						(!_meshData || _meshData !== _displayData.mesh)
					) 
					{
						_displayData.transform.toMatrix(_helpMatrix);
						_helpMatrix.invert();
						Transform.transformPoint(_helpMatrix, 0.0, 0.0, _helpPoint);
						_pivotX -= _helpPoint.x;
						_pivotY -= _helpPoint.y;
						
						currentDisplayData.transform.toMatrix(_helpMatrix);
						_helpMatrix.invert();
						Transform.transformPoint(_helpMatrix, 0.0, 0.0, _helpPoint);
						_pivotX += _helpPoint.x;
						_pivotY += _helpPoint.y;
					}
					
					if (_meshData !== prevMeshData) // Update mesh bones and ffd vertices.
					{
						if (_meshData && _displayData && _meshData === _displayData.mesh) 
						{
							if (_meshData.skinned) 
							{
								_meshBones.length = _meshData.bones.length;
								
								for (var i:uint = 0, l:uint = _meshBones.length; i < l; ++i) 
								{
									_meshBones[i] = _armature.getBone(_meshData.bones[i].name);
								}
								
								var ffdVerticesCount:uint = 0;
								for (i = 0, l = _meshData.boneIndices.length; i < l; ++i) 
								{
									ffdVerticesCount += _meshData.boneIndices[i].length;
								}
								
								_ffdVertices.length = ffdVerticesCount * 2;
							}
							else 
							{
								_meshBones.length = 0;
								_ffdVertices.length = _meshData.vertices.length;
							}
							
							for (i = 0, l = _ffdVertices.length; i < l; ++i) 
							{
								_ffdVertices[i] = 0.0;
							}
							
							_meshDirty = true;
						}
						else 
						{
							_meshBones.length = 0;
							_ffdVertices.length = 0;
						}
					}
					else if (_textureData != prevTextureData)
					{
						_meshDirty = true;
					}
				}
				else 
				{
					_textureData = null;
					_meshData = null;
					_pivotX = 0.0;
					_pivotY = 0.0;
					_meshBones.length = 0;
					_ffdVertices.length = 0;
				}
				
				_displayDirty = true;
				_originalDirty = true;
				
				if (_displayData) 
				{
					origin = _displayData.transform;
				}
				else if (_replacedDisplayData) 
				{
					origin = _replacedDisplayData.transform;
				}
			}
			
			// Update bounding box data.
			if (_replacedDisplayData) 
			{
				_boundingBoxData = _replacedDisplayData.boundingBox;
			}
			else if (_displayData) 
			{
				_boundingBoxData = _displayData.boundingBox;
			}
			else 
			{
				_boundingBoxData = null;
			}
		}
		/**
		 * @private
		 */
		protected function _updateDisplay():void
		{	
			const prevDisplay:Object = _display || _rawDisplay;
			const prevChildArmature:Armature = _childArmature;
			
			if (_displayIndex >= 0 && _displayIndex < _displayList.length)
			{
				_display = _displayList[_displayIndex];
				if (_display is Armature)
				{
					_childArmature = _display as Armature;
					_display = _childArmature.display;
				}
				else
				{
					_childArmature = null;
				}
			}
			else
			{
				_display = null;
				_childArmature = null;
			}
			
			const currentDisplay:Object = _display || _rawDisplay;
			if (currentDisplay != prevDisplay)
			{
				_onUpdateDisplay();
				
				if (prevDisplay)
				{
					_replaceDisplay(prevDisplay);
				}
				else
				{
					_addDisplay();
				}
				
				_blendModeDirty = true;
				_colorDirty = true;
			}
			
			// Update frame.
			if (currentDisplay == _rawDisplay || currentDisplay == _meshDisplay)
			{
				_updateFrame();
			}
			
			// Update child armature.
			if (_childArmature != prevChildArmature)
			{
				if (prevChildArmature)
				{
					prevChildArmature._parent = null; // Update child armature parent.
					prevChildArmature.clock = null;
					if (prevChildArmature.inheritAnimation)
					{
						prevChildArmature.animation.reset();
					}
				}
				
				if (_childArmature)
				{
					_childArmature._parent = this; // Update child armature parent.
					_childArmature.clock = _armature.clock;
					if (_childArmature.inheritAnimation)
					{
						if (_childArmature.cacheFrameRate == 0) // Set child armature frameRate.
						{
							const cacheFrameRate:uint = _armature.cacheFrameRate;
							if (cacheFrameRate != 0) 
							{
								_childArmature.cacheFrameRate = cacheFrameRate;
							}
						}
						
						const actions:Vector.<ActionData> = _skinSlotData.slot.actions.length > 0? _skinSlotData.slot.actions: _childArmature.armatureData.actions;
						if (actions.length > 0) 
						{
							for (var i:uint = 0, l:uint = actions.length; i < l; ++i) {
								_childArmature._bufferAction(actions[i]);
							}
						} 
						else 
						{
							_childArmature.animation.play();
						}
					}
				}
			}
		}
		/**
		 * @private
		 */
		protected function _updateLocalTransformMatrix():void
		{
			if (origin) 
			{
				global.copyFrom(origin).add(offset).toMatrix(_localMatrix);
			}
			else 
			{
				global.copyFrom(offset).toMatrix(_localMatrix);
			}
		}
		/**
		 * @private
		 */
		protected function _updateGlobalTransformMatrix():void
		{
			globalTransformMatrix.copyFrom(_localMatrix);
			globalTransformMatrix.concat(_parent.globalTransformMatrix);
			global.fromMatrix(globalTransformMatrix);
		}
		/**
		 * @private
		 */
		dragonBones_internal function _init(skinSlotData: SkinSlotData, rawDisplay: Object, meshDisplay: Object): void {
			if (_skinSlotData) 
			{
				return;
			}
			
			_skinSlotData = skinSlotData;
			
			const slotData:SlotData = _skinSlotData.slot;
			
			name = slotData.name;
			
			_zOrder = slotData.zOrder;
			_blendMode = slotData.blendMode;
			_colorTransform.alphaMultiplier = slotData.color.alphaMultiplier;
			_colorTransform.redMultiplier = slotData.color.redMultiplier;
			_colorTransform.greenMultiplier = slotData.color.greenMultiplier;
			_colorTransform.blueMultiplier = slotData.color.blueMultiplier;
			_colorTransform.alphaOffset = slotData.color.alphaOffset;
			_colorTransform.redOffset = slotData.color.redOffset;
			_colorTransform.greenOffset = slotData.color.greenOffset;
			_colorTransform.blueOffset = slotData.color.blueOffset;
			_rawDisplay = rawDisplay;
			_meshDisplay = meshDisplay;
			_textureDatas.length = _skinSlotData.displays.length;
			
			_blendModeDirty = true;
			_colorDirty = true;
		}
		/**
		 * @private
		 */
		override dragonBones_internal function _setArmature(value:Armature):void
		{
			if (_armature === value) 
			{
				return;
			}
			
			if (_armature) 
			{
				_armature._removeSlotFromSlotList(this);
			}
			
			_armature = value;
			
			_onUpdateDisplay();
			
			if (_armature) 
			{
				_armature._addSlotToSlotList(this);
				_addDisplay();
			}
			else 
			{
				_removeDisplay();
			}
		}
		/**
		 * @private
		 */
		dragonBones_internal function _update(cacheFrameIndex:int):void
		{
			_updateState = -1;
			
			if (_displayDirty) 
			{
				_displayDirty = false;
				_updateDisplay();
			}
			
			if (_zOrderDirty) 
			{
				_zOrderDirty = false;
				_updateZOrder();
			}
			
			if (!_display) 
			{
				return;
			}
			
			if (_blendModeDirty) 
			{
				_blendModeDirty = false;
				_updateBlendMode();
			}
			
			if (_colorDirty) 
			{
				_colorDirty = false;
				_updateColor();
			}
			
			if (_originalDirty) 
			{
				_originalDirty = false;
				_transformDirty = true;
				_updateLocalTransformMatrix();
			}
			
			if (cacheFrameIndex >= 0 && _cachedFrameIndices) 
			{
				const cachedFrameIndex:int = _cachedFrameIndices[cacheFrameIndex];
				if (cachedFrameIndex >= 0 && _cachedFrameIndex === cachedFrameIndex) // Same cache.
				{
					_transformDirty = false;
				}
				else if (cachedFrameIndex >= 0) // Has been Cached.
				{
					_transformDirty = true;
					_cachedFrameIndex = cachedFrameIndex;
				}
				else if (_transformDirty || _parent._transformDirty !== 0) // Dirty.
				{
					_transformDirty = true;
					_cachedFrameIndex = -1;
				}
				else if (_cachedFrameIndex >= 0) // Same cache, but not set index yet.
				{
					_transformDirty = false;
					_cachedFrameIndices[cacheFrameIndex] = _cachedFrameIndex;
				}
				else // Dirty.
				{
					_transformDirty = true;
					_cachedFrameIndex = -1;
				}
			}
			else if (_transformDirty || _parent._transformDirty !== 0) // Dirty.
			{
				cacheFrameIndex = -1;
				_transformDirty = true;
				_cachedFrameIndex = -1;
			}
			
			if (_meshData && _displayData && _meshData === _displayData.mesh) 
			{
				if (_meshDirty || (_meshData.skinned && _isMeshBonesUpdate())) 
				{
					_meshDirty = false;
					
					_updateMesh();
				}
				
				if (_meshData.skinned) 
				{
					if (_transformDirty) 
					{
						_transformDirty = false;
						_updateTransform(true);
					}
					
					return;
				}
			}
			
			if (_transformDirty) 
			{
				_transformDirty = false;
				
				if (_cachedFrameIndex < 0) 
				{
					_updateGlobalTransformMatrix();
					
					if (cacheFrameIndex >= 0) 
					{
						_cachedFrameIndex = _cachedFrameIndices[cacheFrameIndex] = _armature._armatureData.setCacheFrame(globalTransformMatrix, global);
					}
				}
				else 
				{
					_armature._armatureData.getCacheFrame(globalTransformMatrix, global, _cachedFrameIndex);
				}
				
				_updateTransform(false);
				
				_updateState = 0;
			}
		}
		/**
		 * @private
		 */
		dragonBones_internal function _updateTransformAndMatrix(): void 
		{
			if (_updateState < 0) 
			{
				_updateState = 0;
				_updateLocalTransformMatrix();
				_updateGlobalTransformMatrix();
			}
		}
		/**
		 * @private
		 */
		dragonBones_internal function _setDisplayList(value:Vector.<Object>):Boolean
		{
			if (value && value.length)
			{
				if (_displayList.length != value.length)
				{
					_displayList.length = value.length;
				}
				
				for (var i:uint = 0, l:uint = value.length; i < l; ++i)
				{
					const eachDisplay:Object = value[i];
					if (eachDisplay && eachDisplay != _rawDisplay && eachDisplay != _meshDisplay && 
						!(eachDisplay is Armature) && _displayList.indexOf(eachDisplay) < 0)
					{
						_initDisplay(eachDisplay);
					}
					
					_displayList[i] = eachDisplay;
				}
			}
			else if (_displayList.length > 0)
			{
				_displayList.length = 0;
			}
			
			if (_displayIndex >= 0 && _displayIndex < _displayList.length)
			{
				_displayDirty = _display != _displayList[_displayIndex];
			}
			else
			{
				_displayDirty = _display != null;
			}
			
			_updateDisplayData();
			
			return _displayDirty;
		}
		/**
		 * @private
		 */
		dragonBones_internal function _setDisplayIndex(value:int):Boolean
		{
			if (_displayIndex == value)
			{
				return false;
			}
			
			_displayIndex = value;
			_displayDirty = true;
			
			_updateDisplayData();
			
			return true;
		}
		/**
		 * @private
		 */
		dragonBones_internal function _setZorder(value: Number): Boolean 
		{
			if (_zOrder === value) 
			{
				//return false;
			}
			
			_zOrder = value;
			_zOrderDirty = true;
			
			return true;
		}
		/**
		 * @private
		 */
		dragonBones_internal function _setColor(value:ColorTransform):Boolean
		{
			_colorTransform.alphaMultiplier = value.alphaMultiplier;
			_colorTransform.redMultiplier = value.redMultiplier;
			_colorTransform.greenMultiplier = value.greenMultiplier;
			_colorTransform.blueMultiplier = value.blueMultiplier;
			_colorTransform.alphaOffset = value.alphaOffset;
			_colorTransform.redOffset = value.redOffset;
			_colorTransform.greenOffset = value.greenOffset;
			_colorTransform.blueOffset = value.blueOffset;
			
			_colorDirty = true;
			
			return true;
		}
		/**
		 * @language zh_CN
		 * 判断指定的点是否在插槽的自定义包围盒内。
		 * @param x 点的水平坐标。（骨架内坐标系）
		 * @param y 点的垂直坐标。（骨架内坐标系）
		 * @version DragonBones 5.0
		 */
		public function containsPoint(x: Number, y: Number): Boolean 
		{
			if (!_boundingBoxData) 
			{
				return false;
			}
			
			_updateTransformAndMatrix();
			
			_helpMatrix.copyFrom(globalTransformMatrix);
			_helpMatrix.invert();
			Transform.transformPoint(_helpMatrix, x, y, _helpPoint);
			
			return _boundingBoxData.containsPoint(_helpPoint.x, _helpPoint.y);
		}
		/**
		 * @language zh_CN
		 * 判断指定的线段与插槽的自定义包围盒是否相交。
		 * @param xA 线段起点的水平坐标。（骨架内坐标系）
		 * @param yA 线段起点的垂直坐标。（骨架内坐标系）
		 * @param xB 线段终点的水平坐标。（骨架内坐标系）
		 * @param yB 线段终点的垂直坐标。（骨架内坐标系）
		 * @param intersectionPointA 线段从起点到终点与包围盒相交的第一个交点。（骨架内坐标系）
		 * @param intersectionPointB 线段从终点到起点与包围盒相交的第一个交点。（骨架内坐标系）
		 * @param normalRadians 碰撞点处包围盒切线的法线弧度。 [x: 第一个碰撞点处切线的法线弧度, y: 第二个碰撞点处切线的法线弧度]
		 * @returns 相交的情况。 [-1: 不相交且线段在包围盒内, 0: 不相交, 1: 相交且有一个交点且终点在包围盒内, 2: 相交且有一个交点且起点在包围盒内, 3: 相交且有两个交点, N: 相交且有 N 个交点]
		 * @version DragonBones 5.0
		 */
		public function intersectsSegment(
			xA: Number, yA: Number, xB: Number, yB: Number,
			intersectionPointA: Point = null,
			intersectionPointB: Point = null,
			normalRadians: Point = null
		): int {
			if (!_boundingBoxData) 
			{
				return 0;
			}
			
			_updateTransformAndMatrix();
			
			_helpMatrix.copyFrom(globalTransformMatrix);
			_helpMatrix.invert();
			Transform.transformPoint(_helpMatrix, xA, yA, _helpPoint);
			xA = _helpPoint.x;
			yA = _helpPoint.y;
			Transform.transformPoint(_helpMatrix, xB, yB, _helpPoint);
			xB = _helpPoint.x;
			yB = _helpPoint.y;
			
			const intersectionCount:int = _boundingBoxData.intersectsSegment(xA, yA, xB, yB, intersectionPointA, intersectionPointB, normalRadians);
			if (intersectionCount > 0) 
			{
				if (intersectionCount === 1 || intersectionCount === 2) 
				{
					if (intersectionPointA) 
					{
						Transform.transformPoint(globalTransformMatrix, intersectionPointA.x, intersectionPointA.y, intersectionPointA);
						if (intersectionPointB) 
						{
							intersectionPointB.x = intersectionPointA.x;
							intersectionPointB.y = intersectionPointA.y;
						}
					}
					else if (intersectionPointB) 
					{
						Transform.transformPoint(globalTransformMatrix, intersectionPointB.x, intersectionPointB.y, intersectionPointB);
					}
				}
				else 
				{
					if (intersectionPointA) 
					{
						Transform.transformPoint(globalTransformMatrix, intersectionPointA.x, intersectionPointA.y, intersectionPointA);
					}
					
					if (intersectionPointB) 
					{
						Transform.transformPoint(globalTransformMatrix, intersectionPointB.x, intersectionPointB.y, intersectionPointB);
					}
				}
				
				if (normalRadians) 
				{
					Transform.transformPoint(globalTransformMatrix, Math.cos(normalRadians.x), Math.sin(normalRadians.x), _helpPoint, true);
					normalRadians.x = Math.atan2(_helpPoint.y, _helpPoint.x);
					
					Transform.transformPoint(globalTransformMatrix, Math.cos(normalRadians.y), Math.sin(normalRadians.y), _helpPoint, true);
					normalRadians.y = Math.atan2(_helpPoint.y, _helpPoint.x);
				}
			}
			
			return intersectionCount;
		}
		/**
		 * @language zh_CN
		 * 在下一帧更新显示对象的状态。
		 * @version DragonBones 4.5
		 */
		public function invalidUpdate():void
		{
			_displayDirty = true;
			_transformDirty = true;
		}
		/**
		 * @private
		 */
		public function get skinSlotData(): SkinSlotData 
		{
			return _skinSlotData;
		}
		/**
		 * @language zh_CN
		 * 包含显示对象或子骨架的显示列表。
		 * @version DragonBones 3.0
		 */
		public function get boundingBoxData(): BoundingBoxData 
		{
			return _boundingBoxData;
		}
		/**
		 * @private
		 */
		public function get rawDisplay():Object
		{
			return _rawDisplay;
		}
		/**
		 * @private
		 */
		public function get meshDisplay():Object
		{
			return _meshDisplay;
		}
		/**
		 * @language zh_CN
		 * 此时显示的显示对象在显示列表中的索引。
		 * @version DragonBones 4.5
		 */
		public function get displayIndex():int
		{
			return _displayIndex;
		}
		public function set displayIndex(value:int):void
		{
			if (_setDisplayIndex(value))
			{
				_update(-1);
			}
		}
		/**
		 * @language zh_CN
		 * 包含显示对象或子骨架的显示列表。
		 * @version DragonBones 3.0
		 */
		public function get displayList():Vector.<Object>
		{
			return _displayList.concat();
		}
		public function set displayList(value:Vector.<Object>):void
		{
			const backupDisplayList:Vector.<Object> = _displayList.concat();
			const disposeDisplayList:Vector.<Object> = new Vector.<Object>();
			
			if (_setDisplayList(value))
			{
				_update(-1);
			}
			
			for (var i:uint = 0, l:uint = backupDisplayList.length; i < l; ++i) 
			{
				var eachDisplay:Object = backupDisplayList[i];
				if (eachDisplay && eachDisplay != _rawDisplay && _displayList.indexOf(eachDisplay) < 0)
				{
					if (disposeDisplayList.indexOf(eachDisplay) < 0)
					{
						disposeDisplayList.push(eachDisplay);
					}
				}
			}
			
			for (i = 0, l = disposeDisplayList.length; i < l; ++i) 
			{
				eachDisplay = disposeDisplayList[i];
				if (eachDisplay is Armature)
				{
					(eachDisplay as Armature).dispose();
				}
				else
				{
					_disposeDisplay(eachDisplay);
				}
			}
		}
		/**
		 * @language zh_CN
		 * 此时显示的显示对象。
		 * @version DragonBones 3.0
		 */
		public function get display():Object
		{
			return _display;
		}
		public function set display(value:Object):void
		{
			if (_display === value)
			{
				return;
			}
			
			const displayListLength:uint = _displayList.length;
			if (_displayIndex < 0 && displayListLength === 0)  // Emprty
			{
				_displayIndex = 0;
			}
			
			if (_displayIndex < 0)
			{
				return;
			}
			else
			{
				const replaceDisplayList:Vector.<Object> = displayList; // copy
				if (displayListLength <= _displayIndex)
				{
					replaceDisplayList.length = _displayIndex + 1;
				}
				
				replaceDisplayList[_displayIndex] = value;
				displayList = replaceDisplayList;
			}
		}
		/**
		 * @language zh_CN
		 * 此时显示的子骨架。
		 * @see dragonBones.Armature
		 * @version DragonBones 3.0
		 */
		public function get childArmature():Armature
		{
			return _childArmature;
		}
		public function set childArmature(value:Armature):void
		{
			if (_childArmature === value)
			{
				return;
			}

			display = value;
		}
	}
}