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
	
	/**
	 * A core object that can control the state of a bone
	 * @see dragonBones.Bone
	 */
	final public class Tween extends ProcessBase
	{
		private static const HALF_PI:Number = Math.PI * 0.5;
		
		private static var _soundManager:SoundEventManager = SoundEventManager.getInstance();
		
		private var _bone:Bone;
		
		/** @private */
		dragonBones_internal var _node:Node;
		
		private var _from:Node;
		private var _tweenNode:TweenNode;
		
		private var _movementBoneData:MovementBoneData;
		
		private var _currentFrameData:FrameData;
		private var _nextFrameData:FrameData;
		private var _frameTweenEasing:Number;
		private var _tweenEasing:Number;
		
		/**
		 * @inheritDoc
		 */
		override public function set timeScale(value:Number):void
		{
			super.timeScale = value;
			
			var childArmature:Armature = _bone.childArmature;
			if(childArmature)
			{
				childArmature.animation.timeScale = value;
			}
		}
		
		/**
		 * Creates a new <code>Tween</code>
		 * @param	bone
		 */
		public function Tween(bone:Bone)
		{
			super();
			_bone = bone;
			_node = new Node();
			_from = new Node();
			_tweenNode = new TweenNode();
			_node.scaleX = 0;
			_node.scaleY = 0;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			_bone = null;
			_node = null;
			_from = null;
			_tweenNode = null;
			
			_movementBoneData = null;
			_currentFrameData = null;
			_nextFrameData = null;
		}
		
		public function gotoAndPlay(movementBoneData:MovementBoneData, tweenTime:Number, duration:Number = 0, loop:Boolean = false, tweenEasing:Number = NaN):void
		{
			_movementBoneData = movementBoneData;
			if(!_movementBoneData)
			{
				return;
			}
			
			if(_movementBoneData.totalFrames == 0)
			{
				return;
			}
			
			_isComplete = false;
			_isPause = false;
			_currentTime = 0;
			
			_currentFrameData = null;
			_nextFrameData = null;
			_frameDuration = 0;
			_nextFrameDataTimeEdge = 0;
			_nextFrameDataID = 0;
			
			_node.skewY %= 360;
			
			_totalTime = tweenTime >= 0?tweenTime:0;
			_rawDuration = _movementBoneData.duration;
			_tweenEasing = tweenEasing;
			
			if (_rawDuration == 0)
			{
				_loop = SINGLE;
				_nextFrameData = _movementBoneData.getFrameDataAt(0);
				setBetween(_node, _nextFrameData);
				_frameTweenEasing = 1;
			}
			else
			{
				_duration = duration > 0?duration * _movementBoneData.scale:duration;
				if (loop)
				{
					_loop = LIST_LOOP_START;
				}
				else
				{
					_loop = LIST_START;
					_rawDuration -= _movementBoneData.getFrameDataAt(_movementBoneData.totalFrames - 1).duration;
				}
				
				if (loop && _movementBoneData.delay != 0)
				{
					setNodeTo(updateFrameData(- _movementBoneData.delay), _tweenNode);
					setBetween(_node, _tweenNode);
				}
				else
				{
					_nextFrameData = _movementBoneData.getFrameDataAt(0);
					setBetween(_node, _nextFrameData);
				}
			}
		}
		/**
		 * @inheritDoc
		 */
		override public function play():void
		{
			if (!_movementBoneData)
			{
				return;
			}
			
			super.play();
			var childArmature:Armature = _bone.childArmature;
			if(childArmature)
			{
				childArmature.animation.play();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function stop():void
		{
			super.stop();
			var childArmature:Armature = _bone.childArmature;
			if(childArmature)
			{
				childArmature.animation.stop();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateHandler():void
		{
			if (_progress >= 1)
			{
				switch(_loop)
				{
					case SINGLE:
						_currentFrameData = _nextFrameData;
						_progress = 1;
						_isComplete = true;
						break;
					case LIST_START:
						_loop = LIST;
						_progress = 0;
						_totalTime = _duration;
						_nextFrameDataTimeEdge = 0;
						break;
					case LIST:
						_progress = 1;
						_isComplete = true;
						break;
					case LIST_LOOP_START:
						_loop = 0;
						_totalTime = _duration;
						_frameDuration = 0;
						_nextFrameDataID = 0;
						_nextFrameDataTimeEdge = 0;
						if (_movementBoneData.delay != 0)
						{
							if(_totalTime > 0)
							{
								_currentTime = - _movementBoneData.delay * _totalTime;
							}
							_progress = - _movementBoneData.delay;
						}
						else
						{
							_progress = 0;
						}
						break;
					default:
						//change the loop
						_loop ++;
						_progress = 0;
						_frameDuration = 0;
						_nextFrameDataTimeEdge = 0;
						_nextFrameDataID = 0;
						break;
				}
			}
			else if (_loop < LIST)
			{
				//SINGLE,LIST_START,LIST_LOOP_START
				_progress = Math.sin(_progress * HALF_PI);
			}
			
			if (_loop >= LIST)
			{
				//multiple key frame process
				_progress = updateFrameData(_progress, true);
				
			}
			
			if (!isNaN(_frameTweenEasing))
			{
				setNodeTo(_progress);
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
					_tweenNode.subtract(from, from);
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
				if(_bone.global.z != frameData.z)
				{
					_bone.global.z = frameData.z;
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
		
		private function updateFrameData(progress:Number, activeFrame:Boolean = false):Number
		{
			var playedTime:Number = _rawDuration * progress;
			//refind the current frame
			if (playedTime >= _nextFrameDataTimeEdge)
			{
				var length:int = _movementBoneData.totalFrames;
				do {
					var currentFrameDataID:int = _nextFrameDataID;
					_frameDuration = _movementBoneData.getFrameDataAt(currentFrameDataID).duration;
					_nextFrameDataTimeEdge += _frameDuration;
					if (++ _nextFrameDataID >= length)
					{
						_nextFrameDataID = 0;
					}
				}while (playedTime >= _nextFrameDataTimeEdge);
				if(_loop == LIST && _nextFrameDataID == 0)
				{
					return 1;
				}
				var currentFrameData:FrameData = _movementBoneData.getFrameDataAt(currentFrameDataID);
				var nextFrameData:FrameData = _movementBoneData.getFrameDataAt(_nextFrameDataID);
				_frameTweenEasing = currentFrameData.tweenEasing;
				if (activeFrame)
				{
					_currentFrameData = _nextFrameData;
					_nextFrameData = nextFrameData;
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
			if (easing > 1)
			{
				value = 0.5 * (1 - Math.cos(value * Math.PI ));
				easing -= 1;
			}
			else if (easing > 0)
			{
				value = Math.sin(value * HALF_PI);
			}
			else
			{
				value = 1 - Math.cos(value * HALF_PI);
				easing = -easing;
			}
			return value * easing + (1 - easing);
		}
	}
}