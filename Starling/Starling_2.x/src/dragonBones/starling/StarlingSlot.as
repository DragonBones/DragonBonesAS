package dragonBones.starling
{
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DisplayData;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.display.Quad;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.styles.MeshStyle;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace dragonBones_internal;
	
	public final class StarlingSlot extends Slot
	{
		public var updateTransformEnabled:Boolean;
		
		/**
		 * @private
		 */
		dragonBones_internal var _indexData:IndexData;
		/**
		 * @private
		 */
		dragonBones_internal var _vertexData:VertexData;
		
		private var _renderDisplay:DisplayObject;
		
		public function StarlingSlot()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			const disposeDisplayList:Vector.<Object> = new Vector.<Object>();
			for each (var renderDisplay:Object in this._displayList)
			{
				if (disposeDisplayList.indexOf(renderDisplay) < 0)
				{
					disposeDisplayList.push(renderDisplay);
				}
			}
			
			for each (renderDisplay in disposeDisplayList)
			{
				if (renderDisplay is Armature)
				{
					(renderDisplay as Armature).returnToPool();
				}
				else
				{
					this._disposeDisplay(renderDisplay);
				}
			}
			
			super._onClear();
			
			updateTransformEnabled = false;
			
			_indexData = null;
			_vertexData = null;
			
			_renderDisplay = null;
		}
		
		// Abstract method
		
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
		override protected function _initDisplay(value:Object):void
		{
		}
		
		/**
		 * @private
		 */
		override protected function _addDisplay():void
		{
			const container:DisplayObjectContainer = this._armature.display as DisplayObjectContainer;
			container.addChild(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override protected function _replaceDisplay(value:Object):void
		{
			const container:DisplayObjectContainer = this._armature.display as DisplayObjectContainer;
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
		override protected function _disposeDisplay(value:Object):void
		{
			const renderDisplay:DisplayObject = value as DisplayObject;
			renderDisplay.dispose();
		}
		
		/**
		 * @private
		 */
		override dragonBones_internal function _getDisplayZIndex():int
		{
			const container:DisplayObjectContainer = this._armature.display as DisplayObjectContainer;
			return container.getChildIndex(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override dragonBones_internal function _setDisplayZIndex(value:int):void
		{
			const container:DisplayObjectContainer = this._armature.display as DisplayObjectContainer;
			const index:int = container.getChildIndex(_renderDisplay);
			if (index == value)
			{
				return;
			}
			
			if (index < value)
			{
				container.addChildAt(_renderDisplay, value);
			}
			else
			{
				container.addChildAt(_renderDisplay, value + 1);
			}
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
		private static const BLEND_MODE_LIST:Vector.<String> = Vector.<String>(
			[
				BlendMode.NORMAL,
				BlendMode.ADD,
				null,
				null,
				null,
				BlendMode.ERASE,
				null,
				null,
				null,
				null,
				BlendMode.MULTIPLY,
				null,
				BlendMode.SCREEN,
				null
			]
		);
		
		/**
		 * @private
		 */
		override protected function _updateBlendMode():void
		{
			if (this._blendMode < BLEND_MODE_LIST.length)
			{
				const blendMode:String = BLEND_MODE_LIST[this._blendMode];
				if (blendMode)
				{
					_renderDisplay.blendMode = blendMode;
				}
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
			const frameDisplay:Image = this._rawDisplay as Image;
			
			if (this._display && this._displayIndex >= 0)
			{
				const rawDisplayData:DisplayData = this._displayIndex < this._displayDataSet.displays.length? this._displayDataSet.displays[this._displayIndex]: null;
				const replaceDisplayData:DisplayData = this._displayIndex < this._replaceDisplayDataSet.length? this._replaceDisplayDataSet[this._displayIndex]: null;
				const contentDisplayData:DisplayData = replaceDisplayData || rawDisplayData;
				const currentTextureData:StarlingTextureData = contentDisplayData.textureData as StarlingTextureData;
				
				if (currentTextureData)
				{
					if (!currentTextureData.texture)
					{
						const textureAtlasTexture:Texture = (currentTextureData.parent as StarlingTextureAtlasData).texture;
						if (textureAtlasTexture)
						{
							currentTextureData.texture = new SubTexture(textureAtlasTexture, currentTextureData.region, false, currentTextureData.frame, currentTextureData.rotated);
						}
					}
					
					const texture:Texture = (this._armature._replaceTexture as Texture) || currentTextureData.texture;
					
					if (texture)
					{
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
							
							meshDisplay.texture = currentTextureData.texture;
							//meshDisplay.readjustSize();
							meshDisplay.pivotX = 0;
							meshDisplay.pivotY = 0;
							
							if (this._meshData.skinned)
							{
								const transformationMatrix:Matrix = meshDisplay.transformationMatrix;
								transformationMatrix.identity();
								meshDisplay.transformationMatrix = transformationMatrix;
							}
						}
						else
						{
							const rect:Rectangle = currentTextureData.frame || currentTextureData.region;
							
							var width:Number = rect.width;
							var height:Number = rect.height;
							if (currentTextureData.rotated)
							{
								width = rect.height;
								height = rect.width;
							}
							
							var pivotX:Number = contentDisplayData.pivot.x;
							var pivotY:Number = contentDisplayData.pivot.y;
							if (contentDisplayData.isRelativePivot)
							{
								pivotX = width * pivotX;
								pivotY = height * pivotY;
							}
							
							if (currentTextureData.frame)
							{
								pivotX -= currentTextureData.frame.x;
								pivotY -= currentTextureData.frame.y;
							}
							
							if (rawDisplayData && replaceDisplayData)
							{
								pivotX += replaceDisplayData.transform.x - rawDisplayData.transform.x;
								pivotY += replaceDisplayData.transform.y - rawDisplayData.transform.y;
							}
							
							frameDisplay.texture = currentTextureData.texture;
							frameDisplay.readjustSize();
							frameDisplay.pivotX = pivotX;
							frameDisplay.pivotY = pivotY;
						}
						
						this._updateVisible();
						
						return;
					}
				}
			}
			
			frameDisplay.visible = false;
			frameDisplay.texture = null;
			frameDisplay.readjustSize();
			frameDisplay.pivotX = 0;
			frameDisplay.pivotY = 0;
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
					iH = uint(i / 2);
					
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
			const pivotX:Number = _renderDisplay.pivotX;
			const pivotY:Number = _renderDisplay.pivotY;
			
			if (updateTransformEnabled)
			{
				_renderDisplay.transformationMatrix = this.globalTransformMatrix;
				
				if (pivotX || pivotY)
				{
					_renderDisplay.pivotX = pivotX;
					_renderDisplay.pivotY = pivotY;
				}
			}
			else
			{
				const displayMatrix:Matrix = _renderDisplay.transformationMatrix;
				displayMatrix.a = this.globalTransformMatrix.a;
				displayMatrix.b = this.globalTransformMatrix.b;
				displayMatrix.c = this.globalTransformMatrix.c;
				displayMatrix.d = this.globalTransformMatrix.d;
				
				if (pivotX || pivotY)
				{
					displayMatrix.tx = this.globalTransformMatrix.tx - (displayMatrix.a * pivotX + displayMatrix.c * pivotY);
					displayMatrix.ty = this.globalTransformMatrix.ty - (displayMatrix.b * pivotX + displayMatrix.d * pivotY);
				}
				else
				{
					displayMatrix.tx = this.globalTransformMatrix.tx;
					displayMatrix.ty = this.globalTransformMatrix.ty;
				}
				
				_renderDisplay.setRequiresRedraw();
			}
		}
	}
}