package dragonBones.objects
{
	import dragonBones.utils.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	/** @private */
	public class MovementData
	{
		private var _movementBoneDataDic:Object;
		private var _movementFrameList:Vector.<MovementFrameData>;
		
		internal var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		public function get totalFrames():uint
		{
			return _movementFrameList.length;
		}
		
		public var duration:Number;
		public var durationTo:Number;
		public var durationTween:Number;
		public var loop:Boolean;
		public var tweenEasing:Number;
		
		public function MovementData()
		{
			duration = 0;
			durationTo = 0;
			durationTween = 0;
			_movementBoneDataDic = { };
			_movementFrameList = new Vector.<MovementFrameData>;
		}
		
		public function setValues(duration:Number, durationTo:Number, durationTween:Number, loop:Boolean, tweenEasing:Number):void
		{
			this.duration = duration;
			this.durationTo = durationTo;
			this.durationTween = durationTween;
			this.loop = loop;
			//the default NaN means no tween
			this.tweenEasing = tweenEasing;
		}
		
		public function dispose():void
		{
			for each(var movementBoneData:MovementBoneData in _movementBoneDataDic)
			{
				movementBoneData.dispose();
			}
			_movementBoneDataDic = null;
			_movementFrameList = null;
		}
		
		public function getMovementBoneData(name:String):MovementBoneData
		{
			return _movementBoneDataDic[name];
		}
		
		public function getMovementFrameDataAt(index:int):MovementFrameData
		{
			return _movementFrameList.length > index?_movementFrameList[index]:null;
		}
		
		internal function addMovementBoneData(data:MovementBoneData):void
		{
			var name:String = data.name;
			if(name)
			{
				_movementBoneDataDic[name] = data;
			}
		}
		
		internal function addMovementFrameData(data:MovementFrameData):void
		{
			if(_movementFrameList.indexOf(data) < 0)
			{
				_movementFrameList.push(data);
			}
		}
	}
	
}