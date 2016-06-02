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
		
		private var _tweenColor:int;
		private var _slotColor:ColorTransform;
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
			
			_tweenColor = TWEEN_TYPE_NONE;
			_slotColor = null;
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
				
				if (_tweenColor == TWEEN_TYPE_NONE &&
					(
						currentColor.alphaMultiplier - _slotColor.alphaMultiplier != 0 ||
						currentColor.redMultiplier - _slotColor.redMultiplier != 0 ||
						currentColor.greenMultiplier - _slotColor.greenMultiplier != 0 ||
						currentColor.blueMultiplier - _slotColor.blueMultiplier != 0 ||
						currentColor.alphaOffset - _slotColor.alphaOffset != 0 ||
						currentColor.redOffset - _slotColor.redOffset != 0 ||
						currentColor.greenOffset - _slotColor.greenOffset != 0 ||
						currentColor.blueOffset - _slotColor.blueOffset != 0
					)
				)
				{
					_tweenColor = TWEEN_TYPE_ONCE;
					
					_durationColor.alphaMultiplier = 0;
					_durationColor.redMultiplier = 0;
					_durationColor.greenMultiplier = 0;
					_durationColor.blueMultiplier = 0;
					_durationColor.alphaOffset = 0;
					_durationColor.redOffset = 0;
					_durationColor.greenOffset = 0;
					_durationColor.blueOffset = 0;
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
			
			if (_tweenColor && this._animationState._fadeProgress >= 1)
			{
				if (_tweenColor == TWEEN_TYPE_ONCE)
				{
					_tweenColor = TWEEN_TYPE_NONE;
				}
				
				const currentColor:ColorTransform = currentFrame.color;
				_slotColor.alphaMultiplier = currentColor.alphaMultiplier + _durationColor.alphaMultiplier * this._tweenProgress;
				_slotColor.redMultiplier = currentColor.redMultiplier + _durationColor.redMultiplier * this._tweenProgress;
				_slotColor.greenMultiplier = currentColor.greenMultiplier + _durationColor.greenMultiplier * this._tweenProgress;
				_slotColor.blueMultiplier = currentColor.blueMultiplier + _durationColor.blueMultiplier * this._tweenProgress;
				_slotColor.alphaOffset = currentColor.alphaOffset + _durationColor.alphaOffset * this._tweenProgress;
				_slotColor.redOffset = currentColor.redOffset + _durationColor.redOffset * this._tweenProgress;
				_slotColor.greenOffset = currentColor.greenOffset + _durationColor.greenOffset * this._tweenProgress;
				_slotColor.blueOffset = currentColor.blueOffset + _durationColor.blueOffset * this._tweenProgress;
			
				slot._colorDirty = true;
			}
		}
		
		override public function fadeOut():void
		{
			_tweenColor = TWEEN_TYPE_NONE;
		}
		
		override public function update(time:int):void
		{
			super.update(time);
			
			if (_tweenColor != TWEEN_TYPE_NONE)
			{
				const weight:Number = this._animationState._weightResult;
				if (weight > 0)
				{
					const fadeProgress:Number = this._animationState._fadeProgress;
					if (fadeProgress < 1)
					{
						const currentColor:ColorTransform = (this._currentFrame as SlotFrameData).color;
						_slotColor.alphaMultiplier += (currentColor.alphaMultiplier + _durationColor.alphaMultiplier * this._tweenProgress - _slotColor.alphaMultiplier) * fadeProgress;
						_slotColor.redMultiplier += (currentColor.redMultiplier + _durationColor.redMultiplier * this._tweenProgress - _slotColor.redMultiplier) * fadeProgress;
						_slotColor.greenMultiplier += (currentColor.greenMultiplier + _durationColor.greenMultiplier * this._tweenProgress - _slotColor.greenMultiplier) * fadeProgress;
						_slotColor.blueMultiplier += (currentColor.blueMultiplier + _durationColor.blueMultiplier * this._tweenProgress - _slotColor.blueMultiplier) * fadeProgress;
						_slotColor.alphaOffset += (currentColor.alphaOffset + _durationColor.alphaOffset * this._tweenProgress - _slotColor.alphaOffset) * fadeProgress;
						_slotColor.redOffset += (currentColor.redOffset + _durationColor.redOffset * this._tweenProgress - _slotColor.redOffset) * fadeProgress;
						_slotColor.greenOffset += (currentColor.greenOffset + _durationColor.greenOffset * this._tweenProgress - _slotColor.greenOffset) * fadeProgress;
						_slotColor.blueOffset += (currentColor.blueOffset + _durationColor.blueOffset * this._tweenProgress - _slotColor.blueOffset) * fadeProgress;
						
						slot._colorDirty = true;
					}
				}
			}
		}
	}
}