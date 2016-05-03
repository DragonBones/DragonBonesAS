package dragonBones.starling.mesh 
{
	import flash.geom.Point;
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	/**
	 * 把meshImage放在这个容器里会提高渲染效率
	 * @author sukui
	 */
	public class MeshArmature extends DisplayObjectContainer
	{
		
		public function MeshArmature() 
		{
			
		}
		override public function render(support:RenderSupport, parentAlpha:Number):void 
		{
			super.render(support, parentAlpha);
			if (MeshImage.meshBatch)
			{
				MeshImage.meshBatch.flush();
			}
		}
		
	}

}