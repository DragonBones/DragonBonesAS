package dragonBones.objects
{
	
	/** @private */
	final public class BoneData
	{
		public var displayList:Vector.<String>;
		
		internal var _parent:String;
		public function get parent():String
		{
			return _parent;
		}
		
		public var node:Node;
		
		public function BoneData()
		{
			displayList = new Vector.<String>;
			node = new Node();
		}
		
		public function dispose():void
		{
			displayList.length = 0;
		}
	}
}