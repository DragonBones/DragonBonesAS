package dragonBones.objects {
	/**
	 * ...
	 * @author Akdcl
	 */
	internal class BaseDicData {
		public var name:String;
		protected var datas:Object;
		
		public function BaseDicData(_name:String = null) {
			name = _name;
			datas = { };
		}
		
		public function addData(_data:Object, _id:String = null, _replaceIfExists:Boolean = false):Boolean {
			_id = _id || _data.name;
			var _exData:Object = datas[_id];
			if (_exData) {
				if(_replaceIfExists){
					_exData.dispose();
				}else{
					return false;
				}
			}
			datas[_id] = _data;
			return true;
		}
		
		public function getSearchList():Array {
			var _list:Array = [];
			for (var _name:String in datas) {
				_list.push(_name);
			}
			return _list;
		}
		
		public function dispose():void {
			name = null;
			for each(var _data:Object in datas){
				if("dispose" in _data){
					_data.dispose();
				}
			}
			datas = null;
		}
	}
	
}