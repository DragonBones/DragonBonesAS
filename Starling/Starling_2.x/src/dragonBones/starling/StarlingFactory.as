package dragonBones.starling
{
	import flash.display.BitmapData;
	
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.animation.Animation;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.factories.BaseFactory;
	import dragonBones.factories.BuildArmaturePackage;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.MeshData;
	import dragonBones.objects.SlotData;
	import dragonBones.objects.SlotDisplayDataSet;
	import dragonBones.textures.TextureAtlasData;
	
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace dragonBones_internal;
	
	public final class StarlingFactory extends BaseFactory
	{
		public var generateMipMaps:Boolean = true;
		
		public function StarlingFactory()
		{
			super(this);
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
					(textureAtlasData as StarlingTextureAtlasData).texture = Texture.fromBitmapData(textureAtlas as BitmapData, generateMipMaps, false, textureAtlasData.scale);
				}
				else if (textureAtlas is Texture)
				{
					(textureAtlasData as StarlingTextureAtlasData).texture = textureAtlas as Texture;
				}
			}
			else
			{
				textureAtlasData = BaseObject.borrowObject(StarlingTextureAtlasData) as StarlingTextureAtlasData;
			}
			
			return textureAtlasData;
		}
		
		/**
		 * @private
		 */
		override protected function _generateArmature(dataPackage:BuildArmaturePackage):Armature
		{
			const armature:Armature = BaseObject.borrowObject(Armature) as Armature;
			const armatureDisplayContainer:StarlingArmatureDisplayContainer = new StarlingArmatureDisplayContainer();
			
			armature._armatureData = dataPackage.armature;
			armature._skinData = dataPackage.skin;
			armature._animation = BaseObject.borrowObject(Animation) as Animation;
			armature._display = armatureDisplayContainer;
			
			armatureDisplayContainer._armature = armature;
			armature._animation._armature = armature;
			
			armature.animation.animations = dataPackage.armature.animations;
			
			return armature;
		}
		
		/**
		 * @private
		 */
		override protected function _generateSlot(dataPackage:BuildArmaturePackage, slotDisplayDataSet:SlotDisplayDataSet):Slot
		{
			const slot:StarlingSlot = BaseObject.borrowObject(StarlingSlot) as StarlingSlot;
			const slotData:SlotData = slotDisplayDataSet.slot;
			const displayList:Vector.<Object> = new Vector.<Object>(slotDisplayDataSet.displays.length, true);
			
			slot.name = slotData.name;
			slot._rawDisplay = new Image(null);
			
			slot._indexData = new IndexData();
			slot._vertexData = new VertexData();
			slot._meshDisplay = new Mesh(slot._vertexData, slot._indexData);
			
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
		public function buildArmatureDisplay(armatureName:String, dragonBonesName:String = null, skinName:String = null):StarlingArmatureDisplayContainer
		{
			const armature:Armature = this.buildArmature(armatureName, dragonBonesName, skinName);
			
			return armature? (armature.display as StarlingArmatureDisplayContainer): null;
		}
	}
}