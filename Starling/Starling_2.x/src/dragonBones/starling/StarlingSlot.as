package dragonBones.starling
{
	import flash.geom.Matrix;
	
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DisplayData;
	
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
		 * @language zh_CN
		 * 创建一个空的插槽。
		 * @version DragonBones 3.0
		 */
		public function StarlingSlot()
		{
			super(this);
		}
		
		private function _createTexture(textureData:StarlingTextureData, textureAtlas:Texture): SubTexture
		{
			const texture:SubTexture = new SubTexture(textureAtlas, textureData.region, false, null, textureData.rotated);
			
			return texture;
		}
		
		/**
		 * @inheritDoc
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
		
		// Abstract method
		
		/**
		 * @private
		 */
		override protected function _initDisplay(value:*):void
		{
		}
		
		/**
		 * @private
		 */
		override protected function _disposeDisplay(value:*):void
		{
			(value as DisplayObject).dispose();
		}
		
		/**
		 * @private
		 */
		override protected function _onUpdateDisplay():void
		{
			if (!this._rawDisplay)
			{
				this._rawDisplay = new Image(null);
			}
			
			_renderDisplay = (this._display || this._rawDisplay) as DisplayObject;
		}
		
		/**
		 * @private
		 */
		override protected function _addDisplay():void
		{
			const container:StarlingArmatureDisplay = this._armature._display as StarlingArmatureDisplay;
			container.addChild(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override protected function _replaceDisplay(value:*):void
		{
			const container:StarlingArmatureDisplay = this._armature.display as StarlingArmatureDisplay;
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
			const container:StarlingArmatureDisplay = this._armature._display as StarlingArmatureDisplay;
			container.addChildAt(this._renderDisplay, this._zOrder);
		}
		
		/**
		 * @private
		 */
		override dragonBones_internal function _updateVisible():void
		{
			_renderDisplay.visible = this._parent.visible;
		}
		
		/**
		 * @private
		 */
		override protected function _updateBlendMode():void
		{
			switch (this._blendMode) 
			{
				case DragonBones.BLEND_MODE_NORMAL:
					_renderDisplay.blendMode = BlendMode.NORMAL;
					break;
				
				case DragonBones.BLEND_MODE_ADD:
					_renderDisplay.blendMode = BlendMode.ADD;
					break;
				
				case DragonBones.BLEND_MODE_ERASE:
					_renderDisplay.blendMode = BlendMode.ERASE;
					break;
				
				case DragonBones.BLEND_MODE_MULTIPLY:
					_renderDisplay.blendMode = BlendMode.MULTIPLY;
					break;
				
				case DragonBones.BLEND_MODE_SCREEN:
					_renderDisplay.blendMode = BlendMode.SCREEN;
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
			_renderDisplay.alpha = this._colorTransform.alphaMultiplier;
			
			const quad:Quad = _renderDisplay as Quad;
			if (quad)
			{
				const color:uint = (uint(this._colorTransform.redMultiplier * 0xFF) << 16) + (uint(this._colorTransform.greenMultiplier * 0xFF) << 8) + uint(this._colorTransform.blueMultiplier * 0xFF);
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
			if (this._display && this._displayIndex >= 0)
			{
				const rawDisplayData:DisplayData = this._displayIndex < this._displayDataSet.displays.length? this._displayDataSet.displays[this._displayIndex]: null;
				const replacedDisplayData:DisplayData = this._displayIndex < this._replacedDisplayDataSet.length? this._replacedDisplayDataSet[this._displayIndex]: null;
				const currentDisplayData:DisplayData = replacedDisplayData || rawDisplayData;
				const currentTextureData:StarlingTextureData = currentDisplayData.texture as StarlingTextureData;
				
				if (currentTextureData)
				{
					const currentTextureAtlasData:StarlingTextureAtlasData = currentTextureData.parent as StarlingTextureAtlasData;
					const replacedTextureAtlas:Texture = this._armature.replacedTexture as Texture;
					const currentTextureAtlas:Texture = (replacedTextureAtlas && currentDisplayData.texture.parent == rawDisplayData.texture.parent) ?
						replacedTextureAtlas : currentTextureAtlasData.texture;
					
					if (currentTextureAtlas)
					{
						var currentTexture:SubTexture = currentTextureData.texture;
						
						if (currentTextureAtlas == replacedTextureAtlas) {
							const armatureDisplay:StarlingArmatureDisplay = this._armature._display as StarlingArmatureDisplay;
							const textureName:String = currentTextureData.name;
							currentTexture = armatureDisplay._subTextures[textureName];
							if (!currentTexture) {
								currentTexture = _createTexture(currentTextureData, currentTextureAtlas);
								armatureDisplay._subTextures[textureName] = currentTexture;
							}
						}
						else if (!currentTextureData.texture) {
							currentTexture = _createTexture(currentTextureData, currentTextureAtlas);
							currentTextureData.texture = currentTexture;
						}
						
						this._updatePivot(rawDisplayData, currentDisplayData, currentTextureData);
						
						if (this._meshData && this._display == this._meshDisplay)
						{
							const meshDisplay:Mesh = this._meshDisplay as Mesh;
							const meshStyle:MeshStyle = meshDisplay.style;
							
							_indexData.clear();
							_vertexData.clear();
							
							var i:uint = 0, l:uint = 0;
							
							for (i = 0, l = this._meshData.vertexIndices.length; i < l; ++i)
							{
								_indexData.setIndex(i, this._meshData.vertexIndices[i]);
							}
							
							for (i = 0, l = this._meshData.uvs.length; i < l; i += 2)
							{
								const iH:uint = uint(i / 2);
								meshStyle.setTexCoords(iH, this._meshData.uvs[i], this._meshData.uvs[i + 1]);
								meshStyle.setVertexPosition(iH, this._meshData.vertices[i], this._meshData.vertices[i + 1]);
							}
							
							meshDisplay.texture = currentTexture;
							//meshDisplay.readjustSize();
							
							if (this._meshData.skinned)
							{
								const transformationMatrix:Matrix = meshDisplay.transformationMatrix;
								transformationMatrix.identity();
								meshDisplay.transformationMatrix = transformationMatrix;
							}
						}
						else
						{
							const frameDisplay:Image = this._rawDisplay as Image;
							frameDisplay.texture = currentTexture;
							frameDisplay.readjustSize();
						}
						
						this._updateVisible();
						
						return;
					}
				}
			}
			
			this._pivotX = 0;
			this._pivotY = 0;
			
			if (this._meshData && this._display == this._meshDisplay)
			{
				const meshDisplayB:Mesh = this._meshDisplay as Mesh;
				meshDisplayB.visible = false;
				meshDisplayB.texture = null;
				meshDisplayB.x = this.origin.x;
				meshDisplayB.y = this.origin.y;
			}
			else
			{
				const frameDisplayB:Image = this._rawDisplay as Image;
				frameDisplayB.visible = false;
				frameDisplayB.texture = null;
				frameDisplayB.readjustSize();
				frameDisplayB.x = this.origin.x;
				frameDisplayB.y = this.origin.y;
			}
		}
		
		/**
		 * @private
		 */
		override protected function _updateMesh():void
		{
			const meshDisplay:Mesh = this._meshDisplay as Mesh;
			const meshStyle:MeshStyle = meshDisplay.style;
			const hasFFD:Boolean = this._ffdVertices.length > 0;
			
			var i:uint = 0, iH:uint = 0, iF:uint = 0, l:uint = this._meshData.vertices.length;
			var xG:Number = 0, yG:Number = 0;
			if (this._meshData.skinned)
			{
				for (i = 0; i < l; i += 2)
				{
					iH = i / 2;
					
					const boneIndices:Vector.<uint> = this._meshData.boneIndices[iH];
					const boneVertices:Vector.<Number> = this._meshData.boneVertices[iH];
					const weights:Vector.<Number> = this._meshData.weights[iH];
					
					xG = 0, yG = 0;
					
					for (var iB:uint = 0, lB:uint = boneIndices.length; iB < lB; ++iB)
					{
						const bone:Bone = this._meshBones[boneIndices[iB]];
						const matrix:Matrix = bone.globalTransformMatrix;
						const weight:Number = weights[iB];
						
						var xL:Number = 0, yL:Number = 0;
						if (hasFFD)
						{
							xL = boneVertices[iB * 2] + this._ffdVertices[iF];
							yL = boneVertices[iB * 2 + 1] + this._ffdVertices[iF + 1];
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
				const vertices:Vector.<Number> = this._meshData.vertices;
				for (i = 0; i < l; i += 2)
				{
					xG = vertices[i] + this._ffdVertices[i];
					yG = vertices[i + 1] + this._ffdVertices[i + 1];
					meshStyle.setVertexPosition(i / 2, xG, yG);
				}
			}
		}
		
		/**
		 * @private
		 */
		override protected function _updateTransform():void
		{
			if (transformUpdateEnabled)
			{
				_renderDisplay.transformationMatrix = this.globalTransformMatrix;
				
				if (this._pivotX != 0 || this._pivotY != 0)
				{
					_renderDisplay.pivotX = this._pivotX;
					_renderDisplay.pivotY = this._pivotY;
				}
			}
			else
			{
				const displayMatrix:Matrix = _renderDisplay.transformationMatrix;
				displayMatrix.a = this.globalTransformMatrix.a;
				displayMatrix.b = this.globalTransformMatrix.b;
				displayMatrix.c = this.globalTransformMatrix.c;
				displayMatrix.d = this.globalTransformMatrix.d;
				displayMatrix.tx = this.globalTransformMatrix.tx - (this.globalTransformMatrix.a * this._pivotX + this.globalTransformMatrix.c * this._pivotY);
				displayMatrix.ty = this.globalTransformMatrix.ty - (this.globalTransformMatrix.b * this._pivotX + this.globalTransformMatrix.d * this._pivotY);
				
				_renderDisplay.setRequiresRedraw();
			}
		}
	}
}