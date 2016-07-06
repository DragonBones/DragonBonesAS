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
	import dragonBones.objects.EventData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.TimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public class TimelineState extends BaseObject
	{
		dragonBones_internal var _isCompleted:Boolean;
		dragonBones_internal var _currentPlayTimes:uint;
		dragonBones_internal var _currentTime:Number;
		dragonBones_internal var _timeline:TimelineData;
		
		protected var _isReverse:Boolean;
		protected var _hasAsynchronyTimeline:Boolean;
		protected var _keyFrameCount:uint;
		protected var _frameCount:uint;
		protected var _position:Number;
		protected var _duration:Number;
		protected var _clipDutation:Number;
		protected var _timeScale:Number;
		protected var _timeOffset:Number;
		protected var _timeToFrameSccale:Number;
		protected var _currentFrame:FrameData;
		protected var _armature:Armature;
		protected var _animationState:AnimationState;
		
		public function TimelineState(self:TimelineState)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			_isCompleted = false;
			_currentPlayTimes = 0;
			_currentTime = 0;
			_timeline = null;
			
			_isReverse = false;
			_hasAsynchronyTimeline = false;
			_keyFrameCount =0;
			_frameCount = 0;
			_position = 0;
			_duration = 0;
			_clipDutation = 0;
			_timeScale = 1;
			_timeOffset = 0;
			_timeToFrameSccale = 0;
			_currentFrame = null;
			_armature = null;
			_animationState = null;
		}
		
		protected function _onFadeIn():void
		{
		}
		
		protected function _onUpdateFrame(isUpdate:Boolean):void
		{
		}
		
		protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
		}
		
		protected function _onCrossFrame(frame:FrameData):void
		{
			var i:uint = 0, l:uint = 0;
			
			const actions:Vector.<ActionData> = frame.actions;
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
			const events:Vector.<EventData> = frame.events;
			
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
		
		protected function _setCurrentTime(value:Number):Boolean
		{
			var currentPlayTimes:uint = 0;
			
			if (_hasAsynchronyTimeline)
			{
				const playTimes:uint = _animationState.playTimes;
				const totalTimes:Number = playTimes * _duration;
				
				value *= _timeScale;
				if (_timeOffset != 0)
				{
					value += _timeOffset * _clipDutation;
				}
				
				if (playTimes > 0 && (value >= totalTimes || value <= -totalTimes))
				{	
					_isCompleted = true;
					currentPlayTimes = playTimes;
					
					if (value < 0)
					{
						value = 0;
					}
					else
					{
						value = _duration;
					}
				}
				else
				{
					_isCompleted = false;
					
					if (value < 0)
					{
						currentPlayTimes = uint(-value / _duration);
						value = _duration - (-value % _duration);
					}
					else
					{
						currentPlayTimes = uint(value / _duration);
						value %= _duration;
					}
					
					if (playTimes > 0 && currentPlayTimes > playTimes)
					{
						currentPlayTimes = playTimes;
					}
				}
				
				value += _position;
			}
			else
			{
				_isCompleted = _animationState._timeline._isCompleted;
				currentPlayTimes = _animationState._timeline._currentPlayTimes;
			}
			
			if (_currentTime == value)
			{
				return false;
			}
			
			if (_keyFrameCount == 1 && value > _position && this != _animationState._timeline)
			{
				_isCompleted = true;
			}
			
			_isReverse = _currentTime > value && _currentPlayTimes == currentPlayTimes;
			_currentTime = value;
			_currentPlayTimes = currentPlayTimes;
			
			return true;
		}
		
		public function invalidUpdate():void
		{
			_timeScale = this == _animationState._timeline? 1: (1 / _timeline.scale);
			_timeOffset = this == _animationState._timeline? 0: _timeline.offset;
		}
		
		public function setCurrentTime(value:Number):void
		{
			_setCurrentTime(value);
			
			switch (_keyFrameCount)
			{
				case 0:
					break;
				
				case 1:
					_currentFrame = _timeline.frames[0];
					_onArriveAtFrame(false);
					_onUpdateFrame(false);
					break;
				
				default:
					_currentFrame = _timeline.frames[uint(_currentTime * _timeToFrameSccale)];
					_onArriveAtFrame(false);
					_onUpdateFrame(false);
					break;
			}
			
			_currentFrame = null;
		}
		
		public function fadeIn(armature:Armature, animationState:AnimationState, timelineData:TimelineData, time:Number):void
		{
			_armature = armature;
			_animationState = animationState;
			_timeline = timelineData;
			
			const isMainTimeline:Boolean = this == _animationState._timeline;
			
			_hasAsynchronyTimeline = isMainTimeline || _animationState.clip.hasAsynchronyTimeline;
			_keyFrameCount = _timeline.frames.length;
			_frameCount = _animationState.clip.frameCount;
			_position = _animationState._position;
			_duration = _animationState._duration;
			_clipDutation = _animationState._clipDutation;
			_timeScale = isMainTimeline? 1: (1 / _timeline.scale);
			_timeOffset = isMainTimeline? 0: _timeline.offset;
			_timeToFrameSccale = _frameCount / _clipDutation;
			
			_onFadeIn();
			
			setCurrentTime(time);
		}
		
		public function fadeOut():void
		{
		}
		
		public function update(time:Number):void
		{
			const prevTime:Number = _currentTime;
			
			if (!_isCompleted && _setCurrentTime(time) && _keyFrameCount)
			{
				//const currentFrameIndex:uint = _keyFrameCount > 1? _currentTime * _timeToFrameSccale: 0;
				var currentFrameIndex:uint = 0;
				if (_keyFrameCount > 1)
				{
					currentFrameIndex = uint(_currentTime * _timeToFrameSccale);
				}
				
				const currentFrame:FrameData = _timeline.frames[currentFrameIndex];
				if (_currentFrame != currentFrame)
				{
					if (_keyFrameCount > 1)
					{
						var crossedFrame:FrameData = _currentFrame;
						_currentFrame = currentFrame;
						
						if (_isReverse)
						{
							while (crossedFrame != currentFrame)
							{
								if (!crossedFrame)
								{
									const prevFrameIndexA:uint = uint(prevTime * this._timeToFrameSccale);
									crossedFrame = this._timeline.frames[prevFrameIndexA];
								}
								
								_onCrossFrame(crossedFrame);
								crossedFrame = crossedFrame.prev;
							}
						}
						else
						{
							while (crossedFrame != currentFrame)
							{
								if (crossedFrame)
								{
									crossedFrame = crossedFrame.next;
								}
								else
								{
									const prevFrameIndexB:uint = uint(prevTime * this._timeToFrameSccale);
									crossedFrame = this._timeline.frames[prevFrameIndexB];
								}
								
								_onCrossFrame(crossedFrame);
							}
						}
						
						_onArriveAtFrame(true);
					}
					else
					{
						_currentFrame = currentFrame;
						_onCrossFrame(_currentFrame);
						_onArriveAtFrame(true);
					}
				}
				
				_onUpdateFrame(true);
			}
		}
	}
}