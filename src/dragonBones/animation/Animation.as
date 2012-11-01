package dragonBones.animation{
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.events.Event;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.MovementFrameData;
	import dragonBones.utils.skeletonNamespace;
	
	use namespace skeletonNamespace;
	
	/**
	 * 
	 * @author Akdcl
	 */
	final public class Animation extends ProcessBase {
		private static var soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		public var movementID:String;
		public var movementList:Array;
		
		private var animationData:AnimationData;
		private var movementData:MovementData;
		private var currentFrameData:MovementFrameData;
		
		private var armature:Armature;
		
		override public function set scale(_scale:Number):void {
			super.scale = _scale;
			armature.eachChild(setBoneScale, [_scale], true);
		}
		private function setBoneScale(_bone:Bone, _args:Array):Boolean {
			var _scale:Number = _args[0];
			_bone.tween.scale = _scale;
			if(_bone is Armature){
				(_bone as Armature).animation.scale = _scale;
			}
			return false;
		}
		
		public function Animation(_armature:Armature) {
			armature = _armature;
		}
		
		override public function dispose():void{
			super.dispose();
			movementID = null;
			movementList = null;
			animationData = null;
			movementData = null;
			currentFrameData  = null;
			armature = null;
		}
		
		public function setData(_animationData:AnimationData):void {
			if (!_animationData) {
				return;
			}
			stop();
			animationData = _animationData;
			movementList = animationData.getSearchList();
		}
		
		private var tempArgs:Array = [];
		override public function gotoAndPlay(_movementID:Object, _durationTo:int = -1, _durationTween:int = -1, _loop:* = null, _tweenEasing:Number = NaN):void {
			if (!animationData) {
				return;
			}
			var _movementData:MovementData = animationData.getData(_movementID as String);
			if (!_movementData) {
				return;
			}
			currentFrameData = null;
			toIndex = 0;
			movementID = _movementID as String;
			movementData = _movementData;
			_durationTo = _durationTo < 0?movementData.durationTo:_durationTo;
			_durationTween = _durationTween < 0?movementData.durationTween:_durationTween;
			_loop = _loop === null?movementData.loop:_loop;
			_tweenEasing = isNaN(_tweenEasing)?movementData.tweenEasing:_tweenEasing;
			
			super.gotoAndPlay(null, _durationTo, _durationTween);
			duration = movementData.duration;
			if (duration == 1) {
				loop = SINGLE;
			}else {
				if (_loop) {
					loop = LIST_LOOP_START
				}else {
					loop = LIST_START
					duration --;
				}
				durationTween = _durationTween;
			}
			tempArgs[0] = movementID;
			tempArgs[1] = _durationTo;
			tempArgs[2] = _durationTween;
			tempArgs[3] = _loop;
			tempArgs[4] = _tweenEasing;
			armature.eachChild(gotoAndPlayBone, tempArgs, true);
			armature.dispatchEventWith(Event.MOVEMENT_CHANGE, movementID);
		}
		private function gotoAndPlayBone(_bone:Bone, _args:Array):Boolean{
			var _movementBoneData:MovementBoneData = movementData.getData(_bone.name);
			if (_movementBoneData) {
				_bone.tween.gotoAndPlay(_movementBoneData, _args[1], _args[2], _args[3], _args[4]);
			}else {
				_bone.changeDisplay(-1);
				_bone.tween.stop();
			}
			if(_bone is Armature){
				(_bone as Armature).animation.gotoAndPlay(_args[0]);
			}
			return false;
		}
		
		override public function play():void {
			if (!animationData) {
				return;
			}
			
			if(!movementID){
				gotoAndPlay(movementList[0]);
				return;
			}
			
			if(__isPause){
				super.play();
				armature.eachChild(playBone, null, true);
			}else if(__isComplete){
				gotoAndPlay(movementID);
			}
		}
		private function playBone(_bone:Bone, _args:Array):Boolean {
			_bone.tween.play();
			if(_bone is Armature){
				(_bone as Armature).animation.play();
			}
			return false;
		}
		
		override public function stop():void {
			super.stop();
			armature.eachChild(stopBone, null, true);
		}
		private function stopBone(_bone:Bone, _args:Array):Boolean {
			_bone.tween.stop();
			if(_bone is Armature){
				(_bone as Armature).animation.stop();
			}
			return false;
		}
		
		override protected function updateHandler():void {
			if (currentPrecent >= 1) {
				switch(loop) {
					case LIST_START:
						loop = LIST;
						currentPrecent = (currentPrecent - 1) * totalFrames / durationTween;
						if (currentPrecent >= 1) {
							//播放速度太快或durationTween时间太短，进入下面的case
						}else {
							totalFrames = durationTween;
							armature.dispatchEventWith(Event.START, movementID);
							break;
						}
					case LIST:
					case SINGLE:
						currentPrecent = 1;
						__isComplete = true;
						armature.dispatchEventWith(Event.COMPLETE, movementID);
						break;
					case LIST_LOOP_START:
						loop = 0;
						totalFrames = durationTween > 0?durationTween:1;
						currentPrecent %= 1;
						armature.dispatchEventWith(Event.START, movementID);
						break;
					default:
						//继续循环
						loop += int(currentPrecent);
						currentPrecent %= 1;
						toIndex = 0;
						armature.dispatchEventWith(Event.LOOP_COMPLETE, movementID);
						break;
				}
			}
			if (loop >= LIST) {
				updateFrameData(currentPrecent);
			}
		}
		
		private function updateFrameData(_currentPrecent:Number):void {
			var _length:uint = movementData.frameLength;
			if(_length == 0){
				return;
			}
			var _played:Number = duration * _currentPrecent;
			//播放头到达当前帧的前面或后面则重新寻找当前帧
			if (!currentFrameData || _played >= currentFrameData.duration + currentFrameData.start || _played < currentFrameData.start) {
				while (true) {
					currentFrameData =  movementData.getFrame(toIndex);
					if (++toIndex >= _length) {
						toIndex = 0;
					}
					if(currentFrameData && _played >= currentFrameData.start && _played < currentFrameData.duration + currentFrameData.start){
						break;
					}
				}
				if(currentFrameData.event){
					armature.dispatchEventWith(Event.MOVEMENT_EVENT_FRAME, currentFrameData.event);
				}
				if(currentFrameData.sound){
					soundManager.dispatchEventWith(Event.SOUND_FRAME, currentFrameData.sound);
				}
				if(currentFrameData.movement){
					gotoAndPlay(currentFrameData.movement);
				}
			}
		}
	}
	
}