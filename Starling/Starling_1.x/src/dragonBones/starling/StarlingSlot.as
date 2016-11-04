package dragonBones.starling
{
	import flash.geom.Matrix;
	
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
			const frameDisplay:Image = this._rawDisplay as Image; // TODO
			
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
							// TODO
						}
						else
						{
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