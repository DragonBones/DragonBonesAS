package dragonBones.animation
{
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.ExtensionFrameData;
	import dragonBones.objects.TweenFrameData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public final class FFDTimelineState extends TweenTimelineState
	{
		public var slot:Slot;
		
		private var _tweenFFD:int;
		private var _slotFFDVertices:Vector.<Number>;
		private var _durationFFDFrame:ExtensionFrameData;
		private const _ffdVertices:Vector.<Number> = new Vector.<Number>(0, true);
		
		public function FFDTimelineState()
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
			
			_tweenFFD = TWEEN_TYPE_NONE;
			_slotFFDVertices = null;
			
			if (_durationFFDFrame)
			{
				_durationFFDFrame.returnToPool();
				_durationFFDFrame = null;
			}
			
			if (_ffdVertices.length)
			{
				_ffdVertices.fixed = false;
				_ffdVertices.length = 0;
				_ffdVertices.fixed = true;
			}
		}
		
		override protected function _onFadeIn():void
		{
			_slotFFDVertices = slot._ffdVertices;
			
			_durationFFDFrame = BaseObject.borrowObject(ExtensionFrameData) as ExtensionFrameData;
			_durationFFDFrame.tweens.fixed = false;
			_durationFFDFrame.tweens.length = _slotFFDVertices.length;
			_durationFFDFrame.tweens.fixed = true;
			_ffdVertices.fixed = false;
			_ffdVertices.length = _slotFFDVertices.length;
			_ffdVertices.fixed = true;
		}
		
		override protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
			super._onArriveAtFrame(isUpdate);
			
			if (this._animationState._isDisabled(slot))
			{
				this._tweenEasing = TweenFrameData.NO_TWEEN;
				this._curve = null;
				_tweenFFD = TWEEN_TYPE_NONE;
				return;
			}
			
			const currentFrame:ExtensionFrameData = this._currentFrame as ExtensionFrameData;
			
			_tweenFFD = TWEEN_TYPE_NONE;
			
			if (this._tweenEasing != TweenFrameData.NO_TWEEN || this._curve)
			{
				_tweenFFD = this._updateExtensionKeyFrame(currentFrame, currentFrame.next as ExtensionFrameData, _durationFFDFrame);
			}
			
			if (_tweenFFD == TWEEN_TYPE_NONE)
			{
				const currentFFDVertices:Vector.<Number> = currentFrame.tweens;
				for (var i:uint = 0, l:uint = currentFFDVertices.length; i < l; ++i)
				{
					if (_slotFFDVertices[i] != currentFFDVertices[i])
					{
						_tweenFFD = TWEEN_TYPE_ONCE;
						break;
					}
				}
			}
		}
		
		override protected function _onUpdateFrame(isUpdate:Boolean):void
		{
			super._onUpdateFrame(isUpdate);
			
			if (_tweenFFD != TWEEN_TYPE_NONE && this._animationState._fadeProgress >= 1)
			{
				if (_tweenFFD == TWEEN_TYPE_ONCE)
				{
					_tweenFFD = TWEEN_TYPE_NONE;
				}
				
				const currentFFDVertices:Vector.<Number> = (this._currentFrame as ExtensionFrameData).tweens;
				const nextFFDVertices:Vector.<Number> = _durationFFDFrame.tweens;
				for (var i:uint = 0, l:uint = currentFFDVertices.length; i < l; ++i)
				{
					_ffdVertices[i] = currentFFDVertices[i] + nextFFDVertices[i] * this._tweenProgress;
				}
				
				slot._ffdDirty = true;
			}
		}
		
		override public function update(time:int):void
		{
			super.update(time);
			
			const weight:Number = this._animationState._weightResult;
			if (weight > 0)
			{
				var i:uint = 0, l:uint = _ffdVertices.length;
				if (this._animationState._index <= 1)
				{
					for (i = 0, l = _ffdVertices.length; i < l; ++i)
					{
						_slotFFDVertices[i] = _ffdVertices[i] * weight;
					}
				}
				else
				{
					for (i = 0, l = _ffdVertices.length; i < l; ++i)
					{
						_slotFFDVertices[i] += _ffdVertices[i] * weight;
					}
				}
				
				const fadeProgress:Number = this._animationState._fadeProgress;
				if (fadeProgress < 1)
				{
					slot._ffdDirty = true;
				}
			}
		}
	}
}