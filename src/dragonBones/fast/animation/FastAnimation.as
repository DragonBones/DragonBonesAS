package dragonBones.fast.animation
{
	import dragonBones.cache.AnimationCacheManager;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.fast.FastArmature;
	import dragonBones.fast.FastSlot;
	import dragonBones.objects.AnimationData;

	use namespace dragonBones_internal;
	
	/**
	 * 不支持动画融合，不支持自动补间，不支持时间缩放和offset
	 */
	public class FastAnimation
	{
		public var animationList:Vector.<String>;
		public var animationState:FastAnimationState = new FastAnimationState();
		public var animationCacheManager:AnimationCacheManager;
		
		private var _armature:FastArmature;
		private var _animationDataList:Vector.<AnimationData>;
		private var _animationDataObj:Object;
		private var _isPlaying:Boolean;
		
		public function FastAnimation(armature:FastArmature)
		{
			_armature = armature;
			animationState._armature = armature;
			animationList = new Vector.<String>;
			_animationDataObj = {};

			_isPlaying = false;
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
			
			_armature = null;
			_animationDataList = null;
			animationList = null;
			animationState = null;
		}
		
		public function gotoAndPlay( animationName:String, fadeInTime:Number = -1, duration:Number = -1, playTimes:Number = NaN):FastAnimationState
		{
			if (!_animationDataList)
			{
				return null;
			}
			var animationData:AnimationData = _animationDataObj[animationName];
			if (!animationData)
			{
				return null;
			}
			_isPlaying = true;
			fadeInTime = fadeInTime < 0?(animationData.fadeTime < 0?0.3:animationData.fadeTime):fadeInTime;
			var durationScale:Number;
			if(duration < 0)
			{
				durationScale = animationData.scale < 0?1:animationData.scale;
			}
			else
			{
				durationScale = duration * 1000 / animationData.duration;
			}
			playTimes = isNaN(playTimes)?animationData.playTimes:playTimes;
			
			//播放新动画
			
			animationState.fadeIn(animationData, playTimes, 1 / durationScale, fadeInTime);
			
			if(_armature.enableCache && animationCacheManager)
			{
				animationState.animationCache = animationCacheManager.getAnimationCache(animationName);
			}
			
			var i:int = _armature.slotHasChildArmatureList.length;
			while(i--)
			{
				var slot:FastSlot = _armature.slotHasChildArmatureList[i];
				var childArmature:FastArmature = slot.childArmature;
				if(childArmature)
				{
					childArmature.animation.gotoAndPlay(animationName);
				}
			}
			return animationState;
		}
		
		/**
		 * Control the animation to stop with a specified time. If related animationState haven't been created, then create a new animationState.
		 * @param animationName The name of the animationState.
		 * @param time 
		 * @param normalizedTime 
		 * @param fadeInTime A fade time to apply (>= 0), -1 means use xml data's fadeInTime. 
		 * @param duration The duration of that Animation. -1 means use xml data's duration.
		 * @param layer The layer of the animation.
		 * @param group The group of the animation.
		 * @param fadeOutMode Fade out mode (none, sameLayer, sameGroup, sameLayerAndGroup, all).
		 * @return AnimationState.
		 * @see dragonBones.objects.AnimationData.
		 * @see dragonBones.animation.AnimationState.
		 */
		public function gotoAndStop(
			animationName:String, 
			time:Number, 
			normalizedTime:Number = -1,
			fadeInTime:Number = 0, 
			duration:Number = -1
		):FastAnimationState
		{
			if(!animationState.name != animationName)
			{
				gotoAndPlay(animationName, fadeInTime, duration);
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
			if(!_animationDataList)
			{
				return;
			}
			if(!animationState)
			{
				gotoAndPlay(_animationDataList[0].name);
			}
			else if (!_isPlaying)
			{
				_isPlaying = true;
			}
			else
			{
				gotoAndPlay(animationState.name);
			}
		}
		
		public function stop():void
		{
			_isPlaying = false;
		}
		
		/** @private */
		dragonBones_internal function advanceTime(passedTime:Number, loop:Boolean = false):void
		{
			if(!_isPlaying)
			{
				return;
			}
			
			animationState.advanceTime(passedTime, loop);
		}
		
		/**
		 * check if contains a AnimationData by name.
		 * @return Boolean.
		 * @see dragonBones.animation.AnimationData.
		 */
		public function hasAnimation(animationName:String):Boolean
		{
			return _animationDataObj[animationName] != null;
		}
		
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
			animationList.length = 0;
			for each(var animationData:AnimationData in _animationDataList)
			{
				animationList.push(animationData.name);
				_animationDataObj[animationData.name] = animationData;
			}
		}
		
		/**
		 * Is the animation playing.
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
			return animationState.isComplete;
		}
		
		/**
		 * The last AnimationState this Animation played.
		 * @see dragonBones.objects.AnimationData.
		 */
		public function get lastAnimationState():FastAnimationState
		{
			return animationState;
		}
		/**
		 * The name of the last AnimationData played.
		 * @see dragonBones.objects.AnimationData.
		 */
		public function get lastAnimationName():String
		{
			return animationState?animationState.name:null;
		}
	}
}