package dragonBones.fast
{
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.fast.animation.FastAnimationState;
	import dragonBones.fast.animation.FastBoneTimelineState;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.Frame;

	use namespace dragonBones_internal;
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
		
		/** @private */
		dragonBones_internal var _timelineState:FastBoneTimelineState;
		
		/** @private */
		dragonBones_internal var _needUpdate:int;
		
		public function FastBone()
		{
			super();
			_needUpdate = 2;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			_timelineState = null;
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
			
			//计算global
			updateGlobal();
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
				this.armature._eventList.push(frameEvent);
			}
		}
	}
}