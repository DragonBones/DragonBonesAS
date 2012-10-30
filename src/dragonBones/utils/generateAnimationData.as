package dragonBones.utils {
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.AnimationData;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	public function generateAnimationData(_animationName:String, _animationXML:XML, _armatureData:ArmatureData, _animationData:AnimationData = null):AnimationData {
		if(!_animationData){
			_animationData = new AnimationData(_animationName);
		}
		for each(var _movementXML:XML in _animationXML.elements(ConstValues.MOVEMENT)) {
			var _movementName:String = _movementXML.attribute(ConstValues.A_NAME);
			_animationData.addData(
				generateMovementData(
					_movementName, 
					_movementXML, 
					_armatureData, 
					_animationData.getData(_movementName)
				),
				_movementName
			);
		}
		return _animationData;
	}
	
}