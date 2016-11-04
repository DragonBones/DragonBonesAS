package dragonBones
{
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import dragonBones.core.DragonBones;
	import dragonBones.core.TransformObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.geom.Transform;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.objects.SlotTimelineData;
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
		private static const _helpPoint:Point = new Point();
		
		/**
		 * @private
		 */
		protected static const _helpMatrix:Matrix = new Matrix();
		
		/**
		 * @language zh_CN
         * 子骨架是否继承父骨架的动画。 [true: 继承, false: 不继承]
         * @default true
		 * @version DragonBones 4.5
		 */
		public var inheritAnimation:Boolean;
		
		/**
		 * @language zh_CN
         * 显示对象受到控制的对象，应设置为动画状态的名称或组名称，设置为 null 则表示受所有的动画状态控制。
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
		dragonBones_internal var _blendIndex:int;
		
		/**
		 * @private
		 */
		dragonBones_internal var _zOrder:int;
		
		/**
		 * @private
		 */
		dragonBones_internal var _pivotX:Number;
		
		/**
		 * @private
		 */
		dragonBones_internal var _pivotY:Number;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _displayDataSet:SlotDisplayDataSet;
		
		/**
		 * @private
		 */
		dragonBones_internal var _meshData:MeshData;
		
		/**
		 * @private
		 */
		dragonBones_internal var _childArmature:Armature;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _rawDisplay:*;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _meshDisplay:*;
		
		/**
		 * @private BoneTimelineState
		 */
		dragonBones_internal var _cacheFrames:Vector.<Matrix>;
		
		/**
		 * @private SlotTimelineState
		 */
		dragonBones_internal const _colorTransform:ColorTransform = new ColorTransform();
		
		/**
		 * @private FFDTimelineState
		 */
		dragonBones_internal const _ffdVertices:Vector.<Number> = new Vector.<Number>(0, true);
		
		/**
		 * @private Factory
		 */
		dragonBones_internal const _replacedDisplayDataSet:Vector.<DisplayData> = new Vector.<DisplayData>(0, true);
		
		/**
		 * @private
		 */
		dragonBones_internal var _zOrderDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _displayDirty:Boolean;
		
		/**
		 * @private SlotTimelineState
		 */
		dragonBones_internal var _colorDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _blendModeDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _originDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _transformDirty:Boolean;
		
		/**
		 * @private FFDTimelineState
		 */
		dragonBones_internal var _ffdDirty:Boolean;
		
		/**
		 * @private
		 */
		protected var _displayIndex:int;
		
		/**
		 * @private
		 */
		protected var _blendMode:int;
		
		/**
		 * @private
		 */
		protected var _display:*;
		
		/**
		 * @private
		 */
		protected const _localMatrix:Matrix = new Matrix();
		
		/**
		 * @private
		 */
		protected const _displayList:Vector.<*> = new Vector.<*>(0, true);
		
		/**
		 * @private
		 */
		protected const _meshBones:Vector.<Bone> = new Vector.<Bone>(0, true);
		
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
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			const disposeDisplayList:Vector.<*> = new Vector.<*>();
			for each (var eachDisplay:* in _displayList)
			{
				if (
					eachDisplay != _rawDisplay && eachDisplay != _meshDisplay &&
					disposeDisplayList.indexOf(eachDisplay) < 0
				)
				{
					disposeDisplayList.push(eachDisplay);
				}
			}
			
			for each (eachDisplay in disposeDisplayList)
			{
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
			
			inheritAnimation = true;
			displayController = null;
			
			_colorDirty = false;
			_ffdDirty = false;
			_blendIndex = 0;
			_zOrder = 0;
			_pivotX = 0;
			_pivotY = 0;
			_displayDataSet = null;
			_meshData = null;
			_childArmature = null;
			_rawDisplay = null;
			_meshDisplay = null;
			_cacheFrames = null;
			_colorTransform.alphaMultiplier = 1;
			_colorTransform.redMultiplier = 1;
			_colorTransform.greenMultiplier = 1;
			_colorTransform.blueMultiplier = 1;
			_colorTransform.alphaOffset = 0;
			_colorTransform.redOffset = 0;
			_colorTransform.greenOffset = 0;
			_colorTransform.blueOffset = 0;
			
			if (_ffdVertices.length)
			{
				_ffdVertices.fixed = false;
				_ffdVertices.length = 0;
				_ffdVertices.fixed = true;
			}
			
			if (_replacedDisplayDataSet.length)
			{
				_replacedDisplayDataSet.fixed = false;
				_replacedDisplayDataSet.length = 0;
				_replacedDisplayDataSet.fixed = true;
			}
			
			_displayDirty = false;
			_blendModeDirty = false;
			_originDirty = false;
			_transformDirty = false;
			_displayIndex = 0;
			_blendMode = DragonBones.BLEND_MODE_NORMAL;
			_display = null;
			_localMatrix.identity();
			
			if (_displayList.length)
			{
				_displayList.fixed = false;
				_displayList.length = 0;
				_displayList.fixed = true;
			}
			
			if (_meshBones.length)
			{
				_meshBones.fixed = false;
				_meshBones.length = 0;
				_meshBones.fixed = true;
			}
		}
		
		// Abstract method
		
		/**
		 * @private
		 */
		protected function _initDisplay(value:*):void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		protected function _disposeDisplay(value:*):void
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
		protected function _replaceDisplay(value:*):void
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
		protected function _updateTransform():void
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
		}
		
		/**
		 * @private
		 */
		[inline]
		final private function _isMeshBonesUpdate():Boolean
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
		protected function _updatePivot(rawDisplayData:DisplayData, currentDisplayData:DisplayData, currentTextureData:TextureData):void
		{
			const isReplaceDisplay:Boolean = rawDisplayData && rawDisplayData != currentDisplayData && (!_meshData || _meshData != rawDisplayData.mesh);
			if (_meshData && _display == _meshDisplay)
			{
				_pivotX = 0;
				_pivotY = 0;
			}
			else
			{
				const scale:Number = this._armature.armatureData.scale;
				_pivotX = currentDisplayData.pivot.x;
				_pivotY = currentDisplayData.pivot.y;
				
				if (currentDisplayData.isRelativePivot)
				{
					const rect:Rectangle = currentTextureData.frame || currentTextureData.region;
					
					var width:Number = rect.width * scale;
					var height:Number = rect.height * scale;
					if (currentTextureData.rotated)
					{
						width = rect.height;
						height = rect.width;
					}
					
					this._pivotX *= width;
					this._pivotY *= height;
				}
				
				if (currentTextureData.frame)
				{
					this._pivotX += currentTextureData.frame.x * scale;
					this._pivotY += currentTextureData.frame.y * scale;
				}
			}
			
			if (isReplaceDisplay) 
			{
				rawDisplayData.transform.toMatrix(_helpMatrix);
				_helpMatrix.invert();
				Transform.transformPoint(_helpMatrix, 0, 0, _helpPoint);
				_pivotX -= _helpPoint.x;
				_pivotY -= _helpPoint.y;
				
				currentDisplayData.transform.toMatrix(_helpMatrix);
				_helpMatrix.invert();
				Transform.transformPoint(_helpMatrix, 0, 0, _helpPoint);
				_pivotX += Slot._helpPoint.x;
				_pivotY += Slot._helpPoint.y;
			}
		}
		
		/**
		 * @private
		 */
		protected function _updateDisplay():void
		{	
			const prevDisplay:* = _display || _rawDisplay;
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
			
			const currentDisplay:* = _display || _rawDisplay;
			
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
			
			// Update origin.
			if (_displayDataSet && _displayIndex >= 0 && _displayIndex < _displayDataSet.displays.length)
			{
				this.origin.copyFrom(_displayDataSet.displays[_displayIndex].transform);
				_originDirty = true;
			}
			
			// Update meshData.
			_updateMeshData(false);
			
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
					if (inheritAnimation)
					{
						prevChildArmature.animation.reset();
					}
				}
				
				if (_childArmature)
				{
					_childArmature._parent = this; // Update child armature parent.
					if (inheritAnimation)
					{
						if (_childArmature.cacheFrameRate == 0) // Set child armature frameRate.
						{
							const cacheFrameRate:uint = this._armature.cacheFrameRate;
							if (cacheFrameRate != 0) 
							{
								_childArmature.cacheFrameRate = cacheFrameRate;
							}
						}
						
						const slotData:SlotData = this._armature.armatureData.getSlot(this.name);
						const actions:Vector.<ActionData> = slotData.actions.length > 0? slotData.actions: _childArmature.armatureData.actions;
						if (actions.length > 0) 
						{
							for (var i:uint = 0, l:uint = actions.length; i < l; ++i) 
							{
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
			this.global.copyFrom(this.origin).add(this.offset).toMatrix(_localMatrix);
		}
		
		/**
		 * @private
		 */
		protected function _updateGlobalTransformMatrix():void
		{
			this.globalTransformMatrix.copyFrom(_localMatrix);
			this.globalTransformMatrix.concat(this._parent.globalTransformMatrix);
			this.global.fromMatrix(this.globalTransformMatrix);
		}
		
		/**
		 * @inheritDoc
		 */
		override dragonBones_internal function _setArmature(value:Armature):void
		{
			this._armature = value;
			this._armature._addSlotToSlotList(this);
			
			_onUpdateDisplay(); // Update renderDisplay.
			_addDisplay();
		}
		
		/**
		 * @private Armature
		 */
		dragonBones_internal function _updateMeshData(isTimelineUpdate:Boolean):void
		{
			const prevMeshData:MeshData = _meshData;
			var rawMeshData:MeshData = null;
			
			if (_display && _display == _meshDisplay && _displayIndex >= 0)
			{
				rawMeshData = (_displayDataSet && _displayIndex < _displayDataSet.displays.length) ? _displayDataSet.displays[_displayIndex].mesh : null;
				const replaceDisplayData:DisplayData = (_displayIndex < _replacedDisplayDataSet.length) ? _replacedDisplayDataSet[_displayIndex] : null;
				const replaceMeshData:MeshData = replaceDisplayData? replaceDisplayData.mesh : null;
				_meshData = replaceMeshData || rawMeshData;
			}
			else
			{
				_meshData = null;
			}
			
			if (_meshData != prevMeshData)
			{
				if (_meshData && _meshData == rawMeshData)
				{
					var i:uint = 0, l:uint = 0;
					
					_meshBones.fixed = false;
					_ffdVertices.fixed = false;
					
					if (_meshData.skinned)
					{
						_meshBones.length = _meshData.bones.length;
						
						for (i = 0, l = _meshBones.length; i < l; ++i)
						{
							_meshBones[i] = this._armature.getBone(_meshData.bones[i].name);
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
						_ffdVertices[i] = 0;
					}
					
					_meshBones.fixed = true;
					_ffdVertices.fixed = true;
					_ffdDirty = true;
				}
				else
				{
					_meshBones.fixed = false;
					_meshBones.length = 0;
					_meshBones.fixed = true;
					
					_ffdVertices.fixed = false;
					_ffdVertices.length = 0;
					_ffdVertices.fixed = true;
				}
				
				if (isTimelineUpdate)
				{
					_armature.animation._updateFFDTimelineStates();
				}
			}
		}
		
		/**
		 * @private Armature
		 */
		dragonBones_internal function _update(cacheFrameIndex:int):void
		{
			_blendIndex = 0;
			
			if (_zOrderDirty)
			{
				_zOrderDirty = false;
				_updateZOrder();
			}
			
			if (_displayDirty)
			{
				_displayDirty = false;
				_updateDisplay();
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
			
			if (_meshData)
			{
				if (_ffdDirty || (_meshData.skinned && _isMeshBonesUpdate()))
				{
					_ffdDirty = false;
					
					_updateMesh();
				}
				
				if (_meshData.skinned)
				{
					return;
				}
			}
			
			if (_originDirty)
			{
				_originDirty = false;
				_transformDirty = true;
				_updateLocalTransformMatrix();
			}
			
			if (cacheFrameIndex >= 0)
			{
				const cacheFrame:Matrix = _cacheFrames[cacheFrameIndex];
				
				if (this.globalTransformMatrix == cacheFrame) // Same cache
				{
					_transformDirty = false;
				}
				else if (cacheFrame) // has been Cached
				{
					_transformDirty = true;
					this.globalTransformMatrix = cacheFrame;
				}
				else if (_transformDirty || this._parent._transformDirty != 0)
				{
					_transformDirty = true;
					this.globalTransformMatrix = this._globalTransformMatrix;
				}
				else if (this.globalTransformMatrix != this._globalTransformMatrix) // Same cache but not cached yet
				{
					_transformDirty = false;
					_cacheFrames[cacheFrameIndex] = this.globalTransformMatrix;
				}
				else
				{
					_transformDirty = true;
					this.globalTransformMatrix = this._globalTransformMatrix;
				}
			}
			else if (_transformDirty || this._parent._transformDirty != 0)
			{
				_transformDirty = true;
				this.globalTransformMatrix = this._globalTransformMatrix;
			}
			
			if (_transformDirty)
			{
				_transformDirty = false;
				
				if (this.globalTransformMatrix == this._globalTransformMatrix)
				{
					_updateGlobalTransformMatrix();
					
					if (cacheFrameIndex >= 0 && !_cacheFrames[cacheFrameIndex])
					{
						this.globalTransformMatrix = SlotTimelineData.cacheFrame(_cacheFrames, cacheFrameIndex, this._globalTransformMatrix);
					}
				}
				
				_updateTransform();
			}
		}
		
		/**
		 * @private Factory
		 */
		dragonBones_internal function _setDisplayList(value:Vector.<*>):Boolean
		{
			if (value && value.length)
			{
				if (_displayList.length != value.length)
				{
					_displayList.fixed = false;
					_displayList.length = value.length;
					_displayList.fixed = true;
				}
				
				for (var i:uint = 0, l:uint = value.length; i < l; ++i)
				{
					const eachDisplay:* = value[i];
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
				_displayList.fixed = false;
				_displayList.length = 0;
				_displayList.fixed = true;
			}
			
			if (_displayIndex >= 0 && _displayIndex < _displayList.length)
			{
				_displayDirty = _display != _displayList[_displayIndex];
			}
			else
			{
				_displayDirty = _display != null;
			}
			
			return _displayDirty;
		}
		
		/**
		 * @private Factory
		 */
		dragonBones_internal function _setDisplayIndex(value:int):Boolean
		{
			if (_displayIndex == value)
			{
				return false;
			}
			
			_displayIndex = value;
			_displayDirty = true;
			
			return _displayDirty;
		}
		
		/**
		 * @private Factory
		 */
		dragonBones_internal function _setBlendMode(value:int):Boolean
		{
			if (_blendMode == value)
			{
				return false;
			}
			
			_blendMode = value;
			_blendModeDirty = true;
			
			return true;
		}
		
		/**
		 * @private Factory
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
		 * 在下一帧更新显示对象的状态。
		 * @version DragonBones 4.5
		 */
		public function invalidUpdate():void
		{
			_displayDirty = true;
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
		public function get MeshDisplay():Object
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
		public function get displayList():Vector.<*>
		{
			return _displayList.concat();
		}
		public function set displayList(value:Vector.<*>):void
		{
			const backupDisplayList:Vector.<*> = _displayList.concat();
			const disposeDisplayList:Vector.<*> = new Vector.<*>();
			
			if (_setDisplayList(value))
			{
				_update(-1);
			}
			
			for each (var eachDisplay:* in backupDisplayList)
			{
				if (eachDisplay && eachDisplay != _rawDisplay && _displayList.indexOf(eachDisplay) < 0)
				{
					if (disposeDisplayList.indexOf(eachDisplay) < 0)
					{
						disposeDisplayList.push(eachDisplay);
					}
				}
			}
			
			for each (eachDisplay in disposeDisplayList)
			{
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
		public function get display():*
		{
			return _display;
		}
		public function set display(value:*):void
		{
			if (_display == value)
			{
				return;
			}
			
			const displayListLength:uint = _displayList.length;
			if (_displayIndex < 0 && displayListLength == 0)  // Emprty
			{
				_displayIndex = 0;
			}
			
			if (_displayIndex < 0)
			{
				return;
			}
			else
			{
				const replaceDisplayList:Vector.<*> = displayList; // copy
				if (displayListLength <= _displayIndex)
				{
					replaceDisplayList.fixed = false;
					replaceDisplayList.length = _displayIndex + 1;
					replaceDisplayList.fixed = true;
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
			if (_childArmature == value)
			{
				return;
			}
			
			if (value)
			{
				value.display.advanceTimeBySelf(false); // Stop child armature self advanceTime.
			}

			display = value;
		}
	}
}