package dragonBones.objects {
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class MovementData extends BaseDicData {
		public var duration:int;
		public var durationTo:int;
		public var durationTween:int;
		public var loop:Boolean;
		public var tweenEasing:Number;
		public var frameLength:uint;
		
		private var frameList:Array;
		
		public function MovementData(_name:String = null) {
			super(_name);
			frameList = [];
		}
		
		public function setValues(_duration:int = 1, _durationTo:int = 0, _durationTween:int = 0, _loop:Boolean = false, _tweenEasing:Number = NaN):void{
			duration = _duration > 0?_duration:1;
			durationTo = _durationTo >= 0?_durationTo:0;
			durationTween = _durationTween >= 0?_durationTween:0;
			loop = _loop;
			//为NaN则不启用
			tweenEasing = _tweenEasing;
		}
		
		public function getData(_name:String):MovementBoneData {
			return datas[_name];
		}
		
		public function addFrameData(_frameData:MovementFrameData, _index:int, _replaceIfExists:Boolean = false):Boolean{
			var _exData:MovementFrameData = frameList[_index];
			if (_exData) {
				if(_replaceIfExists){
					_exData.dispose();
				}else{
					return false;
				}
			}
			frameList[_index] = _frameData;
			frameLength = frameList.length;
			return true;
		}
		
		public function getFrame(_index:int):MovementFrameData {
			return frameList[_index];
		}
	}
	
}