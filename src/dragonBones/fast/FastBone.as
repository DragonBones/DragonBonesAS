package dragonBones.fast
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.fast.animation.FastAnimationState;
	import dragonBones.fast.animation.FastBoneTimelineState;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	import dragonBones.objects.ParentTransformObject;
	import dragonBones.utils.TransformUtil;

	use namespace dragonBones_internal;
	
	/**
	 * 不保存子骨骼列表和子插槽列表
	 * 不能动态添加子骨骼和子插槽
	 */
	public class FastBone extends FastDBObject
	{
		public static function initWithBoneData(boneData:BoneData):FastBone
		{
			var outputBone:FastBone = new FastBone();
			
			outputBone.name = boneData.name;
			outputBone.length = boneData.length;
			outputBone.inheritRotation = boneData.inheritRotation;
			outputBone.inheritScale = boneData.inheritScale;
			outputBone.origin.copy(boneData.transform);
			
			return outputBone;
		}
		
		public var rotationIK:Number;
		public var length:Number;
		public var isIKConstraint:Boolean = false;
		public var childrenBones:Vector.<FastBone> = new Vector.<FastBone>();
		
		public var slotList:Vector.<FastSlot> = new Vector.<FastSlot>();
		public var boneList:Vector.<FastBone> = new Vector.<FastBone>();
		
		/** @private */
		dragonBones_internal var _timelineState:FastBoneTimelineState;
		
		/** @private */
		dragonBones_internal var _needUpdate:int;
		/** @private */
		dragonBones_internal var _tweenPivot:Point;
		/** @private */
		dragonBones_internal var _localTransform:DBTransform;
		
		public function FastBone()
		{
			super();
			_needUpdate = 2;
			_tweenPivot = new Point();
		}
		
		/**
		 * Get all Bone instance associated with this bone.
		 * @return A Vector.&lt;Slot&gt; instance.
		 * @see dragonBones.Slot
		 */
		public function getBones(returnCopy:Boolean = true):Vector.<FastBone>
		{
			return returnCopy?boneList.concat():boneList;
		}
		
		/**
		 * Get all Slot instance associated with this bone.
		 * @return A Vector.&lt;Slot&gt; instance.
		 * @see dragonBones.Slot
		 */
		public function getSlots(returnCopy:Boolean = true):Vector.<FastSlot>
		{
			return returnCopy?slotList.concat():slotList;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			_timelineState = null;
			_tweenPivot = null;
		}
		
	//动画
		/**
		 * Force update the bone in next frame even if the bone is not moving.
		 */
		public function invalidUpdate():void
		{
			_needUpdate = 2;
			operationInvalidUpdate(this);
			for each (var i:FastBone in childrenBones) 
			{
				if(i._needUpdate != 2){
					operationInvalidUpdate(i)	
					i.invalidUpdate()
				}
			}
		}
		private function operationInvalidUpdate(bone:FastBone):void
		{
			var arr:Array = this.armature.getIKTargetData(bone);
			var i:int;
			var len:int;
			var j:int;
			var jLen:int;
			var ik:FastIKConstraint;
			var bo:FastBone;
			
			for (i = 0, len = arr.length; i < len; i++)
			{
				ik = arr[i];
				for (j = 0, jLen = ik.bones.length; j < jLen; j++)
				{
					bo = ik.bones[j];
					if(bo._needUpdate != 2){
						bo.invalidUpdate();
					}
				}
			}
		}
		
		override protected function calculateRelativeParentTransform():void
		{
			_global.copy(this._origin);
			if(_timelineState)
			{
				_global.add(_timelineState._transform);
			}
		}
		
		/** @private */
		override dragonBones_internal function updateByCache():void
		{
			super.updateByCache();
			_global = _frameCache.globalTransform;
			_globalTransformMatrix = _frameCache.globalTransformMatrix;
		}
		
		/** @private */
		dragonBones_internal function update(needUpdate:Boolean = false):void
		{
			_needUpdate --;
			if(needUpdate || _needUpdate > 0 || (this._parent && this._parent._needUpdate > 0))
			{
				_needUpdate = 1;
			}
			else
			{
				return;
			}
			updataLocalTransform();
			updateGlobalTransform();
		}
		private function updataLocalTransform():void
		{
			blendingTimeline();
			calculateRelativeParentTransform();
		}
		private function updateGlobalTransform():void
		{
			//计算global
			var result:ParentTransformObject = updateGlobal();
			if (result)
			{
				result.release();
			}
		}
		
		public function adjustGlobalTransformMatrixByIK():void
		{
			if(!parent)
			{
				return;
			}
			updataLocalTransform();
			_global.rotation = rotationIK-parentBoneRotation;
			updateGlobalTransform();
			//global.rotation = rotationIK;
			//TransformUtil.transformToMatrix(global, _globalTransformMatrix);
			//_globalTransformForChild.rotation= rotationIK;
			//TransformUtil.transformToMatrix(_globalTransformForChild, _globalTransformMatrixForChild);
		}
		
		override protected function updateGlobal():ParentTransformObject 
		{
			if (!armature._skewEnable)
			{
				return super.updateGlobal();
			}
			
			//calculateRelativeParentTransform();
			var output:ParentTransformObject = calculateParentTransform();
			if(output != null && output.parentGlobalTransformMatrix && output.parentGlobalTransform)
			{
				//计算父骨头绝对坐标
				var parentMatrix:Matrix = output.parentGlobalTransformMatrix;
				var parentGlobalTransform:DBTransform = output.parentGlobalTransform;
				
				var scaleXF:Boolean = _global.scaleX * parentGlobalTransform.scaleX > 0;
				var scaleYF:Boolean = _global.scaleY * parentGlobalTransform.scaleY > 0;
				var relativeRotation:Number = _global.rotation;
				var relativeScaleX:Number = _global.scaleX;
				var relativeScaleY:Number = _global.scaleY;
				var parentRotation:Number = parentBoneRotation;
				
				_localTransform = _global;
				if (this.inheritScale && !inheritRotation)
				{
					if (parentRotation != 0)
					{
						_localTransform = _localTransform.clone();
						_localTransform.rotation -= parentRotation;
					}
				}
				TransformUtil.transformToMatrix(_localTransform, _globalTransformMatrix);
				_globalTransformMatrix.concat(parentMatrix);
				
				if (inheritScale)
				{
					TransformUtil.matrixToTransform(_globalTransformMatrix, _global, scaleXF, scaleYF);
				}
				else 
				{
					TransformUtil.matrixToTransformPosition(_globalTransformMatrix, _global);

					_global.scaleX = _localTransform.scaleX;
					_global.scaleY = _localTransform.scaleY;
					_global.rotation = _localTransform.rotation + (inheritRotation ? parentRotation : 0);
					
					TransformUtil.transformToMatrix(_global, _globalTransformMatrix);
				}
			}
			return output;
		}
		
		/** @private */
		dragonBones_internal function hideSlots():void
		{
			for each(var childSlot:FastSlot in slotList)
			{
				childSlot.hideSlots();
			}
		}
		
		/** @private When bone timeline enter a key frame, call this func*/
		dragonBones_internal function arriveAtFrame(frame:Frame, animationState:FastAnimationState):void
		{
			var childSlot:FastSlot;
			if(frame.event && this.armature.hasEventListener(FrameEvent.BONE_FRAME_EVENT))
			{
				var frameEvent:FrameEvent = new FrameEvent(FrameEvent.BONE_FRAME_EVENT);
				frameEvent.bone = this;
				frameEvent.animationState = animationState;
				frameEvent.frameLabel = frame.event;
				this.armature.addEvent(frameEvent);
			}
		}	
		
		private function blendingTimeline():void
		{
			if(_timelineState)
			{
				_tweenPivot.x = _timelineState._pivot.x;
				_tweenPivot.y = _timelineState._pivot.y;
			}
		}
		
		/**
		 * Unrecommended API. Recommend use slot.childArmature.
		 */
		public function get childArmature():Object
		{
			var s:FastSlot = slot;
			if(s)
			{
				return s.childArmature;
			}
			return null;
		}
		
		/**
		 * Unrecommended API. Recommend use slot.display.
		 */
		public function get display():Object
		{
			var s:FastSlot = slot;
			if(s)
			{
				return s.display;
			}
			return null;
		}
		public function set display(value:Object):void
		{
			var s:FastSlot = slot;
			if(s)
			{
				s.display = value;
			}
		}
		
		/** @private */
		override public function set visible(value:Boolean):void
		{
			if(this._visible != value)
			{
				this._visible = value;
				for each(var childSlot:FastSlot in armature.slotList)
				{
					if(childSlot.parent == this)
					{
						childSlot.updateDisplayVisible(this._visible);
					}
				}
			}
		}
		
		public function get slot():FastSlot
		{
			return slotList.length > 0? slotList[0]:null;
		}
		
		public function get parentBoneRotation():Number
		{
			return this.parent ? this.parent.rotationIK : 0;
		}
		
		public function set parentBoneData(value:FastBone):void 
		{
			if (_parent != value)
			{
				if (_parent != null)
				{
					var index:int = _parent.childrenBones.indexOf(this);
					if (index >= 0)
					{
						_parent.childrenBones.splice(index, 1);
					}
				}
				setParent(value);
				if (_parent != null)
				{
					var indexs:int = _parent.childrenBones.indexOf(this);
					if (indexs < 0)
					{
						_parent.childrenBones.push(this);
					}
				}
			}
			
		}
	}
}