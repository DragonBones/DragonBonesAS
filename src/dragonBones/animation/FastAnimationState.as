package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.FastArmature;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.AnimationEvent;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.Frame;
	import dragonBones.objects.SlotTimeline;
	import dragonBones.objects.TransformTimeline;

	use namespace dragonBones_internal;
	
	public class FastAnimationState
	{
		private static var _pool:Vector.<FastAnimationState> = new Vector.<FastAnimationState>;
		
		/** @private */
		dragonBones_internal static function borrowObject():FastAnimationState
		{
			if(_pool.length == 0)
			{
				return new FastAnimationState();
			}
			return _pool.pop();
		}
		
		/** @private */
		dragonBones_internal static function returnObject(animationState:FastAnimationState):void
		{
			animationState.clear();
			
			if(_pool.indexOf(animationState) < 0)
			{
				_pool[_pool.length] = animationState;
			}
		}
		
		/** @private */
		dragonBones_internal static function clear():void
		{
			var i:int = _pool.length;
			while(i --)
			{
				_pool[i].clear();
			}
			_pool.length = 0;
			
			TimelineState.clear();
		}
		
		private var _armature:FastArmature;
		
		private var _timelineStateList:Vector.<TimelineState>;
		private var _slotTimelineStateList:Vector.<SlotTimelineState>;
		private var _animationData:AnimationData;
		
		private var _name:String;
		private var _time:Number;//秒
		private var _currentFrameIndex:int;
		private var _currentPlayTimes:int;
		private var _totalTime:int;//毫秒
		private var _currentTime:int;
		private var _isComplete:Boolean;
		private var _isPlaying:Boolean;
		
		public function FastAnimationState()
		{
			_timelineStateList = new Vector.<TimelineState>;
			_slotTimelineStateList = new Vector.<SlotTimelineState>;
		}
		
		/** @private */
		dragonBones_internal function fadeIn(armature:FastArmature, animationData:AnimationData, playTimes:Number):void
		{
			_armature = armature;
			_animationData = animationData;
			
			_name = animationData.name;
			_totalTime = animationData.duration;
			
			setPlayTimes(playTimes);
			
			//reset
			_isComplete = false;
			_currentFrameIndex = -1;
			_currentPlayTimes = -1;
			if(Math.round(_totalTime * animationData.frameRate * 0.001) < 2)
			{
				//以后改成stop=true;
				_currentTime = _totalTime;
			}
			else
			{
				_currentTime = -1;
			}
			_time = 0;
			
			
			//default
			_isPlaying = true;
			
			updateTimelineStates();
			return;
		}
		
		/**
		 * @private
		 * Update timeline state based on mixing transforms and clip.
		 */
		dragonBones_internal function updateTimelineStates():void
		{
			var timelineState:TimelineState;
			var slotTimelineState:SlotTimelineState;
			var i:int = _timelineStateList.length;
			
			
			for each(var timeline:TransformTimeline in _animationData.timelineList)
			{
				addTimelineState(timeline.name);
			}
			
			for each(var slotTimeline:SlotTimeline in _animationData.slotTimelineList)
			{
				addSlotTimelineState(slotTimeline.name);
			}
		}
		
		private function addTimelineState(timelineName:String):void
		{
			var bone:Bone = _armature.getBone(timelineName);
			if(bone)
			{
				for each(var eachState:TimelineState in _timelineStateList)
				{
					if(eachState.name == timelineName)
					{
						return;
					}
				}
				var timelineState:TimelineState = TimelineState.borrowObject();
				timelineState.fadeIn(bone, this, _clip.getTimeline(timelineName));
				_timelineStateList.push(timelineState);
			}
		}
		
		private function addSlotTimelineState(timelineName:String):void
		{
			var slot:Slot = _armature.getSlot(timelineName);
			if(slot && slot.displayList.length > 0)
			{
				for each(var eachState:SlotTimelineState in _slotTimelineStateList)
				{
					if(eachState.name == timelineName)
					{
						return;
					}
				}
				var timelineState:SlotTimelineState = SlotTimelineState.borrowObject();
				timelineState.fadeIn(slot, this, _clip.getSlotTimeline(timelineName));
				_slotTimelineStateList.push(timelineState);
			}
		}
		
		/** @private */
		dragonBones_internal function advanceTime(passedTime:Number):Boolean
		{
			advanceTimelinesTime(passedTime);
		}
		
		private function advanceTimelinesTime(passedTime:Number):void
		{
			_time += passedTime;
			
			
			//计算是否已经播放完成isThisComplete

			
			var progress:Number = _time * 1000 / _totalTime;
			for each(var timeline:TimelineState in _timelineStateList)
			{
				timeline.update(progress);
				_isComplete = timeline._isComplete && _isComplete;
			}
			//update slotTimelie
			for each(var slotTimeline:SlotTimelineState in _slotTimelineStateList)
			{
				slotTimeline.update(progress);
				_isComplete = slotTimeline._isComplete && _isComplete;
			}
			
			//update main timeline
			updateMainTimeline();
			
			//抛事件
			
		}
		
		private function updateMainTimeline(isThisComplete:Boolean):void
		{
			//对于所有跳过的帧,按顺序调用
			//_armature.arriveAtFrame(prevFrame, null, this, true);
		}
		
		private function setPlayTimes(value:int):void
		{
			//如果动画只有一帧  播放一次就可以
			if(Math.round(_totalTime * 0.001 * _clip.frameRate) < 2)
			{
				_playTimes = value < 0?-1:1;
			}
			else
			{
				_playTimes = value < 0?-value:value;
			}
			autoFadeOut = value < 0?true:false;
			return this;
		}
	}
}