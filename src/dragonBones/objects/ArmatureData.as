package dragonBones.objects
{
	
	/** @private */
	public class ArmatureData
	{
		private var _boneDataDic:Object;
		private var _boneList:Vector.<String>;
		
		internal var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		public function get totalBones():uint
		{
			return _boneList.length;
		}
		
		public function get boneList():Vector.<String>
		{
			return _boneList.concat();
		}
		
		public function ArmatureData()
		{
			_boneDataDic = { };
		}
		
		public function dispose():void
		{
			for each(var boneData:BoneData in _boneDataDic)
			{
				boneData.dispose();
			}
			_boneDataDic = null;
			_boneList = null;
		}
		
		public function getBoneData(name:String):BoneData
		{
			return _boneDataDic[name];
		}
		
		public function getBoneDataAt(index:int):BoneData
		{
			var name:String = _boneList.length > index?_boneList[index]:null;
			return getBoneData(name);
		}
		
		internal function addBoneData(data:BoneData):void
		{
			var name:String = data.name;
			if(name)
			{
				_boneDataDic[name] = data;
			}
		}
		
		internal function updateBoneList():void
		{
			var boneList:Array = [];
			for(var boneName:String in _boneDataDic)
			{
				var depth:int = 0;
				var parentData:BoneData = _boneDataDic[boneName];
				while(parentData)
				{
					depth ++;
					parentData = _boneDataDic[parentData.parent];
				}
				boneList.push({depth:depth, boneName:boneName});
			}
			var length:int = boneList.length;
			if(length > 0)
			{
				boneList.sortOn("depth", Array.NUMERIC);
				_boneList = new Vector.<String>;
				var i:int = 0;
				while(i < length)
				{
					_boneList[i] = boneList[i].boneName;
					i ++;
				}
			}
		}
	}
}