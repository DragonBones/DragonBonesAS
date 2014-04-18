package dragonBones.animation
{
	import flash.geom.Point;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.DBTransform;
	
	use namespace dragonBones_internal;
	
	/**
	 * An Animation instance is used to control the animation state of an Armature.
	 * @see dragonBones.Armature
	 * @see dragonBones.animation.Animation
	 * @see dragonBones.animation.AnimationState
	 */
	public class Animation
	{
		public static const NONE:String = "none";
		public static const SAME_LAYER:String = "sameLayer";
		public static const SAME_GROUP:String = "sameGroup";
		public static const SAME_LAYER_AND_GROUP:String = "sameLayerAndGroup";
		public static const ALL:String = "all";
		
		
		/**
		 * Whether animation tweening is enabled or not.
		 */
		public var tweenEnabled:Boolean;
		
		private var _armature:Armature;
		
		private var _animationStateList:Vector.<AnimationState>;
		
		/** @private */
		dragonBones_internal var _lastAnimationState:AnimationState;
		
		/** @private */
		dragonBones_internal var _isFading:Boolean
		
		/** @private */
		dragonBones_internal var _animationStateCount:int;
		
		/**
		 * The last AnimationState this Animation played.
		 * @see dragonBones.objects.AnimationData.
		 */
		public function get lastAnimationState():AnimationState
		{
			return _lastAnimationState;
		}
		/**
		 * The name of the last AnimationData played.
		 * @see dragonBones.objects.AnimationData.
		 */
		public function get lastAnimationName():String
		{
			return _lastAnimationState?_lastAnimationState.name:null;
		}
		
		private var _animationList:Vector.<String>;
		/**
		 * An vector containing all AnimationData names the Animation can play.
		 * @see dragonBones.objects.AnimationData.
		 */
		public function get animationList():Vector.<String>
		{
			return _animationList;
		}
		
		private var _isPlaying:Boolean;
		/**
		 * 动画是否在播放.
		 * @see dragonBones.animation.AnimationState.
		 */
		public function get isPlaying():Boolean
		{
			return _isPlaying && !isComplete;
		}
		
		/**
		 * Is animation complete.
		 * @see dragonBones.animation.AnimationState.
		 */
		public function get isComplete():Boolean
		{
			if(_lastAnimationState)
			{
				if(!_lastAnimationState.isComplete)
				{
					return false;
				}
				var i:int = _animationStateList.length;
				while(i --)
				{
					if(!_animationStateList[i].isComplete)
					{
						return false;
					}
				}
				return true;
			}
			return true;
		}
		
		private var _timeScale:Number;
		/**
		 * The amount by which passed time should be scaled. Used to slow down or speed up animations. Defaults to 1.
		 */
		public function get timeScale():Number
		{
			return _timeScale;
		}
		public function set timeScale(value:Number):void
		{
			if(isNaN(value) || value < 0)
			{
				value = 1;
			}
			_timeScale = value;
		}
		
		private var _animationDataList:Vector.<AnimationData>;
		/**
		 * The AnimationData list associated with this Animation instance.
		 * @see dragonBones.objects.AnimationData.
		 */
		public function get animationDataList():Vector.<AnimationData>
		{
			return _animationDataList;
		}
		public function set animationDataList(value:Vector.<AnimationData>):void
		{
			_animationDataList = value;
			_animationList.length = 0;
			for each(var animationData:AnimationData in _animationDataList)
			{
				_animationList[_animationList.length] = animationData.name;
			}
		}
		
		/**
		 * Creates a new Animation instance and attaches it to the passed Armature.
		 * @param An Armature to attach this Animation instance to.
		 */
		public function Animation(armature:Armature)
		{
			_armature = armature;
			_animationList = new Vector.<String>;
			_animationStateList = new Vector.<AnimationState>;
			
			_timeScale = 1;
			_isPlaying = false;
			
			tweenEnabled = true;
		}
		
		/**
		 * Qualifies all resources used by this Animation instance for garbage collection.
		 */
		public function dispose():void
		{
			if(!_armature)
			{
				return;
			}
			var i:int = _animationStateList.length;
			while(i --)
			{
				AnimationState.returnObject(_animationStateList[i]);
			}
			_animationList.length = 0;
			_animationStateList.length = 0;
			
			_armature = null;
			_animationDataList = null;
			_animationList = null;
			_animationStateList = null;
		}
		
		/**
		 * Fades the animation with name animation in over a period of time seconds and fades other animations out.
		 * @param animationName The name of the AnimationData to play.
		 * @param fadeInTime A fade time to apply (>= 0), 混合影响到的其他动画会尝试使用这个时间淡出, 默认使用AnimationData.fadeInTime.
		 * @param duration The duration of that AnimationData, 默认使用AnimationData.duration.
		 * @param playTimes Play times(0:loop forever, 1~+∞:play times, -1~-∞:will fade animation after play complete), 默认使用AnimationData.loop.
		 * @param layer The layer of the animation.
		 * @param group The group of the animation.
		 * @param fadeOutMode Fade out mode (none, sameLayer, sameGroup, sameLayerAndGroup, all).
		 * @param pauseFadeOut Pause other animation playing.
		 * @param pauseFadeIn Pause this animation playing before fade in complete.
		 * @return AnimationState.
		 * @see dragonBones.objects.AnimationData.
		 * @see dragonBones.animation.AnimationState.
		 */
		public function gotoAndPlay(
			animationName:String, 
			fadeInTime:Number = -1, 
			duration:Number = -1, 
			playTimes:Number = NaN, 
			layer:uint = 0, 
			group:String = null,
			fadeOutMode:String = SAME_LAYER_AND_GROUP,
			pauseFadeOut:Boolean = true,
			pauseFadeIn:Boolean = true
		):AnimationState
		{
			if (!_animationDataList)
			{
				return null;
			}
			var i:int = _animationDataList.length;
			var animationData:AnimationData;
			while(i --)
			{
				if(_animationDataList[i].name == animationName)
				{
					animationData = _animationDataList[i];
					break;
				}
			}
			if (!animationData)
			{
				return null;
			}
			
			_isPlaying = true;
			
			//
			fadeInTime = fadeInTime < 0?(animationData.fadeTime < 0?0.3:animationData.fadeTime):fadeInTime;
			
			var durationScale:Number;
			if(duration < 0)
			{
				durationScale = animationData.scale < 0?1:animationData.scale;
			}
			else
			{
				durationScale = duration / animationData.duration;
			}
			
			playTimes = isNaN(playTimes)?animationData.playTimes:playTimes;
			
			//autoSync = autoSync && !pauseFadeOut && !pauseFadeIn;
			var animationState:AnimationState;
			var j:int;
			switch(fadeOutMode)
			{
				case NONE:
					break;
				
				case SAME_LAYER:
					i = _animationStateList.length;
					while(i --)
					{
						animationState = _animationStateList[i];
						if(animationState.layer == layer)
						{
							animationState.fadeOut(fadeInTime, pauseFadeOut);
						}
					}
					break;
				
				case SAME_GROUP:
					i = _animationStateList.length;
					while(i --)
					{
						animationState = _animationStateList[i];
						if(animationState.group == group)
						{
							animationState.fadeOut(fadeInTime, pauseFadeOut);
						}
					}
					break;
				
				case ALL:
					i = _animationStateList.length;
					while(i --)
					{
						animationState = _animationStateList[i];
						animationState.fadeOut(fadeInTime, pauseFadeOut);
					}
					break;
				
				case SAME_LAYER_AND_GROUP:
				default:
					i = _animationStateList.length;
					while(i --)
					{
						animationState = _animationStateList[i];
						if(animationState.layer == layer && animationState.group == group )
						{
							animationState.fadeOut(fadeInTime, pauseFadeOut);
						}
					}
					break;
			}
			
			_lastAnimationState = AnimationState.borrowObject();
			_lastAnimationState.layer = layer;
			_lastAnimationState.group = group;
			_lastAnimationState.autoTween = tweenEnabled;
			_lastAnimationState.fadeIn(_armature, animationData, fadeInTime, 1 / durationScale, playTimes, pauseFadeIn);
			
			addState(_lastAnimationState);
			/*
			_lastAnimationState.advanceTime(0);
			var boneList:Vector.<Bone> = _armature.getBones(false);
			i = boneList.length;
			while(i --)
			{
				boneList[i].update();
			}
			*/
			
			var slotList:Vector.<Slot> = _armature.getSlots(false);
			i = slotList.length;
			while(i --)
			{
				var slot:Slot = slotList[i];
				//slot.update();
				if(slot.childArmature)
				{
					slot.childArmature.animation.gotoAndPlay(animationName, fadeInTime);
				}
			}
			
			return _lastAnimationState;
		}
		
		/**
		 * 控制一个animationState停止到指定的时间，如果指定的animationState不存在，则添加一个新的animationState
		 * @param animationName The name of the animationState.
		 * @param time 
		 * @param normalizedTime 
		 * @param fadeInTime A fade time to apply (>= 0), 混合影响到的其他动画会尝试使用这个时间淡出, 默认为0, 可以设置为-1来使用AnimationData.fadeInTime.
		 * @param duration The duration of that AnimationData, 默认使用AnimationData.duration.
		 * @param layer The layer of the animation.
		 * @param group The group of the animation.
		 * @return AnimationState.
		 * @see dragonBones.objects.AnimationData.
		 * @see dragonBones.animation.AnimationState.
		 */
		public function gotoAndStop(
			animationName:String, 
			time:Number, 
			normalizedTime:Number = -1,
			fadeInTime:Number = 0, 
			duration:Number = -1, 
			layer:uint = 0, 
			group:String = null
		):AnimationState
		{
			var animationState:AnimationState = getState(animationName, layer);
			if(!animationState)
			{
				animationState = gotoAndPlay(animationName, fadeInTime, duration, NaN, layer, group);
			}
			
			if(normalizedTime >= 0)
			{
				animationState.setCurrentTime(animationState.totalTime * normalizedTime);
			}
			else
			{
				animationState.setCurrentTime(time);
			}
			
			animationState.stop();
			
			return animationState;
		}
		
		/**
		 * Play the animation from the current position.
		 */
		public function play():void
		{
			if (!_animationDataList || _animationDataList.length == 0)
			{
				return;
			}
			if(!_lastAnimationState)
			{
				gotoAndPlay(_animationDataList[0].name);
			}
			else if (!_isPlaying)
			{
				_isPlaying = true;
			}
			else
			{
				gotoAndPlay(_lastAnimationState.name);
			}
		}
		
		public function stop():void
		{
			_isPlaying = false;
		}
		
		/**
		 * Returns the AnimationState named name.
		 * @return A AnimationState instance.
		 * @see dragonBones.animation.AnimationState.
		 */
		public function getState(name:String, layer:int = 0):AnimationState
		{
			var i:int = _animationStateList.length;
			while(i --)
			{
				var animationState:AnimationState = _animationStateList[i];
				if(animationState.name == name && animationState.layer == layer)
				{
					return animationState;
				}
			}
			return null;
		}
		
		/**
		 * 检查是否包含指定的animationData.
		 * @return Boolean.
		 * @see dragonBones.animation.AnimationData.
		 */
		public function hasAnimation(animationName:String):Boolean
		{
			var i:int = _animationDataList.length;
			while(i --)
			{
				if(_animationDataList[i].name == animationName)
				{
					return true;
				}
			}
			
			return false;
		}
		
		/** @private */
		dragonBones_internal function advanceTime(passedTime:Number):void
		{
			if(!_isPlaying)
			{
				return;
			}
			
			_isFading = false;
			
			passedTime *= _timeScale;
			var i:int = _animationStateList.length;
			while(i --)
			{
				var animationState:AnimationState = _animationStateList[i];
				if(animationState.advanceTime(passedTime))
				{
					removeState(animationState);
				}
				else if(animationState.fadeState != 0)
				{
					_isFading = true;
				}
			}
			_animationStateCount = _animationStateList.length;
			
			var boneList:Vector.<Bone> = _armature.getBones(false);
			var boneIndex:int = boneList.length;
			
			while(boneIndex --)
			{
				var bone:Bone = boneList[boneIndex];
				if(_isFading)
				{
					bone.invalidUpdate();
				}
				else if(bone._needUpdate <= 0)
				{
					continue;
				}
				
				if(_animationStateCount > 1 || _isFading)
				{
					blendingTimeline(bone);
				}
				else if(_lastAnimationState)
				{
					var timelineState:TimelineState = _lastAnimationState._timelineStates[bone.name];
					if(timelineState && timelineState._blendEnabled)
					{
						bone._tween.copy(timelineState._transform);
						bone._tweenPivot.copyFrom(timelineState._pivot);
					}
				}
			}
		}
		
		private function blendingTimeline(bone:Bone):void
		{
			var boneName:String = bone.name;
			
			var transform:DBTransform;
			var pivot:Point;
			
			var x:Number = 0;
			var y:Number = 0;
			var skewX:Number = 0;
			var skewY:Number = 0;
			var scaleX:Number = 0;
			var scaleY:Number = 0;
			var pivotX:Number = 0;
			var pivotY:Number = 0;
			
			var i:int = _animationStateList.length;
			while(i --)
			{
				var weigthLeft:Number = 1;
				var layerTotalWeight:Number = 0;
				var animationState:AnimationState = _animationStateList[i];
				var weight:Number = animationState._fadeWeight * animationState.weight * weigthLeft;
				if(weight)
				{
					var timelineState:TimelineState = animationState._timelineStates[boneName];
					if(timelineState && timelineState._blendEnabled)
					{
						transform = timelineState._transform;
						pivot = timelineState._pivot;
						
						x += transform.x * weight;
						y += transform.y * weight;
						skewX += transform.skewX * weight;
						skewY += transform.skewY * weight;
						scaleX += transform.scaleX * weight;
						scaleY += transform.scaleY * weight;
						pivotX += pivot.x * weight;
						pivotY += pivot.y * weight;
						
						layerTotalWeight += weight;
					}
				}
				
				if(layerTotalWeight >= weigthLeft)
				{
					break;
				}
				else
				{
					weigthLeft -= layerTotalWeight;
				}
			}
			
			transform = bone._tween;
			pivot = bone._tweenPivot;
			
			transform.x = x;
			transform.y = y;
			transform.skewX = skewX;
			transform.skewY = skewY;
			transform.scaleX = scaleX;
			transform.scaleY = scaleY;
			pivot.x = pivotX;
			pivot.y = pivotY;
		}
		
		private function addState(animationState:AnimationState):void
		{
			if(_animationStateList.indexOf(animationState) < 0)
			{
				_animationStateList.push(animationState);
				_animationStateList.sort(sortState);
			}
		}
		
		private function removeState(animationState:AnimationState):void
		{
			var index:int = _animationStateList.indexOf(animationState);
			if(index >= 0)
			{
				_animationStateList.splice(index, 1);
				AnimationState.returnObject(animationState);
			}
		}
		
		private function sortState(state1:AnimationState, state2:AnimationState):int
		{
			return state1.layer > state2.layer?1:-1;
		}
	}
}
