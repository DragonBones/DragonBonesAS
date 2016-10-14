package dragonBones.starling
{
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import dragonBones.Slot;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DisplayData;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
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
		private static var _emptyEtexture:Texture = null;
		/**
		 * @private
		 */
		dragonBones_internal static function getEmptyTexture():Texture
		{
			if (!_emptyEtexture)
			{
				_emptyEtexture = Texture.empty(1, 1);
			}
			
			return _emptyEtexture;
		}
		
		
		public var transformUpdateEnabled:Boolean;
		
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
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			transformUpdateEnabled = false;
			
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
				this._rawDisplay = new Image(getEmptyTexture());	
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
		override dragonBones_internal function _getDisplayZIndex():int
		{
			const container:StarlingArmatureDisplay = this._armature._display as StarlingArmatureDisplay;
			return container.getChildIndex(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override dragonBones_internal function _setDisplayZIndex(value:int):void
		{
			const container:StarlingArmatureDisplay = this._armature.display as StarlingArmatureDisplay;
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
			const frameDisplay:Image = this._rawDisplay as Image; // TODO
			
			if (this._display && this._displayIndex >= 0)
			{
				const rawDisplayData:DisplayData = this._displayIndex < this._displayDataSet.displays.length? this._displayDataSet.displays[this._displayIndex]: null;
				const replacedDisplayData:DisplayData = this._displayIndex < this._replacedDisplayDataSet.length? this._replacedDisplayDataSet[this._displayIndex]: null;
				const currentDisplayData:DisplayData = replacedDisplayData || rawDisplayData;
				const currentTextureData:StarlingTextureData = currentDisplayData.texture as StarlingTextureData;
				
				if (currentTextureData)
				{
					const textureAtlasTexture:Texture = (currentTextureData.parent as StarlingTextureAtlasData).texture;
					if (textureAtlasTexture)
					{
						if (!currentTextureData.texture)
						{
							currentTextureData.texture = new SubTexture(textureAtlasTexture, currentTextureData.region, false, null, currentTextureData.rotated);
						}
						else if (this._armature._replacedTexture)
						{
							const texture:Texture = (this._armature._replacedTexture as starling.textures.Texture) || currentTextureData.texture.parent;
							if (currentTextureData.texture.parent != texture)
							{
								currentTextureData.texture.dispose();
								currentTextureData.texture = new SubTexture(textureAtlasTexture, currentTextureData.region, false, null, currentTextureData.rotated);
							}
						}
					}
					
					this._updatePivot(rawDisplayData, currentDisplayData, currentTextureData);
					
					if (this._meshData && this._display == this._meshDisplay)
					{
					}
					else
					{
						frameDisplay.texture = currentTextureData.texture || getEmptyTexture();
						
						frameDisplay.readjustSize();
					}
					
					this._updateVisible();
					
					return;
				}
			}
			
			this._pivotX = 0;
			this._pivotY = 0;
			
			frameDisplay.visible = false;
			frameDisplay.texture = getEmptyTexture();
			frameDisplay.readjustSize();
			frameDisplay.x = this.origin.x;
			frameDisplay.y = this.origin.y;
		}
		
		/**
		 * @private
		 */
		override protected function _updateMesh():void
		{
			// TODO
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
			}
		}
	}
}