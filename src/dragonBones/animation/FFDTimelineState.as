package dragonBones.animation 
{
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.CurveData;
	import dragonBones.objects.FFDFrame;
	import dragonBones.objects.FFDTimeline;
	import dragonBones.objects.Frame;
	import dragonBones.utils.MathUtil;
	
	use namespace dragonBones_internal;
	/**
	 * ...
	 * @author sukui
	 */
	public final class FFDTimelineState
	{
		private static var _pool:Vector.<FFDTimelineState> = new Vector.<FFDTimelineState>;
		/** @private */
		dragonBones_internal static function borrowObject():FFDTimelineState
		{
			if(_pool.length == 0)
			{
				return new FFDTimelineState();
			}
			return _pool.pop();
		}
		
		/** @private */
		dragonBones_internal static function returnObject(timeline:FFDTimelineState):void
		{
			if(_pool.indexOf(timeline) < 0)
			{
				_pool[_pool.length] = timeline;
			}
			
			timeline.clear();
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
		}
		
		public var skin:String;
		public var name:String;
		public var displayIndex:int = 0;
		
		/** @private */
		dragonBones_internal var _weight:Number;
		
		/** @private */
		dragonBones_internal var _blendEnabled:Boolean;
		
		/** @private */
		dragonBones_internal var _isComplete:Boolean;
		
		/** @private */
		dragonBones_internal var _animationState:AnimationState;
		
		private var _totalTime:int; //duration
		
		private var _currentTime:int;
		private var _currentFrameIndex:int;
		private var _currentFramePosition:int;
		private var _currentFrameDuration:int;
		
		private var _tweenEasing:Number;
		private var _tweenCurve:CurveData;
		private var _tweenVertices:Boolean;
		private var _offset:int;
		private var _durationVertices:Vector.<Number>;
		private var _updateVertices:Vector.<Number>;
		private var _rawAnimationScale:Number;
		
		//-1: frameLength>1, 0:frameLength==0, 1:frameLength==1
		private var _updateMode:int;
		
		private var _armature:Armature;
		private var _animation:Animation;
		private var _slot:Slot;
		
		private var _timelineData:FFDTimeline;
		
		public function FFDTimelineState() 
		{
			_durationVertices = new Vector.<Number>();
			_updateVertices = new Vector.<Number>();
		}
		
		private function clear():void
		{
			_slot = null;
			_armature = null;
			_animation = null;
			_animationState = null;
			_timelineData = null;
		}
		
		/** @private */
		dragonBones_internal function fadeIn(slot:Slot, animationState:AnimationState, timelineData:FFDTimeline):void
		{
			_slot = slot;
			//_armature = _slot.armature;
			//_animation = _armature.animation;
			_animationState = animationState;
			_timelineData = timelineData;
			
			name = timelineData.name;
			skin = timelineData.skin;
			displayIndex = timelineData.displayIndex;
			
			_totalTime = _timelineData.duration;
			_rawAnimationScale = _animationState.clip.scale;
			
			_isComplete = false;
			_blendEnabled = false;

			_currentFrameIndex = -1;
			_currentTime = -1;
			_tweenEasing = NaN;
			_weight = 1;
			
			switch(_timelineData.frameList.length)
			{
				case 0:
					_updateMode = 0;
					break;
				case 1:
					_updateMode = 1;
					break;
				default:
					_updateMode = -1;
					break;
			}
		}
		
		/** @private */
		dragonBones_internal function update(progress:Number):void
		{
			if(_updateMode == -1)
			{
				updateMultipleFrame(progress);
			}
			else if(_updateMode == 1)
			{
				_updateMode = 0;
				updateSingleFrame();
			}
		}
		
		private function updateMultipleFrame(progress:Number):void
		{
			var currentPlayTimes:int = 0;
			progress /= _timelineData.scale;
			progress += _timelineData.offset;
			
			var currentTime:int = _totalTime * progress;
			var playTimes:int = _animationState.playTimes;
			if(playTimes == 0)
			{
				_isComplete = false;
				currentPlayTimes = Math.ceil(Math.abs(currentTime) / _totalTime) || 1;
				currentTime -= int(currentTime / _totalTime) * _totalTime;
				
				if(currentTime < 0)
				{
					currentTime += _totalTime;
				}
			}
			else
			{
				var totalTimes:int = playTimes * _totalTime;
				if(currentTime >= totalTimes)
				{
					currentTime = totalTimes;
					_isComplete = true;
				}
				else if(currentTime <= -totalTimes)
				{
					currentTime = -totalTimes;
					_isComplete = true;
				}
				else
				{
					_isComplete = false;
				}
				
				if(currentTime < 0)
				{
					currentTime += totalTimes;
				}
				
				currentPlayTimes = Math.ceil(currentTime / _totalTime) || 1;
				if(_isComplete)
				{
					currentTime = _totalTime;
				}
				else
				{
					currentTime -= int(currentTime / _totalTime) * _totalTime;
				}
			}
			
			if(_currentTime != currentTime)
			{
				_currentTime = currentTime;
				
				var frameList:Vector.<Frame> = _timelineData.frameList;
				var prevFrame:FFDFrame;
				var currentFrame:FFDFrame;
				
				for (var i:int = 0, l:int = _timelineData.frameList.length; i < l; ++i)
				{
					if(_currentFrameIndex < 0)
					{
						_currentFrameIndex = 0;
					}
					else if(_currentTime < _currentFramePosition || _currentTime >= _currentFramePosition + _currentFrameDuration)
					{
						_currentFrameIndex ++;
						if(_currentFrameIndex >= frameList.length)
						{
							if(_isComplete)
							{
								_currentFrameIndex --;
								break;
							}
							else
							{
								_currentFrameIndex = 0;
							}
						}
					}
					else
					{
						break;
					}
					currentFrame = frameList[_currentFrameIndex] as FFDFrame;
					
					_currentFrameDuration = currentFrame.duration;
					_currentFramePosition = currentFrame.position;
					prevFrame = currentFrame;
				}
				
				if(currentFrame)
				{
					updateToNextFrame(currentPlayTimes);
				}
				
				updateTween();
			}
		}
		
		private function updateToNextFrame(currentPlayTimes:int):void
		{
			var nextFrameIndex:int = _currentFrameIndex + 1;
			if(nextFrameIndex >= _timelineData.frameList.length)
			{
				nextFrameIndex = 0;
			}
			var currentFrame:FFDFrame = _timelineData.frameList[_currentFrameIndex] as FFDFrame;
			var nextFrame:FFDFrame = _timelineData.frameList[nextFrameIndex] as FFDFrame;
			var tweenEnabled:Boolean = false;
			if(
				nextFrameIndex == 0 &&
				(
					!_animationState.lastFrameAutoTween ||
					(
						_animationState.playTimes &&
						_animationState.currentPlayTimes >= _animationState.playTimes && 
						((_currentFramePosition + _currentFrameDuration) / _totalTime + currentPlayTimes - _timelineData.offset) * _timelineData.scale > 0.999999
					)
				)
			)
			{
				_tweenEasing = NaN;
				tweenEnabled = false;
			}
			else if(_animationState.autoTween)
			{
				_tweenEasing = _animationState.clip.tweenEasing;
				if(isNaN(_tweenEasing))
				{
					_tweenEasing = currentFrame.tweenEasing;
					_tweenCurve = currentFrame.curve;
					if(isNaN(_tweenEasing) && _tweenCurve == null)    //frame no tween
					{
						tweenEnabled = false;
					}
					else
					{
						if(_tweenEasing == 10)
						{
							_tweenEasing = 0;
						}
						tweenEnabled = true;
					}
				}
				else
				{
					tweenEnabled = true;
				}
			}
			else
			{
				_tweenEasing = NaN;
				_tweenCurve = currentFrame.curve;
				if((isNaN(_tweenEasing) || _tweenEasing == 10) && _tweenCurve == null)   //frame no tween
				{
					_tweenEasing = NaN;
					tweenEnabled = false;
				}
				else
				{
					tweenEnabled = true;
				}
			}
			
			if(tweenEnabled)
			{
				_offset = currentFrame.offset < nextFrame.offset ? currentFrame.offset : nextFrame.offset;
				var end:int = currentFrame.offset + currentFrame.vertices.length > nextFrame.offset + nextFrame.vertices.length ?
							  currentFrame.offset + currentFrame.vertices.length :
							  nextFrame.offset + nextFrame.vertices.length;
				_durationVertices.length = end - _offset;
				
				var curVertex:Number;
				var nextVertex:Number;
				_tweenVertices = false;
				for (var i:int = _offset; i < end; i++)
				{
					curVertex = 0;
					nextVertex = 0;
					if (currentFrame.offset <= i && currentFrame.vertices.length + currentFrame.offset > i)
					{
						curVertex = currentFrame.vertices[i - currentFrame.offset];
					}
					if (nextFrame.offset <= i && nextFrame.vertices.length + nextFrame.offset > i)
					{
						nextVertex = nextFrame.vertices[i - nextFrame.offset];
					}
					_durationVertices[i - _offset] = nextVertex - curVertex;
					
					if (_durationVertices[i - _offset] != 0)
					{
						_tweenVertices = true;
					}
				}
			}
			else
			{
				_tweenVertices = false;
				_slot.updateFFD(currentFrame.vertices, currentFrame.offset);
			}
		}
		
		private function updateTween():void
		{	
			var currentFrame:FFDFrame = _timelineData.frameList[_currentFrameIndex] as FFDFrame;
			
			if(_tweenVertices && _animationState.displayControl)
			{
				var progress:Number = (_currentTime - _currentFramePosition) / _currentFrameDuration;
				if (_tweenCurve != null)
				{
					progress = _tweenCurve.getValueByProgress(progress);
				}
				if(_tweenEasing)
				{
					progress = MathUtil.getEaseValue(progress, _tweenEasing);
				}
				
				var end:int = _offset + _durationVertices.length;
				_updateVertices.length = _durationVertices.length;
				var curVertex:Number;
				for (var i:int = _offset; i < end; i++)
				{
					curVertex = 0;
					if (currentFrame.offset <= i && currentFrame.vertices.length + currentFrame.offset > i)
					{
						curVertex = currentFrame.vertices[i - currentFrame.offset];
					}
					_updateVertices[i - _offset] = curVertex + _durationVertices[i - _offset] * progress;
					
				}
				_slot.updateFFD(_updateVertices, _offset);
			}
		}
		
		private function updateSingleFrame():void
		{
			var currentFrame:FFDFrame = _timelineData.frameList[0] as FFDFrame;
			_isComplete = true;
			_tweenEasing = NaN;
			_tweenVertices = false;
			
			if(_animationState.displayControl)
			{
				_slot.updateFFD(currentFrame.vertices, currentFrame.offset);
			}
		}
	}

}