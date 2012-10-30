package dragonBones.objects {
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class MovementBoneData extends BaseDicData {
		public var scale:Number;
		public var delay:Number;
		public var duration:int;
		public var length:int;
		
		public function MovementBoneData(_name:String = null) {
			super(_name);
			length = 0;
			duration = 0;
		}
		
		public function setValues(_scale:Number = 1, _delay:Number = 0):void{
			scale = _scale > 0?_scale:1;
			delay = (_delay || 0) % 1;
			if (delay > 0) {
				delay -= 1;
			}
		}
		
		override public function addData(_data:Object, _id:String = null, _replaceIfExists:Boolean = false):Boolean {
			var _frameData:FrameData = _data as FrameData;
			if (_frameData) {
				if(super.addData(_frameData, _id, _replaceIfExists)){
					length ++;
					duration += _frameData.duration;
					return true;
				}
			}
			return false;
		}
		
		public function getData(_index:int):FrameData {
			return datas[_index];
		}
	}
	
}