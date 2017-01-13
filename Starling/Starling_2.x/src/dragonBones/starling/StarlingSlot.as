package dragonBones.starling
{
	import flash.geom.Matrix;
	
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.BlendMode;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.display.Quad;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.styles.MeshStyle;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * Starling 插槽。
	 * @version DragonBones 3.0
	 */
	public final class StarlingSlot extends Slot
	{
		public var transformUpdateEnabled:Boolean;
		/**
		 * @private
		 */
		dragonBones_internal var _indexData:IndexData;
		/**
		 * @private
		 */
		dragonBones_internal var _vertexData:VertexData;
		
		private var _renderDisplay:DisplayObject;
		/**
		 * @private
		 */
		public function StarlingSlot()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			transformUpdateEnabled = false;
			
			if (_indexData)
			{
				_indexData.clear();
				_indexData = null;
			}
			
			if (_vertexData)
			{
				_vertexData.clear();
				_vertexData = null;
			}
			
			_renderDisplay = null;
		}
		/**
		 * @private
		 */
		override protected function _initDisplay(value:Object):void
		{
		}
		/**
		 * @private
		 */
		override protected function _disposeDisplay(value:Object):void
		{
			(value as DisplayObject).dispose();
		}
		/**
		 * @private
		 */
		override protected function _onUpdateDisplay():void
		{
			_renderDisplay = (_display ? _display : _rawDisplay) as DisplayObject;
		}
		/**
		 * @private
		 */
		override protected function _addDisplay():void
		{
			const container:StarlingArmatureDisplay = _armature.display as StarlingArmatureDisplay;
			container.addChild(_renderDisplay);
		}
		/**
		 * @private
		 */
		override protected function _replaceDisplay(value:Object):void
		{
			const container:StarlingArmatureDisplay = _armature.display as StarlingArmatureDisplay;
			const prevDisplay:DisplayObject = value as DisplayObject;
			container.addChild(_renderDisplay);
			container.swapChildren(_renderDisplay, prevDisplay);
			container.removeChild(prevDisplay);
		}
		/**
		 * @private
		 */
		override protected function _removeDisplay():void
		{
			_renderDisplay.removeFromParent();
		}
		/**
		 * @private
		 */
		override protected function _updateZOrder():void
		{
			const container:StarlingArmatureDisplay = _armature.display as StarlingArmatureDisplay;
			const index:int = container.getChildIndex(_renderDisplay);
			if (index === _zOrder) 
			{
				return;
			}
			
			container.addChildAt(_renderDisplay, _zOrder < index ? _zOrder : _zOrder + 1);
		}
		/**
		 * @private
		 */
		override dragonBones_internal function _updateVisible():void
		{
			_renderDisplay.visible = _parent.visible;
		}
		/**
		 * @private
		 */
		override protected function _updateBlendMode():void
		{
			switch (_blendMode) 
			{
				case dragonBones.enum.BlendMode.Normal:
					_renderDisplay.blendMode = starling.display.BlendMode.NORMAL;
					break;
				
				case dragonBones.enum.BlendMode.Add:
					_renderDisplay.blendMode = starling.display.BlendMode.ADD;
					break;
				
				case dragonBones.enum.BlendMode.Erase:
					_renderDisplay.blendMode = starling.display.BlendMode.ERASE;
					break;
				
				case dragonBones.enum.BlendMode.Multiply:
					_renderDisplay.blendMode = starling.display.BlendMode.MULTIPLY;
					break;
				
				case dragonBones.enum.BlendMode.Screen:
					_renderDisplay.blendMode = starling.display.BlendMode.SCREEN;
					break;
				
				default:
					break;
			}
		}
		/**
		 * @private
		 */
		override protected function _updateColor():void
		{
			_renderDisplay.alpha = _colorTransform.alphaMultiplier;
			
			const quad:Quad = _renderDisplay as Quad;
			if (quad)
			{
				const color:uint = (uint(_colorTransform.redMultiplier * 0xFF) << 16) + (uint(_colorTransform.greenMultiplier * 0xFF) << 8) + uint(_colorTransform.blueMultiplier * 0xFF);
				if (quad.color != color)
				{
					quad.color = color;
				}
			}
		}
		/**
		 * @private
		 */
		override protected function _updateFrame():void
		{
			const isMeshDisplay:Boolean = _meshData && _renderDisplay === _meshDisplay;
			var currentTextureData:StarlingTextureData = _textureData as StarlingTextureData;
			
			if (_displayIndex >= 0 && _display && currentTextureData)
			{
				var currentTextureAtlasData:StarlingTextureAtlasData = currentTextureData.parent as StarlingTextureAtlasData;
				
				// Update replaced texture atlas.
				if (_armature.replacedTexture && _displayData && currentTextureAtlasData === _displayData.texture.parent) 
				{
					currentTextureAtlasData = _armature._replaceTextureAtlasData as StarlingTextureAtlasData;
					if (!currentTextureAtlasData) 
					{
						currentTextureAtlasData = BaseObject.borrowObject(StarlingTextureAtlasData) as StarlingTextureAtlasData;
						currentTextureAtlasData.copyFrom(_textureData.parent);
						currentTextureAtlasData.texture = _armature.replacedTexture as Texture;
						_armature._replaceTextureAtlasData = currentTextureAtlasData;
					}
					
					currentTextureData = currentTextureAtlasData.getTexture(currentTextureData.name) as StarlingTextureData;
				}
				
				const currentTextureAtlas:Texture = currentTextureAtlasData.texture;
				if (currentTextureAtlas)
				{
					if (!currentTextureData.texture) // Create texture.
					{
						currentTextureData.texture = new SubTexture(currentTextureAtlas, currentTextureData.region, false, null, currentTextureData.rotated);
					}
					
					if (isMeshDisplay)
					{
						var meshDisplay:Mesh = _meshDisplay as Mesh;
						
						_indexData.clear();
						_vertexData.clear();
						
						for (var i:uint = 0, l:uint = _meshData.vertexIndices.length; i < l; ++i)
						{
							_indexData.setIndex(i, _meshData.vertexIndices[i]);
						}
						
						const meshStyle:MeshStyle = meshDisplay.style;
						for (i = 0, l = _meshData.uvs.length; i < l; i += 2)
						{
							const iH:uint = i / 2;
							meshStyle.setTexCoords(iH, _meshData.uvs[i], _meshData.uvs[i + 1]);
							meshStyle.setVertexPosition(iH, _meshData.vertices[i], _meshData.vertices[i + 1]);
						}
						
						meshDisplay.texture = currentTextureData.texture;
					}
					else
					{
						var normalDisplay:Image = _renderDisplay as Image;
						normalDisplay.texture = currentTextureData.texture;
						normalDisplay.readjustSize();
					}
					
					_updateVisible();
					
					return;
				}
			}
			
			if (isMeshDisplay)
			{
				meshDisplay = _renderDisplay as Mesh;
				meshDisplay.visible = false;
				meshDisplay.texture = null;
				meshDisplay.x = 0.0;
				meshDisplay.y = 0.0;
			}
			else
			{
				normalDisplay = _renderDisplay as Image;
				normalDisplay.visible = false;
				normalDisplay.texture = null;
				normalDisplay.readjustSize();
				normalDisplay.x = 0.0;
				normalDisplay.y = 0.0;
			}
		}
		/**
		 * @private
		 */
		override protected function _updateMesh():void
		{
			const meshDisplay:Mesh = _renderDisplay as Mesh;
			const meshStyle:MeshStyle = meshDisplay.style;
			const hasFFD:Boolean = _ffdVertices.length > 0;
			
			var i:uint = 0, iH:uint = 0, iF:uint = 0, l:uint = _meshData.vertices.length;
			var xG:Number = 0, yG:Number = 0;
			if (_meshData.skinned)
			{
				for (i = 0; i < l; i += 2)
				{
					iH = i / 2;
					
					const boneIndices:Vector.<uint> = _meshData.boneIndices[iH];
					const boneVertices:Vector.<Number> = _meshData.boneVertices[iH];
					const weights:Vector.<Number> = _meshData.weights[iH];
					
					xG = 0, yG = 0;
					
					for (var iB:uint = 0, lB:uint = boneIndices.length; iB < lB; ++iB)
					{
						const bone:Bone = _meshBones[boneIndices[iB]];
						const matrix:Matrix = bone.globalTransformMatrix;
						const weight:Number = weights[iB];
						
						var xL:Number = 0, yL:Number = 0;
						if (hasFFD)
						{
							xL = boneVertices[iB * 2] + _ffdVertices[iF];
							yL = boneVertices[iB * 2 + 1] + _ffdVertices[iF + 1];
						}
						else
						{
							xL = boneVertices[iB * 2];
							yL = boneVertices[iB * 2 + 1];
						}
						
						
						xG += (matrix.a * xL + matrix.c * yL + matrix.tx) * weight;
						yG += (matrix.b * xL + matrix.d * yL + matrix.ty) * weight;
						
						iF += 2;
					}
					
					meshStyle.setVertexPosition(iH, xG, yG);
				}
			}
			else if (hasFFD)
			{
				const vertices:Vector.<Number> = _meshData.vertices;
				for (i = 0; i < l; i += 2)
				{
					xG = vertices[i] + _ffdVertices[i];
					yG = vertices[i + 1] + _ffdVertices[i + 1];
					meshStyle.setVertexPosition(i / 2, xG, yG);
				}
			}
		}
		/**
		 * @private
		 */
		override protected function _updateTransform(isSkinnedMesh: Boolean):void
		{
			if (isSkinnedMesh)
			{
				var displayMatrix:Matrix = _renderDisplay.transformationMatrix;
				displayMatrix.identity();
				_renderDisplay.transformationMatrix = displayMatrix;
			}
			else
			{
				if (transformUpdateEnabled)
				{
					_renderDisplay.transformationMatrix = globalTransformMatrix;
					
					if (_pivotX != 0 || _pivotY != 0)
					{
						_renderDisplay.pivotX = _pivotX;
						_renderDisplay.pivotY = _pivotY;
					}
				}
				else
				{
					displayMatrix = _renderDisplay.transformationMatrix;
					displayMatrix.a = globalTransformMatrix.a;
					displayMatrix.b = globalTransformMatrix.b;
					displayMatrix.c = globalTransformMatrix.c;
					displayMatrix.d = globalTransformMatrix.d;
					displayMatrix.tx = globalTransformMatrix.tx - (globalTransformMatrix.a * _pivotX + globalTransformMatrix.c * _pivotY);
					displayMatrix.ty = globalTransformMatrix.ty - (globalTransformMatrix.b * _pivotX + globalTransformMatrix.d * _pivotY);
					
					//
					_renderDisplay.setRequiresRedraw();
				}
			}
		}
	}
}