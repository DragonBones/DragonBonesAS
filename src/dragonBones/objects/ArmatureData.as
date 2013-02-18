package dragonBones.objects
{
	import dragonBones.utils.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	/** @private */
	public class ArmatureData
	{
		private var _boneDataDic:Object;
		private var _boneList:Vector.<String>;
		
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
			_boneList = new Vector.<String>;
		}
		
		public function dispose():void
		{
			for each(var boneData:BoneData in _boneDataDic)
			{
				boneData.dispose();
			}
			_boneDataDic = {};
			_boneList.length = 0;
		}
		
		public function getBoneData(name:String):BoneData
		{
			return _boneDataDic[name];
		}
		
		internal function addBoneData(data:BoneData, name:String):void
		{
			if(data || name)
			{
				_boneDataDic[name] = data;
			}
		}
		
		internal function removeBoneData(data:BoneData):void
		{
			if(data)
			{
				for(var name:String in _boneDataDic)
				{
					if(_boneDataDic[name] == data)
					{
						delete _boneDataDic[name];
						return;
					}
				}
			}
		}
		
		dragonBones_internal function updateBoneList():void
		{
			var boneList:Array = [];
			for(var boneName:String in _boneDataDic)
			{
				var parentData:BoneData = _boneDataDic[boneName];
				var levelValue:int = parentData.node.z;
				var level:int = 0;
				while(parentData)
				{
					level ++;
					levelValue += 1000 * level;
					parentData = _boneDataDic[parentData.parent];
				}
				boneList.push({level:levelValue, boneName:boneName});
			}
			var length:int = boneList.length;
			if(length > 0)
			{
				boneList.sortOn("level", Array.NUMERIC);
				_boneList.length = 0;
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