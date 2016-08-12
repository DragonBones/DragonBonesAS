package dragonBones.flash
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.animation.Animation;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.events.EventObject;
	import dragonBones.factories.BaseFactory;
	import dragonBones.factories.BuildArmaturePackage;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.parsers.DataParser;
	import dragonBones.textures.TextureAtlasData;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 基于 Flash 传统显示列表的工厂。
	 * @version DragonBones 3.0
	 */
	public class FlashFactory extends BaseFactory
	{
		/**
		 * @language zh_CN
		 * 一个可以直接使用的全局工厂实例.
		 * @version DragonBones 4.7
		 */
		public static const factory:FlashFactory = new FlashFactory();
		
		/**
		 * @language zh_CN
		 * 创建一个工厂。
		 * @version DragonBones 3.0
		 */
		public function FlashFactory(dataParser:DataParser = null)
		{
			super(this, dataParser);
			
			if (!EventObject._soundEventManager) 
			{
				EventObject._soundEventManager = new FlashArmatureDisplay();
			}
		}
		
		/**
		 * @private
		 */
		override protected function _generateTextureAtlasData(textureAtlasData:TextureAtlasData, textureAtlas:Object):TextureAtlasData
		{
			if (textureAtlasData)
			{
				if (textureAtlas is BitmapData)
				{
					(textureAtlasData as FlashTextureAtlasData).texture = textureAtlas as BitmapData;
				}
			}
			else
			{
				textureAtlasData = BaseObject.borrowObject(FlashTextureAtlasData) as FlashTextureAtlasData;
			}
			
			return textureAtlasData;
		}
		
		/**
		 * @private
		 */
		override protected function _generateArmature(dataPackage:BuildArmaturePackage):Armature
		{
			const armature:Armature = BaseObject.borrowObject(Armature) as Armature;
			const armatureDisplayContainer:FlashArmatureDisplay = new FlashArmatureDisplay();
			
			armature._armatureData = dataPackage.armature;
			armature._skinData = dataPackage.skin;
			armature._animation = dragonBones.core.BaseObject.borrowObject(Animation) as Animation;
			armature._display = armatureDisplayContainer;
			
			armature._animation._armature = armature;
			armatureDisplayContainer._armature = armature;
			
			armature.animation.animations = dataPackage.armature.animations;
			
			return armature;
		}
		
		/**
		 * @private
		 */
		override protected function _generateSlot(dataPackage:BuildArmaturePackage, slotDisplayDataSet:SlotDisplayDataSet):Slot
		{
			const slot:FlashSlot = BaseObject.borrowObject(FlashSlot) as FlashSlot;
			const slotData:SlotData = slotDisplayDataSet.slot;
			const displayList:Vector.<Object> = new Vector.<Object>(slotDisplayDataSet.displays.length, true);
			
			slot.name = slotData.name;
			slot._rawDisplay = new Shape();
			slot._meshDisplay = slot._rawDisplay;
			
			var displayIndex:uint = 0;
			for each (var displayData:DisplayData in slotDisplayDataSet.displays)
			{
				switch (displayData.type)
				{
					case DragonBones.DISPLAY_TYPE_IMAGE:
						if (!displayData.textureData)
						{
							displayData.textureData = this._getTextureData(dataPackage.dataName, displayData.name);
						}
						
						displayList[displayIndex] = slot._rawDisplay;
						break;
					
					case DragonBones.DISPLAY_TYPE_MESH:
						if (!displayData.textureData)
						{
							displayData.textureData = this._getTextureData(dataPackage.dataName, displayData.name);
						}
						
						displayList[displayIndex] = slot._meshDisplay;
						break;
					
					case DragonBones.DISPLAY_TYPE_ARMATURE:
						const childArmature:Armature = buildArmature(displayData.name, dataPackage.dataName);
						if (childArmature) 
						{
							if (!slot.inheritAnimation)
							{
								const actions:Vector.<ActionData> = slotData.actions.length > 0? slotData.actions: childArmature.armatureData.actions;
								if (actions.length > 0) 
								{
									for (var i:uint = 0, l:uint = actions.length; i < l; ++i) 
									{
										childArmature._bufferAction(actions[i]);
									}
								} 
								else 
								{
									childArmature.animation.play();
								}
							}
							
							displayData.armatureData = childArmature.armatureData; // 
						}
						
						displayList[displayIndex] = childArmature;
						break;
					
					default:
						displayList[displayIndex] = null;
						break;
				}
				
				displayIndex++;
			}
			
			slot._setDisplayList(displayList);
			
			return slot;
		}
		
		/**
		 * @language zh_CN
		 * 创建一个指定名称的骨架，并使用骨架的显示容器来更新骨架动画。
		 * @param armatureName 骨架数据名称。
		 * @param dragonBonesName 龙骨数据名称，如果未设置，将检索所有的龙骨数据，当多个数据中包含同名的骨架数据时，可能无法创建出准确的骨架。
		 * @param skinName 皮肤名称，如果未设置，则使用默认皮肤。
		 * @return 骨架的显示容器。
		 * @see dragonBones.core.IArmatureDisplayContainer
		 * @version DragonBones 4.5
		 */
		public function buildArmatureDisplay(armatureName:String, dragonBonesName:String = null, skinName:String = null):FlashArmatureDisplay
		{
			const armature:Armature = this.buildArmature(armatureName, dragonBonesName, skinName);
			const armatureDisplay:FlashArmatureDisplay = armature? (armature.display as FlashArmatureDisplay): null;
			if (armatureDisplay)
			{
				armatureDisplay.advanceTimeBySelf(true);
			}
			
			return armatureDisplay;
		}
		
		/**
		 * @language zh_CN
		 * 获取全局声音事件管理器。
		 * @version DragonBones 3.0
		 */
		public function get soundEventManager(): FlashArmatureDisplay
		{
			return EventObject._soundEventManager as FlashArmatureDisplay;
		}
	}
}