package dragonBones.starling
{
	import flash.display.BlendMode;
	import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.VertexBoneData;
	import dragonBones.objects.VertexData;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Mesh;
	import starling.styles.MeshStyle;
	
	
	
	use namespace dragonBones_internal;
	
	public class StarlingSlot extends Slot
	{
		private var _starlingDisplay:DisplayObject
		
		public function StarlingSlot()
		{
			super(this);
			
			_starlingDisplay = null;
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
		
		/** @private */
		override dragonBones_internal function updateDisplay(value:Object):void
		{
			_starlingDisplay = value as DisplayObject;
		}
		
		
		//Abstract method
		
		/** @private */
		override dragonBones_internal function getDisplayIndex():int
		{
			if(_starlingDisplay && _starlingDisplay.parent)
			{
				return _starlingDisplay.parent.getChildIndex(_starlingDisplay);
			}
			return -1;
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
		override dragonBones_internal function updateTransform():void
		{
			if(_starlingDisplay && (!_meshData || !_meshData.skinned))
			{
				var pivotX:Number = _starlingDisplay.pivotX;
				var pivotY:Number = _starlingDisplay.pivotY;
				
				_starlingDisplay.transformationMatrix = _globalTransformMatrix;
				
				if(pivotX || pivotY)
				{
					_starlingDisplay.pivotX = pivotX;
					_starlingDisplay.pivotY = pivotY;
				}
			}
		}
		
		/** @private */
		override dragonBones_internal function updateDisplayVisible(value:Boolean):void
		{
			if(_starlingDisplay && this._parent)
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
			bMultiplier:Number,
			colorChanged:Boolean = false):void
		{
			if(_starlingDisplay)
			{
				super.updateDisplayColor(aOffset, rOffset, gOffset, bOffset, aMultiplier, rMultiplier, gMultiplier, bMultiplier,colorChanged);
				_starlingDisplay.alpha = aMultiplier;
				
				if (_starlingDisplay is Mesh)
				{
					(_starlingDisplay as Mesh).color = (uint(rMultiplier * 0xff) << 16) + (uint(gMultiplier * 0xff) << 8) + uint(bMultiplier * 0xff);
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
					case starling.display.BlendMode.NONE:
					case starling.display.BlendMode.AUTO:
					case starling.display.BlendMode.ADD:
					case starling.display.BlendMode.ERASE:
					case starling.display.BlendMode.MULTIPLY:
					case starling.display.BlendMode.NORMAL:
					case starling.display.BlendMode.SCREEN:
						_starlingDisplay.blendMode = blendMode;
						break;
					
					case flash.display.BlendMode.ADD:
						_starlingDisplay.blendMode = starling.display.BlendMode.ADD;
						break;
					
					case flash.display.BlendMode.ERASE:
						_starlingDisplay.blendMode = starling.display.BlendMode.ERASE;
						break;
					
					case flash.display.BlendMode.MULTIPLY:
						_starlingDisplay.blendMode = starling.display.BlendMode.MULTIPLY;
						break;
					
					case flash.display.BlendMode.NORMAL:
						_starlingDisplay.blendMode = starling.display.BlendMode.NORMAL;
						break;
					
					case flash.display.BlendMode.SCREEN:
						_starlingDisplay.blendMode = starling.display.BlendMode.SCREEN;
						break;
					
					case flash.display.BlendMode.ALPHA:
					case flash.display.BlendMode.DARKEN:
					case flash.display.BlendMode.DIFFERENCE:
					case flash.display.BlendMode.HARDLIGHT:
					case flash.display.BlendMode.INVERT:
					case flash.display.BlendMode.LAYER:
					case flash.display.BlendMode.LIGHTEN:
					case flash.display.BlendMode.OVERLAY:
					case flash.display.BlendMode.SHADER:
					case flash.display.BlendMode.SUBTRACT:
						break;
					
					default:
						break;
				}
			}
		}
		
		/**
		 * @private
		 */
		override dragonBones_internal function updateMesh():void
		{
			var mesh:Mesh = _starlingDisplay as Mesh;
			if (!mesh)
			{
				return;
			}
			
			var i:uint = 0;
			var iD:uint = 0;
			var l:uint = 0;
			var style:MeshStyle = mesh.style;
			
			if (_meshData.skinned)
			{
				const bones:Vector.<Bone> = this._armature.getBones(false);
				for (i = 0, l = _meshData.numVertex; i < l; i++)
				{
					const vertexBoneData:VertexBoneData = _meshData.vertexBones[i];
					var j:uint = 0;
					var jD:uint = 0;
					var xL:Number = 0;
					var yL:Number = 0;
					var xG:Number = 0;
					var yG:Number = 0;
					iD = i * 2;
					
					for each (var boneIndex:uint in vertexBoneData.indices)
					{
						const bone:Bone = this._meshBones[boneIndex];
						const matrix:Matrix = bone._globalTransformMatrix;
						const point:Point = vertexBoneData.vertices[j];
						const weight:Number = vertexBoneData.weights[j];
						
						if (!this._ffdVertices || iD < _ffdOffset || iD >= this._ffdVertices.length)
						{
							xL = point.x;
							yL = point.y;
						}
						else
						{
							xL = point.x + this._ffdVertices[iD - _ffdOffset + jD];
							yL = point.y + this._ffdVertices[iD - _ffdOffset + jD + 1];
						}
						
						xG += (matrix.a * xL + matrix.c * yL + matrix.tx) * weight;
						yG += (matrix.b * xL + matrix.d * yL + matrix.ty) * weight;
						
						j++;
						jD = j * 2;
					}
					
					style.setVertexPosition(i, xG, yG);
				}
			}
			else if (_ffdChanged)
			{
				_ffdChanged = false;
				
				for (i = 0, l = _meshData.numVertex; i < l; ++i)
				{
					const vertexData:VertexData = _meshData.vertices[i];
					iD = i * 2;
					if (iD < _ffdOffset || iD >= this._ffdVertices.length)
					{
						xG = vertexData.x;
						yG = vertexData.y;
					}
					else
					{
						xG = vertexData.x + this._ffdVertices[iD - _ffdOffset];
						yG = vertexData.y + this._ffdVertices[iD - _ffdOffset + 1];
					}
					
					style.setVertexPosition(i, xG, yG);
				}
			}
			
		}
	}
}