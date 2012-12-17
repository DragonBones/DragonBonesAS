package dragonBones.objects {
	import dragonBones.utils.dragonBones_internal;
	
	use namespace dragonBones_internal;
	
	/**
	 * A set of armature data and animation data
	 */
	public class SkeletonData
	{
		private var _armatureDataDic:Object;
		private var _animationDataDic:Object;
		private var _displayDataDic:Object;
		private var _armatureList:Vector.<String>;
		private var _animationList:Vector.<String>;
		
		internal var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		public function get totalArmatures():uint
		{
			return _armatureList.length;
		}
		
		public function get totalAnimations():uint
		{
			return _animationList.length;
		}
		
		public function get armatureList():Vector.<String>
		{
			return _armatureList.concat();
		}
		
		public function get animationList():Vector.<String>
		{
			return _animationList.concat();
		}
		
		public function SkeletonData()
		{
			_armatureDataDic = { };
			_animationDataDic = { };
			_displayDataDic = { };
			_armatureList = new Vector.<String>;
			_animationList = new Vector.<String>;
		}
		
		public function dispose():void
		{
			for each(var armatureData:ArmatureData in _armatureDataDic)
			{
				armatureData.dispose();
			}
			for each(var animationData:AnimationData in _animationDataDic)
			{
				animationData.dispose();
			}
			_armatureDataDic = null;
			_animationDataDic = null;
			_displayDataDic = null;
			_armatureList = null;
			_animationList = null;
		}
		
		public function getArmatureData(name:String):ArmatureData
		{
			return _armatureDataDic[name];
		}
		
		public function getAramtureDataAt(index:int):ArmatureData
		{
			var name:String = _armatureList.length > index?_armatureList[index]:null;
			return getArmatureData(name);
		}
		
		public function getAnimationData(name:String):AnimationData
		{
			return _animationDataDic[name];
		}
		
		dragonBones_internal function getDisplayData(name:String):DisplayData
		{
			return _displayDataDic[name];
		}
		
		internal function addArmatureData(data:ArmatureData, name:String):void
		{
			_armatureDataDic[name] = data;
			if(_armatureList.indexOf(name) < 0)
			{
				_armatureList.push(name);
			}
		}
		
		internal function addAnimationData(data:AnimationData, name:String):void
		{
			_animationDataDic[name] = data;
			if(_animationList.indexOf(name) < 0)
			{
				_animationList.push(name);
			}
		}
		
		internal function addDisplayData(data:DisplayData, name:String):void
		{
			_displayDataDic[name] = data;
		}
	}
}