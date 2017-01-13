package dragonBones.animation
{
	import flash.geom.ColorTransform;
	
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.SlotFrameData;
	import dragonBones.objects.TimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public final class SlotTimelineState extends TweenTimelineState
	{
		public var slot:Slot;
		
		private var _colorDirty:Boolean;
		private var _tweenColor:int;
		private const _color:ColorTransform = new ColorTransform();
		private const _durationColor:ColorTransform = new ColorTransform();
		private var _slotColor:ColorTransform;
		
		public function SlotTimelineState()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			slot = null;
			
			_colorDirty = false;
			_tweenColor = TWEEN_TYPE_NONE;
			_color.alphaMultiplier = 1;
			_color.redMultiplier = 1;
			_color.greenMultiplier = 1;
			_color.blueMultiplier = 1;
			_color.alphaOffset = 0;
			_color.redOffset = 0;
			_color.greenOffset = 0;
			_color.blueOffset = 0;
			_durationColor.alphaMultiplier = 1;
			_durationColor.redMultiplier = 1;
			_durationColor.greenMultiplier = 1;
			_durationColor.blueMultiplier = 1;
			_durationColor.alphaOffset = 0;
			_durationColor.redOffset = 0;
			_durationColor.greenOffset = 0;
			_durationColor.blueOffset = 0;
			_slotColor = null;
		}
		
		override protected function _onArriveAtFrame():void
		{
			super._onArriveAtFrame();
			
			if (_animationState._isDisabled(slot))
			{
				_tweenEasing = DragonBones.NO_TWEEN;
				_curve = null;
				_tweenColor = TWEEN_TYPE_NONE;
				return;
			}
			
			const currentFrame:SlotFrameData = _currentFrame as SlotFrameData;
			const displayIndex:int = currentFrame.displayIndex;
			if (_playState >= 0 && slot.displayIndex !== displayIndex) 
			{
				slot._setDisplayIndex(displayIndex);
			}
			
			if (displayIndex >= 0)
			{
				_tweenColor = TWEEN_TYPE_NONE;
				
				const currentColor:ColorTransform = currentFrame.color;
				
				if (_tweenEasing !== DragonBones.NO_TWEEN || _curve)
				{
					const nextFrame:SlotFrameData = currentFrame.next as SlotFrameData;
					const nextColor:ColorTransform = nextFrame.color;
					if (currentColor !== nextColor)
					{
						_durationColor.alphaMultiplier = nextColor.alphaMultiplier - currentColor.alphaMultiplier;
						_durationColor.redMultiplier = nextColor.redMultiplier - currentColor.redMultiplier;
						_durationColor.greenMultiplier = nextColor.greenMultiplier - currentColor.greenMultiplier;
						_durationColor.blueMultiplier = nextColor.blueMultiplier - currentColor.blueMultiplier;
						_durationColor.alphaOffset = nextColor.alphaOffset - currentColor.alphaOffset;
						_durationColor.redOffset = nextColor.redOffset - currentColor.redOffset;
						_durationColor.greenOffset = nextColor.greenOffset - currentColor.greenOffset;
						_durationColor.blueOffset = nextColor.blueOffset - currentColor.blueOffset;
						
						if (
							_durationColor.alphaMultiplier !== 0.0 ||
							_durationColor.redMultiplier !== 0.0 ||
							_durationColor.greenMultiplier !== 0.0 ||
							_durationColor.blueMultiplier !== 0.0 ||
							_durationColor.alphaOffset !== 0 ||
							_durationColor.redOffset !== 0 ||
							_durationColor.greenOffset !== 0 ||
							_durationColor.blueOffset !== 0
						)
						{
							_tweenColor = TWEEN_TYPE_ALWAYS;
						}
					}
				}
				
				if (_tweenColor === TWEEN_TYPE_NONE)
				{
					if (
						_slotColor.alphaMultiplier !== currentColor.alphaMultiplier ||
						_slotColor.redMultiplier !== currentColor.redMultiplier ||
						_slotColor.greenMultiplier !== currentColor.greenMultiplier ||
						_slotColor.blueMultiplier !== currentColor.blueMultiplier ||
						_slotColor.alphaOffset !== currentColor.alphaOffset ||
						_slotColor.redOffset !== currentColor.redOffset ||
						_slotColor.greenOffset !== currentColor.greenOffset ||
						_slotColor.blueOffset !== currentColor.blueOffset
					)
					{
						_tweenColor = TWEEN_TYPE_ONCE;
					}
				}
			}
			else
			{
				_tweenEasing = DragonBones.NO_TWEEN;
				_curve = null;
				_tweenColor = TWEEN_TYPE_NONE;
			}
		}
		
		override protected function _onUpdateFrame():void
		{
			super._onUpdateFrame();
			
			const currentFrame:SlotFrameData = _currentFrame as SlotFrameData;
			
			var tweenProgress:Number = 0.0;
			
			if (_tweenColor !== TWEEN_TYPE_NONE && slot.parent._blendLayer >= _animationState._layer)
			{
				if (_tweenColor === TWEEN_TYPE_ONCE)
				{
					_tweenColor = TWEEN_TYPE_NONE;
					tweenProgress = 0;
				}
				else
				{
					tweenProgress = _tweenProgress;
				}
				
				const currentColor:ColorTransform = currentFrame.color;
				_color.alphaMultiplier = currentColor.alphaMultiplier + _durationColor.alphaMultiplier * tweenProgress;
				_color.redMultiplier = currentColor.redMultiplier + _durationColor.redMultiplier * tweenProgress;
				_color.greenMultiplier = currentColor.greenMultiplier + _durationColor.greenMultiplier * tweenProgress;
				_color.blueMultiplier = currentColor.blueMultiplier + _durationColor.blueMultiplier * tweenProgress;
				_color.alphaOffset = currentColor.alphaOffset + _durationColor.alphaOffset * tweenProgress;
				_color.redOffset = currentColor.redOffset + _durationColor.redOffset * tweenProgress;
				_color.greenOffset = currentColor.greenOffset + _durationColor.greenOffset * tweenProgress;
				_color.blueOffset = currentColor.blueOffset + _durationColor.blueOffset * tweenProgress;
				
				_colorDirty = true;
			}
		}
		
		override public function _init(armature:Armature, animationState:AnimationState, timelineData:TimelineData):void
		{
			super._init(armature, animationState, timelineData);
			
			_slotColor = slot._colorTransform;
		}
		
		override public function fadeOut():void
		{
			_tweenColor = TWEEN_TYPE_NONE;
		}
		
		override public function update(passedTime:Number):void
		{
			super.update(passedTime);
			
			// Fade animation.
			if (_tweenColor !== TWEEN_TYPE_NONE || _colorDirty)
			{
				if (_animationState._fadeState !== 0 || _animationState._subFadeState !== 0)
				{
					const fadeProgress:Number = _animationState._fadeProgress;
					
					_slotColor.alphaMultiplier += (_color.alphaMultiplier - _slotColor.alphaMultiplier) * fadeProgress;
					_slotColor.redMultiplier += (_color.redMultiplier - _slotColor.redMultiplier) * fadeProgress;
					_slotColor.greenMultiplier += (_color.greenMultiplier - _slotColor.greenMultiplier) * fadeProgress;
					_slotColor.blueMultiplier += (_color.blueMultiplier - _slotColor.blueMultiplier) * fadeProgress;
					_slotColor.alphaOffset += (_color.alphaOffset - _slotColor.alphaOffset) * fadeProgress;
					_slotColor.redOffset += (_color.redOffset - _slotColor.redOffset) * fadeProgress;
					_slotColor.greenOffset += (_color.greenOffset - _slotColor.greenOffset) * fadeProgress;
					_slotColor.blueOffset += (_color.blueOffset - _slotColor.blueOffset) * fadeProgress;
					
					slot._colorDirty = true;
				}
				else if (_colorDirty)
				{
					_colorDirty = false;
					
					_slotColor.alphaMultiplier = _color.alphaMultiplier;
					_slotColor.redMultiplier = _color.redMultiplier;
					_slotColor.greenMultiplier = _color.greenMultiplier;
					_slotColor.blueMultiplier = _color.blueMultiplier;
					_slotColor.alphaOffset = _color.alphaOffset;
					_slotColor.redOffset = _color.redOffset;
					_slotColor.greenOffset = _color.greenOffset;
					_slotColor.blueOffset = _color.blueOffset;
					
					slot._colorDirty = true;
				}
			}
		}
	}
}