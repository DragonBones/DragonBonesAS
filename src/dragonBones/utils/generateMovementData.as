package dragonBones.utils {
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.MovementData;
	import dragonBones.objects.MovementFrameData;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	public function generateMovementData(_movementName:String, _movementXML:XML, _armatureData:ArmatureData, _movementData:MovementData = null):MovementData {
		if(!_movementData){
			_movementData = new MovementData(_movementName);
		}
		_movementData.setValues(
			int(_movementXML.attribute(ConstValues.A_DURATION)),
			int(_movementXML.attribute(ConstValues.A_DURATION_TO)),
			int(_movementXML.attribute(ConstValues.A_DURATION_TWEEN)),
			Boolean(int(_movementXML.attribute(ConstValues.A_LOOP)) == 1),
			Number(_movementXML.attribute(ConstValues.A_TWEEN_EASING)[0])
		);
		
		var _xmlList:XMLList = _movementXML.elements(ConstValues.BONE);
		for each(var _boneXML:XML in _xmlList) {
			var _boneName:String = _boneXML.attribute(ConstValues.A_NAME);
			var _boneData:BoneData = _armatureData.getData(_boneName);
			_movementData.addData(
				generateMovementBoneData(
					_boneName, 
					_boneXML, 
					_xmlList.(attribute(ConstValues.A_NAME) == _boneData.parent)[0], 
					_boneData,
					_movementData.getData(_boneName)
				),
				_boneName
			);
		}
		_xmlList = _movementXML.elements(ConstValues.FRAME);
		for each(var _frameXML:XML in _xmlList) {
			var _frameData:MovementFrameData = _movementData.getFrame(_frameXML.childIndex());
			if(!_frameData){
				_frameData = new MovementFrameData();
			}
			
			_frameData.start = int(_frameXML.attribute(ConstValues.A_START));
			_frameData.duration = int(_frameXML.attribute(ConstValues.A_DURATION));
			_frameData.event = _frameXML.attribute(ConstValues.A_EVENT);
			_frameData.movement = _frameXML.attribute(ConstValues.A_MOVEMENT);
			_frameData.sound = _frameXML.attribute(ConstValues.A_SOUND);
			_movementData.addFrameData(
				_frameData,
				_frameXML.childIndex()
			);
		}
		return _movementData;
	}
	
}