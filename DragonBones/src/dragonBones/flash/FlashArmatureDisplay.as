package dragonBones.flash
{
	import flash.display.Shape;
	import flash.display.Sprite;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.animation.Animation;
	import dragonBones.core.IArmatureDisplay;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.BoundingBoxType;
	import dragonBones.events.EventObject;
	import dragonBones.objects.BoundingBoxData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @inheritDoc
	 */
	public class FlashArmatureDisplay extends Sprite implements IArmatureDisplay
	{
		/**
		 * @private
		 */
		dragonBones_internal var _armature:Armature;
		
		private var _debugDrawer:Sprite;
		/**
		 * @private
		 */
		public function FlashArmatureDisplay()
		{
			super();
		}
		/**
		 * @private
		 */
		public function _onClear():void
		{
			_armature = null;
			_debugDrawer = null;
		}
		/**
		 * @private
		 */
		public function _dispatchEvent(type:String, eventObject:EventObject):void
		{
			const event:FlashEvent = new FlashEvent(type, eventObject);
			dispatchEvent(event);
		}
		/**
		 * @private
		 */
		public function _debugDraw(isEnabled:Boolean):void
		{
			if (isEnabled)
			{
				if (!_debugDrawer) 
				{
					_debugDrawer = new Sprite();
				}
				
				addChild(_debugDrawer);
				_debugDrawer.graphics.clear();
				
				const bones:Vector.<Bone> = _armature.getBones();
				for (var i:uint = 0, l:uint = bones.length; i < l; ++i) 
				{
					const bone:Bone = bones[i];
					const boneLength:Number = bone.length;
					const startX:Number = bone.globalTransformMatrix.tx;
					const startY:Number = bone.globalTransformMatrix.ty;
					const endX:Number = startX + bone.globalTransformMatrix.a * boneLength;
					const endY:Number = startY + bone.globalTransformMatrix.b * boneLength;
					
					_debugDrawer.graphics.lineStyle(2.0, bone.ik ? 0xFF0000 : 0x00FFFF, 0.7);
					_debugDrawer.graphics.moveTo(startX, startY);
					_debugDrawer.graphics.lineTo(endX, endY);
					_debugDrawer.graphics.lineStyle(0.0, 0, 0);
					_debugDrawer.graphics.beginFill(0x00FFFF, 0.7);
					_debugDrawer.graphics.drawCircle(startX, startY, 3.0);
					_debugDrawer.graphics.endFill();
				}
				
				const slots:Vector.<Slot> = _armature.getSlots();
				for (i = 0, l = slots.length; i < l; ++i) 
				{
					const slot:Slot = slots[i];
					const boundingBoxData:BoundingBoxData = slot.boundingBoxData;
					
					if (boundingBoxData) 
					{
						var child:Shape = _debugDrawer.getChildByName(slot.name) as Shape;
						if (!child) 
						{
							child = new Shape();
							child.name = slot.name;
							_debugDrawer.addChild(child);
						}
						
						child.graphics.clear();
						child.graphics.beginFill(boundingBoxData.color ? boundingBoxData.color : 0xFF00FF, 0.3);
						
						switch (boundingBoxData.type) 
						{
							case BoundingBoxType.Rectangle:
								child.graphics.drawRect(-boundingBoxData.width * 0.5, -boundingBoxData.height * 0.5, boundingBoxData.width, boundingBoxData.height);
								break;
							
							case BoundingBoxType.Ellipse:
								child.graphics.drawEllipse(-boundingBoxData.width * 0.5, -boundingBoxData.height * 0.5, boundingBoxData.width, boundingBoxData.height);
								break;
							
							case BoundingBoxType.Polygon:
								const vertices:Vector.<Number> = boundingBoxData.vertices;
								for (var iA:uint = 0, lA:uint = boundingBoxData.vertices.length; iA < lA; iA += 2) 
								{
									if (iA === 0) 
									{
										child.graphics.moveTo(vertices[iA], vertices[iA + 1]);
									}
									else 
									{
										child.graphics.lineTo(vertices[iA], vertices[iA + 1]);
									}
								}
								break;
							
							default:
							break;
						}
						
						child.graphics.endFill();
						slot._updateTransformAndMatrix();
						child.transform.matrix = slot.globalTransformMatrix;
					}
					else
					{
						child = _debugDrawer.getChildByName(slot.name) as Shape;
						if (child) 
						{
							_debugDrawer.removeChild(child);
						}
					}
				}
			}
			else if (_debugDrawer && _debugDrawer.parent === this)
			{
				removeChild(_debugDrawer);
			}
		}
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			if (_armature)
			{
				_armature.dispose();
				_armature = null;
			}
		}
		/**
		 * @inheritDoc
		 */
		public function hasEvent(type:String):Boolean
		{
			return hasEventListener(type);
		}
		/**
		 * @inheritDoc
		 */
		public function addEvent(type:String, listener:Function):void
		{
			addEventListener(type, listener);
		}
		/**
		 * @inheritDoc
		 */
		public function removeEvent(type:String, listener:Function):void
		{
			removeEventListener(type, listener);
		}
		/**
		 * @inheritDoc
		 */
		public function get armature():Armature
		{
			return _armature;
		}
		/**
		 * @inheritDoc
		 */
		public function get animation():Animation
		{
			return _armature.animation;
		}
		
		/**
		 * @deprecated
		 */
		public function advanceTimeBySelf(on:Boolean):void
		{
			if (on)
			{
				_armature.clock = FlashFactory._clock;
			} 
			else 
			{
				_armature.clock = null;
			}
		}
	}
}