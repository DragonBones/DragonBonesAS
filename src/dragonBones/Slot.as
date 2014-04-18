package dragonBones
{
	import flash.errors.IllegalOperationError;
	import flash.geom.Matrix;
	
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.FrameCached;
	import dragonBones.objects.TimelineCached;
	import dragonBones.utils.TransformUtil;
	
	use namespace dragonBones_internal;
	
	public class Slot
	{
		public var name:String;
		
		/**
		 * An object that can contain any user extra data.
		 */
		public var userData:Object;
		
		/** @private 需要保持引用DisplayData，slot在切换显示对象时，需要还原显示对象的原始轴点，因为在动画制作过程中，同一个slot的不同显示对象的轴点位置是不一定相同的*/
		dragonBones_internal var _dislayDataList:Vector.<DisplayData>;
		
		/** @private */
		dragonBones_internal var _originZOrder:Number;
		
		/** @private */
		dragonBones_internal var _tweenZorder:Number;
		
		/** @private */
		dragonBones_internal var _isShowDisplay:Boolean;
		
		/** @private */
		protected var _localTransformMatrix:Matrix;
		
		/** @private */
		protected var _globalTransformMatrix:Matrix;
		
		/** @private */
		protected var _offsetZOrder:Number;
		
		/** @private */
		protected var _displayIndex:int;
		
		/**
		 * zOrder. Support decimal for ensure dynamically added slot work toghther with animation controled slot.  
		 * @return zOrder.
		 */
		public function get zOrder():Number
		{
			return _originZOrder + _tweenZorder + _offsetZOrder;
		}
		public function set zOrder(value:Number):void
		{
			if(zOrder != value)
			{
				_offsetZOrder = value - _originZOrder - _tweenZorder;
				if(_armature)
				{
					_armature._slotsZOrderChanged = true;
				}
			}
		}
		
		/** @private */
		protected var _visible:Boolean;
		public function get visible():Boolean
		{
			return _visible;
		}
		public function set visible(value:Boolean):void
		{
			_visible = value;
			if(_visible != value)
			{
				_visible = value;
				updateDisplayVisible(_visible);
			}
		}
		
		protected var _blendMode:String;
		/**
		 * blendMode
		 * @return blendMode.
		 */
		public function get blendMode():String
		{
			return _blendMode;
		}
		public function set blendMode(value:String):void
		{
			if(_blendMode != value)
			{
				_blendMode = value;
				updateDisplayBlendMode(_blendMode);
			}
		}
		
		/** @private */
		protected var _armature:Armature;
		/**
		 * The armature this Slot instance belongs to.
		 */
		public function get armature():Armature
		{
			return _armature;
		}
		/** @private */
		dragonBones_internal function setArmature(value:Armature):void
		{
			_armature = value;
		}
		
		/** @private */
		protected var _parent:Bone;
		/**
		 * Indicates the Bone instance that directly contains this Slot instance if any.
		 */
		public function get parent():Bone
		{
			return _parent;
		}
		/** @private */
		dragonBones_internal function setParent(value:Bone):void
		{
			if(_parent)
			{
				_parent.removeSlot(this);
			}
			_parent = value;
			if(_parent)
			{
				_parent.addSlot(this);
			}
		}
		
		protected var _display:Object;
		/**
		 * The DisplayObject belonging to this Slot instance. Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 */
		public function get display():Object
		{
			return null;
		}
		public function set display(value:Object):void
		{
			if(_displayList[_displayIndex] == value)
			{
				return;
			}
			_childArmature = null;
			_displayList[_displayIndex] = value;
			updateDisplay(value);
		}
		
		protected var _childArmature:Armature;
		/**
		 * The sub-armature of this Slot instance.
		 */
		public function get childArmature():Armature
		{
			return _childArmature;
		}
		public function set childArmature(value:Armature):void
		{
			if(_displayList[_displayIndex] == value)
			{
				return;
			}
			_childArmature = value;
			_displayList[_displayIndex] = _childArmature;
			if(_childArmature)
			{
				updateDisplay(_childArmature.display);
			}
			else
			{
				updateDisplay(null);
			}
		}

		//
		protected var _displayList:Array;
		/**
		 * The DisplayObject list belonging to this Slot instance (display or armature). Replace it to implement switch texture.
		 */
		public function get displayList():Array
		{
			return _displayList;
		}
		public function set displayList(value:Array):void
		{
			if(!value)
			{
				throw new ArgumentError();
			}
			var i:int = _displayList.length = value.length;
			while(i --)
			{
				_displayList[i] = value[i];
				//changeDisplay(i);
				//update();
			}
			
			if(_displayIndex >= 0)
			{
				var displayIndexBackup:int = _displayIndex;
				_displayIndex = -1;
				changeDisplay(displayIndexBackup);
			}
		}
		
		/** @private */
		dragonBones_internal function changeDisplay(displayIndex:int):void
		{
			if(displayIndex < 0)
			{
				if(_isShowDisplay)
				{
					_isShowDisplay = false;
					removeDisplayFromContainer();
					updateChildArmatureAnimation();
				}
			}
			else
			{
				var length:uint = _displayList.length;
				if(displayIndex >= length)
				{
					displayIndex = length - 1;
					if(displayIndex < 0)
					{
						displayIndex = 0;
					}
				}
				
				if(_displayIndex != displayIndex)
				{
					_displayIndex = displayIndex;
					
					var content:Object = _displayList[_displayIndex];
					if(content is Armature)
					{
						_childArmature = content as Armature;
						updateDisplay(_childArmature.display);
					}
					else
					{
						_childArmature = null;
						updateDisplay(content);
					}
					
					if(
						_dislayDataList && 
						_dislayDataList.length > 0 && 
						_displayIndex < _dislayDataList.length
					)
					{
						TransformUtil.transformToMatrix(_dislayDataList[_displayIndex].transform, _localTransformMatrix);
					}
				}
				else if(!_isShowDisplay)
				{
					if(_armature)
					{
						addDisplayToContainer(_armature.display);
						_armature._slotsZOrderChanged = true;
					}
					updateChildArmatureAnimation();
					_isShowDisplay = true;
				}
			}
		}
		
		/**
		 * Creates a Slot blank instance.
		 */
		public function Slot(self:Slot)
		{
			if(self != this)
			{
				throw new IllegalOperationError("Abstract class can not be instantiated!");
			}
			
			_displayList = [];
			_displayIndex = -1;
			
			_originZOrder = 0;
			_tweenZorder = 0;
			_offsetZOrder = 0;
			_dislayDataList = null;
			_isShowDisplay = false;
			
			_visible = true;
			_parent = null;
			_childArmature = null;
			_display = null;
			
			_localTransformMatrix = new Matrix();
			_globalTransformMatrix = new Matrix();
			
			userData = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			_displayList.length = 0;
			
			_displayList = null;
			_dislayDataList = null;
			_childArmature = null;
			_armature = null;
			_parent = null;
			_childArmature = null;
			_display = null;
			
			_localTransformMatrix = null;
			_globalTransformMatrix = null;
			
			userData = null;
		}
		
		/** @private */
		dragonBones_internal function update():void
		{
			if(_parent._needUpdate <= 0)
			{
				return;
			}
			
			var frameCached:FrameCached;
			if(name && _parent._frameCached)
			{
				frameCached = _parent._frameCached.slotFrameCachedMap[name];
				if(frameCached)
				{
					_globalTransformMatrix.copyFrom(frameCached.matrix);
					
					updateTransform();
					return;
				}
				
				_parent._frameCached.slotFrameCachedMap[name] = frameCached = new FrameCached();
			}
			
			var parentMatrix:Matrix = _parent._globalTransformMatrix;
			
			_globalTransformMatrix.copyFrom(_localTransformMatrix);
			_globalTransformMatrix.concat(parentMatrix);
			
			var pivotX:Number = _parent._tweenPivot.x;
			var pivotY:Number = _parent._tweenPivot.y;
			if(pivotX || pivotY)
			{
				_globalTransformMatrix.tx += parentMatrix.a * pivotX + parentMatrix.c * pivotY;
				_globalTransformMatrix.ty += parentMatrix.b * pivotX + parentMatrix.d * pivotY;
			}
			
			if(frameCached)
			{
				frameCached.matrix = new Matrix();
				frameCached.matrix.copyFrom(_globalTransformMatrix);
			}
			
			updateTransform();
		}
		
		private function updateChildArmatureAnimation():void
		{
			/*var childArmature:Armature = this.childArmature;
			
			if(childArmature)
			{
				if(_isHideDisplay)
				{
					childArmature.animation.stop();
					childArmature.animation._lastAnimationState = null;
				}
				else
				{
					if(
						_armature &&
						_armature.animation.lastAnimationState &&
						childArmature.animation.hasAnimation(_armature.animation.lastAnimationState.name)
					)
					{
						childArmature.animation.gotoAndPlay(_armature.animation.lastAnimationState.name);
					}
					else
					{
						childArmature.animation.play();
					}
				}
			}*/
		}
		
		/** @private 
		 * Updates the display of the slot.
		 */
		dragonBones_internal function updateDisplay(value:Object):void
		{
			_display = value;
			if(_armature)
			{
				addDisplayToContainer(_armature.display);
				_armature._slotsZOrderChanged = true;
			}
			updateDisplayBlendMode(_blendMode);
			
			updateChildArmatureAnimation();
		}
		
		
		//Abstract method
		
		/**
		 * @private
		 * Updates the transform of the slot.
		 */
		dragonBones_internal function updateTransform():void
		{
			throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
		}
		
		/**
		 * @private
		 * Adds the original display object to another display object.
		 * @param container
		 * @param index
		 */
		dragonBones_internal function addDisplayToContainer(container:Object, index:int = -1):void
		{
			throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
		}
		
		/**
		 * @private
		 * remove the original display object from its parent.
		 */
		dragonBones_internal function removeDisplayFromContainer():void
		{
			throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function updateDisplayVisible(value:Boolean):void
		{
			/**
			 * bone.visible && slot.visible && updateVisible
			 * this._parent.visible && this._visible && value;
			 */
			throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
		}
		
		/**
		 * @private
		 * Updates the color of the display object.
		 * @param a
		 * @param r
		 * @param g
		 * @param b
		 * @param aM
		 * @param rM
		 * @param gM
		 * @param bM
		 */
		dragonBones_internal function updateDisplayColor(
			aOffset:Number, 
			rOffset:Number, 
			gOffset:Number, 
			bOffset:Number, 
			aMultiplier:Number, 
			rMultiplier:Number, 
			gMultiplier:Number, 
			bMultiplier:Number):void
		{
			throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
		}
		
		/**
		 * @private
         * Update the blend mode of the display object.
         * @param value The blend mode to use. 
         */
		dragonBones_internal function updateDisplayBlendMode(value:String):void
		{
			throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
		}
	}
}