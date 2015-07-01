package dragonBones.animation
{
	import dragonBones.FastArmature;
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.AnimationData;

	use namespace dragonBones_internal;
	
	/**
	 * 不支持动画融合，不支持自动补间，不支持时间缩放和offset
	 */
	public class FastAnimation
	{
		private var _armature:FastArmature;
		private var _animationList:Vector.<String>;
//		private var _animationStateList:Vector.<AnimationState>;
		private var animationState:FastAnimationState
		private var _animationDataList:Vector.<AnimationData>;
		private var _animationDataObj:Object;
		private var _isPlaying:Boolean;
		
		public function FastAnimation(armature:FastArmature)
		{
			_armature = armature;

			_animationList = new Vector.<String>;
//			_animationStateList = new Vector.<AnimationState>;

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
			
			if(animationState)
			{
				FastAnimationState.returnObject(animationState);
			}
			
			_armature = null;
			_animationDataList = null;
			_animationList = null;
			animationState = null;
		}
		
		public function gotoAndPlay( animationName:String, fadeInTime:Number = -1, playTimes:Number = NaN):void
		{
			if (!_animationDataList)
			{
				return;
			}
			var animationData:AnimationData = _animationDataObj[animationName];
			if (!animationData)
			{
				return;
			}
			_isPlaying = true;
			playTimes = isNaN(playTimes)?animationData.playTimes:playTimes;
			
			//播放新动画
			var _lastAnimationState:FastAnimationState;
			_lastAnimationState = FastAnimationState.borrowObject();
			_lastAnimationState.fadeIn(_armature, animationData, playTimes);
			
			addState(_lastAnimationState);
			
			//控制子骨架播放同名动画
			var slotList:Vector.<Slot> = _armature.getSlots(false);
			i = slotList.length;
			while(i --)
			{
				var slot:Slot = slotList[i];
				if(slot.childArmature)
				{
					slot.childArmature.animation.gotoAndPlay(animationName);
				}
			}
		}
		
		/** @private */
		dragonBones_internal function advanceTime(passedTime:Number):void
		{
			if(!_isPlaying)
			{
				return;
			}
			
			animationState.advanceTime(passedTime);
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
			_animationList.length = 0;
			for each(var animationData:AnimationData in _animationDataList)
			{
				_animationList.push(animationData.name);
				_animationDataObj[animationData.name] = animationData;
			}
		}
	}
}