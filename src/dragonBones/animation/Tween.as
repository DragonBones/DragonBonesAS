package dragonBones.animation
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.events.FrameEvent;
	import dragonBones.events.SoundEvent;
	import dragonBones.events.SoundEventManager;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.MovementBoneData;
	import dragonBones.objects.Node;
	import dragonBones.objects.TweenNode;
	import dragonBones.utils.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	/** @private */
	final public class Tween
	{
		private static const HALF_PI:Number = Math.PI * 0.5;
		
		private static var _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		private var _isPause:Boolean;
		private var _rawDuration:Number;
		private var _nextFrameDataTimeEdge:Number;
		private var _frameDuration:Number;
		private var _nextFrameDataID:int;
		private var _loop:int;
		
		private var _bone:Bone;
		private var _node:Node;
		
		private var _from:Node;
		private var _tweenNode:TweenNode;
		
		private var _movementBoneData:MovementBoneData;
		
		private var _currentFrameData:FrameData;
		private var _nextFrameData:FrameData;
		private var _frameTweenEasing:Number;
		private var _tweenEasing:Number;
		
		/**
		 * Creates a new <code>Tween</code>
		 * @param	bone
		 */
		public function Tween(bone:Bone)
		{
			super();
			_from = new Node();
			_tweenNode = new TweenNode();
			
			_bone = bone;
			_node = _bone._tweenNode;
		}
		
		/** @private */
		internal function gotoAndPlay(movementBoneData:MovementBoneData, rawDuration:Number, loop:Boolean, tweenEasing:Number):void
		{
			_movementBoneData = movementBoneData;
			if(!_movementBoneData)
			{
				return;
			}
			var totalFrames:uint = _movementBoneData.totalFrames;
			if(totalFrames == 0)
			{
				return;
			}
			
			_node.skewY %= 360;
			_isPause = false;
			_currentFrameData = null;
			_nextFrameData = null;
			_loop = loop?0:-1;
			
			if (totalFrames == 1)
			{
				_rawDuration = 0;
				_nextFrameData = _movementBoneData.getFrameDataAt(0);
				setBetween(_node, _nextFrameData);
				_frameTweenEasing = 1;
			}
			else
			{
				_rawDuration = rawDuration;
				_tweenEasing = tweenEasing;
				_nextFrameDataTimeEdge = 0;
				_nextFrameDataID = 0;
				
				if (loop && _movementBoneData.delay != 0)
				{
					setNodeTo(updateFrameData(_movementBoneData.delay), _tweenNode);
					setBetween(_node, _tweenNode);
					//
					_nextFrameDataTimeEdge = 0;
					_nextFrameDataID = 0;
				}
				else
				{
					_nextFrameData = _movementBoneData.getFrameDataAt(0);
					setBetween(_node, _nextFrameData);
				}
			}
		}
		
		/** @private */
		internal function stop():void
		{
			_isPause = true;
		}
		
		/** @private */
		internal function advanceTime(progress:Number, playType:int):void
		{
			if(_isPause)
			{
				return;
			}
			if(_rawDuration == 0)
			{
				playType = Animation.SINGLE;
				if(progress == 0)
				{
					progress = 1;
				}
			}
			
			if(playType == Animation.LOOP)
			{
				progress /= _movementBoneData.scale;
				progress += _movementBoneData.delay;
				var loop:int = progress;
				if(loop != _loop)
				{
					_loop = loop;
					_nextFrameDataTimeEdge = 0;
				}
				progress -= _loop;
				progress = updateFrameData(progress, true);
			}
			else if (playType == Animation.LIST)
			{
				progress = updateFrameData(progress, true, true);
			}
			else if (playType == Animation.SINGLE && progress == 1)
			{
				_currentFrameData = _nextFrameData;
				_isPause = true;
			}
			else
			{
				progress = Math.sin(progress * HALF_PI);
			}
			
			if (!isNaN(_frameTweenEasing))
			{
				setNodeTo(progress);
			}
			else if(_currentFrameData)
			{
				setNodeTo(0);
			}
			
			if(_currentFrameData)
			{
				arriveFrameData(_currentFrameData);
				_currentFrameData = null;
			}
		}
		
		private function setBetween(from:Node, to:Node):void
		{
			_from.copy(from);
			if(to is FrameData)
			{
				if((to as FrameData).displayIndex < 0)
				{
					_tweenNode.zero();
					return;
				}
			}
			_tweenNode.subtract(from, to);
		}
		
		private function setNodeTo(value:Number, node:Node = null):void
		{
			node = node || _node;
			node.x = _from.x + value * _tweenNode.x;
			node.y = _from.y + value * _tweenNode.y;
			node.scaleX = _from.scaleX + value * _tweenNode.scaleX;
			node.scaleY = _from.scaleY + value * _tweenNode.scaleY;
			node.skewX = _from.skewX + value * _tweenNode.skewX;
			node.skewY = _from.skewY + value * _tweenNode.skewY;
			node.pivotX = _from.pivotX + value * _tweenNode.pivotX;
			node.pivotY = _from.pivotY + value * _tweenNode.pivotY;
		}
		
		private function arriveFrameData(frameData:FrameData):void
		{
			var displayIndex:int = frameData.displayIndex;
			if(displayIndex >= 0)
			{
				if(_node.z != frameData.z)
				{
					_node.z = frameData.z;
					if(_bone.armature)
					{
						_bone.armature._bonesIndexChanged = true;
					}
				}
			}
			_bone.changeDisplay(displayIndex);
			
			if(frameData.event && _bone._armature.hasEventListener(FrameEvent.BONE_FRAME_EVENT))
			{
				var frameEvent:FrameEvent = new FrameEvent(FrameEvent.BONE_FRAME_EVENT);
				frameEvent.movementID = _bone._armature.animation.movementID;
				frameEvent.frameLabel = frameData.event;
				frameEvent._bone = _bone;
				_bone._armature.dispatchEvent(frameEvent);
			}
			if(frameData.sound && _soundManager.hasEventListener(SoundEvent.SOUND))
			{
				var soundEvent:SoundEvent = new SoundEvent(SoundEvent.SOUND);
				soundEvent.movementID = _bone._armature.animation.movementID;
				soundEvent.sound = frameData.sound;
				soundEvent._armature = _bone._armature;
				soundEvent._bone = _bone;
				_soundManager.dispatchEvent(soundEvent);
			}
			if(frameData.movement)
			{
				var childAramture:Armature = _bone.childArmature;
				if(childAramture)
				{
					childAramture.animation.gotoAndPlay(frameData.movement);
				}
			}
		}
		
		private function updateFrameData(progress:Number, activeFrame:Boolean = false, isList:Boolean= false):Number
		{
			var playedTime:Number = _rawDuration * progress;
			if (playedTime >= _nextFrameDataTimeEdge)
			{
				var length:int = _movementBoneData.totalFrames;
				do 
				{
					var currentFrameDataID:int = _nextFrameDataID;
					_frameDuration = _movementBoneData.getFrameDataAt(currentFrameDataID).duration;
					_nextFrameDataTimeEdge += _frameDuration;
					if (++ _nextFrameDataID >= length)
					{
						_nextFrameDataID = 0;
					}
				}
				while (playedTime >= _nextFrameDataTimeEdge);
				
				var currentFrameData:FrameData = _movementBoneData.getFrameDataAt(currentFrameDataID);
				var nextFrameData:FrameData = _movementBoneData.getFrameDataAt(_nextFrameDataID);
				_frameTweenEasing = currentFrameData.tweenEasing;
				if (activeFrame)
				{
					_currentFrameData = _nextFrameData;
					_nextFrameData = nextFrameData;
				}
				if(isList && _nextFrameDataID == 0)
				{
					_isPause = true;
					return 1;
				}
				setBetween(currentFrameData, nextFrameData);
			}
			
			progress = 1 - (_nextFrameDataTimeEdge - playedTime) / _frameDuration;
			if (!isNaN(_frameTweenEasing))
			{
				//NaN: no tweens;  -1: ease out; 0: linear; 1: ease in; 2: ease in&out
				var tweenEasing:Number = isNaN(_tweenEasing)?_frameTweenEasing:_tweenEasing;
				if (tweenEasing)
				{
					progress = getEaseValue(progress, tweenEasing);
				}
			}
			return progress;
		}
		
		private function getEaseValue(value:Number, easing:Number):Number
		{
			var valueEase:Number;
			if (easing > 1)
			{
				valueEase = 0.5 * (1 - Math.cos(value * Math.PI )) - value;
				easing -= 1;
			}
			else if (easing > 0)
			{
				valueEase = Math.sin(value * HALF_PI) - value;
			}
			else
			{
				valueEase = 1 - Math.cos(value * HALF_PI) - value;
				easing *= -1;
			}
			return valueEase * easing + value;
		}
	}
}