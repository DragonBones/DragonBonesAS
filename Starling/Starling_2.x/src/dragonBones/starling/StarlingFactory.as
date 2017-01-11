package dragonBones.starling
{
	import flash.display.BitmapData;
	
	import dragonBones.Armature;
	import dragonBones.Slot;
	import dragonBones.animation.WorldClock;
	import dragonBones.core.BaseObject;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.DisplayType;
	import dragonBones.factories.BaseFactory;
	import dragonBones.factories.BuildArmaturePackage;
	import dragonBones.objects.ActionData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.SkinSlotData;
	import dragonBones.objects.SlotData;
	import dragonBones.parsers.DataParser;
	import dragonBones.textures.TextureAtlasData;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.events.EnterFrameEvent;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * Starling 工厂。
	 * @version DragonBones 3.0
	 */
	public final class StarlingFactory extends BaseFactory
	{
		/**
		 * @private
		 */
		protected static const _eventManager:StarlingArmatureDisplay = new StarlingArmatureDisplay();
		/**
		 * @private
		 */
		dragonBones_internal static const _clock:WorldClock = new WorldClock();
		/**
		 * @language zh_CN
		 * 一个可以直接使用的全局工厂实例.
		 * @version DragonBones 4.7
		 */
		public static const factory:StarlingFactory = new StarlingFactory();
		/**
		 * @private
		 */
		protected static function _clockHandler(event:EnterFrameEvent):void 
		{
			_clock.advanceTime(event.passedTime);
		}
		
		public var generateMipMaps:Boolean = true;
		/**
		 * @language zh_CN
		 * 创建一个工厂。
		 * @version DragonBones 3.0
		 */
		public function StarlingFactory(dataParser:DataParser = null)
		{
			super(this, dataParser);
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
					(textureAtlasData as StarlingTextureAtlasData).disposeTexture = true;
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
			if (Starling.current && !Starling.current.stage.hasEventListener(EnterFrameEvent.ENTER_FRAME))
			{
				Starling.current.stage.addEventListener(EnterFrameEvent.ENTER_FRAME, _clockHandler);
			}
			
			const armature:Armature = BaseObject.borrowObject(Armature) as Armature;
			const armatureDisplay:StarlingArmatureDisplay = new StarlingArmatureDisplay();
			armatureDisplay._armature = armature;
			
			armature._init(
				dataPackage.armature, dataPackage.skin,
				armatureDisplay, armatureDisplay, _eventManager
			);
			
			return armature;
		}
		/**
		 * @private
		 */
		override protected function _generateSlot(dataPackage:BuildArmaturePackage, skinSlotData:SkinSlotData, armature:Armature):Slot
		{
			const slot:StarlingSlot = BaseObject.borrowObject(StarlingSlot) as StarlingSlot;
			const slotData:SlotData = skinSlotData.slot;
			const displayList:Vector.<Object> = new Vector.<Object>(skinSlotData.displays.length, true);
			
			slot._indexData = new IndexData();
			slot._vertexData = new VertexData();
			
			slot._init(skinSlotData, new Image(null), new Mesh(slot._vertexData, slot._indexData));
			
			for (var i:uint = 0, l:uint = skinSlotData.displays.length; i < l; ++i) 
			{
				const displayData:DisplayData = skinSlotData.displays[i];
				switch (displayData.type)
				{
					case DisplayType.Image:
						if (!displayData.texture || dataPackage.textureAtlasName)
						{
							displayData.texture = _getTextureData(dataPackage.textureAtlasName || dataPackage.dataName, displayData.name);
						}
						
						displayList[i] = slot.rawDisplay;
						break;
					
					case DisplayType.Mesh:
						if (!displayData.texture)
						{
							displayData.texture = _getTextureData(dataPackage.textureAtlasName || dataPackage.dataName, displayData.name);
						}
						
						displayList[i] = slot.meshDisplay;
						break;
					
					case DisplayType.Armature:
						const childArmature:Armature = buildArmature(displayData.name, dataPackage.dataName, null, dataPackage.textureAtlasName);
						if (childArmature) 
						{
							if (!childArmature.inheritAnimation)
							{
								const actions:Vector.<ActionData> = slotData.actions.length > 0? slotData.actions: childArmature.armatureData.actions;
								if (actions.length > 0) 
								{
									for each (var action:ActionData in actions) 
									{
										childArmature._bufferAction(action);
									}
								} 
								else 
								{
									childArmature.animation.play();
								}
							}
							
							displayData.armature = childArmature.armatureData; // 
						}
						
						displayList[i] = childArmature;
						break;
					
					default:
						displayList[i] = null;
						break;
				}
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
		 * @param textureAtlasName 贴图集数据名称，如果未设置，则使用龙骨数据名称。
		 * @return 骨架的显示容器。
		 * @see dragonBones.starling.StarlingArmatureDisplay
		 * @version DragonBones 4.5
		 */
		public function buildArmatureDisplay(armatureName:String, dragonBonesName:String = null, skinName:String = null, textureAtlasName:String = null):StarlingArmatureDisplay
		{
			const armature:Armature = buildArmature(armatureName, dragonBonesName, skinName, textureAtlasName);
			if (armature)
			{
				_clock.add(armature);
				return armature.display as StarlingArmatureDisplay;
			}
			
			return null;
		}
		/**
		 * @language zh_CN
		 * 获取带有指定贴图的显示对象。
		 * @param textureName 指定的贴图名称。
		 * @param textureAtlasName 指定的贴图集数据名称，如果未设置，将检索所有的贴图集数据。
		 * @version DragonBones 3.0
		 */
		public function getTextureDisplay(textureName:String, textureAtlasName:String = null):Image 
		{
			const textureData:StarlingTextureData = _getTextureData(textureAtlasName, textureName) as StarlingTextureData;
			if (textureData)
			{
				if (!textureData.texture)
				{
					const textureAtlasTexture:Texture = (textureData.parent as StarlingTextureAtlasData).texture;
					textureData.texture = new SubTexture(textureAtlasTexture, textureData.region, false, null, textureData.rotated);
				}
				
				return new Image(textureData.texture);
			}
			
			return null;
		}
		/**
		 * @language zh_CN
		 * 获取全局声音事件管理器。
		 * @version DragonBones 4.5
		 */
		public function get soundEventManager(): StarlingArmatureDisplay
		{
			return _eventManager;
		}
	}
}