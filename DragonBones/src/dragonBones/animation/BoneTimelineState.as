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
		
		private var _transformDirty:Boolean;
		private var _tweenTransform:int;
		private var _tweenRotate:int;
		private var _tweenScale:int;
		private const _transform:Transform = new Transform();
		private const _durationTransform:Transform = new Transform();
		private var _boneTransform:Transform;
		private var _originalTransform:Transform;
		
		public function BoneTimelineState()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			super._onClear();
			
			bone = null;
			
			_transformDirty = false;
			_tweenTransform = TWEEN_TYPE_NONE;
			_tweenRotate = TWEEN_TYPE_NONE;
			_tweenScale = TWEEN_TYPE_NONE;
			_transform.identity();
			_durationTransform.identity();
			_boneTransform = null;
			_originalTransform = null;
		}
		
		override protected function _onArriveAtFrame():void
		{
			super._onArriveAtFrame();
			
			const currentFrame:BoneFrameData = _currentFrame as BoneFrameData;
			
			_tweenTransform = TWEEN_TYPE_ONCE;
			_tweenRotate = TWEEN_TYPE_ONCE;
			_tweenScale = TWEEN_TYPE_ONCE;
			
			if (_keyFrameCount > 1 && (_tweenEasing !== DragonBones.NO_TWEEN || _curve))
			{
				const currentTransform:Transform = currentFrame.transform;
				const nextFrame:BoneFrameData = currentFrame.next as BoneFrameData;
				const nextTransform:Transform = nextFrame.transform;
				
				// Transform.
				_durationTransform.x = nextTransform.x - currentTransform.x;
				_durationTransform.y = nextTransform.y - currentTransform.y;
				if (_durationTransform.x !== 0.0 || _durationTransform.y !== 0.0) 
				{
					_tweenTransform = TWEEN_TYPE_ALWAYS;
				}
				
				// Rotate.
				var tweenRotate:Number = currentFrame.tweenRotate;
				if (tweenRotate !== DragonBones.NO_TWEEN) 
				{
					if (tweenRotate) 
					{
						if (tweenRotate > 0.0 ? nextTransform.skewY >= currentTransform.skewY : nextTransform.skewY <= currentTransform.skewY) 
						{
							tweenRotate = tweenRotate > 0.0 ? tweenRotate - 1.0 : tweenRotate + 1.0;
						}
						
						_durationTransform.skewX = nextTransform.skewX - currentTransform.skewX + DragonBones.PI_D * tweenRotate;
						_durationTransform.skewY = nextTransform.skewY - currentTransform.skewY + DragonBones.PI_D * tweenRotate;
					}
					else 
					{
						_durationTransform.skewX = Transform.normalizeRadian(nextTransform.skewX - currentTransform.skewX);
						_durationTransform.skewY = Transform.normalizeRadian(nextTransform.skewY - currentTransform.skewY);
					}
					
					if (_durationTransform.skewX !== 0.0 || _durationTransform.skewY !== 0.0) 
					{
						_tweenRotate = TWEEN_TYPE_ALWAYS;
					}
				}
				else 
				{
					_durationTransform.skewX = 0.0;
					_durationTransform.skewY = 0.0;
				}
				
				// Scale.
				if (currentFrame.tweenScale) 
				{
					_durationTransform.scaleX = nextTransform.scaleX - currentTransform.scaleX;
					_durationTransform.scaleY = nextTransform.scaleY - currentTransform.scaleY;
					if (_durationTransform.scaleX !== 0.0 || _durationTransform.scaleY !== 0.0) 
					{
						_tweenScale = TWEEN_TYPE_ALWAYS;
					}
				}
				else 
				{
					_durationTransform.scaleX = 0.0;
					_durationTransform.scaleY = 0.0;
				}
			}
			else 
			{
				_durationTransform.x = 0.0;
				_durationTransform.y = 0.0;
				_durationTransform.skewX = 0.0;
				_durationTransform.skewY = 0.0;
				_durationTransform.scaleX = 0.0;
				_durationTransform.scaleY = 0.0;
			}
		}
		
		override protected function _onUpdateFrame():void
		{
			super._onUpdateFrame();
			
			var tweenProgress:Number = 0.0;
			const currentTransform:Transform = (_currentFrame as BoneFrameData).transform;
			
			if (_tweenTransform !== TWEEN_TYPE_NONE) 
			{
				if (_tweenTransform === TWEEN_TYPE_ONCE) 
				{
					_tweenTransform = TWEEN_TYPE_NONE;
					tweenProgress = 0.0;
				}
				else 
				{
					tweenProgress = _tweenProgress;
				}
				
				if (_animationState.additiveBlending) // Additive blending.
				{
					_transform.x = currentTransform.x + _durationTransform.x * tweenProgress;
					_transform.y = currentTransform.y + _durationTransform.y * tweenProgress;
				}
				else // Normal blending.
				{
					_transform.x = _originalTransform.x + currentTransform.x + _durationTransform.x * tweenProgress;
					_transform.y = _originalTransform.y + currentTransform.y + _durationTransform.y * tweenProgress;
				}
				
				_transformDirty = true;
			}
			
			if (_tweenRotate !== TWEEN_TYPE_NONE) 
			{
				if (_tweenRotate === TWEEN_TYPE_ONCE) 
				{
					_tweenRotate = TWEEN_TYPE_NONE;
					tweenProgress = 0.0;
				}
				else 
				{
					tweenProgress = _tweenProgress;
				}
				
				if (_animationState.additiveBlending) // Additive blending.
				{
					_transform.skewX = currentTransform.skewX + _durationTransform.skewX * tweenProgress;
					_transform.skewY = currentTransform.skewY + _durationTransform.skewY * tweenProgress;
				}
				else // Normal blending.
				{
					_transform.skewX = _originalTransform.skewX + currentTransform.skewX + _durationTransform.skewX * tweenProgress;
					_transform.skewY = _originalTransform.skewY + currentTransform.skewY + _durationTransform.skewY * tweenProgress;
				}
				
				_transformDirty = true;
			}
			
			if (_tweenScale !== TWEEN_TYPE_NONE) 
			{
				if (_tweenScale === TWEEN_TYPE_ONCE) 
				{
					_tweenScale = TWEEN_TYPE_NONE;
					tweenProgress = 0.0;
				}
				else 
				{
					tweenProgress = _tweenProgress;
				}
				
				if (_animationState.additiveBlending) // Additive blending.
				{
					_transform.scaleX = currentTransform.scaleX + _durationTransform.scaleX * tweenProgress;
					_transform.scaleY = currentTransform.scaleY + _durationTransform.scaleY * tweenProgress;
				}
				else // Normal blending.
				{
					_transform.scaleX = _originalTransform.scaleX * (currentTransform.scaleX + _durationTransform.scaleX * tweenProgress);
					_transform.scaleY = _originalTransform.scaleY * (currentTransform.scaleY + _durationTransform.scaleY * tweenProgress);
				}
				
				_transformDirty = true;
			}
		}
		
		override public function _init(armature: Armature, animationState: AnimationState, timelineData: TimelineData): void 
		{
			super._init(armature, animationState, timelineData);
			
			_originalTransform = (_timelineData as BoneTimelineData).originalTransform;
			_boneTransform = bone._animationPose;
		}
		
		override public function fadeOut():void
		{
			_transform.skewX = Transform.normalizeRadian(_transform.skewX);
			_transform.skewY = Transform.normalizeRadian(_transform.skewY);
		}
		
		override public function update(passedTime: Number):void	
		{
			// Blend animation state.
			const animationLayer:int = _animationState._layer;
			var weight:Number = _animationState._weightResult;
			
			if (bone._updateState <= 0) 
			{
				super.update(passedTime);
				
				bone._blendLayer = animationLayer;
				bone._blendLeftWeight = 1.0;
				bone._blendTotalWeight = weight;
				
				_boneTransform.x = _transform.x * weight;
				_boneTransform.y = _transform.y * weight;
				_boneTransform.skewX = _transform.skewX * weight;
				_boneTransform.skewY = _transform.skewY * weight;
				_boneTransform.scaleX = (_transform.scaleX - 1.0) * weight + 1.0;
				_boneTransform.scaleY = (_transform.scaleY - 1.0) * weight + 1.0;
				
				bone._updateState = 1;
			}
			else if (bone._blendLeftWeight > 0.0) 
			{
				if (bone._blendLayer !== animationLayer) 
				{
					if (bone._blendTotalWeight >= bone._blendLeftWeight) 
					{
						bone._blendLeftWeight = 0.0;
					}
					else 
					{
						bone._blendLayer = animationLayer;
						bone._blendLeftWeight -= bone._blendTotalWeight;
						bone._blendTotalWeight = 0.0;
					}
				}
				
				weight *= bone._blendLeftWeight;
				if (weight >= 0.0) 
				{
					super.update(passedTime);
					
					bone._blendTotalWeight += weight;
					
					_boneTransform.x += _transform.x * weight;
					_boneTransform.y += _transform.y * weight;
					_boneTransform.skewX += _transform.skewX * weight;
					_boneTransform.skewY += _transform.skewY * weight;
					_boneTransform.scaleX += (_transform.scaleX - 1.0) * weight;
					_boneTransform.scaleY += (_transform.scaleY - 1.0) * weight;
					
					bone._updateState++;
				}
			}
			
			if (bone._updateState > 0) 
			{
				if (_transformDirty || _animationState._fadeState !== 0 || _animationState._subFadeState !== 0) 
				{
					_transformDirty = false;
					
					bone.invalidUpdate();
				}
			}
		}
	}
}