package dragonBones.display
{
	import flash.display.BlendMode;
	import flash.geom.Matrix;
	
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	
	use namespace dragonBones_internal;
	
	public class StarlingSlot extends Slot
	{
		private var _starlingDisplay:DisplayObject;
		
		public var updateMatrix:Boolean;
		
		public function StarlingSlot()
		{
			super(this);
			
			_starlingDisplay = null;
			
			updateMatrix = false;
		}
		override public function dispose():void
		{
			for each(var content:Object in this._displayList)
			{
				if(content is Armature)
				{
					(content as Armature).dispose();
				}
				else if(content is DisplayObject)
				{
					(content as DisplayObject).dispose();
				}
			}
			super.dispose();
			
			_starlingDisplay = null;
		}
		
		override dragonBones_internal function updateDisplay(value:Object):void
		{
			_starlingDisplay = value as DisplayObject;
			
			super.updateDisplay(value);
		}
		
		
		//Abstract method
		
		/** @private */
		override dragonBones_internal function getDisplayIndex(value:Object):int
		{
			var startlingDisplay:DisplayObject = value as DisplayObject;
			return startlingDisplay.parent.getChildIndex(startlingDisplay);
		}
		
		/** @private */
		override dragonBones_internal function updateTransform():void
		{
			if(_starlingDisplay)
			{
				var pivotX:Number = _starlingDisplay.pivotX;
				var pivotY:Number = _starlingDisplay.pivotY;
				
				if(updateMatrix)
				{
					_starlingDisplay.transformationMatrix = _globalTransformMatrix;
					if(pivotX || pivotY)
					{
						_display.pivotX = pivotX;
						_display.pivotY = pivotY;
					}
				}
				else
				{
					var displayMatrix:Matrix = _starlingDisplay.transformationMatrix;
					displayMatrix.a = _globalTransformMatrix.a;
					displayMatrix.b = _globalTransformMatrix.b;
					displayMatrix.c = _globalTransformMatrix.c;
					displayMatrix.d = _globalTransformMatrix.d;
					//displayMatrix.copyFrom(_globalTransformMatrix);
					if(pivotX || pivotY)
					{
						displayMatrix.tx = _globalTransformMatrix.tx - (displayMatrix.a * pivotX + displayMatrix.c * pivotY);
						displayMatrix.ty = _globalTransformMatrix.ty - (displayMatrix.b * pivotX + displayMatrix.d * pivotY);
					}
					else
					{
						displayMatrix.tx = _globalTransformMatrix.tx;
						displayMatrix.ty = _globalTransformMatrix.ty;
					}
				}
			}
		}
		
		/** @private */
		override dragonBones_internal function addDisplayToContainer(container:Object, index:int = -1):void
		{
			var starlingContainer:DisplayObjectContainer = container as DisplayObjectContainer;
			if(_starlingDisplay && starlingContainer)
			{
				if (index < 0)
				{
					starlingContainer.addChild(_starlingDisplay);
				}
				else
				{
					starlingContainer.addChildAt(_starlingDisplay, Math.min(index, starlingContainer.numChildren));
				}
			}
		}
		
		/** @private */
		override dragonBones_internal function removeDisplayFromContainer():void
		{
			if(_starlingDisplay && _starlingDisplay.parent)
			{
				_starlingDisplay.parent.removeChild(_starlingDisplay);
			}
		}
		
		/** @private */
		override dragonBones_internal function updateDisplayVisible(value:Boolean):void
		{
			if(_starlingDisplay)
			{
				_starlingDisplay.visible = this._parent.visible && this._visible && value;
			}
		}
		
		/** @private */
		override dragonBones_internal function updateDisplayColor(
			aOffset:Number, 
			rOffset:Number, 
			gOffset:Number, 
			bOffset:Number, 
			aMultiplier:Number, 
			rMultiplier:Number, 
			gMultiplier:Number, 
			bMultiplier:Number):void
		{
			if(_starlingDisplay)
			{
				_starlingDisplay.alpha = aMultiplier;
				if (_starlingDisplay is Quad)
				{
					(_starlingDisplay as Quad).color = (uint(rMultiplier * 0xff) << 16) + (uint(gMultiplier * 0xff) << 8) + uint(bMultiplier * 0xff);
				}
			}
		}
		
		/** @private */
		override dragonBones_internal function updateDisplayBlendMode(value:String):void
		{
			if(_starlingDisplay)
			{
				switch(blendMode)
				{
					case BlendMode.ADD:
					case BlendMode.ALPHA:
					case BlendMode.DARKEN:
					case BlendMode.DIFFERENCE:
					case BlendMode.ERASE:
					case BlendMode.HARDLIGHT:
					case BlendMode.INVERT:
					case BlendMode.LAYER:
					case BlendMode.LIGHTEN:
					case BlendMode.MULTIPLY:
					case BlendMode.NORMAL:
					case BlendMode.OVERLAY:
					case BlendMode.SCREEN:
					case BlendMode.SHADER:
					case BlendMode.SUBTRACT:
						_starlingDisplay.blendMode = blendMode;
						break;
					
					default:
						break;
				}
			}
		}
	}
}