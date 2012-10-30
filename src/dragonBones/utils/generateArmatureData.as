package dragonBones.utils {
	import dragonBones.objects.ArmatureData;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	public function generateArmatureData(_armatureName:String, _armatureXML:XML):ArmatureData {
		var _armatureData:ArmatureData = new ArmatureData(_armatureName);
		
		var _xmlList:XMLList = _armatureXML.elements(ConstValues.BONE);
		for each(var _boneXML:XML in _xmlList) {
			var _boneName:String = _boneXML.attribute(ConstValues.A_NAME);
			var _parentName:String = _boneXML.attribute(ConstValues.A_PARENT);
			var _parentXML:XML = _xmlList.(attribute(ConstValues.A_NAME) == _parentName)[0];
			
			_armatureData.addData(
				generateBoneData(
					_boneName, 
					_boneXML, 
					_parentXML, 
					_armatureData.getData(_boneName)
				), 
				_boneName
			);
		}
		return _armatureData;
	}
	
}