package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.AnimationData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 动画控制器，用来播放动画数据，管理动画状态。
     * @see dragonBones.objects.AnimationData
     * @see dragonBones.animation.AnimationState
	 * @version DragonBones 3.0
	 */
	public class Animation extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 动画的播放速度。 [(-N~0): 倒转播放, 0: 停止播放, (0~1): 慢速播放, 1: 正常播放, (1~N): 快速播放] (默认: 1)
		 * @version DragonBones 3.0
		 */
		public var timeScale:Number;
		
		/**
		 * @private Armature Slot
		 */
		dragonBones_internal var _animationStateDirty:Boolean;
		
		/**
		 * @private Armature Slot
		 */
		dragonBones_internal var _timelineStateDirty:Boolean;
		
		/**
		 * @private Factory
		 */
		dragonBones_internal var _armature:Armature;
		
		/**
		 * @private
		 */
		protected var _isPlaying:Boolean;
		
		/**
		 * @private
		 */
		protected var _time:Number;
		
		/**
		 * @private
		 */
		protected var _lastAnimationState:AnimationState;
		
		/**
		 * @private
		 */
		protected const _animations:Object = {};
		
		/**
		 * @private
		 */
		protected const _animationNames:Vector.<String> = new Vector.<String>(0, true);
		
		/**
		 * @private
		 */
		protected const _animationStates:Vector.<AnimationState> = new Vector.<AnimationState>;
		
		/**
		 * @private
		 */
		public function Animation()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			timeScale = 1;
			
			_animationStateDirty = false;
			_timelineStateDirty = false;
			_armature = null;
			
			_isPlaying = false;
			_time = 0;
			_lastAnimationState = null;
			
			for (var i:String in _animations)
			{
				delete _animations[i];
			}
			
			if (_animationNames.length)
			{
				_animationNames.fixed = false;
				_animationNames.length = 0;
				_animationNames.fixed = true;	
			}
			
			for each (var animationState:AnimationState in _animationStates)
			{
				animationState.returnToPool();
			}
			
			_animationStates.length = 0;
		}
		
		/**
		 * @private
		 */
		protected function _sortAnimationState(a:AnimationState, b:AnimationState):int
		{
			return a.layer > b.layer? 1: -1;
		}
		
		/**
		 * @private
		 */
		protected function _fadeOut(fadeOutTime:Number, layer:int, group:String, fadeOutMode:int, pauseFadeOut:Boolean):void
		{
			var i:uint = 0, l:uint = _animationStates.length;
			var animationState:AnimationState = null;
			
			switch (fadeOutMode)
			{
				case AnimationFadeOutMode.None:
					break;
				
				case AnimationFadeOutMode.SameLayer:
					for ( ; i < l; ++i)
					{
						animationState = _animationStates[i];
						if (animationState.layer == layer)
						{
							animationState.fadeOut(fadeOutTime, pauseFadeOut);
						}
					}
					break;
				
				case AnimationFadeOutMode.SameGroup:
					for ( ; i < l; ++i)
					{
						animationState = _animationStates[i];
						if (animationState.group == group)
						{
							animationState.fadeOut(fadeOutTime, pauseFadeOut);
						}
					}
					break;
				
				case AnimationFadeOutMode.All:
					for ( ; i < l; ++i)
					{
						animationState = _animationStates[i];
						animationState.fadeOut(fadeOutTime, pauseFadeOut);
					}
					break;
				
				case AnimationFadeOutMode.SameLayerAndGroup:
					for ( ; i < l; ++i)
					{
						animationState = _animationStates[i];
						if (animationState.layer == layer && animationState.group == group )
						{
							animationState.fadeOut(fadeOutTime, pauseFadeOut);
						}
					}
					break;
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _updateFFDTimelineStates():void
		{
			for each (var animationState:AnimationState in _animationStates)
			{
				animationState._updateFFDTimelineStates();
			}
		}
		
		/**
		 * @private
		 */
		dragonBones_internal function _advanceTime(passedTime:Number):void
		{
			if (!_isPlaying)
			{
				return;
			}
			
			if (passedTime < 0)
			{
				passedTime = -passedTime;
			}
			
			var animationState:AnimationState = null;
			
			const animationStateCount:uint = _animationStates.length;
			if (animationStateCount == 1)
			{
				animationState = _animationStates[0];
				if (animationState._isFadeOutComplete) // 如果动画状态淡出完毕, 则删除动画状态
				{
					animationState.returnToPool();
					_animationStates.length = 0;
					_animationStateDirty = true;
					_lastAnimationState = null;
				}
				else
				{
					if (_timelineStateDirty)
					{
						animationState._updateTimelineStates();
					}
					
					animationState._advanceTime(passedTime, 1, 0);
				}
			}
			else if (animationStateCount > 1)
			{
				var prevLayer:int = _animationStates[0]._layer;
				var weightLeft:Number = 1;
				var layerTotalWeight:Number = 0;
				var layerIndex:uint = 1; // 多个动画状态索引从 1 开始
				
				for (var i:uint = 0, r:uint = 0; i < animationStateCount; ++i)
				{
					animationState = _animationStates[i];
					if (animationState._isFadeOutComplete) // 如果动画状态淡出完毕, 则删除动画状态
					{
						r++;
						animationState.returnToPool();
						_animationStateDirty = true;
						
						if (_lastAnimationState == animationState) // 要删除的动画状态如果是 _lastAnimationState, 更新 _lastAnimationState 到合适的索引
						{
							if (i >= r)
							{
								_lastAnimationState = _animationStates[i - r];
							}
							else
							{
								_lastAnimationState = null;
							}
						}
					}
					else
					{
						if (r > 0)
						{
							_animationStates[i - r] = animationState;
						}
						
						if (prevLayer != animationState._layer)
						{
							prevLayer = animationState._layer;
							
							if (layerTotalWeight >= weightLeft)
							{
								weightLeft = 0;
							}
							else
							{
								weightLeft -= layerTotalWeight;
							}
							
							layerTotalWeight = 0;
						}
						
						if (_timelineStateDirty)
						{
							animationState._updateTimelineStates();
						}
						
						animationState._advanceTime(passedTime, weightLeft, layerIndex);
						
						if (animationState._weightResult != 0) // 仅拥有权重的动画状态才分配索引
						{
							layerTotalWeight += animationState._weightResult;
							layerIndex++;
						}
					}
					
					if (i == animationStateCount - 1 && r > 0)
					{
						_animationStates.length -= r;
					}
				}
			}
			
			_timelineStateDirty = false;
		}
		
		/**
		 * @language zh_CN
		 * 清除所有正在播放的动画状态。
		 * @version DragonBones 4.5
		 */
		public function reset():void
		{
			_isPlaying = false;
			_lastAnimationState = null;
			
			for (var i:uint = 0, l:uint = _animationStates.length; i < l; ++i)
			{
				_animationStates[i].returnToPool();
			}
			
			_animationStates.length = 0;
		}
		
		/**
		 * @language zh_CN
		 * 暂停播放动画。
		 * @version DragonBones 3.0
		 */
		public function stop(animationName:String = null):void
		{
			if (animationName)
			{
				const animationState:AnimationState = getState(animationName);
				if (animationState)
				{
					animationState.stop();
				}
			}
			else
			{
				_isPlaying = false;
			}
		}
		
		/**
		 * @language zh_CN
		 * 播放动画。
		 * @param animationName 动画数据的名称。 (如果不指定动画名称，则播放默认动画，或将暂停状态切换为播放状态，或重新播放上一个正在播放的动画)
		 * @param playTimes 动画需要播放的次数。 [-1: 使用动画数据默认值, 0: 无限循环播放, [1~N]: 循环播放 N 次] (仅在指定动画名称时生效)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 3.0
		 */
		public function play(animationName:String = null, playTimes:int = -1):AnimationState
		{
			var animationState:AnimationState = null;
			if (animationName)
			{
				animationState = fadeIn(animationName, 0, playTimes, 0, null, AnimationFadeOutMode.All);
			}
			else if (!_lastAnimationState)
			{
				animationState = fadeIn(_armature.armatureData.defaultAnimation.name, 0, -1, 0, null, AnimationFadeOutMode.All);
			}
			else if (!_isPlaying)
			{
				_isPlaying = true;
			}
			else
			{
				animationState = fadeIn(_lastAnimationState.name, 0, -1, 0, null, AnimationFadeOutMode.All);
			}
			
			return animationState;
		}
		
		/**
		 * @language zh_CN
		 * 淡入播放指定名称的动画。
		 * @param animationName 动画数据的名称。
		 * @param playTimes 循环播放的次数。 [-1: 使用数据默认值, 0: 无限循环播放, [1~N]: 循环播放 N 次] (默认: -1)
		 * @param fadeInTime 淡入的时间。 [-1: 使用数据默认值, [0~N]: N 秒淡入完毕] (以秒为单位, 默认: -1)
		 * @param layer 混合的图层，图层高会优先获得混合权重。 (默认: 0)
		 * @param group 混合的组，用于给动画状态编组，方便混合淡出控制。 (默认: null)
		 * @param fadeOutMode 淡出的模式。 (默认: <code>AnimationFadeOutMode.SameLayerAndGroup</code>)
		 * @param additiveBlending 以叠加的形式混合。 (默认: false)
		 * @param displayControl 对显示对象的属性可控。 (默认: true)
		 * @param pauseFadeOut 暂停需要淡出的动画。 (默认: true)
		 * @param pauseFadeIn 暂停需要淡入的动画，直到淡入结束才开始播放。 (默认: true)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationFadeOutMode
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 4.5
		 */
		public function fadeIn(
			animationName:String, fadeInTime:Number = -1, playTimes:int = -1,
			layer:int = 0, group:String = null, fadeOutMode:int = AnimationFadeOutMode.SameLayerAndGroup,
			additiveBlending:Boolean = false, displayControl:Boolean = true,
			pauseFadeOut:Boolean = true, pauseFadeIn:Boolean = true
		):AnimationState
		{
			const clipData:AnimationData = _animations[animationName];
			if (!clipData)
			{
				_time = 0;
				return null;
			}
			
			_isPlaying = true;
			
			if (fadeInTime != fadeInTime || fadeInTime < 0)
			{
				fadeInTime = clipData.fadeInTime;
			}
			
			if (playTimes < 0)
			{
				playTimes = clipData.playTimes;
			}
			
			_fadeOut(fadeInTime, layer, group, fadeOutMode, pauseFadeOut);
			
			_lastAnimationState = BaseObject.borrowObject(AnimationState) as AnimationState;
			_lastAnimationState._layer = layer;
			_lastAnimationState._group = group;
			_lastAnimationState.additiveBlending = additiveBlending;
			_lastAnimationState.displayControl = displayControl;
			_lastAnimationState._fadeIn(
				_armature, clipData.animation || clipData, animationName, 
				playTimes, clipData.position, clipData.duration, _time, 1 / clipData.scale, fadeInTime, 
				pauseFadeIn
			);
			_animationStates.push(_lastAnimationState);
			_animationStateDirty = true;
			_time = 0;
			
			if (_animationStates.length > 1)
			{
				_animationStates.sort(_sortAnimationState);
			}
			
			const slots:Vector.<Slot> = _armature.getSlots();
			for (var i:uint = 0, l:uint = slots.length; i < l; ++i)
			{
				const slot:Slot = slots[i];
				if (slot.inheritAnimation)
				{
					const childArmature:Armature = slot.childArmature;
					if (
						childArmature && 
						childArmature.animation.hasAnimation(animationName) && 
						!childArmature.animation.getState(animationName)
					)
					{
						childArmature.animation.fadeIn(animationName);
					}
				}
			}
			
			if (fadeInTime == 0)
			{
				_armature._delayAdvanceTime = 0;
			}
			
			return _lastAnimationState;
		}
		
		/**
		 * @language zh_CN
		 * 指定名称的动画从指定时间开始播放。
		 * @param animationName 动画数据的名称。
		 * @param time 指定时间。 (以秒为单位，默认: 0)
		 * @param playTimes 动画循环播放的次数。 [-1: 使用动画数据默认值, 0: 无限循环播放, [1~N]: 循环播放 N 次] (默认: -1)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 4.5
		 */
		public function gotoAndPlayByTime(animationName:String, time:Number = 0, playTimes:int = -1):AnimationState
		{
			_time = time;
			
			return fadeIn(animationName, 0, playTimes, 0, null, AnimationFadeOutMode.All);
		}
		
		/**
		 * @language zh_CN
		 * 指定名称的动画从指定帧开始播放。
		 * @param animationName 动画数据的名称。
		 * @param time 指定帧。 (默认: 0)
		 * @param playTimes 动画循环播放的次数。[-1: 使用动画数据默认值, 0: 无限循环播放, [1~N]: 循环播放 N 次] (默认: -1)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 4.5
		 */
		public function gotoAndPlayByFrame(animationName:String, frame:uint = 0, playTimes:int = -1):AnimationState
		{
			const clipData:AnimationData = _animations[animationName];
			if (clipData)
			{
				_time = clipData.duration * frame / clipData.frameCount;
			}
			
			return fadeIn(animationName, 0, playTimes, 0, null, AnimationFadeOutMode.All);
		}
		
		/**
		 * @language zh_CN
		 * 指定名称的动画从指定进度开始播放。
		 * @param animationName 动画数据的名称。
		 * @param time 进度。 [0~1] (默认: 0)
		 * @param playTimes 动画循环播放的次数。[-1: 使用动画数据默认值, 0: 无限循环播放, [1~N]: 循环播放 N 次] (默认: -1)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 4.5
		 */
		public function gotoAndPlayByProgress(animationName:String, progress:Number = 0, playTimes:int = -1):AnimationState
		{
			const clipData:AnimationData = _animations[animationName];
			if (clipData)
			{
				_time = clipData.duration * Math.max(progress, 0);
			}
			
			return fadeIn(animationName, 0, playTimes, 0, null, AnimationFadeOutMode.All);
		}
		
		/**
		 * @language zh_CN
		 * 播放指定名称的动画到指定的时间并停止。
		 * @param animationName 动画数据的名称。
		 * @param time 指定的时间。 (以秒为单位，默认: 0)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 4.5
		 */
		public function gotoAndStopByTime(animationName:String, time:Number = 0):AnimationState
		{
			const animationState:AnimationState = gotoAndPlayByTime(animationName, time, 1);
			if (animationState)
			{
				animationState.stop();
			}
			
			return animationState;
		}
		
		/**
		 * @language zh_CN
		 * 播放指定名称的动画到指定的帧并停止。
		 * @param animationName 动画数据的名称。
		 * @param time 帧。 (默认: 0)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 4.5
		 */
		public function gotoAndStopByFrame(animationName:String, frame:uint = 0):AnimationState
		{
			const animationState:AnimationState = gotoAndPlayByFrame(animationName, frame, 1);
			if (animationState)
			{
				animationState.stop();
			}
			
			return animationState;
		}
		
		/**
		 * @language zh_CN
		 * 播放指定名称的动画到指定的进度并停止。
		 * @param animationName 动画数据的名称。
		 * @param time 指定的进度。 [0~1] (默认: 0)
		 * @return 返回控制这个动画数据的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 4.5
		 */
		public function gotoAndStopByProgress(animationName:String, progress:Number = 0):AnimationState
		{
			const animationState:AnimationState = gotoAndPlayByProgress(animationName, progress, 1);
			if (animationState)
			{
				animationState.stop();
			}
			
			return animationState;
		}
		
		/**
		 * @language zh_CN
		 * 获得指定名称的动画状态。
		 * @param animationName 动画状态的名称。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 3.0
		 */
		public function getState(animationName:String):AnimationState
		{
			for (var i:uint = 0, l:uint = _animationStates.length; i < l; ++i)
			{
				const animationState:AnimationState = _animationStates[i];
				if (animationState.name == animationName)
				{
					return animationState;
				}
			}
			
			return null;
		}
		
		/**
		 * @language zh_CN
		 * 是否包含指定名称的动画数据。
		 * @param animationName 动画数据的名称。
		 * @see dragonBones.objects.AnimationData
		 * @version DragonBones 3.0
		 */
		public function hasAnimation(animationName:String):Boolean
		{
			return _animations[animationName] != null;
		}
		
		/**
		 * @language zh_CN
		 * 动画是否处于播放状态。
		 * @version DragonBones 3.0
		 */
		public function get isPlaying():Boolean
		{
			return _isPlaying;
		}
		
		/**
		 * @language zh_CN
		 * 所有动画状态是否均已播放完毕。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 3.0
		 */
		public function get isCompleted():Boolean
		{
			if (_lastAnimationState)
			{
				if (!_lastAnimationState.isCompleted)
				{
					return false;
				}
				
				for (var i:uint = 0, l:uint = _animationStates.length; i < l; ++i)
				{
					if (!_animationStates[i].isCompleted)
					{
						return false;
					}
				}
			}
			
			return true;
		}
		
		/**
		 * @language zh_CN
		 * 上一个正在播放的动画状态的名称。
		 * @see #lastAnimationState
		 * @version DragonBones 3.0
		 */
		public function get lastAnimationName():String
		{
			return _lastAnimationState? _lastAnimationState.name: null; 
		}
		
		/**
		 * @language zh_CN
		 * 上一个正在播放的动画状态。
		 * @see dragonBones.animation.AnimationState
		 * @version DragonBones 3.0
		 */
		public function get lastAnimationState():AnimationState
		{
			return _lastAnimationState;
		}
		
		/**
		 * @language zh_CN
		 * 当前包含的动画数据名称列表
		 * @see #animations
		 * @version DragonBones 4.5
		 */
		public function get animationNames():Vector.<String>
		{
			return _animationNames;
		}
		
		/**
		 * @language zh_CN
		 * 当前包含的动画数据。
		 * @see dragonBones.objects.AnimationData
		 * @version DragonBones 4.5
		 */
		public function get animations():Object
		{
			return _animations;
		}
		public function set animations(value:Object):void
		{
			if (_animations == value)
			{
				return;
			}
			
			for (var i:String in _animations)
			{
				delete _animations[i];
			}
			
			_animationNames.fixed = false;
			_animationNames.length = 0;
			
			if (value)
			{
				for (var animationName:String in value)
				{
					_animations[animationName] = value[animationName];
					_animationNames.push(animationName);
				}
			}
			
			_animationNames.fixed = true;
		}
		
		/**
		 * @language zh_CN
		 * 不推荐使用的 API。
		 * 请选择以下 API。
		 * @see #play()
		 * @see #fadeIn()
		 * @see #gotoAndPlayByTime()
		 * @see #gotoAndPlayByFrame()
		 * @see #gotoAndPlayByProgress()
		 * @version DragonBones 3.0
		 */
		public function gotoAndPlay(
			animationName:String,
			fadeInTime:Number = -1,
			duration:Number = -1,
			playTimes:int = -1,
			layer:int = 0,
			group:String = null,
			fadeOutMode:int = AnimationFadeOutMode.SameLayerAndGroup,
			additiveBlending:Boolean = false,
			pauseFadeOut:Boolean = true,
			pauseFadeIn:Boolean = true
		):AnimationState
		{
			const animationState:AnimationState = this.fadeIn(animationName, playTimes, fadeInTime, layer, group, fadeOutMode, additiveBlending, pauseFadeOut, pauseFadeIn);
			if (animationState && duration > 0)
			{
				animationState.timeScale = animationState.totalTime / duration;
			}
			
			return animationState;
		}
		
		/**
		 * @language zh_CN
		 * 不推荐使用的 API。
		 * 请选择以下 API。
		 * @see #gotoAndStopByTime()
		 * @see #gotoAndStopByFrame()
		 * @see #gotoAndStopByProgress()
		 * @version DragonBones 3.0
		 */
		public function gotoAndStop(animationName:String, time:Number = 0):AnimationState
		{
			return gotoAndStopByTime(animationName, time);
		}
		
		/**
		 * @language zh_CN
		 * 不推荐使用的 API。
		 * 请选择以下 API。
		 * @see #animationNames
		 * @version DragonBones 3.0
		 */
		public function get animationList():Vector.<String>
		{
			return _animationNames;
		}
	}
}