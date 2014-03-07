package dragonBones
{
	import flash.geom.Point;
	
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.TimelineState;
	import dragonBones.core.DBObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.Frame;
	import dragonBones.objects.TransformFrame;
	
	use namespace dragonBones_internal;
	
	public class Bone extends DBObject
	{
		/**
		 * The instance dispatch sound event.
		 */
		private static const _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		/**
		 * 骨骼的缩放模式，默认为1，当为2时，bone的缩放将影响所有子bone和子slot的缩放，当为1时，只影响slot的缩放，为0时都不影响，
		 * Bone's scaleMode, could be 0, 1(default) or 2. 
		 * scaleMode equals to 0: Bone's scale impact nothing.
		 * scaleMode equals to 1: Bone's scale impact its slots.
		 * scaleMode equals to 2: Bone's scale impact its child bones and slots.
		 */
		public var scaleMode:int;
		
		/** @private */
		dragonBones_internal var _tweenPivot:Point;
		
		private var _children:Vector.<DBObject>;
		
		private var _slot:Slot;
		/**
		 * The first slot of this Bone instance.
		 */
		public function get slot():Slot
		{
			return _slot;
		}
		
		/**
		 * childArmature, keep this API for v2.2 compatibility
		 */
		public function get childArmature():Armature
		{
			return _slot?_slot.childArmature:null; 
		}
		
		/**
		 * display object, keep this API for v2.2 compatibility
		 */
		public function get display():Object
		{
			return _slot?_slot.display:null;
		}
		public function set display(value:Object):void
		{
			if(_slot)
			{
				_slot.display = value;
			}
		}
		
		/**
		 * AnimationState that slots belong to the bone will be controlled by.
		 * Sometimes, we want slots controlled by a spedific animation state when animation is doing mix or addition.
		 */
		public var displayController:String;
		
		/**
		 * @inheritDoc
		 */
		override public function set visible(value:Boolean):void
		{
			if(this._visible != value)
			{
				this._visible = value;
				var i:int = _children.length;
				while(i --)
				{
					var child:DBObject = _children[i];
					if(child is Slot)
					{
						(child as Slot).updateVisible(this._visible);
					}
				}
			}
		}
		
		/** @private */
		override dragonBones_internal function setArmature(value:Armature):void
		{
			super.setArmature(value);
			var i:int = _children.length;
			while(i --)
			{
				_children[i].setArmature(this._armature);
			}
		}
		
		/**
		 * Creates a Bone blank instance.
		 */
		public function Bone()
		{
			super();
			_children = new Vector.<DBObject>(0, true);
			_scaleType = 2;
			
			_tweenPivot = new Point();
			
			scaleMode = 1;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if(!_children)
			{
				return;
			}
			super.dispose();
			
			var i:int = _children.length;
			while(i --)
			{
				_children[i].dispose();
			}
			_children.fixed = false;
			_children.length = 0;
			
			_children = null;
			_slot = null;
			_tweenPivot = null;
		}
		
		/**
		 * If contains some bone or slot
		 * @param Slot or Bone instance
		 * @return Boolean
		 * @see dragonBones.core.DBObject
		 */
		public function contains(child:DBObject):Boolean
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			if(child == this)
			{
				return false;
			}
			var ancestor:DBObject = child;
			while (!(ancestor == this || ancestor == null))
			{
				ancestor = ancestor.parent;
			}
			return ancestor == this;
		}
		
		/**
		 * Add a bone or slot as child
		 * @param a Slot or Bone instance
		 * @see dragonBones.core.DBObject
		 */
		public function addChild(child:DBObject):void
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			
			if(child == this || (child is Bone && (child as Bone).contains(this)))
			{
				throw new ArgumentError("An Bone cannot be added as a child to itself or one of its children (or children's children, etc.)");
			}
			
			if(child.parent)
			{
				child.parent.removeChild(child);
			}
			_children.fixed = false;
			_children[_children.length] = child;
			_children.fixed = true;
			child.setParent(this);
			child.setArmature(this._armature);
			
			if(!_slot && child is Slot)
			{
				_slot = child as Slot;
			}
		}
		
		/**
		 * remove a child bone or slot
		 * @param a Slot or Bone instance
		 * @see dragonBones.core.DBObject
		 */
		public function removeChild(child:DBObject):void
		{
			if(!child)
			{
				throw new ArgumentError();
			}
			
			var index:int = _children.indexOf(child);
			if (index >= 0)
			{
				_children.fixed = false;
				_children.splice(index, 1);
				_children.fixed = true;
				child.setParent(null);
				child.setArmature(null);
				
				if(child == _slot)
				{
					_slot = null;
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
		
		/**
		 * Get all Slot instance associated with this bone.
		 * @return A Vector.&lt;Slot&gt; instance.
		 * @see dragonBones.Slot
		 */
		public function getSlots():Vector.<Slot>
		{
			var slotList:Vector.<Slot> = new Vector.<Slot>;
			var i:int = _children.length;
			while(i --)
			{
				if(_children[i] is Slot)
				{
					slotList.unshift(_children[i]);
				}
			}
			return slotList;
		}
		
		/** @private When bone timeline enter a key frame, call this func*/
		dragonBones_internal function arriveAtFrame(frame:Frame, timelineState:TimelineState, animationState:AnimationState, isCross:Boolean):void
		{
			if(frame)
			{
				var mixingType:int = animationState.getMixingTransform(name);
				if(animationState.displayControl && (mixingType == 2 || mixingType == -1))
				{
					if(
						!displayController || displayController == animationState.name
					)
					{
						var tansformFrame:TransformFrame = frame as TransformFrame;
						if(_slot)
						{
							var displayIndex:int = tansformFrame.displayIndex;
							if(displayIndex >= 0)
							{
								if(!isNaN(tansformFrame.zOrder) && tansformFrame.zOrder != _slot._tweenZorder)
								{
									_slot._tweenZorder = tansformFrame.zOrder;
									this._armature._slotsZOrderChanged = true;
								}
							}
							_slot.changeDisplay(displayIndex);
							_slot.updateVisible(tansformFrame.visible);
						}
					}
				}
				
				if(frame.event && this._armature.hasEventListener(FrameEvent.BONE_FRAME_EVENT))
				{
					var frameEvent:FrameEvent = new FrameEvent(FrameEvent.BONE_FRAME_EVENT);
					frameEvent.bone = this;
					frameEvent.animationState = animationState;
					frameEvent.frameLabel = frame.event;
					this._armature._eventList.push(frameEvent);
				}
				
				if(frame.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
				{
					var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
					soundEvent.armature = this._armature;
					soundEvent.animationState = animationState;
					soundEvent.sound = frame.sound;
					_soundManager.dispatchEvent(soundEvent);
				}
				
				//[TODO]currently there is only gotoAndPlay belongs to frame action. In future, there will be more.  
				//后续会扩展更多的action，目前只有gotoAndPlay的含义
				if(frame.action) 
				{
					for each(var child:DBObject in _children)
					{
						if(child is Slot)
						{
							var childArmature:Armature = (child as Slot).childArmature;
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
				if(_slot)
				{
					_slot.changeDisplay(-1);
				}
			}
		}
		
		/** @private */
		dragonBones_internal function updateColor(
			aOffset:Number, 
			rOffset:Number, 
			gOffset:Number, 
			bOffset:Number, 
			aMultiplier:Number, 
			rMultiplier:Number, 
			gMultiplier:Number, 
			bMultiplier:Number,
			isColorChanged:Boolean
		):void
		{
			if(isColorChanged || _isColorChanged)
			{
				_slot._displayBridge.updateColor(
					aOffset, 
					rOffset, 
					gOffset, 
					bOffset, 
					aMultiplier, 
					rMultiplier, 
					gMultiplier, 
					bMultiplier
				);
			}
			_isColorChanged = isColorChanged;
		}
	}
}