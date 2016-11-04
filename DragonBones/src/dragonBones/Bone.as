package dragonBones
{
	import flash.geom.Matrix;
	
	import dragonBones.core.TransformObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.geom.Transform;
	import dragonBones.objects.BoneTimelineData;
	
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
		 * 是否继承父骨骼的平移。 [true: 继承, false: 不继承]
		 * @version DragonBones 3.0
		 */
		public var inheritTranslation:Boolean;
		
		/**
		 * @language zh_CN
		 * 是否继承父骨骼的旋转。 [true: 继承, false: 不继承]
		 * @version DragonBones 3.0
		 */
		public var inheritRotation:Boolean;
		
		/**
		 * @language zh_CN
		 * 是否继承父骨骼的缩放。 [true: 继承, false: 不继承]
		 * @version DragonBones 4.5
		 */
		public var inheritScale:Boolean;
		
		/**
		 * @language zh_CN
		 * IK 约束时骨骼方向是否为顺时针方向。 [true: 顺时针, false: 逆时针]
		 * @version DragonBones 4.5
		 */
		public var ikBendPositive:Boolean;
		
		/**
		 * @language zh_CN
		 * IK 约束的权重。
		 * @version DragonBones 4.5
		 */
		public var ikWeight:Number;
		
		/**
		 * @language zh_CN
		 * 骨骼长度。
		 * @version DragonBones 4.5
		 */
		public var length:Number;
		
		/**
		 * @private [2: update self, 1: update children, ik children, mesh, ..., 0: stop update]
		 */
		dragonBones_internal var _transformDirty:int;
		
		/**
		 * @private
		 */
		dragonBones_internal var _blendIndex:int;
		
		/**
		 * @private
		 */
		dragonBones_internal var _cacheFrames:Vector.<Matrix>;
		
		/**
		 * @private
		 */
		dragonBones_internal const _animationPose:Transform = new Transform();
		
		/**
		 * @private
		 */
		private var _visible:Boolean;
		
		/**
		 * @private
		 */
		private var _ikChain:uint;
		
		/**
		 * @private
		 */
		private var _ikChainIndex:int;
		
		/**
		 * @private
		 */
		private var _ik:Bone;
		
		/**
		 * @private
		 */
		private const _bones:Vector.<Bone> = new Vector.<Bone>();
		
		/**
		 * @private
		 */
		private const _slots:Vector.<Slot> = new Vector.<Slot>();
		
		/**
		 * @private
		 */
		public function Bone()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			inheritTranslation = false;
			inheritRotation = false;
			inheritScale = false;
			ikBendPositive = false;
			ikWeight = 0;
			this.length = 0;
			
			_transformDirty = 2; // Update
			_blendIndex = -1;
			_cacheFrames = null;
			_animationPose.identity();
			
			_visible = true; //
			_ikChain = 0;
			_ikChainIndex = -1;
			_ik = null;
			_bones.length = 0;
			_slots.length = 0;
		}
		
		/**
		 * @private
		 */
		private function _updateGlobalTransformMatrix():void
		{
			if (this._parent)
			{
				const parentRotation:Number = this._parent.global.skewY; // Only inherit skew y
				const parentMatrix:Matrix = this._parent.globalTransformMatrix;
				
				if (inheritScale)
				{
					if (!inheritRotation)
					{
						this.global.skewX -= parentRotation;
						this.global.skewY -= parentRotation;
					}
					
					this.global.toMatrix(this.globalTransformMatrix);
					this.globalTransformMatrix.concat(parentMatrix);
					
					if (!inheritTranslation)
					{
						this.globalTransformMatrix.tx = this.global.x;
						this.globalTransformMatrix.ty = this.global.y;
					}
					
					this.global.fromMatrix(this.globalTransformMatrix);
				}
				else
				{
					if (inheritTranslation)
					{
						const x:Number = this.global.x;
						const y:Number = this.global.y;
						this.global.x = parentMatrix.a * x + parentMatrix.c * y + parentMatrix.tx;
						this.global.y = parentMatrix.d * y + parentMatrix.b * x + parentMatrix.ty;
					}
					
					if (inheritRotation)
					{
						this.global.skewX += parentRotation;
						this.global.skewY += parentRotation;
					}
					
					this.global.toMatrix(this.globalTransformMatrix);
				}
			}
			else
			{
				this.global.toMatrix(this.globalTransformMatrix);
			}
		}
		
		/**
		 * @private
		 */
		private function _computeIKA():void
		{
			// TODO IK
			/*
			if (this._parent && inheritScale)
			{
			if (this._parent.global.skewX == this._parent.global.skewY)
			{
			}
			}
			*/
			
			const ikGlobal:Transform = _ik.global;
			const x:Number = this.globalTransformMatrix.a * this.length;
			const y:Number = this.globalTransformMatrix.b * this.length;
			
			const ikRadian:Number = 
				(
					Math.atan2(ikGlobal.y - this.global.y, ikGlobal.x - this.global.x) + 
					this.offset.skewY - 
					this.global.skewY * 2 + 
					Math.atan2(y, x)
				) * ikWeight; // Support offset.
			
			this.global.skewX += ikRadian;
			this.global.skewY += ikRadian;
			this.global.toMatrix(this.globalTransformMatrix);
		}
		
		/**
		 * @private
		 */
		private function _computeIKB():void
		{
			// TODO IK
			const parentGlobal:Transform = this._parent.global;
			const ikGlobal:Transform = _ik.global;
			
			const x:Number = this.globalTransformMatrix.a * this.length;
			const y:Number = this.globalTransformMatrix.b * this.length;
			
			const lLL:Number = x * x + y * y;
			const lL:Number = Math.sqrt(lLL);
			
			var dX:Number = this.global.x - parentGlobal.x;
			var dY:Number = this.global.y - parentGlobal.y;
			const lPP:Number = dX * dX + dY * dY;
			const lP:Number = Math.sqrt(lPP);
			
			dX = ikGlobal.x - parentGlobal.x;
			dY = ikGlobal.y - parentGlobal.y;
			const lTT:Number = dX * dX + dY * dY;
			const lT:Number = Math.sqrt(lTT);
			
			var ikRadianA:Number = 0;
			if (lL + lP <= lT || lT + lL <= lP || lT + lP <= lL)
			{
				ikRadianA = Math.atan2(ikGlobal.y - parentGlobal.y, ikGlobal.x - parentGlobal.x) + this._parent.offset.skewY; // Support offset.
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
					this.global.x = hX - rX;
					this.global.y = hY - rY;
				}
				else
				{
					this.global.x = hX + rX;
					this.global.y = hY + rY;
				}
				
				ikRadianA = Math.atan2(this.global.y - parentGlobal.y, this.global.x - parentGlobal.x) + this._parent.offset.skewY; // Support offset
			}
			
			ikRadianA = (ikRadianA - parentGlobal.skewY) * ikWeight;
			
			parentGlobal.skewX += ikRadianA;
			parentGlobal.skewY += ikRadianA;
			parentGlobal.toMatrix(this._parent.globalTransformMatrix);
			this._parent._transformDirty = 1;
			
			this.global.x = parentGlobal.x + Math.cos(parentGlobal.skewY) * lP;
			this.global.y = parentGlobal.y + Math.sin(parentGlobal.skewY) * lP;
			
			const ikRadianB:Number = 
				(
					Math.atan2(ikGlobal.y - this.global.y, ikGlobal.x - this.global.x) + this.offset.skewY - 
					this.global.skewY * 2 + Math.atan2(y, x)
				) * ikWeight; // Support offset.
			
			this.global.skewX += ikRadianB;
			this.global.skewY += ikRadianB;
			
			this.global.toMatrix(this.globalTransformMatrix);
		}
		
		/**
		 * @inheritDoc
		 */
		override dragonBones_internal function _setArmature(value:Armature):void
		{
			this._armature = value;
			this._armature._addBoneToBoneList(this);
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
					var chainEnd:Bone = this._parent;
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
			
			if (this._armature)
			{
				this._armature._bonesDirty = true;
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _update(cacheFrameIndex:int):void
		{
			_blendIndex = 0;
			
			if (cacheFrameIndex >= 0)
			{
				const cacheFrame:Matrix = _cacheFrames[cacheFrameIndex];
				
				if (this.globalTransformMatrix == cacheFrame) // Same cache.
				{
					_transformDirty = 0;
				}
				else if (cacheFrame) // Has been Cached.
				{
					_transformDirty = 2; // For update children and ik children.
					this.globalTransformMatrix = cacheFrame;
				}
				else if (
					_transformDirty == 2 ||
					(this._parent && this._parent._transformDirty) ||
					(_ik && ikWeight > 0 && _ik._transformDirty)
				)
				{
					_transformDirty = 2; // For update children and ik children.
					this.globalTransformMatrix = this._globalTransformMatrix;
				}
				else if (this.globalTransformMatrix != this._globalTransformMatrix) // Same cache but not cached yet.
				{
					_transformDirty = 0;
					_cacheFrames[cacheFrameIndex] = this.globalTransformMatrix;
				}
				else
				{
					_transformDirty = 2;
					this.globalTransformMatrix = this._globalTransformMatrix;
				}
			}
			else if (
				_transformDirty == 2 ||
				(this._parent && this._parent._transformDirty) ||
				(_ik && ikWeight > 0 && _ik._transformDirty)
			)
			{
				_transformDirty = 2; // For update children and ik children.
				this.globalTransformMatrix = this._globalTransformMatrix;
			}
			
			if (_transformDirty != 0)
			{
				if (_transformDirty == 2)
				{
					_transformDirty = 1;
					
					if (this.globalTransformMatrix == this._globalTransformMatrix)
					{
						this.global.copyFrom(this.origin).add(this.offset).add(_animationPose);
						/*this.global.x = this.origin.x + this.offset.x + _animationPose.x;
						this.global.y = this.origin.y + this.offset.y + _animationPose.y;
						this.global.skewX = this.origin.skewX + this.offset.skewX + _animationPose.skewX;
						this.global.skewY = this.origin.skewY + this.offset.skewY + _animationPose.skewY;
						this.global.scaleX = this.origin.scaleX * this.offset.scaleX * _animationPose.scaleX;
						this.global.scaleY = this.origin.scaleY * this.offset.scaleY * _animationPose.scaleY;*/
						
						_updateGlobalTransformMatrix();
						
						if (_ik && _ikChainIndex == _ikChain  && ikWeight > 0)
						{
							if (this.inheritTranslation && _ikChain > 0 && this._parent)
							{
								_computeIKB();
							}
							else
							{
								_computeIKA();
							}
						}
						
						if (cacheFrameIndex >= 0 && !_cacheFrames[cacheFrameIndex])
						{
							this.globalTransformMatrix = BoneTimelineData.cacheFrame(_cacheFrames, cacheFrameIndex, this._globalTransformMatrix);
						}
					}
				}
				else
				{
					_transformDirty = 0;
				}
			}
		}
		
		/**
		 * @language zh_CN
		 * 下一帧更新变换。 (当骨骼没有动画状态或动画状态播放完成时，骨骼将不在更新)
		 * @version DragonBones 3.0
		 */
		[inline]
		final public function invalidUpdate():void
		{
			_transformDirty = 2;
		}
		
		/**
		 * @language zh_CN
		 * 是否包含某个指定的骨骼或插槽。
		 * @return [true: 包含，false: 不包含]
		 * @see dragonBones.core.TransformObject
		 * @version DragonBones 3.0
		 */
		public function contains(child:TransformObject):Boolean
		{
			if (child)
			{
				if (child == this)
				{
					return false;
				}
				
				var ancestor:TransformObject = child;
				while(ancestor != this && ancestor)
				{
					ancestor = ancestor.parent;
				}
				
				return ancestor == this;
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
			
			for each (var bone:Bone in this._armature.getBones())
			{
				if (bone.parent == this)
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
			
			for each (var slot:Slot in this._armature.getSlots())
			{
				if (slot.parent == this)
				{
					_slots.push(slot);	
				}
			}
			
			return _slots;
		}
		
		/**
		 * @private
		 */
		public function get ikChain():uint
		{
			return _ikChain;
		}
		
		/**
		 * @private
		 */
		public function get ikChainIndex():int
		{
			return _ikChainIndex;
		}
		
		/**
		 * @language zh_CN
		 * 当前的 IK 约束目标。
		 * @version DragonBones 4.5
		 */
		public function get ik():Bone
		{
			return _ik;
		}
		
		/**
		 * @language zh_CN
		 * 控制此骨骼所有插槽的显示。
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
			for each (var slot:Slot in this._armature.getSlots())
			{
				if (slot._parent == this)
				{
					slot._updateVisible();
				}
			}
		}
	}
}