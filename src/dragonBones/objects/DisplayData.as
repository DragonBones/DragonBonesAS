package dragonBones.objects
{
	/** @private */
	public class DisplayData
	{
		public var pivotX:int;
		public var pivotY:int;
		
		internal var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		internal var _isArmature:Boolean;
		public function get isArmature():Boolean
		{
			return _isArmature;
		}
		
		public function DisplayData()
		{
		}
	}
}