package dragonBones.animation
{
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.events.AnimationEvent;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.MovementFrameData;
	import dragonBones.utils.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	/**
	 * A core object that can control the state of an armature
	 * @see dragonBones.Armature
	 */
	final public class Animation extends ProcessBase
	{
		private static var _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		/**
		 * The playing movement ID.
		 */
		public var movementID:String;
		
		/**
		 * An vector containing all movements the animation can play.
		 */
		public var movementList:Vector.<String>;
		
		private var _animationData:AnimationData;
		private var _movementData:MovementData;
		
		private var _armature:Armature;
		
		/**
		 * @inheritDoc
		 */
		override public function set timeScale(value:Number):void
		{
			super.timeScale = value;
			for each(var bone:Bone in _armature._boneDepthList)
			{
				bone._tween.timeScale = value;
			}
		}
		
		/**
		 * Creates a new <code>Animation</code>
		 * @param	armature
		 */
		public function Animation(armature:Armature)
		{
			_armature = armature;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			movementList = null;
			_animationData = null;
			_movementData = null;
			_armature = null;
		}
		/** @private */
		public function setData(animationData:AnimationData):void
		{
			if (animationData)
			{
				stop();
				_animationData = animationData;
				movementList = _animationData.movementList;
			}
		}
		
		public function gotoAndPlay(movementID:String, tweenTime:Number = -1, duration:Number = -1, loop:* = null, tweenEasing:Number = NaN):void
		{
			if (!_animationData)
			{
				return;
			}
			var movementData:MovementData = _animationData.getMovementData(movementID as String);
			if (!movementData)
			{
				return;
			}
			_movementData = movementData;
			
			_isComplete = false;
			_isPause = false;
			_currentTime = 0;
			
			_nextFrameDataTimeEdge = 0;
			_nextFrameDataID = 0;
			
			var exMovementID:String = this.movementID;
			this.movementID = movementID as String;
			
			_totalTime = tweenTime > 0?tweenTime:_movementData.durationTo;
			if(_totalTime < 0)
			{
				_totalTime = 0;
			}
			
			_duration = duration > 0?duration:_movementData.durationTween;
			if(_duration < 0)
			{
				_duration = 0;
			}
			loop = Boolean(loop === null?_movementData.loop:loop);
			tweenEasing = isNaN(tweenEasing)?_movementData.tweenEasing:tweenEasing;
			
			
			_rawDuration = _movementData.duration;
			
			if (_rawDuration == 0)
			{
				_loop = SINGLE;
			}
			else
			{
				if (loop)
				{
					_loop = LIST_LOOP_START;
				}
				else
				{
					_loop = LIST_START;
				}
			}
			
			for each(var bone:Bone in _armature._boneDepthList)
			{
				var movementBoneData:MovementBoneData = _movementData.getMovementBoneData(bone.name);
				if (movementBoneData)
				{
					bone._tween.gotoAndPlay(movementBoneData, _totalTime, _duration, loop, tweenEasing);
					if(bone.childArmature)
					{
						bone.childArmature.animation.gotoAndPlay(movementID);
					}
				}
				else if(bone.origin.name)
				{
					bone.changeDisplay(-1);
					bone._tween.stop();
				}
			}
			
			if(_armature.hasEventListener(AnimationEvent.MOVEMENT_CHANGE))
			{
				var event:AnimationEvent = new AnimationEvent(AnimationEvent.MOVEMENT_CHANGE);
				event.exMovementID = exMovementID;
				event.movementID = this.movementID;
				_armature.dispatchEvent(event);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function play():void
		{
			if (!_animationData)
			{
				return;
			}
			
			if(!movementID)
			{
				gotoAndPlay(movementList[0]);
				return;
			}
			
			if(_isPause)
			{
				super.play();
				for each(var bone:Bone in _armature._boneDepthList)
				{
					bone._tween.play();
				}
			}
			else if(_isComplete)
			{
				gotoAndPlay(movementID);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function stop():void
		{
			super.stop();
			for each(var bone:Bone in _armature._boneDepthList)
			{
				bone._tween.stop();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateHandler():void
		{
			var event:AnimationEvent;
			if (_progress >= 1)
			{
				switch(_loop)
				{
					case LIST_START:
						_loop = LIST;
						_progress = 0;
						_totalTime = _duration;
						_nextFrameDataTimeEdge = 0;
						
						if(_armature.hasEventListener(AnimationEvent.START))
						{
							event = new AnimationEvent(AnimationEvent.START);
							event.movementID = movementID;
							_armature.dispatchEvent(event);
						}
						break;
					case LIST:
					case SINGLE:
						_progress = 1;
						_isComplete = true;
						if(_armature.hasEventListener(AnimationEvent.COMPLETE))
						{
							event = new AnimationEvent(AnimationEvent.COMPLETE);
							event.movementID = movementID;
							_armature.dispatchEvent(event);
						}
						break;
					case LIST_LOOP_START:
						_loop = 0;
						_totalTime = _duration;
						_progress %= 1;
						if(_armature.hasEventListener(AnimationEvent.START))
						{
							event = new AnimationEvent(AnimationEvent.START);
							event.movementID = movementID;
							_armature.dispatchEvent(event);
						}
						break;
					default:
						//change the loop
						_loop += int(_progress);
						_progress %= 1;
						_nextFrameDataTimeEdge = 0;
						_nextFrameDataID = 0;
						if(_armature.hasEventListener(AnimationEvent.LOOP_COMPLETE))
						{
							event = new AnimationEvent(AnimationEvent.LOOP_COMPLETE);
							event.movementID = movementID;
							_armature.dispatchEvent(event);
						}
						break;
				}
			}
			if (_loop >= LIST && _movementData.totalFrames > 0)
			{
				updateFrameData(_progress);
			}
		}
		
		private function updateFrameData(progress:Number):void
		{
			var playedTime:Number = _rawDuration * progress;
			//refind the current frame
			if (playedTime >= _nextFrameDataTimeEdge)
			{
				var length:uint = _movementData.totalFrames;
				do {
					var currentFrameDataID:int = _nextFrameDataID;
					var currentFrameData:MovementFrameData = _movementData.getMovementFrameDataAt(currentFrameDataID);
					var frameDuration:Number = currentFrameData.duration;
					_nextFrameDataTimeEdge += frameDuration;
					if (++ _nextFrameDataID >= length)
					{
						_nextFrameDataID = 0;
					}
				}while (playedTime >= _nextFrameDataTimeEdge);
				if(currentFrameData.event && _armature.hasEventListener(FrameEvent.MOVEMENT_FRAME_EVENT))
				{
					var frameEvent:FrameEvent = new FrameEvent(FrameEvent.MOVEMENT_FRAME_EVENT);
					frameEvent.movementID = movementID;
					frameEvent.frameLabel = currentFrameData.event;
					_armature.dispatchEvent(frameEvent);
				}
				if(currentFrameData.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
				{
					var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
					soundEvent.movementID = movementID;
					soundEvent.sound = currentFrameData.sound;
					soundEvent._armature = _armature;
					_soundManager.dispatchEvent(soundEvent);
				}
				if(currentFrameData.movement)
				{
					gotoAndPlay(currentFrameData.movement);
				}
			}
		}
	}
	
}