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
	import starling.display.Quad;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace dragonBones_internal;
	
	public final class StarlingSlot extends Slot
	{
		/**
		 * @private
		 */
		dragonBones_internal static const EMPTY_TEXTURE:Texture = Texture.empty(1, 1);
		
		public var updateTransformEnabled:Boolean = true;
		
		private var _renderDisplay:DisplayObject = null;
		
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
			for each (var eachDisplay:Object in this._displayList)
			{
				if (disposeDisplayList.indexOf(eachDisplay) < 0)
				{
					disposeDisplayList.push(eachDisplay);
				}
			}
			
			for each (eachDisplay in disposeDisplayList)
			{
				if (eachDisplay is Armature)
				{
					(eachDisplay as Armature).returnToPool();
				}
				else
				{
					this._disposeDisplay(eachDisplay);
				}
			}
			
			super._onClear();
			
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
				this._rawDisplay = new Image(EMPTY_TEXTURE);	
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
			const prevDisplay:DisplayObject = value as DisplayObject;
			prevDisplay.dispose();
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
			
			if (this._display && this._displayIndex >= 0 && this._displayIndex < this._displayDataSet.displays.length)
			{
				const displayData:DisplayData = this._displayDataSet.displays[this._displayIndex];
				const textureData:StarlingTextureData = displayData.textureData as StarlingTextureData;
				
				if (textureData && !textureData.texture)
				{
					const textureAtlasTexture:Texture = (textureData.parent as StarlingTextureAtlasData).texture;
					if (textureAtlasTexture)
					{
						textureData.texture = new SubTexture(textureAtlasTexture, textureData.region, false, textureData.frame, textureData.rotated);
					}
				}
				
				if (textureData && textureData.texture)
				{
					const rect:Rectangle = textureData.frame || textureData.region;
					
					var width:Number = rect.width;
					var height:Number = rect.height;
					if (textureData.rotated)
					{
						width = rect.height;
						height = rect.width;
					}
					
					var pivotX:Number = displayData.pivot.x;
					var pivotY:Number = displayData.pivot.y;
					if (displayData.isRelativePivot)
					{
						pivotX = width * pivotX;
						pivotY = height * pivotY;
					}
					
					if (textureData.frame)
					{
						pivotX -= textureData.frame.x;
						pivotY -= textureData.frame.y;
					}
					
					frameDisplay.texture = textureData.texture;
					frameDisplay.readjustSize();
					frameDisplay.pivotX = pivotX;
					frameDisplay.pivotY = pivotY;
					this._updateVisible();
					
					return;
				}
			}
			
			frameDisplay.visible = false;
			frameDisplay.texture = EMPTY_TEXTURE;
			frameDisplay.readjustSize();
			frameDisplay.pivotX = 0;
			frameDisplay.pivotY = 0;
		}
		
		/**
		 * @private
		 */
		override protected function _updateMesh():void
		{
			/*const mesh:Mesh = _renderDisplay as Mesh;
			const meshStyle:MeshStyle = mesh.style;
			
			var i:uint = 0, iH:uint = 0, l:uint = _meshData.vertices.length;
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
						const bone:Bone = this._meshBones[boneIndices[iB]];
						const weight:Number = weights[iB];
						const matrix:Matrix = bone.globalTransformMatrix;
						
						const xL:Number = boneVertices[iB / 2] + this._ffdVertices[i * lB];
						const yL:Number = boneVertices[iB / 2 + 1] + this._ffdVertices[i * lB + 1];
					
						xG += (matrix.a * xL + matrix.c * yL + matrix.tx) * weight;
						yG += (matrix.b * xL + matrix.d * yL + matrix.ty) * weight;
					}
					
					meshStyle.setVertexPosition(i / 2, xG, yG);
				}
			}
			else
			{
				const vertices:Vector.<Number> = _meshData.vertices;
				for (i = 0; i < l; i += 2)
				{
					xG = vertices[i] + this._ffdVertices[i];
					yG = vertices[i + 1] + this._ffdVertices[i + 1];
					meshStyle.setVertexPosition(i / 2, xG, yG);
				}
			}*/
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
			}
		}
	}
}