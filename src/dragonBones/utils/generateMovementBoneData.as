package dragonBones.utils {
	import dragonBones.objects.BoneData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.FrameData;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	public function generateMovementBoneData(_boneName:String, _boneXML:XML, _parentXML:XML, _boneData:BoneData, _movementBoneData:MovementBoneData = null):MovementBoneData {
		if(!_movementBoneData){
			_movementBoneData = new MovementBoneData(_boneName);
		}
		_movementBoneData.setValues(
			Number(_boneXML.attribute(ConstValues.A_MOVEMENT_SCALE)),
			Number(_boneXML.attribute(ConstValues.A_MOVEMENT_DELAY))
		);
		
		if(_parentXML){
			var _xmlList:XMLList = _parentXML.elements(ConstValues.FRAME);
			var _parentFrameXML:XML;
			var _length:uint = _xmlList.length();
			var _i:uint = 0;
			var _parentTotalDuration:uint = 0;
			var _currentDuration:uint = 0;
		}
		
		var _totalDuration:uint = 0;
		for each(var _frameXML:XML in _boneXML.elements(ConstValues.FRAME)) {
			if(_parentXML){
				while(_i < _length && (_parentFrameXML?(_totalDuration < _parentTotalDuration || _totalDuration >= _parentTotalDuration + _currentDuration):true)){
					_parentFrameXML = _xmlList[_i];
					_parentTotalDuration += _currentDuration;
					_currentDuration = int(_parentFrameXML.attribute(ConstValues.A_DURATION));
					_i++;
				}
			}
			var _index:int = _frameXML.childIndex();
			var _frameData:FrameData = generateFrameData(_frameXML, _parentFrameXML, _boneData, _movementBoneData.getData(_index));
			_movementBoneData.addData(_frameData, String(_index));
			_totalDuration += _frameData.duration;
		}
		
		return _movementBoneData;
	}
	
}