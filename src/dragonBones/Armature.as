package dragonBones {
	import dragonBones.animation.Animation;
	import dragonBones.utils.skeletonNamespace;
	
	use namespace skeletonNamespace;
	
	[Event(name="movementChange", type="dragonBones.events.Event")]
	
	[Event(name="start", type="dragonBones.events.Event")]
	
	[Event(name="complete", type="dragonBones.events.Event")]
	
	[Event(name="loopComplete", type="dragonBones.events.Event")]
	
	[Event(name="movementEventFrame", type="dragonBones.events.Event")]
	
	[Event(name="boneEventFrame", type="dragonBones.events.Event")]
	
	/**
	 * 
	 * @author Akdcl
	 */
	public class Armature extends Bone {
		
		public var animation:Animation;
		
		protected var bones:Object;
		skeletonNamespace var bonesIndexChanged:Boolean;
		
		override public function set display(_display:Object):void {
			//warn
			//__display = _display;
		}
		
		public function Armature(_display:Object) {
			super();
			__display = _display;
			
			bones = { };
			animation = new Animation(this);
			bonesIndexChanged = false;
		}
		
		override public function update():void{
			super.update();
			animation.update();
			if(bonesIndexChanged){
				updateBonesZ();
			}
		}
		
		override public function dispose():void{
			super.dispose();
			animation = null;
			bones = null;
		}
		
		override skeletonNamespace function changeDisplay(_displayIndex:int):void{
		}
		
		public function getBone(_name:String):Bone {
			return bones[_name];
		}

		public function addBone(_bone:Bone, _boneName:String = null, _parentName:String = null):void {
			_bone.name = _boneName || _bone.name;
			var _boneParent:Bone = bones[_parentName];
			if (_boneParent) {
				_boneParent.addChild(_bone);
			}else {
				addChild(_bone);
			}
		}
		
		public function removeBone(_name:String):void {
			var _bone:Bone = bones[_name];
			if (_bone) {
				_bone.parent.removeChild(_bone);
			}
		}
		
		skeletonNamespace function addToBones(_bone:Bone):void{
			var _boneName:String = _bone.name;
			if(_boneName){
				var _boneAdded:Bone = bones[_boneName];
				if (_boneAdded) {
				}
				bones[_boneName] = _bone;
			}
		}
		
		skeletonNamespace function removeFromBones(_bone:Bone):void{
			var _boneName:String = _bone.name;
			if(_boneName){
				delete bones[_boneName];
			}
		}
		
		public function updateBonesZ():void {
			var _boneList:Vector.<Bone> = new Vector.<Bone>;
			var _bone:Bone;
			for each(_bone in bones) {
				_boneList.push(_bone);
			}
			_boneList.sort(sortBoneZIndex);
			for each(_bone in _boneList) {
				if (_bone.display) {
					addDisplayChild(_bone.display, __display);
				}
			}
			bonesIndexChanged = false;
		}
		
		private function sortBoneZIndex(_bone1:Bone, _bone2:Bone):int {
			return _bone1.origin.z >= _bone2.origin.z?1: -1;
		}
	}
}