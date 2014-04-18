package dragonBones
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.TimelineState;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.BoneFrameCached;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.Frame;
	import dragonBones.objects.TransformFrame;
	
	use namespace dragonBones_internal;
	
	public class Bone
	{
		/**
		 * The instance dispatch sound event.
		 */
		private static const _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		
		public var name:String;
		
		/**
		 * An object that can contain any user extra data.
		 */
		public var userData:Object;
		
		/**
		 * 
		 */
		public var inheritRotation:Boolean;
		
		/**
		 * 
		 */
		public var inheritScale:Boolean;
		
		/**
		 * AnimationState that slots belong to the bone will be controlled by.
		 * Sometimes, we want slots controlled by a spedific animation state when animation is doing mix or addition.
		 */
		public var displayController:String;
		
		/** @private */
		dragonBones_internal var _globalTransformMatrix:Matrix;
		
		/** @private */
		dragonBones_internal var _tween:DBTransform;
		
		/** @private */
		dragonBones_internal var _tweenPivot:Point;
		
		/** @private */
		dragonBones_internal var _needUpdate:int;
		
		/** @private */
		dragonBones_internal var _frameCached:BoneFrameCached;
		
		/** @private */
		protected var _slotList:Vector.<Slot>;
		
		/** @private */
		protected var _global:DBTransform;
		/**
		 * This DBObject instance global transform instance.
		 * @see dragonBones.objects.DBTransform
		 */
		public function get global():DBTransform
		{
			return _global;
		}
		
		/** @private */
		protected var _origin:DBTransform;
		/**
		 * This DBObject instance origin transform instance.
		 * @see dragonBones.objects.DBTransform
		 */
		public function get origin():DBTransform
		{
			return _origin;
		}
		
		/** @private */
		protected var _offset:DBTransform;
		/**
		 * This DBObject instance offset transform instance.
		 * @see dragonBones.objects.DBTransform
		 */
		public function get offset():DBTransform
		{
			return _offset;
		}
		
		/** @private */
		protected var _visible:Boolean;
		public function get visible():Boolean
		{
			return _visible;
		}
		public function set visible(value:Boolean):void
		{
			_visible = value;
			if(_visible != value)
			{
				_visible = value;
				
				for each(var slot:Slot in _slotList)
				{
					slot.updateDisplayVisible(_visible);
				}
			}
		}
		
		/** @private */
		protected var _armature:Armature;
		/**
		 * The armature this Bone instance belongs to.
		 */
		public function get armature():Armature
		{
			return _armature;
		}
		/** @private */
		dragonBones_internal function setArmature(value:Armature):void
		{
			_armature = value;
		}
		
		/** @private */
		protected var _parent:Bone;
		/**
		 * Indicates the Bone instance that directly contains this Bone instance if any.
		 */
		public function get parent():Bone
		{
			return _parent;
		}
		/** @private */
		dragonBones_internal function setParent(value:Bone):void
		{
			_parent = value;
		}
		
		public function get slot():Slot
		{
			return _slotList.length > 0?_slotList[0]:null;
		}
		
		/**
		 * Creates a Bone blank instance.
		 */
		public function Bone()
		{
			_global = new DBTransform();
			_origin = new DBTransform();
			_offset = new DBTransform();
			_tween = new DBTransform();
			_tweenPivot = new Point();
			_globalTransformMatrix = new Matrix();
			_offset.scaleX = _offset.scaleY = 1;
			_tween.scaleX = _tween.scaleY = 0;
			
			_slotList = new Vector.<Slot>;
			_slotList.fixed = true;
			
			_armature = null;
			_parent = null;
			_frameCached = null;
			
			_visible = true;
			_needUpdate = 2;
			
			inheritRotation = true;
			inheritScale = false;
			
			userData = null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			userData = null;
			
			_armature = null;
			_parent = null;
			_frameCached = null;
			
			_global = null;
			_origin = null;
			_offset = null;
			_tween = null;
			_tweenPivot = null;
			_globalTransformMatrix = null;
			
			_slotList.fixed = false;
			_slotList.length = 0;
			_slotList = null;
		}
		
		/**
		 * 当没有transform的改变时，将不会再更新，通过调用这个方法，让bone在下一帧更新transform
		 */
		public function invalidUpdate():void
		{
			_needUpdate = 2;
		}
		
		public function contains(bone:Bone):Boolean
		{
			if(!bone)
			{
				throw new ArgumentError();
			}
			if(bone == this)
			{
				return false;
			}
			var ancestor:Bone = bone;
			while (!(ancestor == this || ancestor == null))
			{
				ancestor = ancestor.parent;
			}
			return ancestor == this;
		}
		
		public function getBones():Vector.<Bone>
		{
			var boneList:Vector.<Bone> = new Vector.<Bone>;
			var armatureBoneList:Vector.<Bone> = _armature.getBones(false);
			var i:int = armatureBoneList.length;
			while(i --)
			{
				var bone:Bone = armatureBoneList[i];
				if(bone.parent == this)
				{
					boneList[boneList.length] = bone;
				}
			}
			
			return boneList;
		}
		
		public function getSlots(returnCopy:Boolean = true):Vector.<Slot>
		{
			return returnCopy?_slotList.concat():_slotList;
		}
		
		/** @private */
		dragonBones_internal function addSlot(slot:Slot):void
		{
			if(_slotList.indexOf(slot) < 0)
			{
				_slotList.fixed = false;
				_slotList[_slotList.length] = slot;
				_slotList.fixed = true;
			}
		}
		/** @private */
		dragonBones_internal function removeSlot(slot:Slot):void
		{
			var index:int = _slotList.indexOf(slot);
			if(index < 0)
			{
				_slotList.fixed = false;
				_slotList.splice(index, 1);
				_slotList.fixed = true;
			}
		}
		
		/** @private */
		dragonBones_internal function update():void
		{
			_needUpdate --;
			if(_needUpdate > 0)
			{
			}
			else if(_parent && _parent._needUpdate > 0)
			{
				_needUpdate = 1;
			}
			else
			{
				return;
			}
			
			if(_frameCached && _frameCached.matrix)
			{
				_global.copy(_frameCached.transform);
				_globalTransformMatrix.copyFrom(_frameCached.matrix);
				return;
			}
			
			_global.scaleX = (_origin.scaleX + _tween.scaleX) * _offset.scaleX;
			_global.scaleY = (_origin.scaleY + _tween.scaleY) * _offset.scaleY;
			
			if(_parent)
			{
				var x:Number = _origin.x + _offset.x + _tween.x;
				var y:Number = _origin.y + _offset.y + _tween.y;
				var parentMatrix:Matrix = _parent._globalTransformMatrix;
				
				_globalTransformMatrix.tx = _global.x = parentMatrix.a * x + parentMatrix.c * y + parentMatrix.tx;
				_globalTransformMatrix.ty = _global.y = parentMatrix.d * y + parentMatrix.b * x + parentMatrix.ty;
				
				if(inheritRotation)
				{
					_global.skewX = _origin.skewX + _offset.skewX + _tween.skewX + _parent._global.skewX;
					_global.skewY = _origin.skewY + _offset.skewY + _tween.skewY + _parent._global.skewY;
				}
				else
				{
					_global.skewX = _origin.skewX + _offset.skewX + _tween.skewX;
					_global.skewY = _origin.skewY + _offset.skewY + _tween.skewY;
				}
				
				if(inheritScale)
				{
					_global.scaleX *= _parent._global.scaleX;
					_global.scaleY *= _parent._global.scaleY;
				}
			}
			else
			{
				_globalTransformMatrix.tx = _global.x = _origin.x + _offset.x + _tween.x;
				_globalTransformMatrix.ty = _global.y = _origin.y + _offset.y + _tween.y;
				
				_global.skewX = _origin.skewX + _offset.skewX + _tween.skewX;
				_global.skewY = _origin.skewY + _offset.skewY + _tween.skewY;
			}
			
			_globalTransformMatrix.a = _global.scaleX * Math.cos(_global.skewY);
			_globalTransformMatrix.b = _global.scaleX * Math.sin(_global.skewY);
			_globalTransformMatrix.c = -_global.scaleY * Math.sin(_global.skewX);
			_globalTransformMatrix.d = _global.scaleY * Math.cos(_global.skewX);
			
			if(_frameCached)
			{
				_frameCached.transform = new DBTransform();
				_frameCached.matrix = new Matrix();
				_frameCached.transform.copy(_global);
				_frameCached.matrix.copyFrom(_globalTransformMatrix);
			}
		}
		
		/** @private When bone timeline enter a key frame, call this func*/
		dragonBones_internal function arriveAtFrame(frame:Frame, timelineState:TimelineState, animationState:AnimationState, isCross:Boolean):void
		{
			var slot:Slot;
			if(frame)
			{
				var mixingType:int = animationState.getMixingTransform(name);
				if(animationState.displayControl && mixingType == 0)
				{
					if(
						!displayController || displayController == animationState.name
					)
					{
						var tansformFrame:TransformFrame = frame as TransformFrame;
						var defaultSlot:Slot;
						for each(slot in _slotList)
						{
							if(!defaultSlot)
							{
								defaultSlot = slot;
							}
							slot.updateDisplayVisible(tansformFrame.visible);
						}
						
						if(defaultSlot)
						{
							var displayIndex:int = tansformFrame.displayIndex;
							if(displayIndex >= 0)
							{
								if(!isNaN(tansformFrame.zOrder) && tansformFrame.zOrder != defaultSlot._tweenZorder)
								{
									defaultSlot._tweenZorder = tansformFrame.zOrder;
									_armature._slotsZOrderChanged = true;
								}
							}
							defaultSlot.changeDisplay(displayIndex);
						}
					}
				}
				
				if(frame.event && _armature.hasEventListener(FrameEvent.BONE_FRAME_EVENT))
				{
					var frameEvent:FrameEvent = new FrameEvent(FrameEvent.BONE_FRAME_EVENT);
					frameEvent.bone = this;
					frameEvent.animationState = animationState;
					frameEvent.frameLabel = frame.event;
					_armature._eventList.push(frameEvent);
				}
				
				if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
				{
					var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
					soundEvent.armature = _armature;
					soundEvent.animationState = animationState;
					soundEvent.sound = frame.sound;
					_soundManager.dispatchEvent(soundEvent);
				}
				
				//[TODO]currently there is only gotoAndPlay belongs to frame action. In future, there will be more.  
				//后续会扩展更多的action，目前只有gotoAndPlay的含义
				if(frame.action) 
				{
					if(animationState.displayControl)
					{
						for each(slot in _slotList)
						{
							var childArmature:Armature = slot.childArmature;
							if(childArmature)
							{
								childArmature.animation.gotoAndPlay(frame.action);
							}
						}
					}
				}
			}
			else
			{
				for each(slot in _slotList)
				{
					slot.changeDisplay(-1);
				}
			}
		}
	}
}