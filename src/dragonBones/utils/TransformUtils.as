package dragonBones.utils 
{
	import dragonBones.objects.Node;
	import dragonBones.objects.TweenNode;
	import dragonBones.animation.Tween;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/** @private */
	public class TransformUtils 
	{
		private static var _helpMatrix:Matrix = new Matrix();
		private static var _helpPoint:Point = new Point();
		private static var _helpNode:Node = new Node();
		private static var _helpTweenNode:TweenNode = new TweenNode();
		
		public static function transformPointWithParent(bone:Node, parent:Node):void 
		{
			nodeToMatrix(parent, _helpMatrix);
			
			_helpPoint.x = bone.x;
			_helpPoint.y = bone.y;
			
			_helpMatrix.invert();
			_helpPoint = _helpMatrix.transformPoint(_helpPoint);
			bone.x = _helpPoint.x;
			bone.y = _helpPoint.y;
			
			bone.skewX -= parent.skewX;
			bone.skewY -= parent.skewY;
		}
		
		public static function nodeToMatrix(node:Node, matrix:Matrix):void
		{
			matrix.a = node.scaleX * Math.cos(node.skewY)
			matrix.b = node.scaleX * Math.sin(node.skewY)
			matrix.c = -node.scaleY * Math.sin(node.skewX);
			matrix.d = node.scaleY * Math.cos(node.skewX);
			
			matrix.tx = node.x;
			matrix.ty = node.y;
		}
		
		public static function getTweenNode(currentNode:Node, nextNode:Node, progress:Number, ease:Number):Node
		{
			if(isNaN(ease))
			{
				progress = 0;
			}
			else
			{
				progress = Tween.getEaseValue(progress, ease);
			}
			
			_helpTweenNode.subtract(currentNode, nextNode);
			
			_helpNode.x = currentNode.x + progress * _helpTweenNode.x;
			_helpNode.y = currentNode.y + progress * _helpTweenNode.y;
			
			_helpNode.scaleX = currentNode.scaleX + progress * _helpTweenNode.scaleX;
			_helpNode.scaleY = currentNode.scaleY + progress * _helpTweenNode.scaleY;
			_helpNode.skewX = currentNode.skewX + progress * _helpTweenNode.skewX;
			_helpNode.skewY = currentNode.skewY + progress * _helpTweenNode.skewY;
			_helpNode.pivotX = currentNode.pivotX + progress * _helpTweenNode.pivotX;
			_helpNode.pivotY = currentNode.pivotX + progress * _helpTweenNode.pivotY;
			return _helpNode;
		}
	}
	
}