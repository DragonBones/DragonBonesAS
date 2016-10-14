package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	import dragonBones.events.IEventDispatcher;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.AnimationFrameData;
	import dragonBones.objects.EventData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.TimelineData;
	
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
		
		protected function _onCrossFrame(frame:FrameData):void
		{
			var i:uint = 0, l:uint = 0;
			
			if (this._animationState.actionEnabled)
			{
				const actions:Vector.<ActionData> = (frame as AnimationFrameData).actions;
				for (i = 0, l = actions.length; i < l; ++i)
				{
					this._armature._bufferAction(actions[i]);
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
				
				if (
					(eventData.type == DragonBones.EVENT_TYPE_SOUND? 
						this._armature._eventManager: eventDispatcher
					).hasEvent(eventType)
				)
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
		
		override public function fadeIn(armature:Armature, animationState:AnimationState, timelineData:TimelineData, time:Number):void
		{
			super.fadeIn(armature, animationState, timelineData, time);
			
			this._currentTime = time;
		}
		
		override public function update(time:Number):void
		{
			const prevTime:Number = this._currentTime;
			const prevPlayTimes:uint = this._currentPlayTimes;
			
			if (!this._isCompleted && this._setCurrentTime(time)) 
			{
				const eventDispatcher:IEventDispatcher = this._armature.display;
				var eventObject:EventObject = null;
				
				if (!_isStarted)
				{
					_isStarted = true;
					
					if (eventDispatcher.hasEvent(EventObject.START))
					{
						eventObject = BaseObject.borrowObject(EventObject) as EventObject;
						eventObject.animationState = this._animationState;
						this._armature._bufferEvent(eventObject, EventObject.START);
					}
				}
				
				if (this._keyFrameCount > 0)
				{
					const currentFrameIndex:uint = this._keyFrameCount > 1 ? Math.floor(this._currentTime * this._frameRate) : 0;
					const currentFrame:FrameData = this._timeline.frames[currentFrameIndex];
					
					if (this._currentFrame != currentFrame) 
					{
						if (this._keyFrameCount > 1) 
						{
							var crossedFrame:FrameData = this._currentFrame;
							this._currentFrame = currentFrame;
							
							if (!crossedFrame) 
							{
								const prevFrameIndex:uint = Math.floor(prevTime * this._frameRate);
								crossedFrame = this._timeline.frames[prevFrameIndex];
								
								if (this._isReverse) 
								{
								} 
								else 
								{
									if (
										prevTime <= crossedFrame.position || 
										prevPlayTimes != this._currentPlayTimes
									) 
									{
										crossedFrame = crossedFrame.prev;
									}
								}
							}
							
							if (this._isReverse) 
							{
								while (crossedFrame != currentFrame) 
								{
									this._onCrossFrame(crossedFrame);
									crossedFrame = crossedFrame.prev;
								}
							} 
							else 
							{
								while (crossedFrame != currentFrame) 
								{
									crossedFrame = crossedFrame.next;
									this._onCrossFrame(crossedFrame);
								}
							}
						} 
						else 
						{
							this._currentFrame = currentFrame;
							this._onCrossFrame(this._currentFrame);
						}
					}
				}
				
				if (prevPlayTimes != this._currentPlayTimes)
				{
					if (eventDispatcher.hasEvent(EventObject.LOOP_COMPLETE))
					{
						eventObject = BaseObject.borrowObject(EventObject) as EventObject;
						eventObject.animationState = this._animationState;
						this._armature._bufferEvent(eventObject, EventObject.LOOP_COMPLETE);
					}
					
					if (this._isCompleted && eventDispatcher.hasEvent(EventObject.COMPLETE))
					{
						eventObject = BaseObject.borrowObject(EventObject) as EventObject;
						eventObject.animationState = this._animationState;
						this._armature._bufferEvent(eventObject, EventObject.COMPLETE);
					}
				}
			}
		}
		
		public function setCurrentTime(value: Number): void {
			this._setCurrentTime(value);
			this._currentFrame = null;
		}
	}
}