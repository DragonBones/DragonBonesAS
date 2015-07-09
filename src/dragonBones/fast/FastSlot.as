package dragonBones.fast
{
	import flash.errors.IllegalOperationError;
	import flash.geom.ColorTransform;
	
	import dragonBones.animation.SlotTimelineState;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.fast.animation.FastAnimationState;
	import dragonBones.fast.animation.FastSlotTimelineState;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.Frame;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.SlotFrame;

	use namespace dragonBones_internal;
	
	public class FastSlot extends FastDBObject
	{
		/** @private Need to keep the reference of DisplayData. When slot switch displayObject, it need to restore the display obect's origional pivot. */
		dragonBones_internal var _displayDataList:Vector.<DisplayData>;
		/** @private */
		dragonBones_internal var _originZOrder:Number;
		/** @private */
		dragonBones_internal var _tweenZOrder:Number;
		/** @private */
		protected var _offsetZOrder:Number;
		
		protected var _displayList:Array;
		protected var _currentDisplayIndex:int;
		dragonBones_internal var _colorTransform:ColorTransform;
		dragonBones_internal var _isColorChanged:Boolean;
		protected var _currentDisplay:Object;
		dragonBones_internal var _isShowDisplay:Boolean;
		
		protected var _blendMode:String;
		
		/** @private */
		dragonBones_internal var _timelineState:FastSlotTimelineState;
		
		public var hasChildArmature:Boolean;
		public function FastSlot(self:FastSlot)
		{
			super();
			
			if(self != this)
			{
				throw new IllegalOperationError("Abstract class can not be instantiated!");
			}
			hasChildArmature = false;
			_displayList = [];
			_currentDisplayIndex = -1;
			
			_originZOrder = 0;
			_tweenZOrder = 0;
			_offsetZOrder = 0;
			_isShowDisplay = false;
			_colorTransform = new ColorTransform();
			_isColorChanged = false;
			_displayDataList = null;
			_currentDisplay = null;
			
			this.inheritRotation = true;
			this.inheritScale = true;
		}
		
		public function initWithSlotData(slotData:SlotData):void
		{
			name = slotData.name;
			blendMode = slotData.blendMode;
			_originZOrder = slotData.zOrder;
			_displayDataList = slotData.displayDataList;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if(!_displayList)
			{
				return;
			}
			
			super.dispose();
			
			_displayList.length = 0;
			
			_displayDataList = null;
			_displayList = null;
			_currentDisplay = null;
			//_childArmature = null;
			_timelineState = null;
			
		}
		
		private function sortState(state1:SlotTimelineState, state2:SlotTimelineState):int
		{
			return state1._animationState.layer < state2._animationState.layer?-1:1;
		}
		
//		//骨架装配
//		/** @private */
//		override dragonBones_internal function setArmature(value:FastArmature):void
//		{
//			if(_armature == value)
//			{
//				return;
//			}
//			if(_armature)
//			{
//				_armature.removeSlotFromSlotList(this);
//			}
//			_armature = value;
//			if(_armature)
//			{
//				_armature.addSlotToSlotList(this);
//				_armature._slotsZOrderChanged = true;
//				addDisplayToContainer(this._armature.display);
//			}
//			else
//			{
//				removeDisplayFromContainer();
//			}
//		}
		
		//动画
		/** @private */
		override dragonBones_internal function updateByCache():void
		{
			super.updateByCache();
			updateTransform();
		}
		
		/** @private */
		dragonBones_internal function update():void
		{
			if(this._parent._needUpdate <= 0)
			{
				return;
			}
			
			updateGlobal();
			updateTransform();
		}
		
		override protected function calculateRelativeParentTransform():void
		{
			_global.copy(this._origin);
		}
		
		private function updateChildArmatureAnimation():void
		{
			var targetArmature:FastArmature = childArmature;
			if(targetArmature)
			{
				if(_isShowDisplay)
				{
					if(	this.armature &&
						this.armature.animation.animationState &&
						targetArmature.animation.hasAnimation(this.armature.animation.animationState.name))
					{
						targetArmature.animation.gotoAndPlay(this.armature.animation.animationState.name);
					}
					else
					{
						targetArmature.animation.play();
					}
				}
				else
				{
					targetArmature.animation.stop();
					targetArmature.animation.animationState = null;
				}
			}
		}
		
		/** @private */
		dragonBones_internal function changeDisplay(displayIndex:int):void
		{
			if (displayIndex < 0)
			{
				if(_isShowDisplay)
				{
					_isShowDisplay = false;
					removeDisplayFromContainer();
					updateChildArmatureAnimation();
				}
			}
			else if (_displayList.length > 0)
			{
				var length:uint = _displayList.length;
				if(displayIndex >= length)
				{
					displayIndex = length - 1;
				}
				
				if(_currentDisplayIndex != displayIndex)
				{
					_isShowDisplay = true;
					_currentDisplayIndex = displayIndex;
					updateSlotDisplay();
					//updateTransform();//解决当时间和bone不统一时会换皮肤时会跳的bug
					updateChildArmatureAnimation();
					if(
						_displayDataList && 
						_displayDataList.length > 0 && 
						_currentDisplayIndex < _displayDataList.length
					)
					{
						this._origin.copy(_displayDataList[_currentDisplayIndex].transform);
					}
				}
				else if(!_isShowDisplay)
				{
					_isShowDisplay = true;
					if(this.armature)
					{
						this.armature._slotsZOrderChanged = true;
						addDisplayToContainer(this.armature.display);
					}
					updateChildArmatureAnimation();
				}
				
			}
		}
		
		/** @private 
		 * Updates the display of the slot.
		 */
		dragonBones_internal function updateSlotDisplay():void
		{
			var currentDisplayIndex:int = -1;
			if(_currentDisplay)
			{
				currentDisplayIndex = getDisplayIndex();
				removeDisplayFromContainer();
			}
			var displayObj:Object = _displayList[_currentDisplayIndex];
			if (displayObj)
			{
				if(displayObj is FastArmature)
				{
					//_childArmature = display as Armature;
					_currentDisplay = (displayObj as FastArmature).display;
				}
				else
				{
					//_childArmature = null;
					_currentDisplay = displayObj;
				}
			}
			else
			{
				_currentDisplay = null;
				//_childArmature = null;
			}
			updateDisplay(_currentDisplay);
			if(_currentDisplay)
			{
				if(this.armature && _isShowDisplay)
				{
					if(currentDisplayIndex < 0)
					{
						this.armature._slotsZOrderChanged = true;
						addDisplayToContainer(this.armature.display);
					}
					else
					{
						addDisplayToContainer(this.armature.display, currentDisplayIndex);
					}
				}
				updateDisplayBlendMode(_blendMode);
				updateDisplayColor(	_colorTransform.alphaOffset, 
									_colorTransform.redOffset, 
									_colorTransform.greenOffset, 
									_colorTransform.blueOffset,
									_colorTransform.alphaMultiplier, 
									_colorTransform.redMultiplier, 
									_colorTransform.greenMultiplier, 
									_colorTransform.blueMultiplier,
									_isColorChanged);
				updateDisplayVisible(_visible);
				updateTransform();
			}
		}
		
		/** @private */
		override public function set visible(value:Boolean):void
		{
			if(this._visible != value)
			{
				this._visible = value;
				updateDisplayVisible(this._visible);
			}
		}
		
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
			
			//为什么要修改_currentDisplayIndex?
			if (_currentDisplayIndex < 0)
			{
				_currentDisplayIndex = 0;
			}
			var i:int = _displayList.length = value.length;
			var item:Object;
			while(i --)
			{
				item = value[i];
				_displayList[i] = item;
				if(item is FastArmature)
				{
					this.hasChildArmature = true;
				}
			}
			
			//在index不改变的情况下强制刷新 TO DO需要修改
			var displayIndexBackup:int = _currentDisplayIndex;
			_currentDisplayIndex = -1;
			changeDisplay(displayIndexBackup);
			updateTransform();
		}
		
		/**
		 * The DisplayObject belonging to this Slot instance. Instance type of this object varies from flash.display.DisplayObject to startling.display.DisplayObject and subclasses.
		 */
		public function get display():Object
		{
			return _currentDisplay;
		}
		public function set display(value:Object):void
		{
			if (_currentDisplayIndex < 0)
			{
				_currentDisplayIndex = 0;
			}
			if(_displayList[_currentDisplayIndex] == value)
			{
				return;
			}
			_displayList[_currentDisplayIndex] = value;
			updateSlotDisplay();
			updateChildArmatureAnimation();
			updateTransform();//是否可以延迟更新？
		}
		
		/**
		 * The sub-armature of this Slot instance.
		 */
		public function get childArmature():FastArmature
		{
			return _displayList[_currentDisplayIndex] is FastArmature ? _displayList[_currentDisplayIndex] : null;
		}
		public function set childArmature(value:FastArmature):void
		{
			//设计的不好，要修改
			display = value;
		}
		
		/**
		 * zOrder. Support decimal for ensure dynamically added slot work toghther with animation controled slot.  
		 * @return zOrder.
		 */
		public function get zOrder():Number
		{
			return _originZOrder + _tweenZOrder + _offsetZOrder;
		}
		public function set zOrder(value:Number):void
		{
			if(zOrder != value)
			{
				_offsetZOrder = value - _originZOrder - _tweenZOrder;
				if(this.armature)
				{
					this.armature._slotsZOrderChanged = true;
				}
			}
		}
		
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
		
		//Abstract method
		
		/**
		 * @private
		 */
		dragonBones_internal function updateDisplay(value:Object):void
		{
			throw new IllegalOperationError("Abstract method needs to be implemented in subclass!");
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function getDisplayIndex():int
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
		 * Updates the transform of the slot.
		 */
		dragonBones_internal function updateTransform():void
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
			bMultiplier:Number,
			colorChanged:Boolean = false
		):void
		{
			_colorTransform.alphaOffset = aOffset;
			_colorTransform.redOffset = rOffset;
			_colorTransform.greenOffset = gOffset;
			_colorTransform.blueOffset = bOffset;
			_colorTransform.alphaMultiplier = aMultiplier;
			_colorTransform.redMultiplier = rMultiplier;
			_colorTransform.greenMultiplier = gMultiplier;
			_colorTransform.blueMultiplier = bMultiplier;
			_isColorChanged = colorChanged;
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
		
		/** @private When slot timeline enter a key frame, call this func*/
		dragonBones_internal function arriveAtFrame(frame:Frame, animationState:FastAnimationState):void
		{
			var slotFrame:SlotFrame = frame as SlotFrame;
			var displayIndex:int = slotFrame.displayIndex;
			changeDisplay(displayIndex);
			updateDisplayVisible(slotFrame.visible);
			if(displayIndex >= 0)
			{
				if(!isNaN(slotFrame.zOrder) && slotFrame.zOrder != _tweenZOrder)
				{
					_tweenZOrder = slotFrame.zOrder;
					this.armature._slotsZOrderChanged = true;
				}
			}
			
			//[TODO]currently there is only gotoAndPlay belongs to frame action. In future, there will be more.  
			//后续会扩展更多的action，目前只有gotoAndPlay的含义
			if(frame.action) 
			{
				var targetArmature:FastArmature = childArmature;
				if (targetArmature)
				{
					targetArmature.animation.gotoAndPlay(frame.action);
				}
			}
		}
	}
}