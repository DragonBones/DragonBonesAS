package dragonBones.flash
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.GraphicsTrianglePath;
	import flash.display.Shape;
	import flash.geom.Matrix;
	
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.BlendMode;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 基于 Flash 传统显示列表的插槽。
	 * @version DragonBones 3.0
	 */
	public class FlashSlot extends Slot
	{
		private var _renderDisplay:DisplayObject;
		private var _meshTexture:BitmapData;
		private var _path:GraphicsTrianglePath;
		/**
		 * @private
		 */
		public function FlashSlot()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			_renderDisplay = null;
			_meshTexture = null;
			_path = null;
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
		}
		/**
		 * @private
		 */
		override protected function _onUpdateDisplay():void
		{
			_renderDisplay = (_display? _display : _rawDisplay) as DisplayObject;
		}
		/**
		 * @private
		 */
		override protected function _addDisplay():void
		{
			const container:FlashArmatureDisplay = _armature.display as FlashArmatureDisplay;
			container.addChild(_renderDisplay);
		}
		/**
		 * @private
		 */
		override protected function _replaceDisplay(prevDisplay:Object):void
		{
			const container:FlashArmatureDisplay = _armature.display as FlashArmatureDisplay;
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
		override protected function _updateZOrder():void
		{
			const container:FlashArmatureDisplay = _armature.display as FlashArmatureDisplay;
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
					_renderDisplay.blendMode = flash.display.BlendMode.NORMAL;
					break;
				
				case dragonBones.enum.BlendMode.Add:
					_renderDisplay.blendMode = flash.display.BlendMode.ADD;
					break;
				
				case dragonBones.enum.BlendMode.Alpha:
					_renderDisplay.blendMode = flash.display.BlendMode.ALPHA;
					break;
				
				case dragonBones.enum.BlendMode.Darken:
					_renderDisplay.blendMode = flash.display.BlendMode.DARKEN;
					break;
				
				case dragonBones.enum.BlendMode.Difference:
					_renderDisplay.blendMode = flash.display.BlendMode.DIFFERENCE;
					break;
				
				case dragonBones.enum.BlendMode.Erase:
					_renderDisplay.blendMode = flash.display.BlendMode.ERASE;
					break;
				
				case dragonBones.enum.BlendMode.HardLight:
					_renderDisplay.blendMode = flash.display.BlendMode.HARDLIGHT;
					break;
				
				case dragonBones.enum.BlendMode.Invert:
					_renderDisplay.blendMode = flash.display.BlendMode.INVERT;
					break;
				
				case dragonBones.enum.BlendMode.Layer:
					_renderDisplay.blendMode = flash.display.BlendMode.LAYER;
					break;
				
				case dragonBones.enum.BlendMode.Lighten:
					_renderDisplay.blendMode = flash.display.BlendMode.LIGHTEN;
					break;
				
				case dragonBones.enum.BlendMode.Multiply:
					_renderDisplay.blendMode = flash.display.BlendMode.MULTIPLY;
					break;
				
				case dragonBones.enum.BlendMode.Overlay:
					_renderDisplay.blendMode = flash.display.BlendMode.OVERLAY;
					break;
				
				case dragonBones.enum.BlendMode.Screen:
					_renderDisplay.blendMode = flash.display.BlendMode.SCREEN;
					break;
				
				case dragonBones.enum.BlendMode.Subtract:
					_renderDisplay.blendMode = flash.display.BlendMode.SUBTRACT;
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
			_renderDisplay.transform.colorTransform = _colorTransform;
		}
		/**
		 * @private
		 */
		override protected function _updateFrame():void
		{
			const isMeshDisplay:Boolean = _meshData && _renderDisplay === _meshDisplay;
			var currentTextureData:FlashTextureData = _textureData as FlashTextureData;
			
			if (_displayIndex >= 0 && _display && currentTextureData)
			{
				var currentTextureAtlasData:FlashTextureAtlasData = currentTextureData.parent as FlashTextureAtlasData;
				
				// Update replaced texture atlas.
				if (_armature.replacedTexture && _displayData && currentTextureAtlasData === _displayData.texture.parent) 
				{
					currentTextureAtlasData = _armature._replaceTextureAtlasData as FlashTextureAtlasData;
					if (!currentTextureAtlasData) 
					{
						currentTextureAtlasData = BaseObject.borrowObject(FlashTextureAtlasData) as FlashTextureAtlasData;
						currentTextureAtlasData.copyFrom(_textureData.parent);
						currentTextureAtlasData.texture = _armature.replacedTexture as BitmapData;
						_armature._replaceTextureAtlasData = currentTextureAtlasData;
					}
					
					currentTextureData = currentTextureAtlasData.getTexture(currentTextureData.name) as FlashTextureData;
				}
				
				const currentTextureAtlas:BitmapData = currentTextureAtlasData.texture;
				if (currentTextureAtlas)
				{
					const textureAtlasWidth:Number = currentTextureAtlasData.width > 0.0 ? currentTextureAtlasData.width : currentTextureAtlas.width;
					const textureAtlasHeight:Number = currentTextureAtlasData.height > 0.0 ? currentTextureAtlasData.height : currentTextureAtlas.height;
					
					if (isMeshDisplay) // Mesh.
					{
						var meshDisplay:Shape = _renderDisplay as Shape;
						
						if (_path)
						{
							_path.uvtData.fixed = false;
							_path.vertices.fixed = false;
							_path.indices.fixed = false;
							
							_path.uvtData.length = _meshData.uvs.length;
							_path.vertices.length = _meshData.vertices.length;
							_path.indices.length = _meshData.vertexIndices.length;
							
							_path.uvtData.fixed = true;
							_path.vertices.fixed = true;
							_path.indices.fixed = true;
						}
						else
						{
							_path = new GraphicsTrianglePath(
								new Vector.<Number>(_meshData.uvs.length, true),
								new Vector.<int>(_meshData.vertexIndices.length, true),
								new Vector.<Number>(_meshData.vertices.length, true)
							);
						}
						
						var i:uint = 0, l:uint = 0;
						for (i = 0, l = _path.uvtData.length; i < l; i += 2)
						{
							const u:Number = _meshData.uvs[i];
							const v:Number = _meshData.uvs[i + 1];
							_path.uvtData[i] = (currentTextureData.region.x + u * currentTextureData.region.width) / textureAtlasWidth;
							_path.uvtData[i + 1] = (currentTextureData.region.y + v * currentTextureData.region.height) / textureAtlasHeight;
						}
						
						for (i = 0, l = _path.vertices.length; i < l; i += 2)
						{
							_path.vertices[i] = _meshData.vertices[i] - _pivotX;
							_path.vertices[i + 1] = _meshData.vertices[i + 1] - _pivotY;
						}
						
						for (i = 0, l = _path.indices.length; i < l; ++i)
						{
							_path.indices[i] = _meshData.vertexIndices[i];
						}
						
						meshDisplay.graphics.clear();
						
						if (currentTextureAtlas)
						{
							meshDisplay.graphics.beginBitmapFill(currentTextureAtlas, null, false, true);
							meshDisplay.graphics.drawTriangles(_path.vertices, _path.indices, _path.uvtData);
						}
						
						_meshTexture = currentTextureAtlas;
					}
					else // Normal texture.
					{
						var width:Number = 0;
						var height:Number = 0;
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
							_helpMatrix.tx = -_pivotX - currentTextureData.region.y;
							_helpMatrix.ty = -_pivotY + currentTextureData.region.x + height;
						}
						else
						{
							_helpMatrix.a = scale;
							_helpMatrix.b = 0;
							_helpMatrix.c = 0;
							_helpMatrix.d = scale;
							_helpMatrix.tx = -_pivotX - currentTextureData.region.x;
							_helpMatrix.ty = -_pivotY - currentTextureData.region.y;
						}
						
						var normalDisplay:Shape = _renderDisplay as Shape;
						
						normalDisplay.graphics.clear();
						
						if (currentTextureAtlas)
						{
							normalDisplay.graphics.beginBitmapFill(currentTextureAtlas, _helpMatrix, false, true);
							normalDisplay.graphics.drawRect(-_pivotX, -_pivotY, width, height);
						}
					}
					
					_updateVisible();
					
					return;
				}
			}
			
			if (isMeshDisplay)
			{
				meshDisplay = _renderDisplay as Shape;
				meshDisplay.graphics.clear();
				meshDisplay.visible = false;
				meshDisplay.x = 0.0;
				meshDisplay.y = 0.0;
			}
			else
			{
				normalDisplay = _renderDisplay as Shape;
				normalDisplay.graphics.clear();
				normalDisplay.visible = false;
				normalDisplay.x = 0.0;
				normalDisplay.y = 0.0;
			}
		}
		/**
		 * @private
		 */
		override protected function _updateMesh():void
		{
			const meshDisplay:Shape = _renderDisplay as Shape;
			
			if (!_meshTexture)
			{
				return;	
			}
			
			const hasFFD:Boolean = _ffdVertices.length > 0;
			
			var i:uint = 0, iH:uint = 0, iF:uint = 0, l:uint = _meshData.vertices.length;
			var xG:Number = 0, yG:Number = 0;
			if (_meshData.skinned)
			{
				meshDisplay.graphics.clear();
				
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
					
					_path.vertices[i] = xG - _pivotX;
					_path.vertices[i + 1] = yG - _pivotY;
				}
				
				meshDisplay.graphics.beginBitmapFill(_meshTexture, null, false, true);
				meshDisplay.graphics.drawTriangles(_path.vertices, _path.indices, _path.uvtData);
			}
			else if (hasFFD)
			{
				meshDisplay.graphics.clear();
				
				const vertices:Vector.<Number> = _meshData.vertices;
				for (i = 0; i < l; i += 2)
				{
					xG = vertices[i] + _ffdVertices[i];
					yG = vertices[i + 1] + _ffdVertices[i + 1];
					_path.vertices[i] = xG - _pivotX;
					_path.vertices[i + 1] = yG - _pivotY;
				}
				
				meshDisplay.graphics.beginBitmapFill(_meshTexture, null, true, true);
				meshDisplay.graphics.drawTriangles(_path.vertices, _path.indices, _path.uvtData);
			}
		}
		/**
		 * @private
		 */
		override protected function _updateTransform(isSkinnedMesh: Boolean):void
		{
			if (isSkinnedMesh)
			{
				_renderDisplay.transform.matrix = null;
			}
			else
			{
				_renderDisplay.transform.matrix = globalTransformMatrix;
			}
		}
	}
}