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
			super._onClear();
			
			_isStarted = false;
		}
		
		override protected function _onCrossFrame(frame:FrameData):void
		{
			var i:uint = 0, l:uint = 0;
			
			const actions:Vector.<ActionData> = (frame as AnimationFrameData).actions;
			for (i = 0, l = actions.length; i < l; ++i)
			{
				const actionData:ActionData = actions[i];
				if (actionData.slot)
				{
					const slot:Slot = _armature.getSlot(actionData.slot.name);
					if (slot)
					{
						const childArmature:Armature = slot.childArmature;
						if (childArmature)
						{
							childArmature._action = actionData;
						}
					}
				}
				else if (actionData.bone)
				{
					for each (var eachSlot:Slot in _armature.getSlots())
					{
						const eachChildArmature:Armature = eachSlot.childArmature;
						if (eachChildArmature)
						{
							eachChildArmature._action = actionData;
						}
					}
				}
				else
				{
					_armature._action = actionData;
				}
			}
			
			const eventDispatcher:IEventDispatcher = _armature.display;
			const events:Vector.<EventData> = (frame as AnimationFrameData).events;
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
					eventObject.animationState = _animationState;
					
					if (eventData.bone)
					{
						eventObject.bone = _armature.getBone(eventData.bone.name);
					}
					
					if (eventData.slot)
					{
						eventObject.slot = _armature.getSlot(eventData.slot.name);
					}
					
					eventObject.name = eventData.name;
					eventObject.data = eventData.data;
					
					_armature._bufferEvent(eventObject, eventType);
				}
			}
		}
		
		override public function update(time:Number):void
		{
			const prevPlayTimes:uint = this._currentPlayTimes;
			const eventDispatcher:IEventDispatcher = this._armature.display;
			var eventObject:EventObject = null;
			
			if (!_isStarted && time != 0)
			{
				_isStarted = true;
				
				if (eventDispatcher.hasEvent(EventObject.START))
				{
					eventObject = BaseObject.borrowObject(EventObject) as EventObject;
					eventObject.animationState = this._animationState;
					this._armature._bufferEvent(eventObject, EventObject.START);
				}
			}
			
			super.update(time);
			
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
					eventType = EventObject.LOOP_COMPLETE; // TODO buffer loop complete before cross frame event
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