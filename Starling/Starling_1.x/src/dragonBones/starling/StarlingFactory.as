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
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace dragonBones_internal;
	
	public final class StarlingFactory extends BaseFactory
	{
		public var generateMipMaps:Boolean = true;
		
		private var _armatureDisplayClass:Class = null;
		
		public function StarlingFactory()
		{
			super(this);
			
			if (!Armature._soundEventManager) 
			{
				Armature._soundEventManager = new StarlingArmatureDisplayContainer();
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
			const armatureDisplayContainer:StarlingArmatureDisplayContainer = _armatureDisplayClass? new _armatureDisplayClass(): new StarlingArmatureDisplayContainer();
			
			armature._armatureData = dataPackage.armature;
			armature._skinData = dataPackage.skin;
			armature._animation = BaseObject.borrowObject(Animation) as Animation;
			armature._display = armatureDisplayContainer;
			
			armatureDisplayContainer._armature = armature;
			armature._animation._armature = armature;
			
			armature.animation.animations = dataPackage.armature.animations;
			
			_armatureDisplayClass = null;
			
			return armature;
		}
		
		/**
		 * @private
		 */
		override protected function _generateSlot(dataPackage:BuildArmaturePackage, slotDisplayDataSet:SlotDisplayDataSet):Slot
		{
			const slot:Slot = BaseObject.borrowObject(StarlingSlot) as StarlingSlot;
			const slotData:SlotData = slotDisplayDataSet.slot;
			const displayList:Vector.<Object> = new Vector.<Object>();
			
			slot.name = slotData.name;
			slot._rawDisplay = new Image(StarlingSlot.EMPTY_TEXTURE);
			
			for each (var displayData:DisplayData in slotDisplayDataSet.displays)
			{
				switch (displayData.type)
				{
					case DragonBones.DISPLAY_TYPE_IMAGE:
						if (!displayData.textureData)
						{
							displayData.textureData = this._getTextureData(dataPackage.dataName, displayData.name);
						}
						
						displayList.push(slot._rawDisplay);
						break;
					
					case DragonBones.DISPLAY_TYPE_ARMATURE:
						const childArmature:Armature = buildArmature(displayData.name, dataPackage.dataName);
						if (childArmature)
						{
							childArmature.animation.play();
						}
						
						displayList.push(childArmature);
						break;
					
					case DragonBones.DISPLAY_TYPE_MESH:
						if (!displayData.textureData)
						{
							displayData.textureData = this._getTextureData(dataPackage.dataName, displayData.name);
						}
						
						displayList.push(_generateMeshDisplay(displayData));
						break;
					
					default:
						displayList.push(null);
						break;
				}
			}
		
			slot._setDisplayList(displayList);
			
			return slot;
		}
		
		private function _generateMeshDisplay(displayData:DisplayData):*
		{
			/*const meshData:MeshData = displayData.meshData;
			const vertexData:VertexData = new VertexData();
			const indexData:IndexData = new IndexData();
			
			var i:uint = 0, l:uint = 0;
			for (i = 0, l = meshData.uvs.length; i < l; i += 2)
			{
				const iH:uint = i / 2;
				vertexData.setPoint(iH, "texCoords", meshData.uvs[i], meshData.uvs[i + 1]);
				vertexData.setPoint(iH, "position", meshData.vertices[i], meshData.vertices[i + 1]);
			}
			
			for (i = 0, l = meshData.vertexIndices.length; i < l; ++i)
			{
				indexData.setIndex(i, meshData.vertexIndices[i]);
			}
			
			const textureData:StarlingTextureData = displayData.textureData as StarlingTextureData;
			if (!textureData.texture)
			{
				const textureAtlasTexture:Texture = (textureData.parent as StarlingTextureAtlasData).texture;
				if (textureAtlasTexture)
				{
					textureData.texture = new SubTexture(textureAtlasTexture, textureData.region, false, textureData.frame, textureData.rotated, 1 / textureData.parent.scale);
				}
			}
			
			const mesh:Mesh = new Mesh(vertexData, indexData);
			mesh.texture = textureData.texture;*/
			
			return null;
		}
		
		/**
		 * 
		 */
		public function buildArmatureDisplay(armatureName:String, dragonBonesName:String = null, skinName:String = null, displayClass:Class = null):StarlingArmatureDisplayContainer
		{
			_armatureDisplayClass = displayClass;
			
			const armature:Armature = this.buildArmature(armatureName, dragonBonesName, skinName);
			const armatureDisplay:StarlingArmatureDisplayContainer = armature? (armature.display as StarlingArmatureDisplayContainer): null;
			if (armatureDisplay)
			{
				armatureDisplay.advanceTimeBySelf(true);
			}
			
			return armatureDisplay;
		}
		
		/**
		 * 
		 */
		public function get soundEventManager(): StarlingArmatureDisplayContainer
		{
			return Armature._soundEventManager as StarlingArmatureDisplayContainer;
		}
	}
}