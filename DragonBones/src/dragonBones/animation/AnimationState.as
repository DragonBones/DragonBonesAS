package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	import dragonBones.events.IEventDispatcher;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.BoneTimelineData;
	import dragonBones.objects.FFDTimelineData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SlotTimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 动画状态，播放动画时产生，可以对单个动画的播放进行更细致的控制和调节。
	 * @see dragonBones.animation.Animation
	 * @see dragonBones.objects.AnimationData
	 * @version DragonBones 3.0
	 */
	public final class AnimationState extends BaseObject
	{
		/**
		 * @private
		 */
		public static var stateActionEnabled:Boolean = true;
		
		/**
		 * @language zh_CN
		 * 是否对插槽的颜色，显示序列索引，深度排序，行为等拥有控制的权限。
		 * @see dragonBones.Slot#displayController
		 * @version DragonBones 3.0
		 */
		public var displayControl:Boolean;
		
		/**
		 * @language zh_CN
		 * 是否以叠加的方式混合动画。
		 * @version DragonBones 3.0
		 */
		public var additiveBlending:Boolean;
		
		/**
		 * @private
		 */
		public var actionEnabled:Boolean;
		
		/**
		 * @language zh_CN
		 * 需要播放的次数。 [0: 无限循环播放, [1~N]: 循环播放 N 次]
		 * @version DragonBones 3.0
		 */
		public var playTimes:uint;
		
		/**
		 * @language zh_CN
		 * 播放速度。 [(-N~0): 倒转播放, 0: 停止播放, (0~1): 慢速播放, 1: 正常播放, (1~N): 快速播放]
		 * @default 1
		 * @version DragonBones 3.0
		 */
		public var timeScale:Number;
		
		/**
		 * @language zh_CN
		 * 进行动画混合时的权重。
		 * @default 1
		 * @version DragonBones 3.0
		 */
		public var weight:Number;
		
		/**
		 * @language zh_CN
		 * 自动淡出时需要的时间，当设置一个大于等于 0 的值，动画状态将会在播放完成后自动淡出。 (以秒为单位)
		 * @default -1
		 * @version DragonBones 3.0
		 */
		public var autoFadeOutTime:Number;
		
		/**
		 * @private
		 */
		public var fadeTotalTime:Number;
		
		/**
		 * @private
		 */
		internal var _fadeState:int;
		
		/**
		 * @private
		 */
		internal var _layer:int;
		
		/**
		 * @private
		 */
		internal var _position:Number;
		
		/**
		 * @private
		 */
		internal var _duration:Number;
		
		/**
		 * @private
		 */
		internal var _weightResult:Number;
		
		/**
		 * @private
		 */
		internal var _fadeProgress:Number;
		
		/**
		 * @private
		 */
		internal var _group:String;
		
		/**
		 * @private
		 */
		internal var _timeline:AnimationTimelineState;
		
		/**
		 * @private
		 */
		private var _isPlaying:Boolean;
		
		/**
		 * @private
		 */
		private var _isPausePlayhead:Boolean;
		
		/**
		 * @private
		 */
		private var _fadeTime:Number;
		
		/**
		 * @private
		 */
		private var _time:Number;
		
		/**
		 * @private
		 */
		private var _name:String;
		
		/**
		 * @private
		 */
		private var _armature:Armature;
		
		/**
		 * @private
		 */
		private var _animationData:AnimationData;
		
		/**
		 * @private
		 */
		private var _zOrderTimeline: ZOrderTimelineState;
		
		/**
		 * @private
		 */
		private const _boneMask:Vector.<String> = new Vector.<String>(0, true);
		
		/**
		 * @private
		 */
		private const _boneTimelines:Vector.<BoneTimelineState> = new Vector.<BoneTimelineState>(0, true);
		
		/**
		 * @private
		 */
		private const _slotTimelines:Vector.<SlotTimelineState> = new Vector.<SlotTimelineState>(0, true);
		
		/**
		 * @private
		 */
		private const _ffdTimelines:Vector.<FFDTimelineState> = new Vector.<FFDTimelineState>(0, true);
		
		/**
		 * @private
		 */
		public function AnimationState()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			var i:uint = 0, l:uint = 0;
			
			l = _boneTimelines.length;
			if (l)
			{
				for (i = 0; i < l; ++i)
				{
					_boneTimelines[i].returnToPool();
				}
				
				_boneTimelines.fixed = false;
				_boneTimelines.length = 0;
				_boneTimelines.fixed = true;
			}
			
			l = _slotTimelines.length;
			if (l)
			{
				for (i = 0; i < l; ++i)
				{
					_slotTimelines[i].returnToPool();
				}
				
				_slotTimelines.fixed = false;
				_slotTimelines.length = 0;
				_slotTimelines.fixed = true;
			}
			
			l = _ffdTimelines.length;
			if (l)
			{
				for (i = 0; i < l; ++i)
				{
					_ffdTimelines[i].returnToPool();
				}
				
				_ffdTimelines.fixed = false;
				_ffdTimelines.length = 0;
				_ffdTimelines.fixed = true;
			}
			
			if (_timeline)
			{
				_timeline.returnToPool();
			}
			
			if (_zOrderTimeline)
			{
				_zOrderTimeline.returnToPool();
			}
			
			displayControl = true;
			additiveBlending = false;
			actionEnabled = false;
			playTimes = 1;
			timeScale = 1;
			weight = 1;
			autoFadeOutTime = -1;
			fadeTotalTime = 0;
			
			_fadeState = 0;
			_layer = 0;
			_position = 0;
			_duration = 0;
			_weightResult = 0;
			_fadeProgress = 0;
			_group = null;
			_timeline = null;
			
			_isPlaying = true;
			_isPausePlayhead = false;
			_fadeTime = 0;
			_time = 0;
			_name = null;
			_armature = null;
			_animationData = null;
			_zOrderTimeline = null;
			
			if (_boneMask.length)
			{
				_boneMask.fixed = false;
				_boneMask.length = 0;
				_boneMask.fixed = true;
			}
		}
		
		private function _updateTimelineStates():void
		{
			var time:Number = _time;
			if (!_animationData.hasAsynchronyTimeline)
			{
				time = _timeline._currentTime;
			}
			
			var i:uint = 0, l:uint = 0;
			var boneTimelineState:BoneTimelineState = null;
			var slotTimelineState:SlotTimelineState = null;
			
			const boneTimelineStates:Object = {};
			const slotTimelineStates:Object = {};
			
			//
			_boneTimelines.fixed = false;
			
			for (i = 0, l = _boneTimelines.length; i < l; ++i)
			{
				boneTimelineState = _boneTimelines[i];
				boneTimelineStates[boneTimelineState.bone.name] = boneTimelineState;
			}
			
			const bones:Vector.<Bone> = _armature.getBones();
			for (i = 0, l = bones.length; i < l; ++i)
			{
				const bone:Bone = bones[i];
				const boneTimelineName:String = bone.name;
				const boneTimelineData:BoneTimelineData = _animationData.getBoneTimeline(boneTimelineName);
				
				if (boneTimelineData && containsBoneMask(boneTimelineName))
				{
					boneTimelineState = boneTimelineStates[boneTimelineName];
					if (boneTimelineState)
					{
						delete boneTimelineStates[boneTimelineName];
					}
					else
					{
						boneTimelineState = BaseObject.borrowObject(BoneTimelineState) as BoneTimelineState;
						boneTimelineState.bone = bone;
						boneTimelineState.fadeIn(_armature, this, boneTimelineData, time);
						_boneTimelines.push(boneTimelineState);
					}
				}
			}
			
			for each (boneTimelineState in boneTimelineStates)
			{
				boneTimelineState.bone.invalidUpdate();
				_boneTimelines.splice(_boneTimelines.indexOf(boneTimelineState), 1);
				boneTimelineState.returnToPool();
			}
			
			_boneTimelines.fixed = true;
			
			//
			_slotTimelines.fixed = false;
			
			for (i = 0, l = _slotTimelines.length; i < l; ++i)
			{
				slotTimelineState = _slotTimelines[i];
				slotTimelineStates[slotTimelineState.slot.name] = slotTimelineState;
			}
			
			const slots:Vector.<Slot> = _armature.getSlots();
			for (i = 0, l = slots.length; i < l; ++i)
			{
				const slot:Slot = slots[i];
				const slotTimelineName:String = slot.name;
				const parentTimelineName:String = slot.parent.name;
				const slotTimelineData:SlotTimelineData = _animationData.getSlotTimeline(slotTimelineName);
				
				if (slotTimelineData && containsBoneMask(parentTimelineName) && _fadeState <= 0) // 当动画状态已经开始淡出, SlotTimelineState 将不在同步更新
				{
					slotTimelineState = slotTimelineStates[slotTimelineName];
					if (slotTimelineState)
					{
						delete slotTimelineStates[slotTimelineName];
					}
					else
					{
						slotTimelineState = BaseObject.borrowObject(SlotTimelineState) as SlotTimelineState;
						slotTimelineState.slot = slot;
						slotTimelineState.fadeIn(_armature, this, slotTimelineData, time);
						_slotTimelines.push(slotTimelineState);
					}
				}
			}
			
			for each (slotTimelineState in slotTimelineStates)
			{
				_slotTimelines.splice(_slotTimelines.indexOf(slotTimelineState), 1);
				slotTimelineState.returnToPool();
			}
			
			_slotTimelines.fixed = true;
			
			_updateFFDTimelineStates();
		}
		
		private function _advanceFadeTime(passedTime:Number):void
		{
			if (passedTime < 0)
			{
				passedTime = -passedTime;
			}
			
			_fadeTime += passedTime;
			
			var fadeProgress:Number = 0;
			if (_fadeTime >= fadeTotalTime) // Fade complete.
			{
				// fadeProgress = _isFadeOut? 0: 1;
				if (_fadeState > 0)
				{
					fadeProgress = 0;
				}
				else
				{
					fadeProgress = 1;
				}
			}
			else if (_fadeTime > 0) // Fading.
			{
				// fadeProgress = _isFadeOut? (1 - _fadeTime / fadeTotalTime): (_fadeTime / fadeTotalTime);
				if (_fadeState > 0)
				{
					fadeProgress = 1 - _fadeTime / fadeTotalTime;
				}
				else
				{
					fadeProgress = _fadeTime / fadeTotalTime;
				}
			}
			else // Before fade.
			{
				// fadeProgress = _isFadeOut? 1: 0;
				if (_fadeState > 0)
				{
					fadeProgress = 1;
				}
				else
				{
					fadeProgress = 0;
				}
			}
			
			if (_fadeProgress != fadeProgress)
			{
				_fadeProgress = fadeProgress;
				
				const eventDispatcher:IEventDispatcher = _armature._display;
				var event:EventObject = null;
				
				if (_fadeTime <= passedTime)
				{
					if (_fadeState > 0)
					{
						if (eventDispatcher.hasEvent(EventObject.FADE_OUT))
						{
							event = BaseObject.borrowObject(EventObject) as EventObject;
							event.animationState = this;
							_armature._bufferEvent(event, EventObject.FADE_OUT);
						}
					}
					else
					{
						if (eventDispatcher.hasEvent(EventObject.FADE_IN))
						{
							event = BaseObject.borrowObject(EventObject) as EventObject;
							event.animationState = this;
							_armature._bufferEvent(event, EventObject.FADE_IN);
						}
					}
				}
				
				if (_fadeTime >= fadeTotalTime)
				{
					if (_fadeState > 0)
					{
						_isPausePlayhead = true;
						
						if (eventDispatcher.hasEvent(EventObject.FADE_OUT_COMPLETE))
						{
							event = BaseObject.borrowObject(EventObject) as EventObject;
							event.animationState = this;
							_armature._bufferEvent(event, EventObject.FADE_OUT_COMPLETE);
						}
					}
					else
					{
						_isPausePlayhead = false;
						_fadeState = 0;
						
						if (eventDispatcher.hasEvent(EventObject.FADE_IN_COMPLETE))
						{
							event = BaseObject.borrowObject(EventObject) as EventObject;
							event.animationState = this;
							_armature._bufferEvent(event, EventObject.FADE_IN_COMPLETE);
						}
					}
				}
			}
		}
		
		/**
		 * @private
		 */
		[inline]
		internal function _isDisabled(slot:Slot):Boolean
		{
			if (
				displayControl && 
				(
					!slot.displayController || 
					slot.displayController == _name || 
					slot.displayController == _group
				)
			)
			{
				return false;
			}
			
			return true;
		}
		
		/**
		 * @private
		 */
		internal function _fadeIn(
			armature:Armature, clip:AnimationData, animationName:String, 
			playTimes:uint, position:Number, duration:Number, time:Number, timeScale:Number, fadeInTime:Number, 
			pausePlayhead:Boolean
		):void
		{
			_armature = armature;
			_animationData = clip;
			_name = animationName;
			
			actionEnabled = AnimationState.stateActionEnabled;
			this.playTimes = playTimes;
			this.timeScale = timeScale;
			fadeTotalTime = fadeInTime;
			
			_fadeState = -1;
			_position = position;
			_duration = duration;
			_time = time;
			_isPausePlayhead = pausePlayhead;
			if (fadeTotalTime <= 0)
			{
				_fadeProgress = 0.999999;
			}
			
			_timeline = BaseObject.borrowObject(AnimationTimelineState) as AnimationTimelineState;
			_timeline.fadeIn(_armature, this, _animationData, _time);
			
			if (_animationData.zOrderTimeline) 
			{
				_zOrderTimeline = BaseObject.borrowObject(ZOrderTimelineState)as ZOrderTimelineState;
				_zOrderTimeline.fadeIn(_armature, this, _animationData.zOrderTimeline, _time);
			}
			
			_updateTimelineStates();
		}
		
		/**
		 * @private
		 */
		internal function _updateFFDTimelineStates():void
		{
			var time:Number = _time;
			if (!_animationData.hasAsynchronyTimeline)
			{
				time = _timeline._currentTime;
			}
			
			var i:uint = 0, l:uint = 0;
			var ffdTimelineState:FFDTimelineState = null;
			const ffdTimelineStates:Object = {};
			
			//
			_ffdTimelines.fixed = false;
			
			for (i = 0, l = _ffdTimelines.length; i < l; ++i)
			{
				ffdTimelineState = _ffdTimelines[i];
				ffdTimelineStates[ffdTimelineState.slot.name] = ffdTimelineState;
			}
			
			const slots:Vector.<Slot> = _armature.getSlots();
			for (i = 0, l = slots.length; i < l; ++i)
			{
				const slot:Slot = slots[i];
				const slotTimelineName:String = slot.name;
				const parentTimelineName:String = slot.parent.name;
				
				if (slot._meshData)
				{
					const displayIndex:int = slot.displayIndex;
					const rawMeshData:MeshData = displayIndex < slot._displayDataSet.displays.length ? slot._displayDataSet.displays[displayIndex].mesh : null;
					
					if (slot._meshData == rawMeshData) 
					{
						const ffdTimelineData:FFDTimelineData = _animationData.getFFDTimeline(_armature._skinData.name, slotTimelineName, slot.displayIndex);
						if (ffdTimelineData && containsBoneMask(parentTimelineName)) // && !_isFadeOut
						{
							ffdTimelineState = ffdTimelineStates[slotTimelineName];
							if (ffdTimelineState)
							{
								delete ffdTimelineStates[slotTimelineName];
							}
							else
							{
								ffdTimelineState = BaseObject.borrowObject(FFDTimelineState) as FFDTimelineState;
								ffdTimelineState.slot = slot;
								ffdTimelineState.fadeIn(_armature, this, ffdTimelineData, time);
								_ffdTimelines.push(ffdTimelineState);
							}
						}
						else 
						{
							for (var iF:uint = 0, lF:uint = slot._ffdVertices.length; iF < lF; ++iF)
							{
								slot._ffdVertices[iF] = 0;
							}
							
							slot._ffdDirty = true;
						}
					}
				}
			}
			
			for each (ffdTimelineState in ffdTimelineStates)
			{
				//ffdTimelineState.slot._ffdDirty = true;
				_ffdTimelines.splice(_ffdTimelines.indexOf(ffdTimelineState), 1);
				ffdTimelineState.returnToPool();
			}
			
			_ffdTimelines.fixed = true;
		}
		
		/**
		 * @private
		 */
		internal function _getBoneTimelineState(name:String):BoneTimelineState
		{
			for each (var boneTimelineState:BoneTimelineState in _boneTimelines)
			{
				if (boneTimelineState.bone.name == name)
				{
					return boneTimelineState;
				}
			}
			
			return null;
		}
		
		/**
		 * @private
		 */
		internal function _advanceTime(passedTime:Number, weightLeft:Number, index:int):void
		{
			// Update fade time. (Still need to be update even if the passedTime is zero)
			if (_fadeState != 0)
			{
				_advanceFadeTime(passedTime);
			}
			
			// Update time.
			passedTime *= timeScale;
			if (passedTime != 0 && _isPlaying && !_isPausePlayhead)
			{
				_time += passedTime;
			}
			
			// Blend weight.
			_weightResult = weight * _fadeProgress * weightLeft;
			
			if (_weightResult != 0)
			{
				const isCacheEnabled:Boolean = _fadeProgress >= 1 && index == 0 && _armature.cacheFrameRate > 0;
				const cacheTimeToFrameScale:Number = _animationData.cacheTimeToFrameScale;
				var isUpdateTimelines:Boolean = true;
				var isUpdateBoneTimelines:Boolean = true;
				var time:Number = cacheTimeToFrameScale * 2;
				time = isCacheEnabled? (uint(_time * time) / time): _time; // Cache time internval.
				
				// Update main timeline.
				_timeline.update(time);
				if (!_animationData.hasAsynchronyTimeline)
				{
					time = _timeline._currentTime;
				}
				
				if (_zOrderTimeline) 
				{
					_zOrderTimeline.update(time);
				}
				
				var i:uint = 0, l:uint = 0;
				
				if (isCacheEnabled)
				{
					const cacheFrameIndex:uint = uint(_timeline._currentTime * cacheTimeToFrameScale);
					if (_armature._cacheFrameIndex == cacheFrameIndex) // Same cache.
					{
						isUpdateTimelines = false;
						isUpdateBoneTimelines = false;
					}
					else
					{
						_armature._cacheFrameIndex = cacheFrameIndex;
						
						if (_armature._animation._animationStateDirty) // Update _cacheFrames.
						{
							_armature._animation._animationStateDirty = false;
							
							for (i = 0, l = _boneTimelines.length; i < l; ++i)
							{
								const boneTimeline:BoneTimelineState = _boneTimelines[i];
								boneTimeline.bone._cacheFrames = (boneTimeline._timeline as BoneTimelineData).cachedFrames;
							}
							
							for (i = 0, l = _slotTimelines.length; i < l; ++i)
							{
								const slotTimeline:SlotTimelineState = _slotTimelines[i];
								slotTimeline.slot._cacheFrames = (slotTimeline._timeline as SlotTimelineData).cachedFrames;
							}
						}
						
						if (_animationData.cachedFrames[cacheFrameIndex]) // Cached.
						{
							isUpdateBoneTimelines = false;
						}
						else // Cache.
						{
							_animationData.cachedFrames[cacheFrameIndex] = true;
						}
					}
				}
				else
				{
					_armature._cacheFrameIndex = -1;
				}
				
				if (isUpdateTimelines)
				{
					if (isUpdateBoneTimelines)
					{
						for (i = 0, l = _boneTimelines.length; i < l; ++i)
						{
							_boneTimelines[i].update(time);
						}
					}
					
					for (i = 0, l = _slotTimelines.length; i < l; ++i)
					{
						_slotTimelines[i].update(time);
					}
					
					for (i = 0, l = _ffdTimelines.length; i < l; ++i)
					{
						_ffdTimelines[i].update(time);
					}
				}
			}
			
			if (autoFadeOutTime >= 0 && _fadeProgress >= 1 && _timeline._isCompleted)
			{
				fadeOut(autoFadeOutTime);
			}
		}
		
		/**
		 * @language zh_CN
		 * 继续播放。
		 * @version DragonBones 3.0
		 */
		public function play():void
		{
			_isPlaying = true;
		}
		
		/**
		 * @language zh_CN
		 * 暂停播放。
		 * @version DragonBones 3.0
		 */
		public function stop():void
		{
			_isPlaying = false;
		}
		
		/**
		 * @language zh_CN
		 * 淡出动画。
		 * @param fadeOutTime 淡出时间。 (以秒为单位)
		 * @param pausePlayhead 淡出时是否暂停动画。 [true: 暂停, false: 不暂停]
		 * @version DragonBones 3.0
		 */
		public function fadeOut(fadeOutTime:Number, pausePlayhead:Boolean = true):void
		{
			if (fadeOutTime < 0 || fadeOutTime != fadeOutTime)
			{ 
				fadeOutTime = 0;
			}
			
			_isPausePlayhead = pausePlayhead;
			
			if (_fadeState > 0)
			{
				if (fadeOutTime > fadeOutTime - _fadeTime)
				{
					//If the animation is already in fade out, the new fade out will be ignored.
					return;
				}
			}
			else
			{
				_fadeState = 1;
				
				if (fadeOutTime <= 0 || _fadeProgress <= 0)
				{
					_fadeProgress = 0.000001;
				}
				
				for each(var boneTimelineState:BoneTimelineState in _boneTimelines)
				{
					boneTimelineState.fadeOut();
				}
				
				for each(var slotTimelineState:SlotTimelineState in _slotTimelines)
				{
					slotTimelineState.fadeOut();
				}
			}
			
			displayControl = false;
			fadeTotalTime = _fadeProgress > 0.000001? fadeOutTime / _fadeProgress: 0;
			_fadeTime = fadeTotalTime * (1 - _fadeProgress);
		}
		
		/**
		 * @language zh_CN
		 * 是否包含指定的骨骼遮罩。
		 * @param name 指定的骨骼名称。
		 * @version DragonBones 3.0
		 */
		[inline]
		public function containsBoneMask(name:String):Boolean
		{
			return !_boneMask.length || _boneMask.indexOf(name) >= 0;
		}
		
		/**
		 * @language zh_CN
		 * 添加指定的骨骼遮罩。
		 * @param boneName 指定的骨骼名称。
		 * @param recursive 是否为该骨骼的子骨骼添加遮罩。
		 * @version DragonBones 3.0
		 */
		public function addBoneMask(name:String, recursive:Boolean = true):void
		{
			const currentBone:Bone = _armature.getBone(name);
			if (!currentBone)
			{
				return;
			}
			
			_boneMask.fixed = false;
			
			if (
				_boneMask.indexOf(name) < 0 &&
				_animationData.getBoneTimeline(name)
			) // Add mixing.
			{
				_boneMask.push(name);
			}
			
			if (recursive)
			{
				for each(var bone:Bone in _armature.getBones())
				{
					const boneName:String = bone.name;
					if (
						_boneMask.indexOf(boneName) < 0 &&
						_animationData.getBoneTimeline(boneName) &&
						currentBone.contains(bone)
					) // Add recursive mixing.
					{
						_boneMask.push(boneName);
					}
				}
			}
			
			_boneMask.fixed = true;
			
			_updateTimelineStates();
		}
		
		/**
		 * @language zh_CN
		 * 删除指定的骨骼遮罩。
		 * @param boneName 指定的骨骼名称。
		 * @param recursive 是否删除该骨骼的子骨骼遮罩。
		 * @version DragonBones 3.0
		 */
		public function removeBoneMask(name:String, recursive:Boolean = true):void
		{
			_boneMask.fixed = false;
			
			const indexA:int = _boneMask.indexOf(name);
			if (indexA >= 0) // Remove mixing.
			{
				_boneMask.splice(indexA, 1);
			}
			
			if (recursive)
			{
				const currentBone:Bone = _armature.getBone(name);
				if (currentBone)
				{
					for each(var bone:Bone in _armature.getBones())
					{
						const boneName:String = bone.name;
						const indexB:int = _boneMask.indexOf(boneName);
						if (
							indexB >= 0 &&
							currentBone.contains(bone)
						) // Remove recursive mixing.
						{
							_boneMask.splice(indexB, 1);
						}
					}
				}
			}
			
			_boneMask.fixed = true;
			
			_updateTimelineStates();
		}
		
		/**
		 * @language zh_CN
		 * 删除所有骨骼遮罩。
		 * @version DragonBones 3.0
		 */
		public function removeAllBoneMask():void
		{
			_boneMask.length = 0;
			_updateTimelineStates();
		}
		
		/**
		 * @language zh_CN
		 * 动画图层。
		 * @see dragonBones.animation.Animation#fadeIn()
		 * @version DragonBones 3.0
		 */
		public function get layer():int
		{
			return _layer;
		}
		
		/**
		 * @language zh_CN
		 * 动画组。
		 * @see dragonBones.animation.Animation#fadeIn()
		 * @version DragonBones 3.0
		 */
		public function get group():String
		{
			return _group;
		}
		
		/**
		 * @language zh_CN
		 * 动画名称。
		 * @see dragonBones.objects.AnimationData#name
		 * @version DragonBones 3.0
		 */
		public function get name():String
		{
			return _name;
		}
		
		/**
		 * @language zh_CN
		 * 动画数据。
		 * @see dragonBones.objects.AnimationData
		 * @version DragonBones 3.0
		 */
		public function get animationData():AnimationData
		{
			return _animationData;
		}
		
		/**
		 * @language zh_CN
		 * 是否播放完毕。
		 * @version DragonBones 3.0
		 */
		public function get isCompleted():Boolean
		{
			return _timeline._isCompleted; 
		}
		
		/**
		 * @language zh_CN
		 * 是否正在播放。
		 * @version DragonBones 3.0
		 */
		public function get isPlaying():Boolean
		{
			return _isPlaying && !_timeline._isCompleted;
		}
		
		/**
		 * @language zh_CN
		 * 当前动画的播放次数。
		 * @version DragonBones 3.0
		 */
		public function get currentPlayTimes():uint
		{
			return _timeline._currentPlayTimes;
		}
		
		/**
		 * @language zh_CN
		 * 当前动画的总时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public function get totalTime():Number
		{
			return _duration;
		}
		
		/**
		 * @language zh_CN
		 * 当前动画的播放时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public function get currentTime():Number
		{
			return _timeline._currentTime;
		}
		public function set currentTime(value:Number):void
		{
			if (value < 0 || value != value)
			{
				value = 0;
			}
			
			const currentPlayTimes:uint = _timeline._currentPlayTimes - (_timeline._isCompleted? 1: 0);
			value = (value % _duration) + currentPlayTimes * _duration;
			if (_time == value) 
			{
				return;
			}
			
			_time = value;
			_timeline.setCurrentTime(_time);
			
			if (_zOrderTimeline) 
			{
				_zOrderTimeline._isCompleted = false;
			}
			
			var i:uint = 0, l:uint = 0;
			for (i = 0, l = _boneTimelines.length; i < l; ++i) 
			{
				_boneTimelines[i]._isCompleted = false;
			}
			
			for (i = 0, l = _slotTimelines.length; i < l; ++i) 
			{
				_slotTimelines[i]._isCompleted = false;
			}
			
			for (i = 0, l = _ffdTimelines.length; i < l; ++i) 
			{
				_ffdTimelines[i]._isCompleted = false;
			}
		}
		
		/**
		 * @deprecated
		 * @see #animationData
		 */
		public function get clip():AnimationData
		{
			return _animationData;
		}
	}
}
