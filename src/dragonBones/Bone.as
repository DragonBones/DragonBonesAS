package dragonBones
{
	import dragonBones.animation.Tween;
	import dragonBones.display.IDisplayBridge;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.Node;
	import dragonBones.utils.dragonBones_internal;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	use namespace dragonBones_internal;
	
	/**
	 * A object representing a single joint in an armature. It controls the transform of displays in it.
	 *
	 * @see dragonBones.Armature
	 */
	public class Bone extends EventDispatcher
	{
		private static var _helpPoint:Point = new Point();
		/**
		 * The name of the Armature.
		 */
		public var name:String;
		/**
		 * An object that can contain any extra data.
		 */
		public var userData:Object;
		
		/**
		 * The transform information relative to the armature's coordinates.
		 */
		public var global:Node;
		
		/**
		 * The transform information relative to the local coordinates.
		 */
		public var node:Node;
		
		/** @private */
		dragonBones_internal var origin:BoneData;
		/** @private */
		dragonBones_internal var _tween:Tween;
		/** @private */
		dragonBones_internal var _children:Vector.<Bone>;
		/** @private */
		dragonBones_internal var _displayBridge:IDisplayBridge;
		/** @private */
		dragonBones_internal var _displayVisible:Boolean;
		/** @private */
		dragonBones_internal var _armature:Armature;
		
		private var _globalTransformMatrix:Matrix = new Matrix;
		private var _displayList:Array;
		private var _displayIndex:int;
		private var _parent:Bone;
		
		/**
		 * The armature holding this bone.
		 */
		public function get armature():Armature
		{
			return _armature;
		}
		
		/**
		 * The sub-armature of this bone.
		 */
		public function get childArmature():Armature
		{
			return _displayList[_displayIndex] as Armature;
		}
		
		/**
		 * Indicates the bone that contains this bone.
		 */
		public function get parent():Bone
		{
			return _parent;
		}
		
		/**
		 * Indicates the display object belonging to this bone.
		 */
		public function get display():Object
		{
			return _displayBridge.display;
		}
		
		public function set display(value:Object):void
		{
			if(_displayBridge.display == value)
			{
				return;
			}
			_displayList[_displayIndex] = value;
			if(value is Armature)
			{
				value = (value as Armature).display;
			}
			_displayBridge.display = value;
		}
		
		/** @private */
		dragonBones_internal function changeDisplay(displayIndex:int):void
		{
			if(displayIndex < 0)
			{
				if(_displayVisible)
				{
					_displayVisible = false;
					//hide
					_displayBridge.removeDisplay();
				}
			}
			else
			{
				if(!_displayVisible)
				{
					_displayVisible = true;
					//show
					if(_armature)
					{
						_displayBridge.addDisplay(_armature.display, global.z);
						_armature._bonesIndexChanged = true;
					}
				}
				
				if(_displayIndex != displayIndex)
				{
					_displayIndex = displayIndex;
					//change
					display = _displayList[_displayIndex];
				}
			}
		}
		
		/**
		 * Creates a new <code>Bone</code> object
		 * @param	displayBrideg
		 */
		public function Bone(displayBrideg:IDisplayBridge)
		{
			_displayBridge = displayBrideg;
			
			_tween = new Tween(this);
			
			_children = new Vector.<Bone>;
			
			_displayList = [];
			_displayIndex = -1;
			
			origin = new BoneData();
			global = new Node();
			node = new Node();
			node.scaleX = 0;
			node.scaleY = 0;
		}
		
		/**
		 * Cleans up any resources used by the current object.
		 */
		public function dispose():void
		{
			for each(var _child:Bone in _children)
			{
				_child.dispose();
			}
			
			setParent(null);
			_tween.dispose();
			
			userData = null;
			origin = null;
			global = null;
			node = null;
			
			_globalTransformMatrix = null;
			
			//_displayBridge = null;
			_displayList = null;
			
			_tween = null;
			_children = null;
			
			_armature = null;
			_parent = null;
		}
		
		/** @private */
		dragonBones_internal function update():void
		{
			//update tween
			_tween.update();
			
			//update node and matirx
			var currentDisplay:Object = _displayBridge.display;
			if (_children.length > 0 || (_displayVisible && currentDisplay))
			{
				var tweenNode:Node = _tween._node;
				
				_helpPoint.x = origin.x + node.x + tweenNode.x;
				_helpPoint.y = origin.y + node.y + tweenNode.y;
				global.skewX = origin.skewX + node.skewX + tweenNode.skewX;
				global.skewY = origin.skewY + node.skewY + tweenNode.skewY;
				
				//transform
				if(_parent)
				{
					_helpPoint = _parent._globalTransformMatrix.deltaTransformPoint(_helpPoint);
					_helpPoint.x += _parent.global.x;
					_helpPoint.y += _parent.global.y;
					global.skewX += _parent.global.skewX;
					global.skewY += _parent.global.skewY;
				}
				
				//update global
				global.x = _helpPoint.x;
				global.y = _helpPoint.y;
				global.scaleX = origin.scaleX + node.scaleX + tweenNode.scaleX;
				global.scaleY = origin.scaleY + node.scaleY + tweenNode.scaleY;
				global.pivotX = origin.pivotX + node.pivotX + tweenNode.pivotX;
				global.pivotY = origin.pivotY + node.pivotY + tweenNode.pivotY;
				
				//Note: this formula of transform is defined by Flash pro
				_globalTransformMatrix.a = global.scaleX * Math.cos(global.skewY);
				_globalTransformMatrix.b = global.scaleX * Math.sin(global.skewY);
				_globalTransformMatrix.c = -global.scaleY * Math.sin(global.skewX);
				_globalTransformMatrix.d = global.scaleY * Math.cos(global.skewX);
				_globalTransformMatrix.tx = global.x;
				_globalTransformMatrix.ty = global.y;
				
				//update display
				if(_displayVisible && currentDisplay)
				{
					_displayBridge.update(_globalTransformMatrix, global);
					var childArmature:Armature = this.childArmature;
					if(childArmature)
					{
						childArmature.update();
					}
				}
				
				//update children
				if (_children.length > 0)
				{
					for each(var child:Bone in _children)
					{
						child.update();
					}
				}
			}
		}
		
		/** @private */
		public function addChild(child:Bone):void
		{
			if (_children.length > 0?(_children.indexOf(child) < 0):true)
			{
				child.removeFromParent();
				
				_children.push(child);
				child.setParent(this);
				
				if (_armature)
				{
					_armature.addToBones(child);
				}
			}
		}
		
		/** @private */
		public function removeChild(child:Bone):void
		{
			var index:int = _children.indexOf(child);
			if (index >= 0)
			{
				if (_armature)
				{
					_armature.removeFromBones(child);
				}
				child.setParent(null);
				_children.splice(index, 1);
			}
		}
		/** @private */
		public function removeFromParent():void
		{
			if(_parent)
			{
				_parent.removeChild(this);
			}
		}
		
		private function setParent(parent:Bone):void
		{
			var ancestor:Bone = parent;
			while (ancestor != this && ancestor != null)
			{
				ancestor = ancestor.parent;
			}
			if (ancestor == this)
			{
				throw new ArgumentError("An Bone cannot be added as a child to itself or one of its children (or children's children, etc.)");
			}
			else
			{
				_parent = parent;
			}
		}
	}
}