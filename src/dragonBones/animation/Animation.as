package dragonBones.animation
{
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.events.Event;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.MovementFrameData;
	import dragonBones.utils.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	/**
	 *
	 * @author Akdcl
	 */
	final public class Animation extends ProcessBase 
	{
		private static var _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		public var movementID:String;
		public var movementList:Vector.<String>;
		
		private var _animationData:AnimationData;
		private var _movementData:MovementData;
		private var _currentFrameData:MovementFrameData;
		
		private var _armature:Armature;
		
		override public function set timeScale(value:Number):void 
		{
			super.timeScale = value;
			for each(var bone:Bone in _armature._boneDepthList)
			{
				bone._tween.timeScale = value;
			}
		}
		
		public function Animation(armature:Armature) 
		{
			_armature = armature;
		}
		
		override public function dispose():void
		{
			super.dispose();
			movementList = null;
			_animationData = null;
			_movementData = null;
			_currentFrameData  = null;
			_armature = null;
		}
		
		public function setData(animationData:AnimationData):void 
		{
			if (animationData)
			{
				stop();
				_animationData = animationData;
				
				movementList = _animationData.movementList;
			}
		}
		
		override public function gotoAndPlay(movementID:Object, durationTo:int = -1, durationTween:int = -1, loop:* = null, tweenEasing:Number = NaN):void
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
			_currentFrameData = null;
			_toIndex = 0;
			_movementData = movementData;
			this.movementID = movementID as String;
			
			durationTo = durationTo < 0?_movementData.durationTo:durationTo;
			durationTween = durationTween < 0?_movementData.durationTween:durationTween;
			loop = loop === null?_movementData.loop:loop;
			tweenEasing = isNaN(tweenEasing)?_movementData.tweenEasing:tweenEasing;
			
			super.gotoAndPlay(null, durationTo, durationTween);
			
			_duration = _movementData.duration;
			if (_duration == 1) 
			{
				_loop = SINGLE;
			}
			else
			{
				if (loop) 
				{
					_loop = LIST_LOOP_START
				}
				else
				{
					_loop = LIST_START
					_duration --;
				}
				_durationTween = durationTween;
			}
			
			for each(var bone:Bone in _armature._boneDepthList)
			{
				var movementBoneData:MovementBoneData = _movementData.getMovementBoneData(bone.name);
				if (movementBoneData)
				{
					bone._tween.gotoAndPlay(movementBoneData, durationTo, durationTween, loop, tweenEasing);
					if(bone.childArmature)
					{
						bone.childArmature.animation.gotoAndPlay(movementID);
					}
				}
				else
				{
					bone.changeDisplay(-1);
					bone._tween.stop();
				}
			}
			
			_armature.dispatchEventWith(Event.MOVEMENT_CHANGE, movementID);
		}
		
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
		
		override public function stop():void 
		{
			super.stop();
			for each(var bone:Bone in _armature._boneDepthList)
			{
				bone._tween.stop();
			}
		}
		
		override protected function updateHandler():void 
		{
			if (_currentPrecent >= 1) 
			{
				switch(_loop) 
				{
					case LIST_START:
						_loop = LIST;
						_currentPrecent = (_currentPrecent - 1) * _totalFrames / _durationTween;
						if (_currentPrecent >= 1) 
						{
							//the speed of playing is too fast or the durationTween is too short
						}
						else
						{
							_totalFrames = _durationTween;
							_armature.dispatchEventWith(Event.START, movementID);
							break;
						}
					case LIST:
					case SINGLE:
						_currentPrecent = 1;
						_isComplete = true;
						_armature.dispatchEventWith(Event.COMPLETE, movementID);
						break;
					case LIST_LOOP_START:
						_loop = 0;
						_totalFrames = _durationTween > 0?_durationTween:1;
						_currentPrecent %= 1;
						_armature.dispatchEventWith(Event.START, movementID);
						break;
					default:
						//change the loop
						_loop += int(_currentPrecent);
						_currentPrecent %= 1;
						_toIndex = 0;
						_armature.dispatchEventWith(Event.LOOP_COMPLETE, movementID);
						break;
				}
			}
			if (_loop >= LIST)
			{
				updateFrameData(_currentPrecent);
			}
		}
		
		private function updateFrameData(currentPrecent:Number):void 
		{
			var length:uint = _movementData._movementFrameList.length;
			if(length == 0)
			{
				return;
			}
			var played:Number = _duration * currentPrecent;
			//refind the current frame
			if (!_currentFrameData || played >= _currentFrameData.duration + _currentFrameData.start || played < _currentFrameData.start) 
			{
				while (true) 
				{
					_currentFrameData =  _movementData._movementFrameList[_toIndex];
					if (++_toIndex >= length) 
					{
						_toIndex = 0;
					}
					if(_currentFrameData && played >= _currentFrameData.start && played < _currentFrameData.duration + _currentFrameData.start)
					{
						break;
					}
				}
				if(_currentFrameData.event)
				{
					_armature.dispatchEventWith(Event.MOVEMENT_EVENT_FRAME, _currentFrameData.event);
				}
				if(_currentFrameData.sound)
				{
					_soundManager.dispatchEventWith(Event.SOUND_FRAME, _currentFrameData.sound);
				}
				if(_currentFrameData.movement)
				{
					gotoAndPlay(_currentFrameData.movement);
				}
			}
		}
	}
	
}