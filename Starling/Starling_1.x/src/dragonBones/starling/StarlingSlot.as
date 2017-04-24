package dragonBones.starling
{
	import flash.geom.Matrix;
	
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.BlendMode;
	
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
			
			container.addChildAt(_renderDisplay, _zOrder);
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
					
					if (isMeshDisplay) // Mesh.
					{
						// TODO
					}
					else // Normal texture.
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
				// TODO
			}
			else
			{
				normalDisplay = _renderDisplay as Image;
				normalDisplay.visible = false;
				normalDisplay.texture = getEmptyTexture();
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
			// TODO
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
				}
			}
		}
	}
}