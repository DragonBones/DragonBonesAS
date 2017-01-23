package dragonBones
{
	import flash.geom.Matrix;
	
	import dragonBones.core.TransformObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.geom.Transform;
	import dragonBones.objects.BoneData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 骨骼，一个骨架中可以包含多个骨骼，骨骼以树状结构组成骨架。
	 * 骨骼在骨骼动画体系中是最重要的逻辑单元之一，负责动画中的平移旋转缩放的实现。
	 * @see dragonBones.objects.BoneData
	 * @see dragonBones.Armature
	 * @see dragonBones.Slot
	 * @version DragonBones 3.0
	 */
	public final class Bone extends TransformObject
	{
		/**
		 * @language zh_CN
		 * 是否继承父骨骼的平移。
		 * @version DragonBones 3.0
		 */
		public var inheritTranslation:Boolean;
		/**
		 * @language zh_CN
		 * 是否继承父骨骼的旋转。
		 * @version DragonBones 3.0
		 */
		public var inheritRotation:Boolean;
		/**
		 * @language zh_CN
		 * 是否继承父骨骼的缩放。
		 * @version DragonBones 4.5
		 */
		public var inheritScale:Boolean;
		/**
		 * @private
		 */
		public var ikBendPositive:Boolean;
		/**
		 * @language zh_CN
		 * 骨骼长度。
		 * @version DragonBones 4.5
		 */
		public var length:Number;
		/**
		 * @private
		 */
		public var ikWeight:Number;
		/**
		 * @private [2: update self, 1: update children, ik children, mesh, ..., 0: stop update]
		 */
		dragonBones_internal var _transformDirty:int;
		private var _visible:Boolean;
		private var _cachedFrameIndex:int;
		private var _ikChain:uint;
		private var _ikChainIndex:int;
		/**
		 * @private
		 */
		dragonBones_internal var _updateState:int;
		/**
		 * @private
		 */
		dragonBones_internal var _blendLayer:int;
		/**
		 * @private
		 */
		dragonBones_internal var _blendLeftWeight:Number;
		/**
		 * @private
		 */
		dragonBones_internal var _blendTotalWeight:Number;
		/**
		 * @private
		 */
		dragonBones_internal const _animationPose:Transform = new Transform();
		private const _bones:Vector.<Bone> = new Vector.<Bone>();
		private const _slots:Vector.<Slot> = new Vector.<Slot>();
		private var _boneData:BoneData;
		private var _ik:Bone;
		/**
		 * @private
		 */
		dragonBones_internal var _cachedFrameIndices:Vector.<int>;
		/**
		 * @private
		 */
		public function Bone()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			inheritTranslation = false;
			inheritRotation = false;
			inheritScale = false;
			ikBendPositive = false;
			length = 0.0;
			ikWeight = 0.0;
			
			_transformDirty = 0;
			_visible = true;
			_cachedFrameIndex = -1;
			_ikChain = 0;
			_ikChainIndex = 0;
			_updateState = -1;
			_blendLayer = 0;
			_blendLeftWeight = 1.0;
			_blendTotalWeight = 0.0;
			_animationPose.identity();
			_bones.length = 0;
			_slots.length = 0;
			_boneData = null;
			_ik = null;
			_cachedFrameIndices = null;
		}
		/**
		 * @private
		 */
		private function _updateGlobalTransformMatrix():void
		{
			global.x = origin.x + offset.x + _animationPose.x;
			global.y = origin.y + offset.y + _animationPose.y;
			global.skewX = origin.skewX + offset.skewX + _animationPose.skewX;
			global.skewY = origin.skewY + offset.skewY + _animationPose.skewY;
			global.scaleX = origin.scaleX * offset.scaleX * _animationPose.scaleX;
			global.scaleY = origin.scaleY * offset.scaleY * _animationPose.scaleY;
			
			if (_parent)
			{
				const parentRotation:Number = _parent.global.skewY; // Only inherit skew y
				const parentMatrix:Matrix = _parent.globalTransformMatrix;
				
				if (inheritScale)
				{
					if (!inheritRotation)
					{
						global.skewX -= parentRotation;
						global.skewY -= parentRotation;
					}
					
					global.toMatrix(globalTransformMatrix);
					globalTransformMatrix.concat(parentMatrix);
					
					if (!inheritTranslation)
					{
						globalTransformMatrix.tx = global.x;
						globalTransformMatrix.ty = global.y;
					}
					
					global.fromMatrix(globalTransformMatrix);
				}
				else
				{
					if (inheritTranslation)
					{
						const x:Number = global.x;
						const y:Number = global.y;
						global.x = parentMatrix.a * x + parentMatrix.c * y + parentMatrix.tx;
						global.y = parentMatrix.d * y + parentMatrix.b * x + parentMatrix.ty;
					}
					
					if (inheritRotation)
					{
						global.skewX += parentRotation;
						global.skewY += parentRotation;
					}
					
					global.toMatrix(globalTransformMatrix);
				}
			}
			else
			{
				global.toMatrix(globalTransformMatrix);
			}
			
			if (_ik && _ikChainIndex == _ikChain  && ikWeight > 0)
			{
				if (inheritTranslation && _ikChain > 0 && _parent)
				{
					_computeIKB();
				}
				else
				{
					_computeIKA();
				}
			}
		}
		/**
		 * @private
		 */
		private function _computeIKA():void
		{
			const ikGlobal:Transform = _ik.global;
			const x:Number = globalTransformMatrix.a * length;
			const y:Number = globalTransformMatrix.b * length;
			
			const ikRadian:Number = 
				(
					Math.atan2(ikGlobal.y - global.y, ikGlobal.x - global.x) + 
					offset.skewY - 
					global.skewY * 2 + 
					Math.atan2(y, x)
				) * ikWeight; // Support offset.
			
			global.skewX += ikRadian;
			global.skewY += ikRadian;
			global.toMatrix(globalTransformMatrix);
		}
		/**
		 * @private
		 */
		private function _computeIKB():void
		{
			// TODO IK
			const parentGlobal:Transform = _parent.global;
			const ikGlobal:Transform = _ik.global;
			
			const x:Number = globalTransformMatrix.a * length;
			const y:Number = globalTransformMatrix.b * length;
			
			const lLL:Number = x * x + y * y;
			const lL:Number = Math.sqrt(lLL);
			
			var dX:Number = global.x - parentGlobal.x;
			var dY:Number = global.y - parentGlobal.y;
			const lPP:Number = dX * dX + dY * dY;
			const lP:Number = Math.sqrt(lPP);
			
			dX = ikGlobal.x - parentGlobal.x;
			dY = ikGlobal.y - parentGlobal.y;
			const lTT:Number = dX * dX + dY * dY;
			const lT:Number = Math.sqrt(lTT);
			
			var ikRadianA:Number = 0;
			if (lL + lP <= lT || lT + lL <= lP || lT + lP <= lL)
			{
				ikRadianA = Math.atan2(ikGlobal.y - parentGlobal.y, ikGlobal.x - parentGlobal.x) + _parent.offset.skewY; // Support offset.
				if (lL + lP <= lT)
				{
				}
				else if (lP < lL)
				{
					ikRadianA += Math.PI;
				}
			}
			else
			{
				const h:Number = (lPP - lLL + lTT) / (2 * lTT);
				const r:Number = Math.sqrt(lPP - h * h * lTT) / lT;
				const hX:Number = parentGlobal.x + (dX * h);
				const hY:Number = parentGlobal.y + (dY * h);
				const rX:Number = -dY * r;
				const rY:Number = dX * r;
				
				if (ikBendPositive)
				{
					global.x = hX - rX;
					global.y = hY - rY;
				}
				else
				{
					global.x = hX + rX;
					global.y = hY + rY;
				}
				
				ikRadianA = Math.atan2(global.y - parentGlobal.y, global.x - parentGlobal.x) + _parent.offset.skewY; // Support offset
			}
			
			ikRadianA = (ikRadianA - parentGlobal.skewY) * ikWeight;
			
			parentGlobal.skewX += ikRadianA;
			parentGlobal.skewY += ikRadianA;
			parentGlobal.toMatrix(_parent.globalTransformMatrix);
			_parent._transformDirty = 1;
			
			global.x = parentGlobal.x + Math.cos(parentGlobal.skewY) * lP;
			global.y = parentGlobal.y + Math.sin(parentGlobal.skewY) * lP;
			
			const ikRadianB:Number = 
				(
					Math.atan2(ikGlobal.y - global.y, ikGlobal.x - global.x) + offset.skewY - 
					global.skewY * 2 + Math.atan2(y, x)
				) * ikWeight; // Support offset.
			
			global.skewX += ikRadianB;
			global.skewY += ikRadianB;
			
			global.toMatrix(globalTransformMatrix);
		}
		/**
		 * @private
		 */
		dragonBones_internal function _init(boneData: BoneData): void 
		{
			if (_boneData) 
			{
				return;
			}
			
			_boneData = boneData;
			
			inheritTranslation = _boneData.inheritTranslation;
			inheritRotation = _boneData.inheritRotation;
			inheritScale = _boneData.inheritScale;
			length = _boneData.length;
			name = _boneData.name;
			origin = _boneData.transform;
		}
		/**
		 * @private
		 */
		override dragonBones_internal function _setArmature(value:Armature):void
		{
			_armature = value;
			_armature._addBoneToBoneList(this);
		}
		/**
		 * @private
		 */
		dragonBones_internal function _setIK(value:Bone, chain:uint, chainIndex:uint):void
		{
			if (value)
			{
				if (chain == chainIndex)
				{
					var chainEnd:Bone = _parent;
					if (chain && chainEnd)
					{
						chain = 1;
					}
					else
					{
						chain = 0;
						chainIndex = 0;
						chainEnd = this;
					}
					
					if (chainEnd == value || chainEnd.contains(value))
					{
						value = null;
						chain = 0;
						chainIndex = 0;
					}
					else
					{
						var ancestor:Bone = value;
						while(ancestor.ik && ancestor.ikChain)
						{
							if (chainEnd.contains(ancestor.ik))
							{
								value = null;
								chain = 0;
								chainIndex = 0;
								break;
							}
							
							ancestor = ancestor.parent;
						}
					}
				}
			}
			else
			{
				chain = 0;
				chainIndex = 0;
			}
			
			_ik = value;
			_ikChain = chain;
			_ikChainIndex = chainIndex;
			
			if (_armature)
			{
				_armature._bonesDirty = true;
			}
		}
		/**
		 * @private
		 */
		dragonBones_internal function _update(cacheFrameIndex:int):void
		{
			_updateState = -1;
			
			if (cacheFrameIndex >= 0 && _cachedFrameIndices) 
			{
				const cachedFrameIndex:int = _cachedFrameIndices[cacheFrameIndex];
				if (cachedFrameIndex >= 0 && _cachedFrameIndex === cachedFrameIndex) // Same cache.
				{
					_transformDirty = 0;
				}
				else if (cachedFrameIndex >= 0) // Has been Cached.
				{
					_transformDirty = 2;
					_cachedFrameIndex = cachedFrameIndex;
				}
				else if (
					_transformDirty === 2 ||
					(_parent && _parent._transformDirty !== 0) ||
					(_ik && ikWeight > 0 && _ik._transformDirty !== 0)
				) // Dirty.
				{
					_transformDirty = 2;
					_cachedFrameIndex = -1;
				}
				else if (_cachedFrameIndex >= 0) // Same cache, but not set index yet.
				{
					_transformDirty = 0;
					_cachedFrameIndices[cacheFrameIndex] = _cachedFrameIndex;
				}
				else // Dirty.
				{
					_transformDirty = 2;
					_cachedFrameIndex = -1;
				}
			}
			else if (
				_transformDirty === 2 ||
				(_parent && _parent._transformDirty !== 0) ||
				(_ik && ikWeight > 0 && _ik._transformDirty !== 0)
			) // Dirty.
			{
				cacheFrameIndex = -1;
				_transformDirty = 2;
				_cachedFrameIndex = -1;
			}
			
			if (_transformDirty !== 0) 
			{
				if (_transformDirty === 2) 
				{
					_transformDirty = 1;
					
					if (_cachedFrameIndex < 0) 
					{
						_updateGlobalTransformMatrix();
						
						if (cacheFrameIndex >= 0) 
						{
							_cachedFrameIndex = _cachedFrameIndices[cacheFrameIndex] = _armature._armatureData.setCacheFrame(globalTransformMatrix, global);
						}
					}
					else 
					{
						_armature._armatureData.getCacheFrame(globalTransformMatrix, global, _cachedFrameIndex);
					}
					
					_updateState = 0;
				}
				else {
					_transformDirty = 0;
				}
			}
		}
		/**
		 * @language zh_CN
		 * 下一帧更新变换。 (当骨骼没有动画状态或动画状态播放完成时，骨骼将不在更新)
		 * @version DragonBones 3.0
		 */
		public function invalidUpdate():void
		{
			_transformDirty = 2;
		}
		/**
		 * @language zh_CN
         * 是否包含骨骼或插槽。
		 * @return
		 * @see dragonBones.core.TransformObject
		 * @version DragonBones 3.0
		 */
		public function contains(child:TransformObject):Boolean
		{
			if (child)
			{
				if (child === this)
				{
					return false;
				}
				
				var ancestor:TransformObject = child;
				while(ancestor != this && ancestor)
				{
					ancestor = ancestor.parent;
				}
				
				return ancestor === this;
			}
			
			return false;
		}
		/**
		 * @language zh_CN
		 * 所有的子骨骼。
		 * @version DragonBones 3.0
		 */
		public function getBones():Vector.<Bone>
		{
			_bones.length = 0;
			
			const bones:Vector.<Bone> = _armature.getBones();
			for (var i:uint = 0, l:uint = bones.length; i < l; ++i) 
			{
				const bone:Bone = bones[i];
				if (bone.parent === this)
				{
					_bones.push(bone);	
				}
			}
			
			return _bones;
		}
		/**
		 * @language zh_CN
		 * 所有的插槽。
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function getSlots():Vector.<Slot>
		{
			_slots.length = 0;
			
			const slots:Vector.<Slot> = _armature.getSlots();
			for (var i:uint = 0, l:uint = slots.length; i < l; ++i) 
			{
				const slot:Slot = slots[i];
				if (slot.parent === this)
				{
					_slots.push(slot);	
				}
			}
			
			return _slots;
		}
		/**
		 * @private
		 */
		public function get boneData():BoneData
		{
			return _boneData;
		}
		/**
		 * @language zh_CN
		 * 控制此骨骼所有插槽的可见。
		 * @default true
		 * @see dragonBones.Slot
		 * @version DragonBones 3.0
		 */
		public function get visible():Boolean
		{
			return _visible;
		}
		public function set visible(value:Boolean):void
		{
			if (_visible == value)
			{
				return;
			}
			
			_visible = value;
			
			const slots:Vector.<Slot> = _armature.getSlots();
			for (var i:uint = 0, l:uint = slots.length; i < l; ++i) 
			{
				const slot:Slot = slots[i];
				if (slot._parent == this)
				{
					slot._updateVisible();
				}
			}
		}
		
		/**
		 * @deprecated
		 */
		public function get ikChain():uint
		{
			return _ikChain;
		}
		/**
		 * @deprecated
		 */
		public function get ikChainIndex():int
		{
			return _ikChainIndex;
		}
		/**
		 * @deprecated
		 */
		public function get ik():Bone
		{
			return _ik;
		}
	}
}