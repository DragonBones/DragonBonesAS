package dragonBones.objects
{
	
	public final class DisplayData
	{
		public var name:String;
		public var isArmature:Boolean;
		
		public function DisplayData(_name:String, _isArmature:Boolean = false){
			name = _name;
			isArmature = _isArmature;
		}
	}
}