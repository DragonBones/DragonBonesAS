package dragonBones.objects{
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class AnimationData extends BaseDicData {
		public function AnimationData(_name:String = null) {
			super(_name);
		}
		
		public function getData(_name:String):MovementData {
			return datas[_name];
		}
	}
	
}