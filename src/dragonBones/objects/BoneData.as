package dragonBones.objects{
	
	import dragonBones.utils.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class BoneData extends Node {
		dragonBones_internal var name:String;
		public var parent:String;
		
		public function BoneData(_x:Number = 0, _y:Number = 0, _skewX:Number = 0, _skewY:Number = 0) {
			super(_x, _y, _skewX, _skewY);
		}
		
		override public function dispose():void{
			super.dispose();
			name = null;
			parent = null;
			displayList = null;
		}
		
		override public function copy(_node:Node):void{
			super.copy(_node);
			var _boneData:BoneData = _node as BoneData;
			if(_boneData){
				name = _boneData.name;
				parent = _boneData.parent;
			}
		}
		
		private var displayList:Array;
		
		dragonBones_internal function get displayLength():uint{
			return displayList?displayList.length:0;
		}
		
		dragonBones_internal function getDisplayData(_index:int):DisplayData{
			return displayList?displayList[_index]:null;
		}
		
		dragonBones_internal function setDisplayAt(_name:String, _isArmature:Boolean = false, _index:int = 0):void{
			if(!displayList){
				displayList = [];
			}
			var _displayData:DisplayData = displayList[_index];
			if(_displayData){
				_displayData.name = _name;
				_displayData.isArmature = _isArmature;
			}else{
				_displayData = new DisplayData(_name, _isArmature);
				displayList[_index] = _displayData;
			}
		}
	}
}