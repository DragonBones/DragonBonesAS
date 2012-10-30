package dragonBones {
	import dragonBones.animation.Tween;
	import dragonBones.events.EventDispatcher;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.Node;
	import dragonBones.utils.skeletonNamespace;
	
	import flash.geom.Matrix;
	
	use namespace skeletonNamespace;
	
	/**
	 *
	 * @author akdcl
	 */
	public class Bone extends EventDispatcher {
		public var name:String;
		public var userData:Object;
		
		public var origin:BoneData;
		public var global:Node;
		public var node:Node;
		
		skeletonNamespace var tween:Tween;
		
		protected var _globalTransformMatrix:Matrix = new Matrix;
		protected var _transformMatrixForChildren:Matrix = new Matrix;
		
		protected var children:Vector.<Bone>;
		
		skeletonNamespace var addDisplayChild:Function;
		skeletonNamespace var removeDisplayChild:Function;
		skeletonNamespace var updateDisplay:Function;
		
		private var displayList:Array;
		private var displayIndex:int = -1;
		
		private var __armature:Armature;
		public function get armature():Armature{
			return __armature;
		}
		
		private var __parent:Bone;
		public function get parent():Bone{
			return __parent;
		}
		
		protected var __display:Object;
		public function get display():Object {
			return __display;
		}
		public function set display(_display:Object):void {
			if(__display == _display) {
				return;
			}
			
			if (__display) {
				removeDisplayChild(__display);
				__display = null;
			}else if (displayList[displayIndex] is Armature) {
				removeChild(displayList[displayIndex] as Bone);
			}else {
				
			}
			
			if (_display is Armature) {
				displayList[displayIndex] = _display;
				childArmature.origin.z = origin.z;
				addChild(_display as Bone);
			}else if (_display) {
				displayList[displayIndex] = _display;
				if(__armature){
					addDisplayChild(_display, __armature.display, origin.z);
				}
				__display = _display;
			}else {
				if(displayIndex >= 0){
					displayList[displayIndex] = false;
				}
			}
		}
		
		public function get childArmature():Armature{
			return displayList[displayIndex] as Armature;
		}
		
		skeletonNamespace function changeDisplay(_displayIndex:int):void {
			if(displayIndex == _displayIndex){
				return;
			}
			
			displayIndex = _displayIndex;
			if(displayIndex < 0){
				display = null;
			}else{
				var _display:Object = displayList[displayIndex];
				if(_display){
					display = _display;
				}else if (_display === false) {
					display = null;
				}
			}
			if(__armature){
				__armature.bonesIndexChanged = true;
			}
		}
		
		public function Bone() {
			
			origin = new BoneData();
			displayList = [];
			
			children = new Vector.<Bone>;
			
			global = new Node();
			node = new Node();
			node.scaleX = 0;
			node.scaleY = 0;
			
			tween = new Tween(this);
		}
		
		public function update():void {
			if (__armature) {
				tween.update();
				
				global.x = origin.x + node.x + tween.node.x;
				global.y = origin.y + node.y + tween.node.y;
				global.skewX = origin.skewX + node.skewX + tween.node.skewX;
				global.skewY = origin.skewY + node.skewY + tween.node.skewY;
				//origin.scaleX + node.scaleX + tweenNode.scaleX;
				//origin.scaleY + node.scaleY + tweenNode.scaleY;
				global.scaleX = node.scaleX + tween.node.scaleX;
				global.scaleY = node.scaleX + tween.node.scaleY;
				
				//Note: this formula of transform is defined by Flash pro
				var cosX:Number = Math.cos(global.skewX);
				var sinX:Number = Math.sin(global.skewX);
				var cosY:Number = Math.cos(global.skewY);
				var sinY:Number = Math.sin(global.skewY);
				
				if (children.length > 0 || __display)
				{
					_globalTransformMatrix.a = global.scaleX * cosY;
					_globalTransformMatrix.b = global.scaleX * sinY;
					_globalTransformMatrix.c = -global.scaleY * sinX;
					_globalTransformMatrix.d = global.scaleY * cosX;
					_globalTransformMatrix.tx = global.x;
					_globalTransformMatrix.ty = global.y;
				}
				
				if (children.length > 0)
				{
					//如何让斜切只传递给children的 x y rotation呢？
					_transformMatrixForChildren.a = cosY;
					_transformMatrixForChildren.b = sinY;
					_transformMatrixForChildren.c = -sinX;
					_transformMatrixForChildren.d = cosX;
					_transformMatrixForChildren.tx = global.x;
					_transformMatrixForChildren.ty = global.y;
				}
				
				if (__parent != __armature) {
					_globalTransformMatrix.concat(__parent._transformMatrixForChildren);
					if (children.length > 0)
					{
						_transformMatrixForChildren.concat(__parent._transformMatrixForChildren);
					}
				}
				if (__display) {
					updateDisplay(__display, _globalTransformMatrix);
				}
			}
			
			for each(var _child:Bone in children) {
				_child.update();
			}
		}
		
		public function dispose():void{
			removeEventListeners();
			for each(var _child:Bone in children){
				_child.dispose();
			}
			
			setParent(null);
			tween.dispose();
			
			tween = null;
			userData = null;
			origin = null;
			node = null;
			
			children = null;
			
			__armature = null;
			__parent = null;
			__display = null;
			
			displayList = null;
		}
		
		public function getChildByDisplay(_display:Object, _searchInChild:Boolean = false):Bone{
			if(_display){
				for each(var _eachBone:Bone in children){
					if(_eachBone.display == _display){
						return _eachBone;
					}
					if(_searchInChild && !(_eachBone is Armature)){
						var _boneInChild:Bone = _eachBone.getChildByDisplay(_display, true);
						if(_boneInChild){
							return _boneInChild;
						}
					}
				}
			}
			return null;
		}
		
		public function getChildByName(_name:String, _searchInChild:Boolean = false):Bone{
			if(_name){
				for each(var _eachBone:Bone in children){
					if(_eachBone.origin.name == _name){
						return _eachBone;
					}
					if(_searchInChild && !(_eachBone is Armature)){
						var _boneInChild:Bone = _eachBone.getChildByName(_name, true);
						if(_boneInChild){
							return _boneInChild;
						}
					}
				}
			}
			return null;
		}
		
		public function eachChild(_callback:Function, _args:Array = null, _searchInChild:Boolean = false):Object{
			var _result:Object;
			for each(var _eachBone:Bone in children){
				_result = _callback(_eachBone, _args);
				if(_result){
					return _result;
				}
				if(_searchInChild && !(_eachBone is Armature)){
					_result = _eachBone.eachChild(_callback, _args, _searchInChild);
					if(_result){
						return _result;
					}
				}
			}
			return null;
		}
		
		public function addChild(_child:Bone):void {
			if (children.length > 0?(children.indexOf(_child) < 0):true) {
				children.push(_child);
				_child.removeFromParent();
				_child.setParent(this);
			}
		}
		
		public function removeChild(_child:Bone, _dispose:Boolean = false):void {
			var _index:int = children.indexOf(_child);
			if (_index >= 0) {
				_child.setParent(null);
				children.splice(_index, 1);
				if(_dispose){
					_child.dispose();
				}
			}else{
				
			}
		}
		
		public function removeFromParent(_dispose:Boolean = false):void{
			if(__parent){
				__parent.removeChild(this, _dispose);
			}
		}
		
		private function setParent(_parent:Bone):void{
			var _ancestor:Bone = _parent;
			while (_ancestor != this && _ancestor != null){
				_ancestor = _ancestor.parent;
			}
			
			if (_ancestor == this){
				throw new ArgumentError("An Bone cannot be added as a child to itself or one of its children (or children's children, etc.)");
			}else{
				__parent = _parent;
			}
			var _child:Bone;
			if(__parent){
				__armature = (__parent as Armature) || __parent.armature;
				if (__armature) {
					if(__display){
						addDisplayChild(__display, __armature.display, origin.z);
					}
					__armature.addToBones(this);
					if(!this is Armature){
						for each(_child in children){
							if(_child.display){
								addDisplayChild(_child.display, __armature.display, origin.z);
							}
							__armature.addToBones(_child);
						}
					}
				}
			}else if (__armature) {
				if(!this is Armature){
					for each(_child in children){
						removeDisplayChild(_child.display);
						__armature.removeFromBones(_child);
					}
				}
				if(__display){
					removeDisplayChild(__display);
				}
				__armature.removeFromBones(this);
				__armature = null;
			}
		}
	}
	
}