package dragonBones.animation {
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.events.Event;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.Node;
	import dragonBones.utils.skeletonNamespace;
	
	use namespace skeletonNamespace;
	
	/**
	 * 
	 * @author Akdcl
	 */
	final public class Tween extends ProcessBase {
		private static const HALF_PI:Number = Math.PI * 0.5;
		
		private static var soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		private var bone:Bone;
		
		skeletonNamespace var node:Node;
		private var from:Node;
		private var between:Node;
		
		private var movementBoneData:MovementBoneData;
		
		private var currentKeyFrame:FrameData;
		private var nextKeyFrame:FrameData;
		private var isTweenKeyFrame:Boolean;
		private var betweenDuration:int;
		private var totalDuration:int;
		private var frameTweenEasing:Number;
		
		public function Tween(_bone:Bone) {
			super();
			bone = _bone;
			node = new Node();
			from = new Node();
			between = new Node();
		}
		
		override public function dispose():void{
			super.dispose();
			bone = null;
			node = null;
			from = null;
			between = null;
			
			movementBoneData = null;
			currentKeyFrame = null;
			nextKeyFrame = null;
		}
		
		override public function gotoAndPlay(_movementBoneData:Object, _durationTo:int = 0, _durationTween:int = 0, _loop:* = false, _tweenEasing:Number = NaN):void {
			movementBoneData = _movementBoneData as MovementBoneData;
			if(!movementBoneData){
				return;
			}
			currentKeyFrame = null;
			nextKeyFrame = null;
			isTweenKeyFrame = false;
			super.gotoAndPlay(null, _durationTo, _durationTween, _loop, _tweenEasing);
			//
			totalDuration = 0;
			betweenDuration = 0;
			toIndex = 0;
			node.skewY %= 360;
			var _frameData:FrameData;
			if (movementBoneData.length == 1) {
				loop = SINGLE;
				nextKeyFrame = movementBoneData.getData(0);
				setBetween(node, nextKeyFrame);
				isTweenKeyFrame = true;
				frameTweenEasing = 1;
			}else if (movementBoneData.length > 1) {
				if (_loop) {
					loop = LIST_LOOP_START;
					duration = movementBoneData.duration;
				}else {
					loop = LIST_START;
					duration = movementBoneData.duration - 1;
				}
				durationTween = _durationTween * movementBoneData.scale;
				if (_loop && movementBoneData.delay != 0) {
					setBetween(node, tweenNodeTo(updateFrameData(1 -movementBoneData.delay), between));
				}else {
					nextKeyFrame = movementBoneData.getData(0);
					setBetween(node, nextKeyFrame);
					isTweenKeyFrame = true;
				}
			}
		}
		
		override public function play():void {
			if (!movementBoneData) {
				return;
			}
			
			if(__isPause){
				super.play();
			}else if(__isComplete){
				gotoAndPlay(movementBoneData);
			}
		}
		
		override protected function updateHandler():void {
			if (currentPrecent >= 1) {
				switch(loop) {
					case SINGLE:
						currentKeyFrame = nextKeyFrame;
						currentPrecent = 1;
						__isComplete = true;
						break;
					case LIST_START:
						loop = LIST;
						if (durationTween <= 0) {
							currentPrecent = 1;
						}else {
							currentPrecent = (currentPrecent - 1) * totalFrames / durationTween;
						}
						if (currentPrecent >= 1) {
							//播放速度太快或durationTween时间太短
							currentPrecent = 1;
							__isComplete = true;
							break;
						}else {
							totalFrames = durationTween;
							totalDuration = 0;
							break;
						}
					case LIST:
						currentPrecent = 1;
						__isComplete = true;
						break;
					case LIST_LOOP_START:
						loop = 0;
						totalFrames = durationTween > 0?durationTween:1;
						if (movementBoneData.delay != 0) {
							//
							currentFrame = (1 - movementBoneData.delay) * totalFrames;
							currentPrecent += currentFrame / totalFrames;
						}
						currentPrecent %= 1;
						break;
					default:
						//循环
						loop += int(currentPrecent);
						currentPrecent %= 1;
						
						totalDuration = 0;
						betweenDuration = 0;
						toIndex = 0;
						break;
				}
			}else if (loop < -1) {
				currentPrecent = Math.sin(currentPrecent * HALF_PI);
			}
			if (loop >= LIST) {
				//多关键帧动画过程
				currentPrecent = updateFrameData(currentPrecent, true);
			}
			if (!isNaN(frameTweenEasing)) {
				tweenNodeTo(currentPrecent);
			}else if(currentKeyFrame) {
				tweenNodeTo(0);
			}
			if(currentKeyFrame){
				//arrived
				var _displayIndex:int = currentKeyFrame.displayIndex;
				var _childAramture:Armature = bone.childArmature;
				if(_displayIndex >= 0){
					if(bone.origin.z != currentKeyFrame.z){
						bone.origin.z = currentKeyFrame.z;
						if(bone.armature){
							bone.armature.bonesIndexChanged = true;
						}
					}
				}
				bone.changeDisplay(_displayIndex);
				if(_childAramture){
					_childAramture.origin.z = currentKeyFrame.z;
					if(currentKeyFrame.movement){
						_childAramture.animation.gotoAndPlay(currentKeyFrame.movement);
					}
				}
				
				if(currentKeyFrame.event){
					bone.dispatchEventWith(Event.BONE_EVENT_FRAME, currentKeyFrame.event);
				}
				if(currentKeyFrame.sound){
					soundManager.dispatchEventWith(Event.SOUND_FRAME, currentKeyFrame.sound);
				}
				currentKeyFrame = null;
			}
			if(isTweenKeyFrame){
				//to
				/*if(nextKeyFrame.displayIndex < 0){
					//bone.changeDisplay(nextKeyFrame.displayIndex);
					if(bone.armature){
						//bone.armature.bonesIndexChanged = true;
					}
				}*/
				isTweenKeyFrame = false;
			}
		}
		
		private function setBetween(_from:Node, _to:Node):void {
			from.copy(_from);
			if(_to is FrameData){
				if((_to as FrameData).displayIndex < 0){
					between.subtract(_from, _from);
					return;
				}
			}
			between.subtract(_from, _to);
		}
		
		private function tweenNodeTo(_value:Number, _node:Node = null):Node {
			_node = _node || node;
			_node.x = from.x + _value * between.x;
			_node.y = from.y + _value * between.y;
			_node.scaleX = from.scaleX + _value * between.scaleX;
			_node.scaleY = from.scaleY + _value * between.scaleY;
			_node.skewX = from.skewX + _value * between.skewX;
			_node.skewY = from.skewY + _value * between.skewY;
			return _node;
		}
		
		private function updateFrameData(_currentPrecent:Number, _activeFrame:Boolean = false):Number {
			var _played:Number = duration * _currentPrecent;
			var _fromIndex:int;
			var _from:FrameData;
			var _to:FrameData;
			var _isListEnd:Boolean;
			//播放头到达当前帧的前面或后面则重新寻找当前帧
			if (_played >= totalDuration || _played < totalDuration - betweenDuration) {
				var _length:int = movementBoneData.length;
				do {
					betweenDuration = movementBoneData.getData(toIndex).duration;
					totalDuration += betweenDuration;
					_fromIndex = toIndex;
					if (++toIndex >= _length) {
						toIndex = 0;
					}
				}while (_played >= totalDuration);
				_isListEnd = loop == LIST && toIndex == 0;
				if(_isListEnd){
					_to = _from = movementBoneData.getData(_fromIndex);
				}else{
					_from = movementBoneData.getData(_fromIndex);
					_to = movementBoneData.getData(toIndex);
				}
				frameTweenEasing = _from.tweenEasing;
				if (_activeFrame) {
					currentKeyFrame = nextKeyFrame;
					if(!_isListEnd){
						nextKeyFrame = _to;
						isTweenKeyFrame = true;
					}
				}
				setBetween(_from, _to);
			}
			_currentPrecent = 1 - (totalDuration - _played) / betweenDuration;
			
			//frameTweenEasing为NaN则不会补间，-1~0~1~2、淡出、线性、淡入、淡入淡出
			var _tweenEasing:Number;
			if (!isNaN(frameTweenEasing)) {
				_tweenEasing = isNaN(tweenEasing)?frameTweenEasing:tweenEasing;
				if (_tweenEasing) {
					_currentPrecent = getEaseValue(_currentPrecent, _tweenEasing);
				}
			}
			return _currentPrecent;
		}
		
		private static function getEaseValue(_value:Number, _easing:Number):Number {
			if (_easing > 1) {
				_value = 0.5 * (1 - Math.cos(_value * Math.PI ));
				_easing -= 1;
			}else if (_easing > 0) {
				_value = Math.sin(_value * HALF_PI);
			}else {
				_value = 1 - Math.cos(_value * HALF_PI);
				_easing = -_easing;
			}
			return _value * _easing + (1 - _easing);
		}
	}
}