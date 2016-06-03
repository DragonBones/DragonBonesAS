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
		private var _ffdVertices:Vector.<Number>;
		private var _durationFFDFrame:ExtensionFrameData;
		
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
			_ffdVertices = null;
			
			if (_durationFFDFrame)
			{
				_durationFFDFrame.returnToPool();
				_durationFFDFrame = null;
			}
		}
		
		override protected function _onFadeIn():void
		{
			_ffdVertices = slot._ffdVertices;
			
			_durationFFDFrame = BaseObject.borrowObject(ExtensionFrameData) as ExtensionFrameData;
			_durationFFDFrame.tweens.fixed = false;
			_durationFFDFrame.tweens.length = _ffdVertices.length;
			_durationFFDFrame.tweens.fixed = true;
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
					if (_ffdVertices[i] != currentFFDVertices[i])
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
		
		override public function fadeOut():void
		{
			_tweenFFD = TWEEN_TYPE_NONE;
		}
		
		override public function update(time:int):void
		{
			super.update(time);
			
			if (_tweenFFD != TWEEN_TYPE_NONE)
			{
				const weight:Number = this._animationState._weightResult;
				if (weight > 0)
				{
					const fadeProgress:Number = this._animationState._fadeProgress;
					if (fadeProgress < 1)
					{
						
						const currentFFDVertices:Vector.<Number> = (this._currentFrame as ExtensionFrameData).tweens;
						for (var i:uint = 0, l:uint = currentFFDVertices.length; i < l; ++i)
						{
							_ffdVertices[i] += (currentFFDVertices[i] + _durationFFDFrame.tweens[i] * this._tweenProgress - _ffdVertices[i]) * fadeProgress;
						}
						
						slot._ffdDirty = true;
					}
				}
			}
		}
	}
}