package dragonBones.display
{
	import flash.geom.Matrix;

	public interface IDisplayBridge
	{
		function get display():Object;
		function set display(value:Object):void;
		function update(matrix:Matrix):void;
		function addDisplay(container:Object, index:int = -1):void;
		function removeDisplay():void;
	}
}