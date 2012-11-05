package dragonBones.objects{
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class AnimationData extends BaseDicData {
		private var firstMovement:String;
		public function AnimationData(_name:String = null) {
			super(_name);
		}
		
		override public function addData(_data:Object, _id:String=null, _replaceIfExists:Boolean=false):Boolean{
			if(!firstMovement){
				firstMovement = _id;
			}
			return super.addData(_data, _id, _replaceIfExists);
		}
		
		override public function getSearchList():Array{
			if(firstMovement){
				var _list:Array = [firstMovement];
				for (var _name:String in datas) {
					if(_list.indexOf(_name) < 0){
						_list.push(_name);
					}
				}
				return _list;
			}
			return super.getSearchList();
		}
		
		public function getData(_name:String):MovementData {
			return datas[_name];
		}
	}
	
}