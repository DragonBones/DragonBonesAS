package dragonBones.core
{
	public interface ICacheableArmature extends IArmature
	{
		function get enableCache():Boolean;
		function get enableEventDispatch():Boolean;
	}
}