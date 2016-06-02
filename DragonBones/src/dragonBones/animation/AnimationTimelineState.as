package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	import dragonBones.events.IEventDispatcher;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.AnimationFrameData;
	import dragonBones.objects.EventData;
	import dragonBones.objects.FrameData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public final class AnimationTimelineState extends TimelineState
	{
		private var _isStarted:Boolean;
		
		public function AnimationTimelineState()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			_isStarted = false;
		}
		
		override protected function _onCrossFrame(frame:FrameData):void
		{
			const animationFrame:AnimationFrameData = frame as AnimationFrameData;
			
			var i:uint = 0, l:uint = 0;
				
			const events:Vector.<EventData> = animationFrame.events;
			const eventDispatcher:IEventDispatcher = this._armature.display;
			for (i = 0, l = events.length; i < l; ++i)
			{
				const eventData:EventData = events[i];
				
				var eventType:String = null;
				switch (eventData.type)
				{
					case DragonBones.EVENT_TYPE_FRAME:
						eventType = EventObject.FRAME_EVENT;
						break;
					
					case DragonBones.EVENT_TYPE_SOUND:
						eventType = EventObject.SOUND_EVENT;
						break;
				}
				
				if (eventDispatcher.hasEvent(eventType))
				{
					const eventObject:EventObject = BaseObject.borrowObject(EventObject) as EventObject;
					eventObject.animationState = this._animationState;
					
					if (eventData.bone)
					{
						eventObject.bone = this._armature.getBone(eventData.bone.name);
					}
					
					if (eventData.slot)
					{
						eventObject.slot = this._armature.getSlot(eventData.slot.name);
					}
					
					eventObject.name = eventData.name;
					eventObject.data = eventData.data;
					
					this._armature._bufferEvent(eventObject, eventType);
				}
			}
			
			const actions:Vector.<ActionData> = animationFrame.actions;
			for (i = 0, l = actions.length; i < l; ++i)
			{
				const actionData:ActionData = actions[i];
				
				var animationActionTarget:Armature = this._armature;
				if (actionData.slot)
				{
					const slot:Slot = this._armature.getSlot(actionData.slot.name);
					if (slot)
					{
						animationActionTarget = slot.childArmature || animationActionTarget;
					}
				}
				
				animationActionTarget._action = actionData;
			}
		}
		
		override public function update(time:int):void
		{
			const prevPlayTimes:uint = this._currentPlayTimes;
			
			super.update(time);
			
			const eventDispatcher:IEventDispatcher = this._armature.display;
			var eventObject:EventObject = null;
			
			if (!_isStarted && this._currentTime > 0)
			{
				_isStarted = true;
				
				if (eventDispatcher.hasEvent(EventObject.START))
				{
					eventObject = BaseObject.borrowObject(EventObject) as EventObject;
					this._armature._bufferEvent(eventObject, EventObject.START);
				}
			}
			
			if (prevPlayTimes != this._currentPlayTimes)
			{
				//const eventType:String = _isCompleted? EventObject.COMPLETE: EventObject.LOOP_COMPLETE;
				var eventType:String = null;
				if (_isCompleted)
				{
					eventType = EventObject.COMPLETE;
				}
				else
				{
					eventType = EventObject.LOOP_COMPLETE;
				}
				
				if (eventDispatcher.hasEvent(eventType))
				{
					eventObject = BaseObject.borrowObject(EventObject) as EventObject;
					eventObject.animationState = this._animationState;
					this._armature._bufferEvent(eventObject, eventType);
				}
			}
		}
	}
}