package dragonBones.animation
{
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.EventType;
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
		public function AnimationTimelineState()
		{
			super(this);
		}
		
		protected function _onCrossFrame(frame:FrameData):void
		{
			if (_animationState.actionEnabled)
			{
				const actions:Vector.<ActionData> = (frame as AnimationFrameData).actions;
				for (var i:uint = 0, l:uint = actions.length; i < l; ++i)
				{
					_armature._bufferAction(actions[i]);
				}
			}
			
			const eventDispatcher:IEventDispatcher = _armature.eventDispatcher;
			const events:Vector.<EventData> = (frame as AnimationFrameData).events;
			for (i = 0, l = events.length; i < l; ++i)
			{
				const eventData:EventData = events[i];
				
				var eventType:String = null;
				switch (eventData.type) 
				{
					case EventType.Frame:
						eventType = EventObject.FRAME_EVENT;
						break;
					
					case EventType.Sound:
						eventType = EventObject.SOUND_EVENT;
						break;
				}
				
				if (eventDispatcher.hasEvent(eventType) || eventData.type === EventType.Sound) 
				{
					const eventObject:EventObject = BaseObject.borrowObject(EventObject) as EventObject;
					eventObject.name = eventData.name;
					eventObject.frame = frame as AnimationFrameData;
					eventObject.data = eventData.data;
					eventObject.animationState = _animationState;
					
					if (eventData.bone) 
					{
						eventObject.bone = _armature.getBone(eventData.bone.name);
					}
					
					if (eventData.slot) 
					{
						eventObject.slot = _armature.getSlot(eventData.slot.name);
					}
					
					_armature._bufferEvent(eventObject, eventType);
				}
			}
		}
		
		override public function update(passedTime:Number):void
		{
			const prevState:int = _playState;
			const prevPlayTimes:uint = _currentPlayTimes;
			const prevTime:Number = _currentTime;
			
			if (_playState <= 0 && _setCurrentTime(passedTime)) 
			{
				const eventDispatcher:IEventDispatcher = _armature.eventDispatcher;
				
				if (prevState < 0 && _playState !== prevState) 
				{
					if (_animationState.displayControl)
					{
						_armature._sortZOrder(null);
					}
					
					if (eventDispatcher.hasEvent(EventObject.START)) 
					{
						var eventObject:EventObject = BaseObject.borrowObject(EventObject) as EventObject;
						eventObject.animationState = _animationState;
						_armature._bufferEvent(eventObject, EventObject.START);
					}
				}
				
				if (prevTime < 0.0) 
				{
					return;
				}
				
				if (_keyFrameCount > 1) 
				{
					const currentFrameIndex:uint = Math.floor(_currentTime * _frameRate);
					const currentFrame:AnimationFrameData = _timelineData.frames[currentFrameIndex] as AnimationFrameData;
					if (_currentFrame !== currentFrame) 
					{
						const isReverse:Boolean = _currentPlayTimes === prevPlayTimes && prevTime > _currentTime;
						var crossedFrame:AnimationFrameData = _currentFrame as AnimationFrameData;
						_currentFrame = currentFrame;
						
						if (!crossedFrame) 
						{
							const prevFrameIndex:uint = Math.floor(prevTime * _frameRate);
							crossedFrame = _timelineData.frames[prevFrameIndex] as AnimationFrameData;
							
							if (isReverse) 
							{
							}
							else 
							{
								if (
									prevTime <= crossedFrame.position
									// || prevPlayTimes !== _currentPlayTimes ?
								) 
								{
									crossedFrame = crossedFrame.prev as AnimationFrameData;
								}
							}
						}
						
						if (isReverse) 
						{
							while (crossedFrame !== currentFrame) 
							{
								_onCrossFrame(crossedFrame);
								crossedFrame = crossedFrame.prev as AnimationFrameData;
							}
						}
						else 
						{
							while (crossedFrame !== currentFrame) 
							{
								crossedFrame = crossedFrame.next as AnimationFrameData;
								_onCrossFrame(crossedFrame);
							}
						}
					}
				}
				else if (_keyFrameCount > 0 && !_currentFrame) 
				{
					_currentFrame = _timelineData.frames[0];
					_onCrossFrame(_currentFrame);
				}
				
				if (_currentPlayTimes !== prevPlayTimes) 
				{
					if (eventDispatcher.hasEvent(EventObject.LOOP_COMPLETE)) 
					{
						eventObject = BaseObject.borrowObject(EventObject) as EventObject;
						eventObject.animationState = _animationState;
						_armature._bufferEvent(eventObject, EventObject.LOOP_COMPLETE);
					}
					
					if (_playState > 0 && eventDispatcher.hasEvent(EventObject.COMPLETE)) 
					{
						eventObject = BaseObject.borrowObject(EventObject) as EventObject;
						eventObject.animationState = _animationState;
						_armature._bufferEvent(eventObject, EventObject.COMPLETE);
					}
				}
			}
		}
		
		public function setCurrentTime(value: Number): void 
		{
			_setCurrentTime(value);
			_currentFrame = null;
		}
	}
}