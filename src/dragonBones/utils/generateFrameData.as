package dragonBones.utils {
	import dragonBones.objects.BoneData;
	import dragonBones.objects.FrameData;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	public function generateFrameData(_frameXML:XML, _parentFrameXML:XML, _boneData:BoneData, _frameData:FrameData = null):FrameData {
		if(!_frameData){
			_frameData = new FrameData();
		}
		
		_frameData.x = Number(_frameXML.attribute(ConstValues.A_X));
		_frameData.y = Number(_frameXML.attribute(ConstValues.A_Y));
		_frameData.skewX = Number(_frameXML.attribute(ConstValues.A_SKEW_X)) * ConstValues.ANGLE_TO_RADIAN;
		_frameData.skewY = Number(_frameXML.attribute(ConstValues.A_SKEW_Y)) * ConstValues.ANGLE_TO_RADIAN;
		_frameData.z = int(_frameXML.attribute(ConstValues.A_Z));
		_frameData.duration = int(_frameXML.attribute(ConstValues.A_DURATION));
		_frameData.tweenEasing = Number(_frameXML.attribute(ConstValues.A_TWEEN_EASING));
		_frameData.tweenRotate = int(_frameXML.attribute(ConstValues.A_TWEEN_ROTATE));
		_frameData.displayIndex = int(_frameXML.attribute(ConstValues.A_DISPLAY_INDEX));
		_frameData.movement = String(_frameXML.attribute(ConstValues.A_MOVEMENT));
		
		_frameData.event = String(_frameXML.attribute(ConstValues.A_EVENT));
		_frameData.sound = String(_frameXML.attribute(ConstValues.A_SOUND));
		_frameData.soundEffect = String(_frameXML.attribute(ConstValues.A_SOUND_EFFECT));
		
		
		if(_parentFrameXML){
			Help.helpNode.x = Number(_parentFrameXML.attribute(ConstValues.A_X));
			Help.helpNode.y = Number(_parentFrameXML.attribute(ConstValues.A_Y));
			Help.helpNode.skewX = Number(_parentFrameXML.attribute(ConstValues.A_SKEW_X)) * ConstValues.ANGLE_TO_RADIAN;
			Help.helpNode.skewY = Number(_parentFrameXML.attribute(ConstValues.A_SKEW_Y)) * ConstValues.ANGLE_TO_RADIAN;
			//Help.helpNode.scaleX = Number(_parentFrameXML.attribute(ConstValues.A_SCALE_X));
			//Help.helpNode.scaleY = Number(_parentFrameXML.attribute(ConstValues.A_SCALE_Y));
			
			TransfromUtils.transfromPointWidthParent(_frameData, Help.helpNode);
		}
		
		_frameData.x -=	_boneData.x;
		_frameData.y -=	_boneData.y;
		_frameData.skewX -=	_boneData.skewX;
		_frameData.skewY -=_boneData.skewY;
		_frameData.scaleX = Number(_frameXML.attribute(ConstValues.A_SCALE_X));
		_frameData.scaleY = Number(_frameXML.attribute(ConstValues.A_SCALE_Y));
		//_frameData.scaleX -=_boneData.scaleX;
		//_frameData.scaleY -=_boneData.scaleY;
		return _frameData;
	}
	
}

import dragonBones.objects.Node;
class Help{
	public static var helpNode:Node = new Node();
}