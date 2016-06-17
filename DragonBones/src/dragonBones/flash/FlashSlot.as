package dragonBones.flash
{
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DisplayData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 基于 Flash 传统显示列表的渲染插槽。
	 * @version DragonBones 3.0
	 */
	public class FlashSlot extends Slot
	{
		private static const _helpMatrix:Matrix = new Matrix();
		
		private var _renderDisplay:DisplayObject = null;
		
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
			const container:DisplayObjectContainer = this._armature.display as DisplayObjectContainer;
			container.addChild(_renderDisplay);
		}
		
		/**
		 * @private
		 */
		override protected function _replaceDisplay(prevDisplay:Object):void
		{
			const container:DisplayObjectContainer = this._armature.display as DisplayObjectContainer;
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
			frameDisplay.graphics.clear();
			
			if (this._display && this._displayIndex >= 0)
			{
				const rawDisplayData:DisplayData = this._displayIndex < this._displayDataSet.displays.length? this._displayDataSet.displays[this._displayIndex]: null;
				const replaceDisplayData:DisplayData = this._displayIndex < this._replaceDisplayDataSet.length? this._replaceDisplayDataSet[this._displayIndex]: null;
				const contentDisplayData:DisplayData = replaceDisplayData || rawDisplayData;
				const currentTextureData:FlashTextureData = contentDisplayData.textureData as FlashTextureData;
				if (currentTextureData)
				{
					const currentTexture:BitmapData = 
						(this._armature._replaceTexture as BitmapData) 
						|| (currentTextureData.parent as FlashTextureAtlasData).texture 
						|| currentTextureData.texture;
					
					if (currentTexture)
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
						
						const scale:Number = 1 / currentTextureData.parent.scale;
						
						if (currentTextureData.rotated)
						{
							_helpMatrix.a = 0;
							_helpMatrix.b = -scale;
							_helpMatrix.c = scale;
							_helpMatrix.d = 0;
							_helpMatrix.tx = -pivotX - currentTextureData.region.y;
							_helpMatrix.ty = -pivotY + currentTextureData.region.x + height;
						}
						else
						{
							_helpMatrix.a = scale;
							_helpMatrix.b = 0;
							_helpMatrix.c = 0;
							_helpMatrix.d = scale;
							_helpMatrix.tx = -pivotX - currentTextureData.region.x;
							_helpMatrix.ty = -pivotY - currentTextureData.region.y;
						}
						
						frameDisplay.graphics.beginBitmapFill(currentTexture, _helpMatrix, false, true);
						frameDisplay.graphics.drawRect(-pivotX, -pivotY, width, height);
						this._updateVisible();
						
						return;
					}
				}
			}
			
			frameDisplay.visible = false;
		}
		
		/**
		 * @private
		 */
		override protected function _updateMesh():void
		{
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