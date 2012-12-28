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
		
		private var _global:Node;
		/**
		 * The transform information relative to the armature's coordinates.
		 */
		public function get global():Node
		{
			return _global;
		}
		
		private var _node:Node;
		/**
		 * The transform information relative to the local coordinates.
		 */
		public function get node():Node
		{
			return _node;
		}
		
		/** @private */
		dragonBones_internal var _origin:BoneData;
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
		
		private var _globalTransformMatrix:Matrix;
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
						_displayBridge.addDisplay(_armature.display, _global.z);
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
			
			_globalTransformMatrix = new Matrix()
			_displayList = [];
			_displayIndex = -1;
			_origin = new BoneData();
			_global = new Node();
			_node = new Node();
			_node.scaleX = 0;
			_node.scaleY = 0;
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
			
			_displayList.length = 0;
			_children.length = 0;
			//_displayBridge.display = null;
			
			_armature = null;
			_parent = null;
			
			//_tween.dispose();
			//_tween = null;
			
			userData = null;
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
		
		/** @private */
		dragonBones_internal function update():void
		{
			//update node and matirx
			var currentDisplay:Object = _displayBridge.display;
			if (_children.length > 0 || (_displayVisible && currentDisplay))
			{
				var tweenNode:Node = _tween._node;
				
				_helpPoint.x = _origin.x + _node.x + tweenNode.x;
				_helpPoint.y = _origin.y + _node.y + tweenNode.y;
				_global.skewX = _origin.skewX + _node.skewX + tweenNode.skewX;
				_global.skewY = _origin.skewY + _node.skewY + tweenNode.skewY;
				
				//transform
				if(_parent)
				{
					_helpPoint = _parent._globalTransformMatrix.deltaTransformPoint(_helpPoint);
					_helpPoint.x += _parent._global.x;
					_helpPoint.y += _parent._global.y;
					_global.skewX += _parent._global.skewX;
					_global.skewY += _parent._global.skewY;
				}
				
				//update global
				_global.x = _helpPoint.x;
				_global.y = _helpPoint.y;
				_global.scaleX = _origin.scaleX + _node.scaleX + tweenNode.scaleX;
				_global.scaleY = _origin.scaleY + _node.scaleY + tweenNode.scaleY;
				_global.pivotX = _origin.pivotX + _node.pivotX + tweenNode.pivotX;
				_global.pivotY = _origin.pivotY + _node.pivotY + tweenNode.pivotY;
				
				//Note: this formula of transform is defined by Flash pro
				_globalTransformMatrix.a = _global.scaleX * Math.cos(_global.skewY);
				_globalTransformMatrix.b = _global.scaleX * Math.sin(_global.skewY);
				_globalTransformMatrix.c = -_global.scaleY * Math.sin(_global.skewX);
				_globalTransformMatrix.d = _global.scaleY * Math.cos(_global.skewX);
				_globalTransformMatrix.tx = _global.x;
				_globalTransformMatrix.ty = _global.y;
				
				//update display
				if(_displayVisible && currentDisplay)
				{
					_displayBridge.update(_globalTransformMatrix, _global);
				}
				
				//update children
				if (_children.length > 0)
				{
					for each(var child:Bone in _children)
					{
						child.update();
					}
				}
				var childArmature:Armature = this.childArmature;
				if(childArmature)
				{
					childArmature.update();
				}
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