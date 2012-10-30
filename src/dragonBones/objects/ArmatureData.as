package dragonBones.objects{
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class ArmatureData extends BaseDicData {
		public function ArmatureData(_name:String = null) {
			super(_name);
		}
		
		public function getData(_name:String):BoneData {
			return datas[_name];
		}
	}
}