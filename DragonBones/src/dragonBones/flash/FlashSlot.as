package dragonBones.flash
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.GraphicsTrianglePath;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DisplayData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 基于 Flash 传统显示列表的插槽。
	 * @version DragonBones 3.0
	 */
	public class FlashSlot extends Slot
	{
		private static const _helpMatrix:Matrix = new Matrix();
		
		private var _renderDisplay:DisplayObject;
		
		private var _meshTexture:BitmapData;
		private var _pach:GraphicsTrianglePath;
		
		/**
		 * @language zh_CN
		 * 创建一个空的插槽。
		 * @version DragonBones 3.0
		 */
		public function FlashSlot()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			_renderDisplay = null;
			_meshTexture = null;
			_pach = null;
		}
		
		// Abstract method
		
		/**
		 * @private
		 */
		override protected function _initDisplay(value:Object):void
		{
		}
		
		/**
		 * @private
		 */
		override protected function _onUpdateDisplay():void
		{
			if (!this._rawDisplay)
			{
				this._rawDisplay = new Shape();
			}
			
			_renderDisplay = (this._display || this._rawDisplay) as DisplayObject;
		}
		
		/**
		 * @private
		 */
		override protected function _addDisplay():void
		{
			const container:FlashArmatureDisplay = this._armature._display as FlashArmatureDisplay;
			container.addChild(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override protected function _replaceDisplay(prevDisplay:Object):void
		{
			const container:FlashArmatureDisplay = this._armature.display as FlashArmatureDisplay;
			const displayObject:DisplayObject = prevDisplay as DisplayObject;
			container.addChild(_renderDisplay);
			container.swapChildren(_renderDisplay, displayObject);
			container.removeChild(displayObject);
		}
		
		/**
		 * @private
		 */
		override protected function _removeDisplay():void
		{
			_renderDisplay.parent.removeChild(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override protected function _disposeDisplay(value:Object):void
		{
		}
		
		/**
		 * @private
		 */
		override dragonBones_internal function _getDisplayZIndex():int
		{
			const container:FlashArmatureDisplay = this._armature._display as FlashArmatureDisplay;
			return container.getChildIndex(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override dragonBones_internal function _setDisplayZIndex(value:int):void
		{
			const container:FlashArmatureDisplay = this._armature.display as FlashArmatureDisplay;
			const index:int = container.getChildIndex(_renderDisplay);
			if (index == value)
			{
				return;
			}
			
			// container.addChildAt(_renderDisplay, index < value? value: value + 1);
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
				BlendMode.ALPHA,
				BlendMode.DARKEN,
				BlendMode.DIFFERENCE,
				BlendMode.ERASE,
				BlendMode.HARDLIGHT,
				BlendMode.INVERT,
				BlendMode.LAYER,
				BlendMode.LIGHTEN,
				BlendMode.MULTIPLY,
				BlendMode.OVERLAY,
				BlendMode.SCREEN,
				BlendMode.SUBTRACT
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
			_renderDisplay.transform.colorTransform = this._colorTransform;
		}
		
		/**
		 * @private
		 */
		override protected function _updateFrame():void
		{
			const frameDisplay:Shape = _renderDisplay as Shape;
			
			if (this._display && this._displayIndex >= 0)
			{
				const rawDisplayData:DisplayData = this._displayIndex < this._displayDataSet.displays.length? this._displayDataSet.displays[this._displayIndex]: null;
				const replacedDisplayData:DisplayData = this._displayIndex < this._replacedDisplayDataSet.length? this._replacedDisplayDataSet[this._displayIndex]: null;
				const currentDisplayData:DisplayData = replacedDisplayData || rawDisplayData;
				const currentTextureData:FlashTextureData = currentDisplayData.textureData as FlashTextureData;
				
				if (currentTextureData)
				{
					const textureAtlasTexture:BitmapData = (currentTextureData.parent as FlashTextureAtlasData).texture;
					const texture:BitmapData = 
						(this._armature._replacedTexture as BitmapData) ||
						textureAtlasTexture ||
						currentTextureData.texture;
					
					if (this._meshData && this._display == this._meshDisplay)
					{
						const meshDisplay:Shape = this._meshDisplay as Shape;
						
						if (_pach)
						{
							_pach.uvtData.fixed = false;
							_pach.vertices.fixed = false;
							_pach.indices.fixed = false;
							
							_pach.uvtData.length = this._meshData.uvs.length;
							_pach.vertices.length = this._meshData.vertices.length;
							_pach.indices.length = this._meshData.vertexIndices.length;
							
							_pach.uvtData.fixed = true;
							_pach.vertices.fixed = true;
							_pach.indices.fixed = true;
						}
						else
						{
							_pach = new GraphicsTrianglePath(
								new Vector.<Number>(this._meshData.uvs.length, true),
								new Vector.<int>(this._meshData.vertexIndices.length, true),
								new Vector.<Number>(this._meshData.vertices.length, true)
							);
						}
						
						var i:uint = 0, l:uint = 0;
						for (i = 0, l = _pach.uvtData.length; i < l; i += 2)
						{
							const u:Number = this._meshData.uvs[i];
							const v:Number = this._meshData.uvs[i + 1];
							_pach.uvtData[i] = (currentTextureData.region.x + u * currentTextureData.region.width) / textureAtlasTexture.width;
							_pach.uvtData[i + 1] = (currentTextureData.region.y + v * currentTextureData.region.height) / textureAtlasTexture.height;
						}
						
						for (i = 0, l = _pach.vertices.length; i < l; ++i)
						{
							_pach.vertices[i] = this._meshData.vertices[i];
						}
						
						for (i = 0, l = _pach.indices.length; i < l; ++i)
						{
							_pach.indices[i] = this._meshData.vertexIndices[i];
						}
						
						meshDisplay.graphics.clear();
						
						this._pivotX = 0;
						this._pivotY = 0;
						
						if (texture)
						{
							_meshTexture = texture;
							meshDisplay.graphics.beginBitmapFill(texture, null, false, true);
							meshDisplay.graphics.drawTriangles(_pach.vertices, _pach.indices, _pach.uvtData);
						}
						
						if (this._meshData.skinned)
						{
							//const transformationMatrix:Matrix = meshDisplay.transform.matrix;
							//transformationMatrix.identity();
							//meshDisplay.transform.matrix = transformationMatrix;
							meshDisplay.transform.matrix = null;
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
						
						this._pivotX = currentDisplayData.pivot.x;
						this._pivotY = currentDisplayData.pivot.y;
						
						if (currentDisplayData.isRelativePivot)
						{
							this._pivotX = width * this._pivotX;
							this._pivotY = height * this._pivotY;
						}
						
						if (currentTextureData.frame)
						{
							this._pivotX += currentTextureData.frame.x;
							this._pivotY += currentTextureData.frame.y;
						}
						
						if (rawDisplayData && rawDisplayData != currentDisplayData)
						{
							this._pivotX += rawDisplayData.transform.x - currentDisplayData.transform.x;
							this._pivotY += rawDisplayData.transform.y - currentDisplayData.transform.y;
						}
						
						if (currentTextureData.rotated)
						{
							width = currentTextureData.region.height;
							height = currentTextureData.region.width;
						}
						else
						{
							height = currentTextureData.region.height;
							width = currentTextureData.region.width;
						}
						
						const scale:Number = 1 / currentTextureData.parent.scale;
						
						if (currentTextureData.rotated)
						{
							_helpMatrix.a = 0;
							_helpMatrix.b = -scale;
							_helpMatrix.c = scale;
							_helpMatrix.d = 0;
							_helpMatrix.tx = -this._pivotX - currentTextureData.region.y;
							_helpMatrix.ty = -this._pivotY + currentTextureData.region.x + height;
						}
						else
						{
							_helpMatrix.a = scale;
							_helpMatrix.b = 0;
							_helpMatrix.c = 0;
							_helpMatrix.d = scale;
							_helpMatrix.tx = -this._pivotX - currentTextureData.region.x;
							_helpMatrix.ty = -this._pivotY - currentTextureData.region.y;
						}
						
						frameDisplay.graphics.clear();
						
						if (texture)
						{
							frameDisplay.graphics.beginBitmapFill(texture, _helpMatrix, false, true);
							frameDisplay.graphics.drawRect(-this._pivotX, -this._pivotY, width, height);
						}
					}
					
					this._updateVisible(); //
					
					return;
				}
			}
			
			this._pivotX = 0;
			this._pivotY = 0;
			
			frameDisplay.graphics.clear();
			frameDisplay.visible = false; //
			frameDisplay.x = this.origin.x;
			frameDisplay.y = this.origin.y;
		}
		
		/**
		 * @private
		 */
		override protected function _updateMesh():void
		{
			const meshDisplay:Shape = this._meshDisplay as Shape;
			
			if (!meshDisplay.visible)
			{
				return;	
			}
			
			const hasFFD:Boolean = this._ffdVertices.length > 0;
			
			var i:uint = 0, iH:uint = 0, iF:uint = 0, l:uint = this._meshData.vertices.length;
			var xG:Number = 0, yG:Number = 0;
			if (this._meshData.skinned)
			{
				meshDisplay.graphics.clear();
				
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
					
					_pach.vertices[i] = xG;
					_pach.vertices[i + 1] = yG;
				}
				
				meshDisplay.graphics.beginBitmapFill(_meshTexture, null, false, true);
				meshDisplay.graphics.drawTriangles(_pach.vertices, _pach.indices, _pach.uvtData);
			}
			else if (hasFFD)
			{
				meshDisplay.graphics.clear();
				
				const vertices:Vector.<Number> = this._meshData.vertices;
				for (i = 0; i < l; i += 2)
				{
					xG = vertices[i] + this._ffdVertices[i];
					yG = vertices[i + 1] + this._ffdVertices[i + 1];
					_pach.vertices[i] = xG;
					_pach.vertices[i + 1] = yG;
				}
				
				meshDisplay.graphics.beginBitmapFill(_meshTexture, null, true, true);
				meshDisplay.graphics.drawTriangles(_pach.vertices, _pach.indices, _pach.uvtData);
			}
		}
		
		/**
		 * @private
		 */
		override protected function _updateTransform():void
		{
			_renderDisplay.transform.matrix = this.globalTransformMatrix;
		}
	}
}