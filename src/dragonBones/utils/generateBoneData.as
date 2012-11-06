package dragonBones.utils {
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.utils.skeletonNamespace;
	
	use namespace skeletonNamespace;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	public function generateBoneData(_boneName:String, _boneXML:XML, _parentXML:XML, _boneData:BoneData = null):BoneData {
		if(!_boneData){
			_boneData = new BoneData();
		}
		_boneData.name =_boneName;
		_boneData.parent = _boneXML.attribute(ConstValues.A_PARENT);
		_boneData.x = Number(_boneXML.attribute(ConstValues.A_X));
		_boneData.y = Number(_boneXML.attribute(ConstValues.A_Y));
		_boneData.skewX = Number(_boneXML.attribute(ConstValues.A_SKEW_X)) * ConstValues.ANGLE_TO_RADIAN;
		_boneData.skewY = Number(_boneXML.attribute(ConstValues.A_SKEW_Y)) * ConstValues.ANGLE_TO_RADIAN;
		//_boneData.scaleX = Number(_boneXML.attribute(ConstValues.A_SCALE_X));
		//_boneData.scaleY = Number(_boneXML.attribute(ConstValues.A_SCALE_Y));
		_boneData.z = int(_boneXML.attribute(ConstValues.A_Z));
		
		for each(var _displayXML:XML in _boneXML.elements(ConstValues.DISPLAY)){
			_boneData.setDisplayAt(_displayXML.attribute(ConstValues.A_NAME), Boolean(int(_displayXML.attribute(ConstValues.A_IS_ARMATURE))), _displayXML.childIndex());
		}
		
		if(_parentXML){
			Help.helpNode.x = Number(_parentXML.attribute(ConstValues.A_X));
			Help.helpNode.y = Number(_parentXML.attribute(ConstValues.A_Y));
			Help.helpNode.skewX = Number(_parentXML.attribute(ConstValues.A_SKEW_X)) * ConstValues.ANGLE_TO_RADIAN;
			Help.helpNode.skewY = Number(_parentXML.attribute(ConstValues.A_SKEW_Y)) * ConstValues.ANGLE_TO_RADIAN;
			//Help.helpNode.scaleX = Number(_parentXML.attribute(ConstValues.A_SCALE_X));
			//Help.helpNode.scaleY = Number(_parentXML.attribute(ConstValues.A_SCALE_Y));
			
			TransfromUtils.transfromPointWithParent(_boneData, Help.helpNode);
		}
		return _boneData;
	}
}

import dragonBones.objects.Node;
class Help{
	public static var helpNode:Node = new Node();
}