package dragonBones
{
	import dragonBones.animation.Animation;
	import dragonBones.animation.IAnimateble;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.IArmatureDisplay;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	import dragonBones.events.IEventDispatcher;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 骨架，是骨骼动画系统的核心，由显示容器、骨骼、插槽、动画、事件系统构成。
	 * @see dragonBones.objects.ArmatureData
	 * @see dragonBones.Bone
	 * @see dragonBones.Slot
	 * @see dragonBones.animation.Animation
	 * @see dragonBones.core.IArmatureDisplayContainer
	 * @version DragonBones 3.0
	 */
	public final class Armature extends BaseObject implements IAnimateble
	{
		private static function _onSortSlots(a:Slot, b:Slot):int 
		{
			return a._zOrder > b._zOrder ? 1 : -1;
		}
		
		/**
		 * @language zh_CN
		 * 可以用于存储临时数据。
		 * @version DragonBones 3.0
		 */
		public var userData:Object;
		
		/**
		 * @private Bone
		 */
		dragonBones_internal var _bonesDirty:Boolean;
		
		/**
		 * @private AnimationState
		 */
		dragonBones_internal var _cacheFrameIndex:int;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _armatureData:ArmatureData;
		
		/**
		 * @private Factory AnimationState
		 */
		dragonBones_internal var _skinData:SkinData;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _animation:Animation;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _display:IArmatureDisplay;
		
		/**
		 * @private Slot
		 */
		dragonBones_internal var _parent:Slot;
		
		/**
		 * @private Slot
		 */
		dragonBones_internal var _replacedTexture:*;
		
		/**
		 * @private Slot
		 */
		dragonBones_internal var _eventManager:IEventDispatcher;
		
		/**
		 * @private
		 */
		private var _delayDispose:Boolean;
		
		/**
		 * @private
		 */
		private var _lockDispose:Boolean;
		
		/**
		 * @private
		 */
		private var _slotsDirty:Boolean;
		
		/**
		 * @private Store bones based on bones' hierarchy (From root to leaf)
		 */
		private const _bones:Vector.<Bone> = new Vector.<Bone>(0, true);
		
		/**
		 * @private Store slots based on slots' zOrder (From low to high)
		 */
		private const _slots:Vector.<Slot> = new Vector.<Slot>(0, true);
		
		/**
		 * @private
		 */
		private const _actions:Vector.<ActionData> = new Vector.<ActionData>();
		
		/**
		 * @private
		 */
		private const _events:Vector.<EventObject> = new Vector.<EventObject>();
		
		/**
		 * @private
		 */
		public function Armature()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			if (_bones.length)
			{
				for each (var bone:Bone in _bones)
				{
					bone.returnToPool();
				}
				
				_bones.fixed = false;
				_bones.length = 0;
				_bones.fixed = true;
			}
			
			if (_slots.length)
			{
				for each (var slot:Slot in _slots)
				{
					slot.returnToPool();
				}
				
				_slots.fixed = false;
				_slots.length = 0;
				_slots.fixed = true;
			}
			
			for each (var event:EventObject in _events)
			{
				event.returnToPool();
			}
			
			if (_animation)
			{
				_animation.returnToPool();
			}
			
			if (_display)
			{
				_display._onClear();
			}
			
			userData = null;
			
			_bonesDirty = false;
			_cacheFrameIndex = -1;
			_armatureData = null;
			_skinData = null;
			
			_animation = null;
			_display = null;
			_parent = null;
			_eventManager = null;
			
			_delayDispose = false;
			_lockDispose = false;
			_slotsDirty = false;
			_replacedTexture = null;
			_actions.length = 0;
			_events.length = 0;
		}
		
		/**
		 * @private
		 */
		private function _sortBones():void
		{
			const total:uint = _bones.length;
			if (total <= 0)
			{
				return;
			}
			
			const sortHelper:Vector.<Bone> = _bones.concat();
			var index:uint = 0;
			var count:uint = 0;
			
			_bones.length = 0;
			
			while(count < total)
			{
				const bone:Bone = sortHelper[index++];
				
				if (index >= total)
				{
					index = 0;
				}
				
				if (_bones.indexOf(bone) >= 0)
				{
					continue;
				}
				
				if (bone.parent && _bones.indexOf(bone.parent) < 0)
				{
					continue;
				}
				
				if (bone.ik && _bones.indexOf(bone.ik) < 0)
				{
					continue;
				}
				
				if (bone.ik && bone.ikChain > 0 && bone.ikChainIndex == bone.ikChain)
				{
					_bones.splice(_bones.indexOf(bone.parent) + 1, 0, bone); // ik, parent, bone, children
				}
				else
				{
					_bones.push(bone);
				}
				
				count++;
			}
		}
		
		/**
		 * @private
		 */
		private function _sortSlots():void
		{
			_slots.sort(_onSortSlots);
		}
		
		/**
		 * @private
		 */
		private function _doAction(value:ActionData):void
		{
			switch (value.type) 
			{
				case DragonBones.ACTION_TYPE_PLAY:
					_animation.play(value.data[0], value.data[1]);
					break;
				
				case DragonBones.ACTION_TYPE_STOP:
					_animation.stop(value.data[0]);
					break;
				
				case DragonBones.ACTION_TYPE_GOTO_AND_PLAY:
					_animation.gotoAndPlayByTime(value.data[0], value.data[1], value.data[2]);
					break;
				
				case DragonBones.ACTION_TYPE_GOTO_AND_STOP:
					_animation.gotoAndStopByTime(value.data[0], value.data[1]);
					break;
				
				case DragonBones.ACTION_TYPE_FADE_IN:
					_animation.fadeIn(value.data[0], value.data[1], value.data[2]);
					break;
				
				case DragonBones.ACTION_TYPE_FADE_OUT:
					// TODO fade out
					break;
				
				default:
					break;
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _addBoneToBoneList(value:Bone):void
		{
			if (_bones.indexOf(value) < 0)
			{
				_bonesDirty = true;
				_bones.fixed = false;
				_bones.push(value);
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _addSlotToSlotList(value:Slot):void
		{
			if (_slots.indexOf(value) < 0)
			{
				_slotsDirty = true;
				_slots.fixed = false;
				_slots.push(value);
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _sortZOrder(slotIndices: Vector.<int>):void 
		{
			const sortedSlots:Vector.<SlotData> = _armatureData.sortedSlots;
			const isOriginal:Boolean = slotIndices.length < 1;
			
			for (var i:uint = 0, l:uint = sortedSlots.length; i < l; ++i) 
			{
				const slotIndex:int = isOriginal? i: slotIndices[i];
				const slotData:SlotData = sortedSlots[slotIndex];
				const slot:Slot = getSlot(slotData.name);
				
				if (slot && slot._zOrder != i) 
				{
					slot._zOrder = i;
					slot._zOrderDirty = true;
				}
			}
			
			_slotsDirty = true;
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _bufferAction(value:ActionData):void
		{
			_actions.push(value);
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _bufferEvent(value:EventObject, type:String):void
		{
			value.type = type;
			value.armature = this;
			_events.push(value);
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _addBone(value:Bone, parentName:String = null):void
		{
			if (value)
			{
				value._setArmature(this);
				value._setParent(parentName? getBone(parentName): null);
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _addSlot(value:Slot, parentName:String):void
		{
			const bone:Bone = getBone(parentName);
			if (bone)
			{
				value._setArmature(this);
				value._setParent(bone);
			}
		}
		
		/**
		 * @language zh_CN
		 * 释放骨架。 (会回收到内存池)
		 * @version DragonBones 3.0
		 */
		public function dispose():void
		{
			_delayDispose = true;
			
			if (!_lockDispose && _animation) // 
			{
				this.returnToPool();
			}
		}
		
		/**
		 * @language zh_CN
		 * 更新骨架和动画。 (可以使用时钟实例或显示容器来更新)
		 * @param passedTime 两帧之前的时间间隔。 (以秒为单位)
		 * @see dragonBones.animation.IAnimateble
		 * @see dragonBones.animation.WorldClock
		 * @see dragonBones.core.IArmatureDisplay
		 * @version DragonBones 3.0
		 */
		public function advanceTime(passedTime:Number):void
		{
			if (!_animation)
			{
				throw new Error("The armature has been disposed.");
			}
			
			const scaledPassedTime:Number = passedTime * _animation.timeScale;
			
			//
			_animation._advanceTime(scaledPassedTime);
			
			//
			if (_bonesDirty)
			{
				_bonesDirty = false;
				_sortBones();
				_bones.fixed = true;
			}
			
			if (_slotsDirty)
			{
				_slotsDirty = false;
				_sortSlots();
				_slots.fixed = true;
			}
			
			//
			var i:uint = 0, l:uint = 0;
			
			for (i = 0, l = _bones.length; i < l; ++i)
			{
				_bones[i]._update(_cacheFrameIndex);
			}
			
			for (i = 0, l = _slots.length; i < l; ++i)
			{
				const slot:Slot = _slots[i];
				
				slot._update(_cacheFrameIndex);
				
				const childArmature:Armature = slot._childArmature;
				if (childArmature)
				{
					if (slot.inheritAnimation) // Animation's time scale will impact to childArmature
					{
						childArmature.advanceTime(scaledPassedTime);
					}
					else
					{
						childArmature.advanceTime(passedTime);
					}
				}
			}
			
			// 
			if (DragonBones.debugDraw)
			{
				_display._debugDraw();
			}
			
			if (!_lockDispose)
			{
				_lockDispose = true;
				
				
				// Actions and events.
				if (_events.length > 0) // Dispatch event before action.
				{
					for (i = 0, l = _events.length; i < l; ++i)
					{
						const event:EventObject = _events[i];
						
						if (event.type == EventObject.SOUND_EVENT)
						{
							_eventManager._dispatchEvent(event);
						}
						else
						{
							_display._dispatchEvent(event);
						}
						
						event.returnToPool();
					}
					
					_events.length = 0;
				}
				
				if (_actions.length > 0) 
				{
					for (i = 0, l = _actions.length; i < l; ++i) 
					{
						const action:ActionData = _actions[i];
						if (action.slot) 
						{
							const eachSlot:Slot = getSlot(action.slot.name);
							if (eachSlot) 
							{
								const childArmatureA:Armature = eachSlot._childArmature;
								if (childArmatureA) 
								{
									childArmatureA._doAction(action);
								}
							}
						} 
						else if (action.bone) 
						{
							for (i = 0, l = _slots.length; i < l; ++i) 
							{
								const childArmatureB:Armature = _slots[i]._childArmature;
								if (childArmature) 
								{
									childArmature._doAction(action);
								}
							}
						} 
						else 
						{
							_doAction(action);
						}
					}
					
					_actions.length = 0;
				}
				
				_lockDispose = false;
			}
			
			if (_delayDispose)
			{
				this.returnToPool();
			}
		}
		
		/**
		 * @language zh_CN
		 * 更新骨骼和插槽的变换。 (当骨骼没有动画状态或动画状态播放完成时，骨骼将不在更新)
		 * @param boneName 指定的骨骼名称，如果未设置，将更新所有骨骼。
		 * @param updateSlotDisplay 是否更新插槽的显示对象。
		 * @see dragonBones.Bone
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function invalidUpdate(boneName:String = null, updateSlotDisplay:Boolean = false):void
		{
			var slot:Slot = null;
			
			if (boneName)
			{
				const bone:Bone = getBone(boneName);
				if (bone)
				{
					bone.invalidUpdate();
					
					if (updateSlotDisplay)
					{
						for each (slot in _slots)
						{
							if (slot.parent == bone)
							{
								slot.invalidUpdate();
							}
						}
					}
				}
			}
			else
			{
				for each (var eachBone:Bone in _bones)
				{
					eachBone.invalidUpdate();
				}
				
				if (updateSlotDisplay)
				{
					for each (slot in _slots)
					{
						slot.invalidUpdate();
					}
				}
			}
		}
		
		/**
		 * @language zh_CN
		 * 获取指定名称的骨骼。
		 * @param name 骨骼的名称。
		 * @return 骨骼。
		 * @see dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function getBone(name:String):Bone
		{
			for each(var bone:Bone in _bones)
			{
				if (bone.name == name)
				{
					return bone;
				}
			}
			
			return null;
		}
		
		/**
		 * @language zh_CN
		 * 通过显示对象获取骨骼。
		 * @param display 显示对象。
		 * @return 包含这个显示对象的骨骼。
		 * @see dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function getBoneByDisplay(display:Object):Bone
		{
			const slot:Slot = getSlotByDisplay(display);
			
			return slot? slot.parent: null;
		}
		
		/**
		 * @language zh_CN
		 * 获取指定名称的插槽。
		 * @param name 插槽的名称。
		 * @return 插槽。
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function getSlot(name:String):Slot
		{
			for each(var slot:Slot in _slots)
			{
				if (slot.name == name)
				{
					return slot;
				}
			}
			
			return null;
		}
		
		/**
		 * @language zh_CN
		 * 通过显示对象获取插槽。
		 * @param display 显示对象。
		 * @return 包含这个显示对象的插槽。
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function getSlotByDisplay(display:Object):Slot
		{
			if (display)
			{
				for each(var slot:Slot in _slots)
				{
					if (slot.display == display)
					{
						return slot;
					}
				}
			}
			
			return null;
		}
		
		/**
		 * @language zh_CN
		 * 替换骨架的主贴图，根据渲染引擎的不同，提供不同的贴图数据。
		 * @param texture 贴图。
		 * @version DragonBones 4.5
		 */
		public function replaceTexture(texture:Object):void
		{
			replacedTexture = texture;
		}
		
		/**
		 * @language zh_CN
		 * 获取所有骨骼。
		 * @see dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function getBones():Vector.<Bone>
		{
			return _bones;
		}
		
		/**
		 * @language zh_CN
		 * 获取所有插槽。
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function getSlots():Vector.<Slot>
		{
			return _slots;
		}
		
		/**
		 * @language zh_CN
		 * 骨架名称。
		 * @see dragonBones.objects.ArmatureData#name
		 * @version DragonBones 3.0
		 */
		public function get name():String
		{
			return _armatureData? _armatureData.name: null;
		}
		
		/**
		 * @language zh_CN
		 * 获取骨架数据。
		 * @see dragonBones.objects.ArmatureData
		 * @version DragonBones 4.5
		 */
		public function get armatureData():ArmatureData
		{
			return _armatureData;
		}
		
		/**
		 * @language zh_CN
		 * 获取动画控制器。
		 * @see dragonBones.animation.Animation
		 * @version DragonBones 3.0
		 */
		public function get animation():Animation	
		{
			return _animation;
		}
		
		/**
		 * @language zh_CN
		 * 获取显示容器，插槽的显示对象都会以此显示容器为父级，根据渲染平台的不同，类型会不同，通常是 DisplayObjectContainer 类型。
		 * @version DragonBones 3.0
		 */
		public function get display():IArmatureDisplay
		{
			return _display;
		}
		
		/**
		 * @language zh_CN
		 * 获取父插槽。 (当此骨架是某个骨架的子骨架时，可以通过此属性向上查找从属关系)
		 * @see dragonBones.Slot
		 * @version DragonBones 4.5
		 */
		public function get parent():Slot
		{
			return _parent;
		}
		
		/**
		 * @language zh_CN
		 * 动画缓存的帧率，当设置一个大于 0 的帧率时，将会开启动画缓存。
		 * 通过将动画数据缓存在内存中来提高运行性能，会有一定的内存开销。
		 * 帧率不宜设置的过高，通常跟动画的帧率相当且低于程序运行的帧率。
		 * 开启动画缓存后，某些功能将会失效，比如 Bone 和 Slot 的 offset 属性等。
		 * @see dragonBones.objects.DragonBonesData#frameRate
		 * @see dragonBones.objects.ArmatureData#frameRate
		 * @version DragonBones 4.5
		 */
		public function get cacheFrameRate():uint
		{
			return _armatureData.cacheFrameRate;
		}
		public function set cacheFrameRate(value:uint):void
		{
			if (_armatureData.cacheFrameRate != value)
			{
				_armatureData.cacheFrames(value);
				
				// Set child armature frameRate.
				
				for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
				{
					const slot:Slot = _slots[i];
					const childArmature:Armature = slot.childArmature;
					if (childArmature && childArmature.cacheFrameRate == 0) 
					{
						childArmature.cacheFrameRate = value;
					}
				}
			}
		}
		
		/**
		 * @language zh_CN
		 * 替换骨架的主贴图，根据渲染引擎的不同，提供不同的贴图数据。
		 * @version DragonBones 4.5
		 */
		public function get replacedTexture():Object 
		{
			return _replacedTexture;
		}
		public function set replacedTexture(value:Object):void
		{
			_replacedTexture = value;
			
			for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
			{
				_slots[i].invalidUpdate();
			}
		}
		
		/**
		 * @language zh_CN
		 * 是否包含指定类型的事件。
		 * @param type 事件类型。
		 * @return  [true: 包含, false: 不包含]
		 * @version DragonBones 3.0
		 */
		public function hasEventListener(type:String):void
		{
			_display.hasEvent(type);
		}
		
		/**
		 * @language zh_CN
		 * 添加指定事件。
		 * @param type 事件类型。
		 * @param listener 事件回调。
		 * @version DragonBones 3.0
		 */
		public function addEventListener(type:String, listener:Function):void
		{
			_display.addEvent(type, listener);
		}
		
		/**
		 * @language zh_CN
		 * 移除指定事件。
		 * @param type 事件类型。
		 * @param listener 事件回调。
		 * @version DragonBones 3.0
		 */
		public function removeEventListener(type:String, listener:Function):void
		{
			_display.removeEvent(type, listener);
		}
	}
}