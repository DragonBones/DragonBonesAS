package dragonBones.core
{
	import dragonBones.animation.IAnimatable;

	public interface IArmature extends IAnimatable
	{
		function get animation():Object;
		function resetAnimation():void
		
	}
}