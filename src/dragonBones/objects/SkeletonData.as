package dragonBones.objects {
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.generateAnimationData;
	import dragonBones.utils.generateArmatureData;
	
	import flash.utils.ByteArray;
	
	/**
	 * 
	 * @author Akdcl
	 */
	final public class SkeletonData extends BaseDicData {
		private var animationDatas:Object;
		
		public function SkeletonData(_skeletonXML:XML) {
			super(null);
			animationDatas = { };
			if (_skeletonXML) {
				setData(_skeletonXML);
			}
		}
		
		override public function dispose():void{
			super.dispose();
			for each(var _data:AnimationData in animationDatas){
				_data.dispose();
			}
			animationDatas = null;
		}
		
		public function getArmatureData(_name:String):ArmatureData {
			return datas[_name];
		}
		
		public function getAnimationData(_name:String):AnimationData {
			return animationDatas[_name];
		}
		
		public function addAnimationData(_data:AnimationData, _id:String = null):void{
			_id = _id || _data.name;
			if (animationDatas[_id]) {
				animationDatas[_id].dispose();
			}
			animationDatas[_id] = _data;
		}
		
		public function setData(_skeletonXML:XML):void {
			name = _skeletonXML.attribute(ConstValues.A_NAME);
			
			var _dataName:String;
			for each(var _armatureXML:XML in _skeletonXML.elements(ConstValues.ARMATURES).elements(ConstValues.ARMATURE)) {
				_dataName = _armatureXML.attribute(ConstValues.A_NAME);
				addData(generateArmatureData(_dataName, _armatureXML), _dataName);
			}
			
			for each(var _animationXML:XML in _skeletonXML.elements(ConstValues.ANIMATIONS).elements(ConstValues.ANIMATION)) {
				_dataName = _animationXML.attribute(ConstValues.A_NAME);
				addAnimationData(generateAnimationData(_dataName, _animationXML, getArmatureData(_dataName)), _dataName);
			}
		}
	}
}