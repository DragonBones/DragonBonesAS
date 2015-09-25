package dragonBones.fast
{
	import dragonBones.animation.TimelineState;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.fast.animation.FastAnimationState;
	import dragonBones.fast.animation.FastBoneTimelineState;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	import flash.geom.Point;

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
			outputBone.inheritRotation = boneData.inheritRotation;
			outputBone.inheritScale = boneData.inheritScale;
			outputBone.origin.copy(boneData.transform);
			
			return outputBone;
		}
		
		public var slotList:Vector.<FastSlot> = new Vector.<FastSlot>();
		public var boneList:Vector.<FastBone> = new Vector.<FastBone>();
		/** @private */
		dragonBones_internal var _timelineState:FastBoneTimelineState;
		
		/** @private */
		dragonBones_internal var _needUpdate:int;
		/** @private */
		dragonBones_internal var _tweenPivot:Point;
		
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
			blendingTimeline();
			//计算global
			updateGlobal();
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
	}
}