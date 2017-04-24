package dragonBones
{
	import flash.geom.Point;
	
	import dragonBones.animation.Animation;
	import dragonBones.animation.IAnimateble;
	import dragonBones.animation.WorldClock;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.IArmatureProxy;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.ActionType;
	import dragonBones.events.EventObject;
	import dragonBones.events.IEventDispatcher;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SlotData;
	import dragonBones.textures.TextureAtlasData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 骨架，是骨骼动画系统的核心，由显示容器、骨骼、插槽、动画、事件系统构成。
	 * @see dragonBones.objects.ArmatureData
	 * @see dragonBones.Bone
	 * @see dragonBones.Slot
	 * @see dragonBones.animation.Animation
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
		 * 是否继承父骨架的动画状态。
		 * @default true
		 * @version DragonBones 4.5
		 */
		public var inheritAnimation: Boolean;
		/**
		 * @private
		 */
		public var debugDraw: Boolean;
		/**
		 * @language zh_CN
		 * 用于存储临时数据。
		 * @version DragonBones 3.0
		 */
		public var userData:Object;
		
		private var _debugDraw:Boolean;
		private var _delayDispose:Boolean;
		private var _lockDispose:Boolean;
		/**
		 * @private
		 */
		dragonBones_internal var _bonesDirty:Boolean;
		private var _slotsDirty:Boolean;
		private var _zOrderDirty:Boolean;
		private const _bones:Vector.<Bone> = new Vector.<Bone>();
		private const _slots:Vector.<Slot> = new Vector.<Slot>();
		private const _actions:Vector.<ActionData> = new Vector.<ActionData>();
		private const _events:Vector.<EventObject> = new Vector.<EventObject>();
		/**
		 * @private
		 */
		dragonBones_internal var _armatureData:ArmatureData;
		/**
		 * @private
		 */
		dragonBones_internal var _skinData:SkinData;
		private var _animation:Animation;
		private var _proxy:IArmatureProxy;
		private var _display:Object;
		private var _eventManager:IEventDispatcher;
		/**
		 * @private Slot
		 */
		dragonBones_internal var _parent:Slot;
		private var _clock:WorldClock;
		/**
		 * @private
		 */
		dragonBones_internal var _replaceTextureAtlasData:TextureAtlasData;
		private var _replacedTexture:Object;
		/**
		 * @private
		 */
		public function Armature()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			for (var i:uint = 0, l:uint = _bones.length; i < l; ++i) 
			{
				_bones[i].returnToPool();
			}
			
			for (i = 0, l = _slots.length; i < l; ++i) 
			{
				_slots[i].returnToPool();
			}
			
			for (i = 0, l = _events.length; i < l; ++i) 
			{
				_events[i].returnToPool();
			}
			
			if (_clock) 
			{
				_clock.remove(this);
			}
			
			if (_proxy) 
			{
				_proxy._onClear();
			}
			
			if (_replaceTextureAtlasData) 
			{
				_replaceTextureAtlasData.returnToPool();
			}
			
			if (_animation) 
			{
				_animation.returnToPool();
			}
			
			inheritAnimation = true;
			debugDraw = false;
			userData = null;
			
			_debugDraw = false;
			_delayDispose = false;
			_lockDispose = false;
			_bonesDirty = false;
			_slotsDirty = false;
			_zOrderDirty = false;
			_bones.fixed = false;
			_bones.length = 0;
			_slots.fixed = false;
			_slots.length = 0;
			_actions.length = 0;
			_events.length = 0;
			_armatureData = null;
			_skinData = null;
			_animation = null;
			_proxy = null;
			_display = null;
			_eventManager = null;
			_parent = null;
			_clock = null;
			_replaceTextureAtlasData = null;
			_replacedTexture = null;
		}
		
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
				
				if (bone.ik && bone.ikChain > 0 && bone.ikChainIndex === bone.ikChain)
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
		
		private function _sortSlots():void
		{
			_slots.sort(_onSortSlots);
		}
		
		private function _doAction(value:ActionData):void
		{
			switch (value.type) 
			{
				case ActionType.Play:
					_animation.playConfig(value.animationConfig);
					break;
				
				default:
					break;
			}
		}
		/**
		 * @private
		 */
		public function _init(
			armatureData: ArmatureData, skinData: SkinData,
			display: Object, proxy: IArmatureProxy, eventManager: IEventDispatcher
		): void 
		{
			if (_armatureData) 
			{
				return;
			}
			
			_armatureData = armatureData;
			_skinData = skinData;
			_animation = BaseObject.borrowObject(Animation) as Animation;
			_proxy = proxy;
			_display = display;
			_eventManager = eventManager;
			
			_animation._init(this);
			_animation.animations = _armatureData.animations;
		}
		/**
		 * @private
		 */
		dragonBones_internal function _addBoneToBoneList(value:Bone):void
		{
			if (_bones.indexOf(value) < 0)
			{
				_bones.fixed = false;
				
				_bonesDirty = true;
				_bones.push(value);
				_animation._timelineStateDirty = true;
			}
		}
		/**
		 * @private
		 */
		dragonBones_internal function _removeBoneFromBoneList(value: Bone): void 
		{
			const index:int = _bones.indexOf(value);
			if (index >= 0) 
			{
				_bones.fixed = false;
				
				_bones.splice(index, 1);
				_animation._timelineStateDirty = true;
				
				_bones.fixed = true;
			}
		}
		/**
		 * @private
		 */
		dragonBones_internal function _addSlotToSlotList(value:Slot):void
		{
			if (_slots.indexOf(value) < 0)
			{
				_slots.fixed = false;
				
				_slotsDirty = true;
				_slots.push(value);
				_animation._timelineStateDirty = true;
			}
		}
		/**
		 * @internal
		 * @private
		 */
		dragonBones_internal function _removeSlotFromSlotList(value: Slot): void 
		{
			const index:int = _slots.indexOf(value);
			if (index >= 0) 
			{
				_slots.fixed = false;
				
				_slots.splice(index, 1);
				_animation._timelineStateDirty = true;
				
				_slots.fixed = true;
			}
		}
		/**
		 * @private
		 */
		dragonBones_internal function _sortZOrder(slotIndices: Vector.<int>):void 
		{
			const sortedSlots:Vector.<SlotData> = _armatureData.sortedSlots;
			const isOriginal:Boolean = !slotIndices || slotIndices.length < 1;
			
			if (_zOrderDirty || !isOriginal)
			{
				for (var i:uint = 0, l:uint = sortedSlots.length; i < l; ++i) 
				{
					const slotIndex:int = isOriginal? i: slotIndices[i];
					const slotData:SlotData = sortedSlots[slotIndex];
					
					if (slotData)
					{
						const slot:Slot = getSlot(slotData.name);
						if (slot) 
						{
							slot._setZorder(i);
						}
					}
				}
				
				_slotsDirty = true;
				_zOrderDirty = !isOriginal;
			}
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
		 * @language zh_CN
         * 释放骨架。 (回收到对象池)
		 * @version DragonBones 3.0
		 */
		public function dispose():void
		{
			if (_armatureData)
			{
				if (_lockDispose)
				{
					_delayDispose = true;
				}
				else
				{
					returnToPool();
				}
			}
		}
		/**
		 * @language zh_CN
		 * 更新骨架和动画。
         * @param passedTime 两帧之间的时间间隔。 (以秒为单位)
		 * @see dragonBones.animation.IAnimateble
		 * @see dragonBones.animation.WorldClock
		 * @version DragonBones 3.0
		 */
		public function advanceTime(passedTime:Number):void
		{
			if (!_armatureData)
			{
				throw new Error("The armature has been disposed.");
			}
			else if (!_armatureData.parent)
			{
				throw new Error("The armature data has been disposed.");
			}
			
			const prevCacheFrameIndex:int = _animation._cacheFrameIndex;
			
			// Update nimation.
			_animation._advanceTime(passedTime);
			
			const currentCacheFrameIndex:int = _animation._cacheFrameIndex;
			
			// Sort bones and slots.
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
			
			var i:uint = 0, l:uint = 0;
			
			// Update bones and slots.
			if (currentCacheFrameIndex < 0 || currentCacheFrameIndex !== prevCacheFrameIndex) 
			{
				for (i = 0, l = _bones.length; i < l; ++i)
				{
					_bones[i]._update(currentCacheFrameIndex);
				}
				
				for (i = 0, l = _slots.length; i < l; ++i)
				{
					_slots[i]._update(currentCacheFrameIndex);
				}
			}
			
			// 
			const drawed:Boolean = debugDraw || DragonBones.debugDraw;
			if (drawed || _debugDraw) 
			{
				_debugDraw = drawed;
				_proxy._debugDraw(_debugDraw);
			}
			
			if (!_lockDispose)
			{
				_lockDispose = true;
				
				// Events. (Dispatch event before action.)
				l = _events.length;
				if (l > 0) 
				{
					for (i = 0; i < l; ++i) 
					{
						const eventObject:EventObject = _events[i];
						_proxy._dispatchEvent(eventObject.type, eventObject);
						
						if (eventObject.type === EventObject.SOUND_EVENT)
						{
							_eventManager._dispatchEvent(eventObject.type, eventObject);
						}
						
						eventObject.returnToPool();
					}
					
					_events.length = 0;
				}
				
				// Actions.
				l = _actions.length;
				if (l > 0) 
				{
					for (i = 0; i < l; ++i) 
					{
						const action:ActionData = _actions[i];
						if (action.slot) 
						{
							var slot:Slot = getSlot(action.slot.name);
							if (slot) 
							{
								var childArmature:Armature = slot.childArmature;
								if (childArmature) 
								{
									childArmature._doAction(action);
								}
							}
						} 
						else if (action.bone) 
						{
							for (var iA:uint = 0, lA:uint = _slots.length; iA < lA; ++iA) 
							{
								childArmature = _slots[iA].childArmature;
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
				returnToPool();
			}
		}
		/**
		 * @language zh_CN
		 * 更新骨骼和插槽。 (当骨骼没有动画状态或动画状态播放完成时，骨骼将不在更新)
		 * @param boneName 指定的骨骼名称，如果未设置，将更新所有骨骼。
		 * @param updateSlotDisplay 是否更新插槽的显示对象。
		 * @see dragonBones.Bone
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function invalidUpdate(boneName:String = null, updateSlotDisplay:Boolean = false):void
		{
			if (boneName)
			{
				var bone:Bone = getBone(boneName);
				if (bone)
				{
					bone.invalidUpdate();
					
					if (updateSlotDisplay)
					{
						for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
						{
							var slot:Slot = _slots[i];
							if (slot.parent === bone)
							{
								slot.invalidUpdate();
							}
						}
					}
				}
			}
			else
			{
				for (i = 0, l = _bones.length; i < l; ++i) 
				{
					_bones[i].invalidUpdate();
				}
				
				if (updateSlotDisplay) 
				{
					for (i = 0, l = _slots.length; i < l; ++i) 
					{
						_slots[i].invalidUpdate();
					}
				}
			}
		}
		/**
		 * @language zh_CN
         * 判断点是否在所有插槽的自定义包围盒内。
		 * @param x 点的水平坐标。（骨架内坐标系）
		 * @param y 点的垂直坐标。（骨架内坐标系）
		 * @version DragonBones 5.0
		 */
		public function containsPoint(x: Number, y: Number): Slot 
		{
			for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
			{
				const slot:Slot = _slots[i];
				if (slot.containsPoint(x, y)) 
				{
					return slot;
				}
			}
			
			return null;
		}
		/**
		 * @language zh_CN
         * 判断线段是否与骨架的所有插槽的自定义包围盒相交。
		 * @param xA 线段起点的水平坐标。（骨架内坐标系）
		 * @param yA 线段起点的垂直坐标。（骨架内坐标系）
		 * @param xB 线段终点的水平坐标。（骨架内坐标系）
		 * @param yB 线段终点的垂直坐标。（骨架内坐标系）
		 * @param intersectionPointA 线段从起点到终点与包围盒相交的第一个交点。（骨架内坐标系）
		 * @param intersectionPointB 线段从终点到起点与包围盒相交的第一个交点。（骨架内坐标系）
		 * @param normalRadians 碰撞点处包围盒切线的法线弧度。 [x: 第一个碰撞点处切线的法线弧度, y: 第二个碰撞点处切线的法线弧度]
		 * @returns 线段从起点到终点相交的第一个自定义包围盒的插槽。
		 * @version DragonBones 5.0
		 */
		public function intersectsSegment(
			xA: Number, yA: Number, xB: Number, yB: Number,
			intersectionPointA: Point = null,
			intersectionPointB: Point = null,
			normalRadians: Point = null
		): Slot 
		{
			const isV:Boolean = xA === xB;
			var dMin:Number = 0.0;
			var dMax:Number = 0.0;
			var intXA:Number = 0.0;
			var intYA:Number = 0.0;
			var intXB:Number = 0.0;
			var intYB:Number = 0.0;
			var intAN:Number = 0.0;
			var intBN:Number = 0.0;
			var intSlotA: Slot = null;
			var intSlotB: Slot = null;
			
			for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
			{
				const slot:Slot = _slots[i];
				const intersectionCount:int = slot.intersectsSegment(xA, yA, xB, yB, intersectionPointA, intersectionPointB, normalRadians);
				if (intersectionCount > 0) 
				{
					if (intersectionPointA || intersectionPointB) 
					{
						if (intersectionPointA) 
						{
							var d:Number = isV ? intersectionPointA.y - yA : intersectionPointA.x - xA;
							if (d < 0.0) 
							{
								d = -d;
							}
							
							if (!intSlotA || d < dMin) 
							{
								dMin = d;
								intXA = intersectionPointA.x;
								intYA = intersectionPointA.y;
								intSlotA = slot;
								
								if (normalRadians) 
								{
									intAN = normalRadians.x;
								}
							}
						}
						
						if (intersectionPointB) 
						{
							d = intersectionPointB.x - xA;
							if (d < 0.0) 
							{
								d = -d;
							}
							
							if (!intSlotB || d > dMax) 
							{
								dMax = d;
								intXB = intersectionPointB.x;
								intYB = intersectionPointB.y;
								intSlotB = slot;
								
								if (normalRadians) 
								{
									intBN = normalRadians.y;
								}
							}
						}
					}
					else 
					{
						intSlotA = slot;
						break;
					}
				}
			}
			
			if (intSlotA && intersectionPointA) 
			{
				intersectionPointA.x = intXA;
				intersectionPointA.y = intYA;
				
				if (normalRadians) 
				{
					normalRadians.x = intAN;
				}
			}
			
			if (intSlotB && intersectionPointB) 
			{
				intersectionPointB.x = intXB;
				intersectionPointB.y = intYB;
				
				if (normalRadians) 
				{
					normalRadians.y = intBN;
				}
			}
			
			return intSlotA;
		}
		/**
		 * @language zh_CN
         * 获取骨骼。
		 * @param name 骨骼的名称。
		 * @return 骨骼。
		 * @see dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function getBone(name:String):Bone
		{
			for (var i:uint = 0, l:uint = _bones.length; i < l; ++i)
			{
				const bone:Bone = _bones[i];
				if (bone.name === name) 
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
         * 获取插槽。
		 * @param name 插槽的名称。
		 * @return 插槽。
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function getSlot(name:String):Slot
		{
			for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
			{
				const slot:Slot = _slots[i];
				if (slot.name === name) 
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
				for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
				{
					const slot:Slot = _slots[i];
					if (slot.display == display)
					{
						return slot;
					}
				}
			}
			
			return null;
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
         * 替换骨架的主贴图，根据渲染引擎的不同，提供不同的贴图类型。
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
		 * 获取事件监听器。
		 * @version DragonBones 5.0
		 */
		public function get eventDispatcher():IEventDispatcher
		{
			return _proxy;
		}
		/**
		 * @language zh_CN
		 * 获取显示容器，插槽的显示对象都会以此显示容器为父级，根据渲染平台的不同，类型会不同，通常是 DisplayObjectContainer 类型。
		 * @version DragonBones 3.0
		 */
		public function get display():Object
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
         * 动画缓存帧率，当设置的值大于 0 的时，将会开启动画缓存。
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
			if (_armatureData.cacheFrameRate !== value)
			{
				_armatureData.cacheFrames(value);
				
				// Set child armature frameRate.
				for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
				{
					const childArmature:Armature = _slots[i].childArmature;
					if (childArmature) 
					{
						childArmature.cacheFrameRate = value;
					}
				}
			}
		}
		/**
		 * @inheritDoc
		 */
		public function get clock(): WorldClock 
		{
			return _clock;
		}
		public function set clock(value: WorldClock) :void
		{
			if (_clock === value) 
			{
				return;
			}
			
			const prevClock:WorldClock = _clock;
			_clock = value;
			
			if (prevClock) 
			{
				prevClock.remove(this);
			}
			
			if (_clock) 
			{
				_clock.add(this);
			}
			
			// Update childArmature clock.
			for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
			{
				const childArmature:Armature = _slots[i].childArmature;
				if (childArmature) 
				{
					childArmature.clock = _clock;
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
			if (_replacedTexture === value)
			{
				return;
			}
			
			if (_replaceTextureAtlasData) 
			{
				_replaceTextureAtlasData.returnToPool();
				_replaceTextureAtlasData = null;
			}
			
			_replacedTexture = value;
			
			for (var i:uint = 0, l:uint = _slots.length; i < l; ++i) 
			{
				const slot:Slot = _slots[i];
				slot.invalidUpdate();
				slot._update(-1);
			}
		}
		
		/**
		 * @deprecated
		 * @see dragonBones.Armature#eventDispatcher
		 */
		public function hasEventListener(type:String):void
		{
			_display.hasEvent(type);
		}
		/**
		 * @deprecated
		 * @see dragonBones.Armature#eventDispatcher
		 */
		public function addEventListener(type:String, listener:Function):void
		{
			_display.addEvent(type, listener);
		}
		/**
		 * @deprecated
		 * @see dragonBones.Armature#eventDispatcher
		 */
		public function removeEventListener(type:String, listener:Function):void
		{
			_display.removeEvent(type, listener);
		}
	}
}