package dragonBones.animation {
	
	/**
	 * 
	 * @author Akdcl
	 */
	internal class ProcessBase {
		protected static const SINGLE:int = -4;
		protected static const LIST_START:int = -3;
		protected static const LIST_LOOP_START:int = -2;
		protected static const LIST:int = -1;
		
		protected var currentFrame:Number;
		protected var totalFrames:int;
		protected var currentPrecent:Number;
		
		protected var durationTween:int;
		protected var duration:int;
		
		protected var loop:int;
		protected var tweenEasing:int;
		
		protected var toIndex:int;

		public function get isPlaying():Boolean{
			return !__isComplete && !__isPause;
		}
		
		protected var __isComplete:Boolean;
		public function get isComplete():Boolean{
			return __isComplete;
		}
		
		protected var __isPause:Boolean;
		public function get isPause():Boolean{
			return __isPause;
		}
		
		protected var __scale:Number;
		public function get scale():Number {
			return __scale;
		}
		public function set scale(_scale:Number):void {
			__scale = _scale;
		}
		
		public function ProcessBase() {
			__scale = 1;
			__isComplete = true;
			__isPause = false;
			currentFrame = 0;
		}
		
		public function dispose():void{
			
		}
		
		public function gotoAndPlay(_animation:Object, _durationTo:int = 0, _durationTween:int = 0, _loop:* = false, _tweenEasing:Number = NaN):void {
			__isComplete = false;
			__isPause = false;
			currentFrame = 0;
			totalFrames = _durationTo;
			tweenEasing = _tweenEasing;
		}
		
		public function play():void {
			if(__isComplete){
				__isComplete = false;
				currentFrame = 0;
			}
			__isPause = false;
		}
		
		public function stop():void {
			__isPause = true;
		}
		
		final public function update():void {
			if (isComplete || isPause) {
				return;
			}
			if (totalFrames <= 0) {
				currentFrame = totalFrames = 1;
			}
			currentFrame += __scale;
			currentPrecent = currentFrame / totalFrames;
			currentFrame %= totalFrames;
			updateHandler();
		}
		
		protected function updateHandler():void {
			
		}
	}
	
}