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
		private var _slotColor:ColorTransform;
		private const _color:ColorTransform = new ColorTransform();
		private const _durationColor:ColorTransform = new ColorTransform();
		
		public function SlotTimelineState()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			slot = null;
			
			_colorDirty = false;
			_tweenColor = TWEEN_TYPE_NONE;
			_slotColor = null;
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
		}
		
		override protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
			super._onArriveAtFrame(isUpdate);
			
			if (this._animationState._isDisabled(slot))
			{
				this._tweenEasing = DragonBones.NO_TWEEN;
				this._curve = null;
				_tweenColor = TWEEN_TYPE_NONE;
				return;
			}
			
			const currentFrame:SlotFrameData = this._currentFrame as SlotFrameData;
			
			if (slot._displayDataSet)
			{
				const displayIndex:int = currentFrame.displayIndex;
				if (slot.displayIndex >= 0 && displayIndex >= 0)
				{
					if (slot._displayDataSet.displays.length > 1)
					{
						slot._setDisplayIndex(displayIndex);
					}
				}
				else
				{
					slot._setDisplayIndex(displayIndex);
				}
				
				slot._updateMeshData(true);
			}
			
			if (currentFrame.displayIndex >= 0)
			{
				_tweenColor = TWEEN_TYPE_NONE;
				
				const currentColor:ColorTransform = currentFrame.color;
				
				if (this._keyFrameCount > 1 && (this._tweenEasing != DragonBones.NO_TWEEN || this._curve))
				{
					const nextFrame:SlotFrameData = this._currentFrame.next as SlotFrameData;
					const nextColor:ColorTransform = nextFrame.color;
					if (currentColor != nextColor && nextFrame.displayIndex >= 0)
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
							_durationColor.alphaMultiplier != 0 ||
							_durationColor.redMultiplier != 0 ||
							_durationColor.greenMultiplier != 0 ||
							_durationColor.blueMultiplier != 0 ||
							_durationColor.alphaOffset != 0 ||
							_durationColor.redOffset != 0 ||
							_durationColor.greenOffset != 0 ||
							_durationColor.blueOffset != 0
						)
						{
							_tweenColor = TWEEN_TYPE_ALWAYS;
						}
					}
				}
				
				if (_tweenColor == TWEEN_TYPE_NONE)
				{
					if (
						_slotColor.alphaMultiplier != currentColor.alphaMultiplier ||
						_slotColor.redMultiplier != currentColor.redMultiplier ||
						_slotColor.greenMultiplier != currentColor.greenMultiplier ||
						_slotColor.blueMultiplier != currentColor.blueMultiplier ||
						_slotColor.alphaOffset != currentColor.alphaOffset ||
						_slotColor.redOffset != currentColor.redOffset ||
						_slotColor.greenOffset != currentColor.greenOffset ||
						_slotColor.blueOffset != currentColor.blueOffset
					)
					{
						_tweenColor = TWEEN_TYPE_ONCE;
					}
				}
			}
			else
			{
				this._tweenEasing = DragonBones.NO_TWEEN;
				this._curve = null;
				_tweenColor = TWEEN_TYPE_NONE;
			}
		}
		
		override protected function _onUpdateFrame(isUpdate:Boolean):void
		{
			super._onUpdateFrame(isUpdate);
			
			const currentFrame:SlotFrameData = this._currentFrame as SlotFrameData;
			
			var tweenProgress:Number = 0;
			
			if (_tweenColor)
			{
				if (_tweenColor == TWEEN_TYPE_ONCE)
				{
					_tweenColor = TWEEN_TYPE_NONE;
					tweenProgress = 0;
				}
				else
				{
					tweenProgress = this._tweenProgress;
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
		
		override public function fadeIn(armature:Armature, animationState:AnimationState, timelineData:TimelineData, time:Number):void
		{
			super.fadeIn(armature, animationState, timelineData, time);
			
			_slotColor = slot._colorTransform;
		}
		
		override public function fadeOut():void
		{
			_tweenColor = TWEEN_TYPE_NONE;
		}
		
		override public function update(time:Number):void
		{
			super.update(time);
			
			if (_tweenColor != TWEEN_TYPE_NONE || _colorDirty)
			{
				const weight:Number = this._animationState._weightResult;
				if (weight > 0)
				{
					if (this._animationState._fadeState != 0)
					{
						const fadeProgress:Number = this._animationState._fadeProgress;
						
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
}