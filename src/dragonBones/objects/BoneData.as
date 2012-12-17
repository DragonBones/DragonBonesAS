package dragonBones.objects
{
	
	/** @private */
	final public class BoneData extends Node
	{
		private var _displayList:Vector.<String>;
		
		internal var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		internal var _parent:String;
		public function get parent():String
		{
			return _parent;
		}
		
		public function get totalDisplays():uint
		{
			return _displayList.length;
		}
		
		public function BoneData()
		{
			super();
			_displayList = new Vector.<String>;
		}
		
		public function dispose():void
		{
			_displayList.length = 0;
			_displayList = null;
		}
		
		override public function copy(node:Node):void
		{
			super.copy(node);
			var boneData:BoneData = node as BoneData;
			if(boneData)
			{
				_name = boneData.name;
				_parent = boneData.parent;
			}
		}
		
		public function getDisplayDataAt(index:int):String
		{
			return _displayList.length > index?_displayList[index]:null;
		}
		
		internal function addDisplayData(data:String):void
		{
			if(_displayList.indexOf(data) < 0)
			{
				_displayList.push(data);
			}
		}
	}
}