package dragonBones.objects{
	
	import dragonBones.utils.skeletonNamespace;
	
	use namespace skeletonNamespace;
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class BoneData extends Node {
		public var name:String;
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
		
		skeletonNamespace function get displayLength():uint{
			return displayList?displayList.length:0;
		}
		
		skeletonNamespace function getDisplayData(_index:int):DisplayData{
			return displayList?displayList[_index]:null;
		}
		
		skeletonNamespace function setDisplayAt(_name:String, _isArmature:Boolean = false, _index:int = 0):void{
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