package dragonBones.objects
{
	
	/** @private */
	public class AnimationData
	{
		private var _movementDataDic:Object;
		private var _movementList:Vector.<String>;
		private var _boneList:Vector.<String>;
		
		public function get totalMovements():uint
		{
			return _movementList.length;
		}
		
		public function get movementList():Vector.<String>
		{
			return _movementList.concat();
		}
		
		public function AnimationData()
		{
			_movementDataDic = { };
			_movementList = new Vector.<String>;
			_boneList = new Vector.<String>;
		}
		
		public function dispose():void
		{
			for each(var movementData:MovementData in _movementDataDic)
			{
				movementData.dispose();
			}
			_movementDataDic = {};
			_movementList.length = 0;
		}
		
		public function getMovementData(name:String):MovementData
		{
			return _movementDataDic[name];
		}
		
		public function getMovementDataAt(index:int):MovementData
		{
			var name:String = _movementList.length > index?_movementList[index]:null;
			return getMovementData(name);
		}
		
		public function containsBone(boneName:String):Boolean
		{
			return _boneList.indexOf(boneName) != -1;
		}
		
		internal function addMovementData(data:MovementData, name:String):void
		{
			_movementDataDic[name] = data;
			if(_movementList.indexOf(name) < 0)
			{
				_movementList.push(name);
			}
		}
		
		internal function addBoneList(boneList:Vector.<String>):void
		{
			for each(var boneName:String in boneList)
			{
				if(_boneList.indexOf(boneName) == -1)
				{
					_boneList.push(boneName);
				}
			}
		}
		
	}
	
}