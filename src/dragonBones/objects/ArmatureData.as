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
			_boneDataDic[name] = data;
		}
		
		dragonBones_internal function updateBoneList():void
		{
			var boneList:Array = [];
			for(var boneName:String in _boneDataDic)
			{
				var parentData:BoneData = _boneDataDic[boneName];
				var z:int = parentData.z;
				var depth:int = 0;
				while(parentData)
				{
					depth ++;
					z += 1000 * depth;
					parentData = _boneDataDic[parentData.parent];
				}
				boneList.push({z:z, boneName:boneName});
			}
			var length:int = boneList.length;
			if(length > 0)
			{
				boneList.sortOn("z", Array.NUMERIC);
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