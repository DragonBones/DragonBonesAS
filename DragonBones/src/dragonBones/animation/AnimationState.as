package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	import dragonBones.objects.AnimationConfig;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.BoneTimelineData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.FFDTimelineData;
	import dragonBones.objects.SlotTimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
     * 动画状态，播放动画时产生，可以对每个播放的动画进行更细致的控制和调节。
	 * @see dragonBones.animation.Animation
	 * @see dragonBones.objects.AnimationData
	 * @version DragonBones 3.0
	 */
	public final class AnimationState extends BaseObject
	{
		/**
		 * @language zh_CN
         * 是否对插槽的显示对象有控制权。
		 * @see dragonBones.Slot#displayController
		 * @version DragonBones 3.0
		 */
		public var displayControl:Boolean;
		/**
		 * @language zh_CN
         * 是否以增加的方式混合。
		 * @version DragonBones 3.0
		 */
		public var additiveBlending:Boolean;
		/**
		 * @language zh_CN
		 * 是否能触发行为。
		 * @version DragonBones 5.0
		 */
		public var actionEnabled:Boolean;
		/**
		 * @language zh_CN
         * 播放次数。 [0: 无限循环播放, [1~N]: 循环播放 N 次]
		 * @version DragonBones 3.0
		 */
		public var playTimes:uint;
		/**
		 * @language zh_CN
         * 播放速度。 [(-N~0): 倒转播放, 0: 停止播放, (0~1): 慢速播放, 1: 正常播放, (1~N): 快速播放]
		 * @version DragonBones 3.0
		 */
		public var timeScale:Number;
		/**
		 * @language zh_CN
         * 混合权重。
		 * @version DragonBones 3.0
		 */
		public var weight:Number;
		/**
		 * @language zh_CN
         * 自动淡出时间。 [-1: 不自动淡出, [0~N]: 淡出时间] (以秒为单位)
         * 当设置一个大于等于 0 的值，动画状态将会在播放完成后自动淡出。
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
		internal var _playheadState:int;
		/**
		 * @private
		 */
		internal var _fadeState:int;
		/**
		 * @private
		 */
		internal var _subFadeState:int;
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
		private var _fadeTime:Number;
		/**
		 * @private
		 */
		private var _time:Number;
		/**
		 * @private
		 */
		internal var _fadeProgress:Number;
		/**
		 * @private
		 */
		internal var _weightResult:Number;
		/**
		 * @private
		 */
		private var _name:String;
		/**
		 * @private
		 */
		internal var _group:String;
		/**
		 * @private
		 */
		private const _boneMask:Vector.<String> = new Vector.<String>();
		/**
		 * @private
		 */
		private const _boneTimelines:Vector.<BoneTimelineState> = new Vector.<BoneTimelineState>();
		/**
		 * @private
		 */
		private const _slotTimelines:Vector.<SlotTimelineState> = new Vector.<SlotTimelineState>();
		/**
		 * @private
		 */
		private const _ffdTimelines:Vector.<FFDTimelineState> = new Vector.<FFDTimelineState>();
		/**
		 * @private
		 */
		private var _animationData:AnimationData;
		/**
		 * @private
		 */
		private var _armature:Armature;
		/**
		 * @private
		 */
		internal var _timeline:AnimationTimelineState;
		/**
		 * @private
		 */
		private var _zOrderTimeline: ZOrderTimelineState;
		/**
		 * @private
		 */
		public function AnimationState()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			for (var i:uint = 0, l:uint = _boneTimelines.length; i < l; ++i)
			{
				_boneTimelines[i].returnToPool();
			}
			
			for (i = 0, l = _slotTimelines.length; i < l; ++i)
			{
				_slotTimelines[i].returnToPool();
			}
			
			for (i = 0, l = _ffdTimelines.length; i < l; ++i)
			{
				_ffdTimelines[i].returnToPool();
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
			timeScale = 1.0;
			weight = 1.0;
			autoFadeOutTime = -1.0;
			fadeTotalTime = 0.0;
			
			_playheadState = 0;
			_fadeState = -1;
			_subFadeState = -1;
			_layer = 0;
			_position = 0.0;
			_duration = 0.0;
			_fadeTime = 0.0;
			_time = 0.0;
			_fadeProgress = 0.0;
			_weightResult = 0.0;
			_name = null;
			_group = null;
			_boneMask.fixed = false;
			_boneMask.length = 0;
			_boneTimelines.fixed = false;
			_boneTimelines.length = 0;
			_slotTimelines.fixed = false;
			_slotTimelines.length = 0;
			_ffdTimelines.fixed = false;
			_ffdTimelines.length = 0;
			_animationData = null;
			_armature = null;
			_timeline = null;
			_zOrderTimeline = null;
		}
		
		private function _advanceFadeTime(passedTime:Number):void
		{
			const isFadeOut:Boolean = _fadeState > 0;
			
			if (_subFadeState < 0) // Fade start event.
			{
				_subFadeState = 0;
				
				var eventType:String = isFadeOut ? EventObject.FADE_OUT : EventObject.FADE_IN;
				if (_armature.eventDispatcher.hasEvent(eventType)) 
				{
					var eventObject:EventObject = BaseObject.borrowObject(EventObject) as EventObject;
					eventObject.animationState = this;
					_armature._bufferEvent(eventObject, eventType);
				}
			}
			
			if (passedTime < 0.0) 
			{
				passedTime = -passedTime;
			}
			
			_fadeTime += passedTime;
			
			if (_fadeTime >= fadeTotalTime) // Fade complete.
			{
				_subFadeState = 1;
				_fadeProgress = isFadeOut ? 0.0 : 1.0;
			}
			else if (_fadeTime > 0.0) // Fading.
			{
				_fadeProgress = isFadeOut ? (1.0 - _fadeTime / fadeTotalTime) : (_fadeTime / fadeTotalTime);
			}
			else // Before fade.
			{
				_fadeProgress = isFadeOut ? 1.0 : 0.0;
			}
			
			if (_subFadeState > 0) // Fade complete event.
			{
				if (!isFadeOut) 
				{
					_playheadState |= 1; // x1
					_fadeState = 0;
				}
				
				eventType = isFadeOut ? EventObject.FADE_OUT_COMPLETE : EventObject.FADE_IN_COMPLETE;
				if (_armature.eventDispatcher.hasEvent(eventType)) 
				{
					eventObject = BaseObject.borrowObject(EventObject) as EventObject;
					eventObject.animationState = this;
					_armature._bufferEvent(eventObject, eventType);
				}
			}
		}
		/**
		 * @private
		 */
		public function _init(armature: Armature, animationData: AnimationData, animationConfig: AnimationConfig): void 
		{
			_armature = armature;
			_animationData = animationData;
			_name = animationConfig.name ? animationConfig.name : animationConfig.animationName;
			
			actionEnabled = animationConfig.actionEnabled;
			additiveBlending = animationConfig.additiveBlending;
			displayControl = animationConfig.displayControl;
			playTimes = animationConfig.playTimes;
			timeScale = animationConfig.timeScale;
			fadeTotalTime = animationConfig.fadeInTime;
			autoFadeOutTime = animationConfig.autoFadeOutTime;
			weight = animationConfig.weight;
			
			if (animationConfig.pauseFadeIn) 
			{
				_playheadState = 2; // 10
			}
			else 
			{
				_playheadState = 3; // 11
			}
			
			_fadeState = -1;
			_subFadeState = -1;
			_layer = animationConfig.layer;
			_time = animationConfig.position;
			_group = animationConfig.group;
			
			if (animationConfig.duration < 0.0) 
			{
				_position = 0.0;
				_duration = _animationData.duration;
			}
			else 
			{
				_position = animationConfig.position;
				_duration = animationConfig.duration;
			}
			
			if (fadeTotalTime <= 0.0) 
			{
				_fadeProgress = 0.999999;
			}
			
			if (animationConfig.boneMask.length > 0) 
			{
				_boneMask.length = animationConfig.boneMask.length;
				for (var i:uint = 0, l:uint = _boneMask.length; i < l; ++i) 
				{
					_boneMask[i] = animationConfig.boneMask[i];
				}
				
				_boneMask.fixed = true;
			}
			
			_timeline = BaseObject.borrowObject(AnimationTimelineState) as AnimationTimelineState;
			_timeline._init(_armature, this, _animationData);
			
			if (_animationData.zOrderTimeline) 
			{
				_zOrderTimeline = BaseObject.borrowObject(ZOrderTimelineState) as ZOrderTimelineState;
				_zOrderTimeline._init(_armature, this, _animationData.zOrderTimeline);
			}
			
			_updateTimelineStates();
		}
		/**
		 * @private
		 */
		internal function _updateTimelineStates():void
		{
			_boneTimelines.fixed = false;
			_slotTimelines.fixed = false;
			_ffdTimelines.fixed = false;
			
			const boneTimelineStates: Object = {};
			const slotTimelineStates: Object = {};
			const ffdTimelineStates: Object = {};
			
			for (var i:uint = 0, l:uint = _boneTimelines.length; i < l; ++i) // Creat bone timelines map.
			{
				var boneTimelineState:BoneTimelineState = _boneTimelines[i];
				boneTimelineStates[boneTimelineState.bone.name] = boneTimelineState;
			}
			
			const bones:Vector.<Bone> = _armature.getBones();
			for (i = 0, l = bones.length; i < l; ++i) 
			{
				const bone:Bone = bones[i];
				const boneTimelineName:String = bone.name;
				if (containsBoneMask(boneTimelineName))
				{
					const boneTimelineData:BoneTimelineData = _animationData.getBoneTimeline(boneTimelineName);
					if (boneTimelineData) 
					{
						if (boneTimelineStates[boneTimelineName]) // Remove bone timeline from map.
						{
							delete boneTimelineStates[boneTimelineName];
						}
						else // Create new bone timeline.
						{
							boneTimelineState = BaseObject.borrowObject(BoneTimelineState) as BoneTimelineState;
							boneTimelineState.bone = bone;
							boneTimelineState._init(_armature, this, boneTimelineData);
							_boneTimelines.push(boneTimelineState);
						}
					}
				}
			}
			
			for each(boneTimelineState in boneTimelineStates) // Remove bone timelines.
			{
				boneTimelineState.bone.invalidUpdate(); //
				_boneTimelines.splice(_boneTimelines.indexOf(boneTimelineState), 1);
				boneTimelineState.returnToPool();
			}
			
			for (i = 0, l = _slotTimelines.length; i < l; ++i) // Create slot timelines map.
			{ 
				var slotTimelineState:SlotTimelineState = _slotTimelines[i];
				slotTimelineStates[slotTimelineState.slot.name] = slotTimelineState;
			}
			
			for (i = 0, l = _ffdTimelines.length; i < l; ++i) // Create ffd timelines map.
			{ 
				var ffdTimelineState:FFDTimelineState = _ffdTimelines[i];
				const display:DisplayData = (ffdTimelineState._timelineData as FFDTimelineData).display;
				var meshName:String = display.inheritAnimation ? display.mesh.name : display.name;
				ffdTimelineStates[meshName] = ffdTimelineState;
			}
			
			const slots:Vector.<Slot> = _armature.getSlots();
			for (i = 0, l = slots.length; i < l; ++i)
			{
				const slot:Slot = slots[i];
				const slotTimelineName:String = slot.name;
				const parentTimelineName:String = slot.parent.name;
				var resetFFDVertices:Boolean = false;
				
				if (containsBoneMask(parentTimelineName)) 
				{
					const slotTimelineData:SlotTimelineData = _animationData.getSlotTimeline(slotTimelineName);
					if (slotTimelineData) 
					{
						if (slotTimelineStates[slotTimelineName]) // Remove slot timeline from map.
						{
							delete slotTimelineStates[slotTimelineName];
						}
						else  // Create new slot timeline.
						{
							slotTimelineState = BaseObject.borrowObject(SlotTimelineState) as SlotTimelineState;
							slotTimelineState.slot = slot;
							slotTimelineState._init(_armature, this, slotTimelineData);
							_slotTimelines.push(slotTimelineState);
						}
					}
					
					const ffdTimelineDatas:Object = _animationData.getFFDTimeline(_armature._skinData.name, slotTimelineName);
					if (ffdTimelineDatas) 
					{
						for (var k:String in ffdTimelineDatas) 
						{
							if (ffdTimelineStates[k]) // Remove ffd timeline from map.
							{
								delete ffdTimelineStates[k];
							}
							else // Create new ffd timeline.
							{
								ffdTimelineState = BaseObject.borrowObject(FFDTimelineState) as FFDTimelineState;
								ffdTimelineState.slot = slot;
								ffdTimelineState._init(_armature, this, ffdTimelineDatas[k]);
								_ffdTimelines.push(ffdTimelineState);
							}
						}
					}
					else 
					{
						resetFFDVertices = true;
					}
				}
				else 
				{
					resetFFDVertices = true;
				}
				
				if (resetFFDVertices) 
				{
					for (var iA:uint = 0, lA:uint = slot._ffdVertices.length; iA < lA; ++iA) 
					{
						slot._ffdVertices[iA] = 0.0;
					}
					
					slot._meshDirty = true;
				}
			}
			
			for each (slotTimelineState in slotTimelineStates) // Remove slot timelines.
			{
				_slotTimelines.splice(_slotTimelines.indexOf(slotTimelineState), 1);
				slotTimelineState.returnToPool();
			}
			
			for each (ffdTimelineState in ffdTimelineStates) // Remove ffd timelines.
			{
				_ffdTimelines.splice(_ffdTimelines.indexOf(ffdTimelineState), 1);
				ffdTimelineState.returnToPool();
			}
			
			_boneTimelines.fixed = true;
			_slotTimelines.fixed = true;
			_ffdTimelines.fixed = true;
		}
		/**
		 * @private
		 */
		internal function _advanceTime(passedTime:Number, cacheFrameRate:Number):void
		{
			// Update fade time.
			if (_fadeState !== 0 || _subFadeState !== 0) 
			{
				_advanceFadeTime(passedTime);
			}
			
			// Update time.
			if (timeScale !== 1.0) 
			{
				passedTime *= timeScale;
			}
			
			if (passedTime !== 0.0 && _playheadState === 3) // 11
			{
				_time += passedTime;
			}
			
			// Weight.
			_weightResult = weight * _fadeProgress;
			if (_weightResult !== 0.0) 
			{
				const isCacheEnabled:Boolean = _fadeState === 0 && cacheFrameRate > 0.0;
				var isUpdatesTimeline:Boolean = true;
				var isUpdatesBoneTimeline:Boolean = true;
				var time:Number = _time;
				
				// Update main timeline.
				_timeline.update(time);
				
				// Cache time internval.
				if (isCacheEnabled) 
				{
					_timeline._currentTime = Math.floor(_timeline._currentTime * cacheFrameRate) / cacheFrameRate;
				}
				
				// Update zOrder timeline.
				if (_zOrderTimeline) 
				{
					_zOrderTimeline.update(time);
				}
				
				// Update cache.
				if (isCacheEnabled) 
				{
					const cacheFrameIndex:int = Math.floor(_timeline._currentTime * cacheFrameRate); // uint
					if (_armature.animation._cacheFrameIndex === cacheFrameIndex) // Same cache.
					{
						isUpdatesTimeline = false;
						isUpdatesBoneTimeline = false;
					}
					else 
					{
						_armature.animation._cacheFrameIndex = cacheFrameIndex;
						
						if (_animationData.cachedFrames[cacheFrameIndex]) // Cached.
						{
							isUpdatesBoneTimeline = false;
						}
						else // Cache.
						{
							_animationData.cachedFrames[cacheFrameIndex] = true;
						}
					}
				}
				
				// Update timelines.
				if (isUpdatesTimeline) 
				{
					if (isUpdatesBoneTimeline) 
					{
						for (var i:uint = 0, l:uint = _boneTimelines.length; i < l; ++i) 
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
			
			if (_fadeState === 0) 
			{
				if (_subFadeState > 0) 
				{
					_subFadeState = 0;
				}
				
				// Auto fade out.
				if (autoFadeOutTime >= 0.0) 
				{
					if (_timeline._playState > 0) 
					{
						fadeOut(autoFadeOutTime);
					}
				}
			}
		}
		/**
		 * @private
		 */
		internal function _isDisabled(slot:Slot):Boolean
		{
			if (
				displayControl &&
				(
					!slot.displayController ||
					slot.displayController === _name ||
					slot.displayController === _group
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
		 * @language zh_CN
		 * 继续播放。
		 * @version DragonBones 3.0
		 */
		public function play():void
		{
			_playheadState = 3; // 11
		}
		/**
		 * @language zh_CN
		 * 暂停播放。
		 * @version DragonBones 3.0
		 */
		public function stop():void
		{
			_playheadState &= 1; // 0x
		}
		/**
		 * @language zh_CN
		 * 淡出动画。
		 * @param fadeOutTime 淡出时间。 (以秒为单位)
		 * @param pausePlayhead 淡出时是否暂停动画。
		 * @version DragonBones 3.0
		 */
		public function fadeOut(fadeOutTime:Number, pausePlayhead:Boolean = true):void
		{
			if (fadeOutTime < 0.0 || fadeOutTime !== fadeOutTime) 
			{
				fadeOutTime = 0.0;
			}
			
			if (pausePlayhead) 
			{
				_playheadState &= 2; // x0
			}
			
			if (_fadeState > 0) {
				if (fadeOutTime > fadeOutTime - _fadeTime) 
				{
					// If the animation is already in fade out, the new fade out will be ignored.
					return;
				}
			}
			else 
			{
				_fadeState = 1;
				_subFadeState = -1;
				
				if (fadeOutTime <= 0.0 || _fadeProgress <= 0.0) 
				{
					_fadeProgress = 0.000001; // Modify _fadeProgress to different value.
				}
				
				for (var i:uint = 0, l:uint = _boneTimelines.length; i < l; ++i)
				{
					_boneTimelines[i].fadeOut();
				}
				
				for (i = 0, l = _slotTimelines.length; i < l; ++i)
				{
					_slotTimelines[i].fadeOut();
				}
				
				for (i = 0, l = _ffdTimelines.length; i < l; ++i)
				{
					_ffdTimelines[i].fadeOut();
				}
			}
			
			displayControl = false; //
			fadeTotalTime = _fadeProgress > 0.000001 ? fadeOutTime / _fadeProgress : 0.0;
			_fadeTime = fadeTotalTime * (1.0 - _fadeProgress);
		}
		/**
		 * @language zh_CN
         * 是否包含骨骼遮罩。
		 * @param name 指定的骨骼名称。
		 * @version DragonBones 3.0
		 */
		public function containsBoneMask(name:String):Boolean
		{
			return _boneMask.length === 0 || _boneMask.indexOf(name) >= 0;
		}
		/**
		 * @language zh_CN
         * 添加骨骼遮罩。
		 * @param boneName 指定的骨骼名称。
		 * @param recursive 是否为该骨骼的子骨骼添加遮罩。
		 * @version DragonBones 3.0
		 */
		public function addBoneMask(name:String, recursive:Boolean = true):void
		{
			const currentBone: Bone = _armature.getBone(name);
			if (!currentBone) 
			{
				return;
			}
			
			_boneMask.fixed = false;
			
			if (_boneMask.indexOf(name) < 0) // Add mixing
			{
				_boneMask.push(name);
			}
			
			if (recursive) // Add recursive mixing.
			{
				const bones:Vector.<Bone> = _armature.getBones();
				for (var i:uint = 0, l:uint = bones.length; i < l; ++i) 
				{
					const bone:Bone = bones[i];
					if (_boneMask.indexOf(bone.name) < 0 && currentBone.contains(bone))
					{
						_boneMask.push(bone.name);
					}
				}
			}
			
			_boneMask.fixed = true;
			
			_updateTimelineStates();
		}
		/**
		 * @language zh_CN
         * 删除骨骼遮罩。
		 * @param boneName 指定的骨骼名称。
		 * @param recursive 是否删除该骨骼的子骨骼遮罩。
		 * @version DragonBones 3.0
		 */
		public function removeBoneMask(name:String, recursive:Boolean = true):void
		{
			_boneMask.fixed = false;
			
			var index:int = _boneMask.indexOf(name);
			if (index >= 0) // Remove mixing.
			{
				_boneMask.splice(index, 1);
			}
			
			if (recursive) 
			{
				const currentBone:Bone = _armature.getBone(name);
				if (currentBone) 
				{
					const bones:Vector.<Bone> = _armature.getBones();
					if (_boneMask.length > 0) // Remove recursive mixing.
					{
						for (var i:uint = 0, l:uint = bones.length; i < l; ++i) 
						{
							var bone:Bone = bones[i];
							index = _boneMask.indexOf(bone.name);
							if (index >= 0 && currentBone.contains(bone))
							{
								_boneMask.splice(index, 1);
							}
						}
					}
					else // Add unrecursive mixing.
					{
						for (i = 0, l = bones.length; i < l; ++i)
						{
							bone = bones[i];
							if (!currentBone.contains(bone))
							{
								_boneMask.push(bone.name);
							}
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
			_boneMask.fixed = false;
			_boneMask.length = 0;
			_boneMask.fixed = true;
			
			_updateTimelineStates();
		}
		/**
		 * @language zh_CN
         * 混合图层。
		 * @version DragonBones 3.0
		 */
		public function get layer():int
		{
			return _layer;
		}
		/**
		 * @language zh_CN
         * 混合组。
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
			return _timeline._playState > 0;
		}
		/**
		 * @language zh_CN
		 * 是否正在播放。
		 * @version DragonBones 3.0
		 */
		public function get isPlaying():Boolean
		{
			return (_playheadState & 2) && _timeline._playState <= 0;
		}
		/**
		 * @language zh_CN
         * 当前播放次数。
		 * @version DragonBones 3.0
		 */
		public function get currentPlayTimes():uint
		{
			return _timeline._currentPlayTimes;
		}
		
		/**
		 * @language zh_CN
         * 动画的总时间。 (以秒为单位)
		 * @version DragonBones 3.0
		 */
		public function get totalTime():Number
		{
			return _duration;
		}
		
		/**
		 * @language zh_CN
         * 动画当前播放的时间。 (以秒为单位)
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
			
			const currentPlayTimes:uint = _timeline._currentPlayTimes - (_timeline._playState > 0? 1: 0);
			value = (value % _duration) + currentPlayTimes * _duration;
			if (_time === value) 
			{
				return;
			}
			
			_time = value;
			_timeline.setCurrentTime(_time);
			
			if (_zOrderTimeline) 
			{
				_zOrderTimeline._playState = -1;
			}
			
			for (var i:uint = 0, l:uint = _boneTimelines.length; i < l; ++i) 
			{
				_boneTimelines[i]._playState = -1;
			}
			
			for (i = 0, l = _slotTimelines.length; i < l; ++i) 
			{
				_slotTimelines[i]._playState = -1;
			}
			
			for (i = 0, l = _ffdTimelines.length; i < l; ++i) 
			{
				_ffdTimelines[i]._playState = -1;
			}
		}
	}
}
