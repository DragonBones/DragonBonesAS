package dragonBones.objects
{
	import dragonBones.core.BaseObject;
	
	/**
	 * @private
	 */
	public final class SkinSlotData extends BaseObject
	{
		public const displays:Vector.<DisplayData> = new Vector.<DisplayData>();
		public const meshs:Object = {};
		public var slot:SlotData;
		
		public function SkinSlotData()
		{
			super(this);
		}
		
		override protected function _onClear():void
		{
			for (var i:uint = 0, l:uint = displays.length; i < l; ++i)
			{
				displays[i].returnToPool();
			}
			
			for (var k:String in meshs) 
			{
				meshs[k].returnToPool();
				delete meshs[k];
			}
			
			displays.fixed = false;
			displays.length = 0;
			//meshs.clear();
			slot = null;
		}
		
		public function getDisplay(name: String): DisplayData 
		{
			for (var i:uint = 0, l:uint = displays.length; i < l; ++i) 
			{
				const display:DisplayData = displays[i];
				if (display.name === name) 
				{
					return display;
				}
			}
			
			return null;
		}
		
		public function addMesh(value: MeshData): void 
		{
			if (value && value.name && !meshs[value.name]) 
			{
				meshs[value.name] = value;
			}
			else 
			{
				throw new ArgumentError();
			}
		}
		
		public function getMesh(name: String): MeshData 
		{
			return meshs[name];
		}
	}
}