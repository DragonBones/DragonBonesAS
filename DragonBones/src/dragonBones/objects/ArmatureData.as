package dragonBones.objects
{
	import flash.geom.Rectangle;
	
	import dragonBones.core.BaseObject;
	
	/**
	 * @language zh_CN
	 * 骨架数据。
	 * @see dragonBones.Armature
	 * @version DragonBones 3.0
	 */
	public class ArmatureData extends BaseObject
	{
		private static function _onSortSlots(a:SlotData, b:SlotData):int
		{
			return a.zOrder > b.zOrder? 1: -1;
		}
		
		/**
		 * @language zh_CN
		 * 动画帧率。
		 * @version DragonBones 3.0
		 */
		public var frameRate:uint;
		
		/**
		 * @language zh_CN
		 * 骨架类型。
		 * @version DragonBones 3.0
		 */
		public var type:int;
		
		/**
		 * @language zh_CN
		 * 数据名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		
		/**
		 * @private
		 */
		public var parent:DragonBonesData;
		
		/**
		 * @private
		 */
		public const aabb:Rectangle = new Rectangle();
		
		/**
		 * @language zh_CN
		 * 所有的骨骼数据。
		 * @see dragonBones.objects.BoneData
		 * @version DragonBones 3.0
		 */
		public const bones:Object = {};
		
		/**
		 * @language zh_CN
		 * 所有的插槽数据。
		 * @see dragonBones.objects.SlotData
		 * @version DragonBones 3.0
		 */
		public const slots:Object = {};
		
		/**
		 * @language zh_CN
		 * 所有的皮肤数据。
		 * @see dragonBones.objects.SkinData
		 * @version DragonBones 3.0
		 */
		public const skins:Object = {};
		
		/**
		 * @language zh_CN
		 * 所有的动画数据。
		 * @see dragonBones.objects.AnimationData
		 * @version DragonBones 3.0
		 */
		public const animations:Object = {};
		
		/**
		 * @private
		 */
		public const actions: Vector.<ActionData> = new Vector.<ActionData>(0, true);
		
		/**
		 * @private
		 */
		public var cacheFrameRate:uint;
		
		/**
		 * @private
		 */
		public var scale:Number;
		
		private var _boneDirty:Boolean;
		private var _slotDirty:Boolean;
		private var _defaultSkin:SkinData;
		private var _defaultAnimation:AnimationData;
		private const _animationNames:Vector.<String> = new Vector.<String>();
		private const _sortedBones:Vector.<BoneData> = new Vector.<BoneData>(0, true);
		private const _sortedSlots:Vector.<SlotData> = new Vector.<SlotData>(0, true);
		private const _bonesChildren:Object = {};
		
		/**
		 * @private
		 */
		public function ArmatureData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			frameRate = 0;
			type = 0;
			name = null;
			parent = null;
			aabb.x = 0;
			aabb.y = 0;
			aabb.width = 0;
			aabb.height = 0;
			
			var i:String = null;
			
			for (i in bones)
			{
				(bones[i] as BoneData).returnToPool();
				delete bones[i];
			}
			
			for (i in slots)
			{
				(slots[i] as SlotData).returnToPool();
				delete slots[i];
			}
			
			for (i in skins)
			{
				(skins[i] as SkinData).returnToPool();
				delete skins[i];
			}
			
			for (i in animations)
			{
				(animations[i] as AnimationData).returnToPool();
				delete animations[i];
			}
			
			if (actions.length) 
			{
				for each (var actionData:ActionData in actions) 
				{
					actionData.returnToPool();
				}
				
				actions.fixed = false;
				actions.length = 0;
				actions.fixed = true;	
			}
			
			cacheFrameRate = 0;
			scale = 1;
			
			_boneDirty = false;
			_slotDirty = false;
			_defaultSkin = null;
			_defaultAnimation = null;
			_animationNames.length = 0;
			
			if (_sortedBones.length)
			{
				_sortedBones.fixed = false;
				_sortedBones.length = 0;
				_sortedBones.fixed = true;	
			}
			
			if (_sortedSlots.length)
			{
				_sortedSlots.fixed = false;
				_sortedSlots.length = 0;
				_sortedSlots.fixed = true;	
			}
			
			for (i in _bonesChildren)
			{
				delete _bonesChildren[i];
			}
		}
		
		private function _sortBones():void
		{
			const total:uint = _sortedBones.length;
			if (!total)
			{
				return;
			}
			
			const sortHelper:Vector.<BoneData> = _sortedBones.concat();
			var index:uint = 0;
			var count:uint = 0;
			
			_sortedBones.length = 0;
			
			while(count < total)
			{
				const bone:BoneData = sortHelper[index++];
				
				if (index >= total)
				{
					index = 0;
				}
				
				if (_sortedBones.indexOf(bone) >= 0)
				{
					continue;
				}
				
				if (bone.parent && _sortedBones.indexOf(bone.parent) < 0)
				{
					continue;
				}
				
				if (bone.ik && _sortedBones.indexOf(bone.ik) < 0)
				{
					continue;
				}
				
				if (bone.ik && bone.chain > 0 && bone.chainIndex == bone.chain)
				{
					_sortedBones.splice(_sortedBones.indexOf(bone.parent) + 1, 0, bone); // ik, parent, bone, children
				}
				else
				{
					_sortedBones.push(bone);
				}
				
				count++;
			}
		}
		
		private function _sortSlots():void
		{
			_sortedSlots.sort(_onSortSlots);
		}
		
		/**
		 * @private
		 */
		public function cacheFrames(value:uint):void
		{
			if (cacheFrameRate == value)
			{
				return;
			}
			
			cacheFrameRate = value;
			
			const frameScale:Number = cacheFrameRate / frameRate;
			for each (var animation:AnimationData in animations)
			{
				animation.cacheFrames(frameScale);
			}
		}
		
		/**
		 * @private
		 */
		public function addBone(value:BoneData, parentName:String):void
		{
			if (value && value.name && !bones[value.name])
			{
				if (parentName)
				{
					const parent:BoneData = getBone(parentName);
					if (parent)
					{
						value.parent = parent;
					}
					else
					{
						(_bonesChildren[parentName] = _bonesChildren[parentName] || new Vector.<BoneData>()).push(value);
					}
				}
				
				const children:Vector.<BoneData> = _bonesChildren[value.name];
				if (children)
				{
					for each (var child:BoneData in children)
					{
						child.parent = value;
					}
					
					delete _bonesChildren[value.name];
				}
				
				bones[value.name] = value;
				
				if (_sortedBones.fixed)
				{
					_sortedBones.fixed = false;
				}
				
				_sortedBones.push(value);
				_boneDirty = true;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * @private
		 */
		public function addSlot(value:SlotData):void
		{
			if (value && value.name && !slots[value.name])
			{
				slots[value.name] = value;
				
				if (_sortedSlots.fixed)
				{
					_sortedSlots.fixed = false;
				}
				
				_sortedSlots.push(value);
				_slotDirty = true;
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * @private
		 */
		public function addSkin(value:SkinData):void
		{
			if (value && value.name && !skins[value.name])
			{
				skins[value.name] = value;
				if (!_defaultSkin)
				{
					_defaultSkin = value;
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * @private
		 */
		public function addAnimation(value:AnimationData):void
		{
			if (value && value.name && !animations[value.name])
			{
				animations[value.name] = value;
				_animationNames.push(value.name);
				
				if (!_defaultAnimation)
				{
					_defaultAnimation = value;
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * @language zh_CN
		 * 获取指定名称的骨骼数据。
		 * @param name 骨骼数据名称。
		 * @see dragonBones.objects.BoneData
		 * @version DragonBones 3.0
		 */
		public function getBone(name:String):BoneData
		{
			return bones[name] as BoneData;
		}
		
		/**
		 * @language zh_CN
		 * 获取指定名称的插槽数据。
		 * @param name 插槽数据名称。
		 * @see dragonBones.objects.SlotData
		 * @version DragonBones 3.0
		 */
		public function getSlot(name:String):SlotData
		{
			return slots[name] as SlotData;
		}
		
		/**
		 * @language zh_CN
		 * 获取指定名称的皮肤数据。
		 * @param name 皮肤数据名称。
		 * @see dragonBones.objects.SkinData
		 * @version DragonBones 3.0
		 */
		public function getSkin(name:String):SkinData
		{
			return name? (skins[name] as SkinData): _defaultSkin;
		}
		
		/**
		 * @language zh_CN
		 * 获取指定名称的动画数据。
		 * @param name 动画数据名称。
		 * @see dragonBones.objects.AnimationData
		 * @version DragonBones 3.0
		 */
		public function getAnimation(name:String):AnimationData
		{
			return name? (animations[name] as AnimationData): _defaultAnimation;
		}
		
		/**
		 * @private
		 */
		public function get sortedBones():Vector.<BoneData>
		{
			if (_boneDirty)
			{
				_boneDirty = false;
				_sortBones();
				_sortedBones.fixed = true;
			}
			
			return _sortedBones;
		}
		
		/**
		 * @private
		 */
		public function get sortedSlots():Vector.<SlotData>
		{
			if (_slotDirty)
			{
				_slotDirty = false;
				_sortSlots();
				_sortedSlots.fixed = true;
			}
			
			return _sortedSlots;
		}
		
		/**
		 * @language zh_CN
		 * 获取默认的皮肤数据。
		 * @see dragonBones.objects.SkinData
		 * @version DragonBones 4.5
		 */
		public function get defaultSkin():SkinData
		{
			return _defaultSkin;
		}
		
		/**
		 * @language zh_CN
		 * 获取默认的动画数据。
		 * @see dragonBones.objects.AnimationData
		 * @version DragonBones 4.5
		 */
		public function get defaultAnimation():AnimationData
		{
			return _defaultAnimation;
		}
		
		/**
		 * @private
		 */
		public function get animationNames():Vector.<String>
		{
			return _animationNames;
		}
	}
}