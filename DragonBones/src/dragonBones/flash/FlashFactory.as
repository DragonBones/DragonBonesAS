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
	import dragonBones.factories.BaseFactory;
	import dragonBones.factories.BuildArmaturePackage;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.textures.TextureAtlasData;
	
	use namespace dragonBones_internal;
	
	/**
	 * 
	 */
	public class FlashFactory extends BaseFactory
	{	
		public function FlashFactory()
		{
			super(this);
			
			if (!Armature.soundEventManager) 
			{
				Armature.soundEventManager = new FlashArmatureDisplayContainer();
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
			const armatureDisplayContainer:FlashArmatureDisplayContainer = new FlashArmatureDisplayContainer();
			
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
							childArmature.animation.play();
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
		 * 
		 */
		public function buildArmatureDisplay(armatureName:String, dragonBonesName:String = null, skinName:String = null):FlashArmatureDisplayContainer
		{
			const armature:Armature = this.buildArmature(armatureName, dragonBonesName, skinName);
			const armatureDisplay:FlashArmatureDisplayContainer = armature? (armature.display as FlashArmatureDisplayContainer): null;
			if (armatureDisplay)
			{
				armatureDisplay.advanceTimeBySelf(true);
			}
			
			return armatureDisplay;
		}
	}
}