package dragonBones.animation
{
	import flash.geom.ColorTransform;
	
	import dragonBones.Slot;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.SlotFrameData;
	import dragonBones.objects.TweenFrameData;
	
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
		
		override protected function _onFadeIn():void
		{
			_slotColor = slot._colorTransform;
		}
		
		override protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
			super._onArriveAtFrame(isUpdate);
			
			if (this._animationState._isDisabled(slot))
			{
				this._tweenEasing = TweenFrameData.NO_TWEEN;
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
			
			if (slot.displayIndex >= 0)
			{
				_tweenColor = TWEEN_TYPE_NONE;
				
				const nextFrame:SlotFrameData = this._currentFrame.next as SlotFrameData;
				const currentColor:ColorTransform = currentFrame.color;
				
				if (this._keyFrameCount > 1 && (this._tweenEasing != TweenFrameData.NO_TWEEN || this._curve))
				{
					const nextColor:ColorTransform = nextFrame.color;
					if (currentColor != nextColor)
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
					_durationColor.alphaMultiplier = currentColor.alphaMultiplier - _slotColor.alphaMultiplier;
					_durationColor.redMultiplier = currentColor.redMultiplier - _slotColor.redMultiplier;
					_durationColor.greenMultiplier = currentColor.greenMultiplier - _slotColor.greenMultiplier;
					_durationColor.blueMultiplier = currentColor.blueMultiplier - _slotColor.blueMultiplier;
					_durationColor.alphaOffset = currentColor.alphaOffset - _slotColor.alphaOffset;
					_durationColor.redOffset = currentColor.redOffset - _slotColor.redOffset;
					_durationColor.greenOffset = currentColor.greenOffset - _slotColor.greenOffset;
					_durationColor.blueOffset = currentColor.blueOffset - _slotColor.blueOffset;
					
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
						_tweenColor = TWEEN_TYPE_ONCE;
					}
				}
			}
			else
			{
				this._tweenEasing = TweenFrameData.NO_TWEEN;
				this._curve = null;
				_tweenColor = TWEEN_TYPE_NONE;
			}
		}
		
		override protected function _onUpdateFrame(isUpdate:Boolean):void
		{
			super._onUpdateFrame(isUpdate);
			
			const currentFrame:SlotFrameData = this._currentFrame as SlotFrameData;
			
			if (_tweenColor)
			{
				if (_tweenColor == TWEEN_TYPE_ONCE)
				{
					_tweenColor = TWEEN_TYPE_NONE;
				}
				
				const currentColor:ColorTransform = currentFrame.color;
				_color.alphaMultiplier = currentColor.alphaMultiplier + _durationColor.alphaMultiplier * this._tweenProgress;
				_color.redMultiplier = currentColor.redMultiplier + _durationColor.redMultiplier * this._tweenProgress;
				_color.greenMultiplier = currentColor.greenMultiplier + _durationColor.greenMultiplier * this._tweenProgress;
				_color.blueMultiplier = currentColor.blueMultiplier + _durationColor.blueMultiplier * this._tweenProgress;
				_color.alphaOffset = currentColor.alphaOffset + _durationColor.alphaOffset * this._tweenProgress;
				_color.redOffset = currentColor.redOffset + _durationColor.redOffset * this._tweenProgress;
				_color.greenOffset = currentColor.greenOffset + _durationColor.greenOffset * this._tweenProgress;
				_color.blueOffset = currentColor.blueOffset + _durationColor.blueOffset * this._tweenProgress;
				
				_colorDirty = true;
			}
		}
		
		override public function fadeOut():void
		{
			_tweenColor = TWEEN_TYPE_NONE;
		}
		
		override public function update(time:int):void
		{
			super.update(time);
			
			if (_tweenColor != TWEEN_TYPE_NONE || _colorDirty)
			{
				const weight:Number = this._animationState._weightResult;
				if (weight > 0)
				{
					const fadeProgress:Number = this._animationState._fadeProgress;
					if (fadeProgress < 1)
					{
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