package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.geom.Transform;
	import dragonBones.objects.BoneFrameData;
	import dragonBones.objects.BoneTimelineData;
	import dragonBones.objects.TimelineData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @private
	 */
	public final class BoneTimelineState extends TweenTimelineState
	{
		public var bone:Bone;
		
		private var _tweenTransform:int;
		private var _tweenRotate:int;
		private var _tweenScale:int;
		private var _boneTransform:Transform;
		private var _originTransform:Transform;
		private const _transform:Transform = new Transform();
		private const _currentTransform:Transform = new Transform();
		private const _durationTransform:Transform = new Transform();
		
		public function BoneTimelineState()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			bone = null;
			
			_tweenTransform = TWEEN_TYPE_NONE;
			_tweenRotate = TWEEN_TYPE_NONE;
			_tweenScale = TWEEN_TYPE_NONE;
			_boneTransform = null;
			_originTransform = null;
			_transform.identity();
			_currentTransform.identity();
			_durationTransform.identity();
		}
		
		override protected function _onArriveAtFrame(isUpdate:Boolean):void
		{
			super._onArriveAtFrame(isUpdate);
			
			const currentFrame:BoneFrameData = this._currentFrame as BoneFrameData;
			
			_currentTransform.copyFrom(currentFrame.transform);
			
			_tweenTransform = TWEEN_TYPE_ONCE;
			_tweenRotate = TWEEN_TYPE_ONCE;
			_tweenScale = TWEEN_TYPE_ONCE;
			
			if (this._keyFrameCount > 1 && (this._tweenEasing != DragonBones.NO_TWEEN || this._curve))
			{
				const nextFrame:BoneFrameData = this._currentFrame.next as BoneFrameData;
				const nextTransform:Transform = nextFrame.transform;
				
				// Transform.
				_durationTransform.x = nextTransform.x - _currentTransform.x;
				_durationTransform.y = nextTransform.y - _currentTransform.y;
				if (_durationTransform.x != 0 || _durationTransform.y != 0)
				{
					_tweenTransform = TWEEN_TYPE_ALWAYS;
				}
				
				// Rotate.
				const tweenRotate:Number = currentFrame.tweenRotate;
				if (tweenRotate == tweenRotate)
				{
					if (tweenRotate != 0)
					{
						if (tweenRotate > 0 ? nextTransform.skewY >= _currentTransform.skewY : nextTransform.skewY <= _currentTransform.skewY) {
							const rotate:int = tweenRotate > 0? tweenRotate - 1: tweenRotate + 1;
							_durationTransform.skewX = nextTransform.skewX - _currentTransform.skewX + DragonBones.PI_D * rotate;
							_durationTransform.skewY = nextTransform.skewY - _currentTransform.skewY + DragonBones.PI_D * rotate;
						} 
						else
						{
							_durationTransform.skewX = nextTransform.skewX - _currentTransform.skewX + DragonBones.PI_D * tweenRotate;
							_durationTransform.skewY = nextTransform.skewY - _currentTransform.skewY + DragonBones.PI_D * tweenRotate;
						}
					}
					else
					{
						_durationTransform.skewX = Transform.normalizeRadian(nextTransform.skewX - _currentTransform.skewX);
						_durationTransform.skewY = Transform.normalizeRadian(nextTransform.skewY - _currentTransform.skewY);
					}
					
					if (_durationTransform.skewX != 0 || _durationTransform.skewY != 0)
					{
						_tweenRotate = TWEEN_TYPE_ALWAYS;
					}
				}
				else 
				{
					_durationTransform.skewX = 0;
					_durationTransform.skewY = 0;
				}
				
				// Scale.
				if (currentFrame.tweenScale)
				{
					_durationTransform.scaleX = nextTransform.scaleX - _currentTransform.scaleX;
					_durationTransform.scaleY = nextTransform.scaleY - _currentTransform.scaleY;
					if (_durationTransform.scaleX != 0 || _durationTransform.scaleY != 0)
					{
						_tweenScale = TWEEN_TYPE_ALWAYS;
					}
				}
				else
				{
					_durationTransform.scaleX = 0;
					_durationTransform.scaleY = 0;
				}
			}
			else
			{
				_durationTransform.x = 0;
				_durationTransform.y = 0;
				_durationTransform.skewX = 0;
				_durationTransform.skewY = 0;
				_durationTransform.scaleX = 0;
				_durationTransform.scaleY = 0;
			}
		}
		
		override protected function _onUpdateFrame(isUpdate:Boolean):void
		{
			if (_tweenTransform || _tweenRotate || _tweenScale)
			{
				super._onUpdateFrame(isUpdate);
				
				var tweenProgress:Number = 0;
				
				if (_tweenTransform)
				{
					if (_tweenTransform == TWEEN_TYPE_ONCE)
					{
						_tweenTransform = TWEEN_TYPE_NONE;
						tweenProgress = 0;
					}
					else
					{
						tweenProgress = this._tweenProgress;
					}
					
					if (this._animationState.additiveBlending) // Additive blending.
					{
						_transform.x = _currentTransform.x + _durationTransform.x * tweenProgress;
						_transform.y = _currentTransform.y + _durationTransform.y * tweenProgress;
					}
					else // Normal blending.
					{
						_transform.x = _originTransform.x + _currentTransform.x + _durationTransform.x * tweenProgress;
						_transform.y = _originTransform.y + _currentTransform.y + _durationTransform.y * tweenProgress;
					}
				}
				
				if (_tweenRotate)
				{
					if (_tweenRotate == TWEEN_TYPE_ONCE)
					{
						_tweenRotate = TWEEN_TYPE_NONE;
						tweenProgress = 0;
					}
					else
					{
						tweenProgress = this._tweenProgress;
					}
					
					if (this._animationState.additiveBlending) // Additive blending.
					{
						_transform.skewX = _currentTransform.skewX + _durationTransform.skewX * tweenProgress;
						_transform.skewY = _currentTransform.skewY + _durationTransform.skewY * tweenProgress;
					}
					else // Normal blending.
					{
						_transform.skewX = _originTransform.skewX + _currentTransform.skewX + _durationTransform.skewX * tweenProgress;
						_transform.skewY = _originTransform.skewY + _currentTransform.skewY + _durationTransform.skewY * tweenProgress;
					}
				}
				
				if (_tweenScale)
				{
					if (_tweenScale == TWEEN_TYPE_ONCE)
					{
						_tweenScale = TWEEN_TYPE_NONE;
						tweenProgress = 0;
					}
					else
					{
						tweenProgress = this._tweenProgress;
					}
					
					if (this._animationState.additiveBlending) // Additive blending.
					{
						_transform.scaleX = _currentTransform.scaleX + _durationTransform.scaleX * tweenProgress;
						_transform.scaleY = _currentTransform.scaleY + _durationTransform.scaleY * tweenProgress;
					}
					else // Normal blending.
					{
						_transform.scaleX = _originTransform.scaleX * (_currentTransform.scaleX + _durationTransform.scaleX * tweenProgress);
						_transform.scaleY = _originTransform.scaleY * (_currentTransform.scaleY + _durationTransform.scaleY * tweenProgress);
					}
				}
				
				bone.invalidUpdate();
			}
		}
		
		override public function fadeIn(armature:Armature, animationState:AnimationState, timelineData:TimelineData, time:Number):void
		{
			super.fadeIn(armature, animationState, timelineData, time);
			
			_originTransform = (this._timeline as BoneTimelineData).originTransform;
			_boneTransform = bone._animationPose;
		}
		
		override public function fadeOut():void
		{
			_transform.skewX = Transform.normalizeRadian(_transform.skewX);
			_transform.skewY = Transform.normalizeRadian(_transform.skewY);
		}
		
		override public function update(time:Number):void	
		{
			super.update(time);
			
			// Blend animation state.
			const weight:Number = this._animationState._weightResult;
			
			if (weight > 0)
			{
				if (bone._blendIndex == 0)
				{
					_boneTransform.x = _transform.x * weight;
					_boneTransform.y = _transform.y * weight;
					_boneTransform.skewX = _transform.skewX * weight;
					_boneTransform.skewY = _transform.skewY * weight;
					_boneTransform.scaleX = (_transform.scaleX - 1) * weight + 1;
					_boneTransform.scaleY = (_transform.scaleY - 1) * weight + 1;
				}
				else
				{
					_boneTransform.x += _transform.x * weight;
					_boneTransform.y += _transform.y * weight;
					_boneTransform.skewX += _transform.skewX * weight;
					_boneTransform.skewY += _transform.skewY * weight;
					_boneTransform.scaleX += (_transform.scaleX - 1) * weight;
					_boneTransform.scaleY += (_transform.scaleY - 1) * weight;
				}
				
				bone._blendIndex++;
				
				if (this._animationState._fadeState != 0)
				{
					bone.invalidUpdate();
				}
			}
		}
	}
}