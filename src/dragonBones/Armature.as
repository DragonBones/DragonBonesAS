package dragonBones
{
	import dragonBones.animation.Animation;
	import dragonBones.utils.dragonBones_internal;
	import flash.events.EventDispatcher;
	
	use namespace dragonBones_internal;
	
	[Event(name="movementChange", type="dragonBones.events.AnimationEvent")]
	
	[Event(name="animationStart", type="dragonBones.events.AnimationEvent")]
	
	[Event(name="movementComplete", type="dragonBones.events.AnimationEvent")]
	
	[Event(name="movementLoopComplete", type="dragonBones.events.AnimationEvent")]
	
	[Event(name="movementFrameEvent", type="dragonBones.events.FrameEvent")]
	
	[Event(name="boneFrameEvent", type="dragonBones.events.FrameEvent")]
	
	/**
	 *
	 * @author Akdcl
	 */
	public class Armature extends EventDispatcher
	{
		public var name:String;
		public var userData:Object;
		
		public var animation:Animation;
		
		dragonBones_internal var _bonesIndexChanged:Boolean;
		dragonBones_internal var _boneDepthList:Vector.<Bone>;
		
		private var _rootBoneList:Vector.<Bone>;
		
		protected var _display:Object;
		public function get display():Object{
			return _display;
		}
		
		public function Armature(display:Object)
		{
			super();
			_display = display;
			
			_boneDepthList = new Vector.<Bone>;
			_rootBoneList = new Vector.<Bone>;
			
			animation = new Animation(this);
			_bonesIndexChanged = false;
		}
		
		public function dispose():void
		{
			for each(var bone:Bone in _rootBoneList)
			{
				bone.dispose();
			}
			
			animation.dispose();
			animation = null;
			//_display = null;
			
			_boneDepthList = null;
			_rootBoneList = null;
		}
		
		public function update():void
		{
			for each(var bone:Bone in _rootBoneList)
			{
				bone.update();
			}
			animation.update();
			
			if(_bonesIndexChanged)
			{
				updateBonesZ();
			}
		}
		
		public function getBone(name:String):Bone
		{
			if(name)
			{
				for each(var bone:Bone in _boneDepthList)
				{
					if(bone.name == name)
					{
						return bone;
					}
				}
			}
			return null;
		}
		
		public function getBoneByDisplay(display:Object):Bone
		{
			for each(var eachBone:Bone in _boneDepthList)
			{
				if(eachBone.display == display)
				{
					return eachBone;
				}
			}
			return null;
		}

		public function addBone(bone:Bone, parentName:String = null):void
		{
			var boneParent:Bone = getBone(parentName);
			if (boneParent)
			{
				boneParent.addChild(bone);
			}
			else
			{
				bone.removeFromParent();
				addToBones(bone, true);
			}
		}
		
		public function removeBone(boneName:String):void
		{
			var bone:Bone = getBone(boneName);
			if (bone)
			{
				if(bone.parent)
				{
					bone.removeFromParent();
				}
				else
				{
					removeFromBones(bone);
				}
			}
		}
		
		dragonBones_internal function addToBones(bone:Bone, _root:Boolean = false):void
		{
			var boneIndex:int = _boneDepthList.indexOf(bone);
			if(boneIndex < 0)
			{
				_boneDepthList.push(bone);
			}
			
			boneIndex = _rootBoneList.indexOf(bone);
			if(_root)
			{
				if(boneIndex < 0)
				{
					_rootBoneList.push(bone);
				}
			}else if(boneIndex >= 0)
			{
				_rootBoneList.splice(boneIndex, 1);
			}
			
			bone._armature = this;
			bone._displayBridge.addDisplay(_display, bone.global.z);
			for each(var child:Bone in bone._children)
			{
				addToBones(child);
			}
		}
		
		dragonBones_internal function removeFromBones(bone:Bone):void
		{
			var boneIndex:int = _boneDepthList.indexOf(bone);
			if(boneIndex >= 0)
			{
				_boneDepthList.splice(boneIndex, 1);
			}
			
			boneIndex = _rootBoneList.indexOf(bone);
			if(boneIndex >= 0)
			{
				_rootBoneList.splice(boneIndex, 1);
			}
			
			bone._armature = null;
			bone._displayBridge.removeDisplay();
			for each(var child:Bone in bone._children)
			{
				removeFromBones(child);
			}
		}
		
		
		public function updateBonesZ():void
		{
			_boneDepthList.sort(sortBoneZIndex);
			for each(var bone:Bone in _boneDepthList)
			{
				if(bone._displayVisible)
				{
					bone._displayBridge.addDisplay(_display);
				}
			}
			_bonesIndexChanged = false;
		}
		
		private function sortBoneZIndex(bone1:Bone, bone2:Bone):int
		{
			return bone1.global.z >= bone2.global.z?1: -1;
		}
	}
}