package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.objects.ExtensionFrameData;
	import dragonBones.objects.FFDTimelineData;
	import dragonBones.objects.TimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public final class FFDTimelineState extends TweenTimelineState
	{
		public var slot:Slot;
		
		private var _ffdDirty:Boolean;
		private var _tweenFFD:int;
		private const _ffdVertices:Vector.<Number> = new Vector.<Number>();
		private const _durationFFDVertices:Vector.<Number> = new Vector.<Number>();
		private var _slotFFDVertices:Vector.<Number>;
		
		public function FFDTimelineState()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			slot = null;
			
			_ffdDirty = false;
			_tweenFFD = TWEEN_TYPE_NONE;
			_ffdVertices.fixed = false;
			_durationFFDVertices.fixed = false;
			_ffdVertices.length = 0;
			_durationFFDVertices.length = 0;
			_slotFFDVertices = null;
		}
		
		override protected function _onArriveAtFrame():void
		{
			super._onArriveAtFrame();
			
			if (slot.displayIndex >= 0 && _animationState._isDisabled(slot)) 
			{
				_tweenEasing = DragonBones.NO_TWEEN;
				_curve = null;
				_tweenFFD = TWEEN_TYPE_NONE;
				return;
			}
			
			const currentFrame:ExtensionFrameData = _currentFrame as ExtensionFrameData;
			
			_tweenFFD = TWEEN_TYPE_NONE;
			
			if (_tweenEasing !== DragonBones.NO_TWEEN || _curve)
			{
				const currentFFDVertices:Vector.<Number> = currentFrame.tweens;
				const nextFFDVertices:Vector.<Number> = (currentFrame.next as ExtensionFrameData).tweens;
				for (var i:uint = 0, l:uint = currentFFDVertices.length; i < l; ++i) 
				{
					const duration:Number = nextFFDVertices[i] - currentFFDVertices[i];
					_durationFFDVertices[i] = duration;
					if (duration !== 0.0) 
					{
						_tweenFFD = TWEEN_TYPE_ALWAYS;
					}
				}
			}
			
			if (_tweenFFD === TWEEN_TYPE_NONE)
			{
				_tweenFFD = TWEEN_TYPE_ONCE;
				for (i = 0, l = _durationFFDVertices.length; i < l; ++i)
				{
					_durationFFDVertices[i] = 0.0;
				}
			}
		}
		
		override protected function _onUpdateFrame():void
		{
			super._onUpdateFrame();
			
			var tweenProgress:Number = 0.0;
			
			if (_tweenFFD !== TWEEN_TYPE_NONE && slot.parent._blendLayer >= _animationState._layer)
			{
				if (_tweenFFD === TWEEN_TYPE_ONCE)
				{
					_tweenFFD = TWEEN_TYPE_NONE;
					tweenProgress = 0.0;
				}
				else
				{
					tweenProgress = _tweenProgress;
				}
				
				const currentFFDVertices:Vector.<Number> = (_currentFrame as ExtensionFrameData).tweens;
				for (var i:uint = 0, l:uint = currentFFDVertices.length; i < l; ++i)
				{
					_ffdVertices[i] = currentFFDVertices[i] + _durationFFDVertices[i] * tweenProgress;
				}
				
				_ffdDirty = true;
			}
		}
		
		override public function _init(armature:Armature, animationState:AnimationState, timelineData:TimelineData):void
		{
			super._init(armature, animationState, timelineData);
			
			_slotFFDVertices = slot._ffdVertices;
			
			_ffdVertices.length = (_timelineData.frames[0] as ExtensionFrameData).tweens.length;
			_durationFFDVertices.length = _ffdVertices.length;
			_ffdVertices.fixed = true;
			_durationFFDVertices.fixed = true;
			
			for (var i:uint = 0, l:uint = _ffdVertices.length; i < l; ++i) 
			{
				_ffdVertices[i] = 0.0;
			}
			
			for (i = 0, l = _durationFFDVertices.length; i < l; ++i) 
			{
				_durationFFDVertices[i] = 0.0;
			}
		}
		
		override public function fadeOut():void
		{
			_tweenFFD = TWEEN_TYPE_NONE;
		}
		
		override public function update(passedTime: Number):void
		{
			super.update(passedTime);
			
			if (slot._meshData !== (_timelineData as FFDTimelineData).display.mesh) 
			{
				return;
			}
			
			// Fade animation.
			if (_tweenFFD !== TWEEN_TYPE_NONE || _ffdDirty)
			{
				if (_animationState._fadeState !== 0 || _animationState._subFadeState !== 0)
				{
					const fadeProgress:Number = Math.pow(_animationState._fadeProgress, 4.0);
					
					for (var i:uint = 0, l:uint = _ffdVertices.length; i < l; ++i)
					{
						_slotFFDVertices[i] += (_ffdVertices[i] - _slotFFDVertices[i]) * fadeProgress;
					}
					
					slot._meshDirty = true;
				}
				else if (_ffdDirty)
				{
					_ffdDirty = false;
					
					for (i = 0, l = _ffdVertices.length; i < l; ++i)
					{
						_slotFFDVertices[i] = _ffdVertices[i];
					}
					
					slot._meshDirty = true;
				}
			}
		}
	}
}