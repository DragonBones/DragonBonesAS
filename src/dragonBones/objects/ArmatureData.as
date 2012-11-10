package dragonBones.objects{
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class ArmatureData extends BaseDicData 
	{
		public function ArmatureData(_name:String = null) 
		{
			super(_name);
		}
		
		override public function getSearchList():Array
		{
			var list:Array = [];
			
			for(var boneName:String in datas)
			{
				var boneData:BoneData = datas[boneName];
				var depth:int = 0;
				var parent:BoneData = boneData;
				while(parent)
				{
					depth ++;
					parent = datas[parent.parent];
				}
				list.push({depth:depth, data:boneName});
			}
			list.sortOn("depth", Array.NUMERIC);
			
			var i:int = list.length;
			while(-- i >= 0){
				list[i] = list[i].data;
			}
			return list;
		}
		
		public function getData(_name:String):BoneData 
		{
			return datas[_name];
		}
	}
}