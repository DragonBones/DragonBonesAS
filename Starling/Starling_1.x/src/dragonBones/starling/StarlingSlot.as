package dragonBones.starling
{
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import dragonBones.Slot;
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
		/**
		 * @private
		 */
		dragonBones_internal static const EMPTY_TEXTURE:Texture = Texture.empty(1, 1);
		
		public var transformUpdateEnabled:Boolean = false;
		
		private var _renderDisplay:DisplayObject = null;
		
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
			const container:StarlingArmatureDisplay = this._armature._display as StarlingArmatureDisplay;
			container.addChild(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override protected function _replaceDisplay(value:Object):void
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
				const replacedDisplayData:DisplayData = this._displayIndex < this._replacedDisplayDataSet.length? this._replacedDisplayDataSet[this._displayIndex]: null;
				const currentDisplayData:DisplayData = replacedDisplayData || rawDisplayData;
				const currentTextureData:StarlingTextureData = currentDisplayData.textureData as StarlingTextureData;
				
				if (currentTextureData)
				{
					if (!currentTextureData.texture)
					{
						const textureAtlasTexture:Texture = (currentTextureData.parent as StarlingTextureAtlasData).texture;
						if (textureAtlasTexture)
						{
							currentTextureData.texture = new SubTexture(textureAtlasTexture, currentTextureData.region, false, null, currentTextureData.rotated);
						}
					}
					
					const currentTexture:Texture = (this._armature._replacedTexture as Texture) || currentTextureData.texture;
					
					if (currentTexture)
					{
						if (this._meshData && this._display == this._meshDisplay)
						{
							// TODO
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
							
							var pivotX:Number = currentDisplayData.pivot.x;
							var pivotY:Number = currentDisplayData.pivot.y;
							
							if (currentDisplayData.isRelativePivot)
							{
								pivotX = width * pivotX;
								pivotY = height * pivotY;
							}
							
							if (currentTextureData.frame)
							{
								pivotX += currentTextureData.frame.x;
								pivotY += currentTextureData.frame.y;
							}
							
							if (rawDisplayData && rawDisplayData != currentDisplayData)
							{
								pivotX += currentDisplayData.transform.x - rawDisplayData.transform.x;
								pivotY += currentDisplayData.transform.y - rawDisplayData.transform.y;
							}
							
							frameDisplay.texture = currentTexture;
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
			// TODO
		}
		
		/**
		 * @private
		 */
		override protected function _updateTransform():void
		{
			const pivotX:Number = _renderDisplay.pivotX;
			const pivotY:Number = _renderDisplay.pivotY;
			
			if (transformUpdateEnabled)
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
					displayMatrix.tx = this.globalTransformMatrix.tx - (this.globalTransformMatrix.a * pivotX + this.globalTransformMatrix.c * pivotY);
					displayMatrix.ty = this.globalTransformMatrix.ty - (this.globalTransformMatrix.b * pivotX + this.globalTransformMatrix.d * pivotY);
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