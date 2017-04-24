package dragonBones.factories
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.core.BaseObject;
	import dragonBones.core.DragonBones;
	import dragonBones.core.dragonBones_internal;
	import dragonBones.enum.DisplayType;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.DragonBonesData;
	import dragonBones.objects.SkinData;
	import dragonBones.objects.SkinSlotData;
	import dragonBones.objects.SlotData;
	import dragonBones.parsers.DataParser;
	import dragonBones.parsers.ObjectDataParser;
	import dragonBones.textures.TextureAtlasData;
	import dragonBones.textures.TextureData;
	
	use namespace dragonBones_internal;
	
	/** 
	 * Dispatched after a sucessful call to parseDragonBonesData().
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * @language zh_CN
	 * 创建骨架的基础工厂。
	 * @see dragonBones.objects.DragonBonesData
	 * @see dragonBones.textures.TextureAtlasData
	 * @see dragonBones.objects.ArmatureData
	 * @see dragonBones.Armature
	 * @version DragonBones 3.0
	 */
	public class BaseFactory extends EventDispatcher
	{
		/**
		 * @private
		 */
		protected static const _defaultDataParser:DataParser = new ObjectDataParser();
		/**
		 * @language zh_CN
		 * 是否开启共享搜索。
		 * 如果开启，创建一个骨架时，可以从多个龙骨数据中寻找骨架数据，或贴图集数据中寻找贴图数据。 (通常在有共享导出的数据时开启)
		 * @see dragonBones.DragonBonesData#autoSearch
		 * @see dragonBones.TextureAtlasData#autoSearch
		 * @version DragonBones 4.5
		 */
		public var autoSearch:Boolean = false;
		/** 
		 * @private 
		 */
		protected const _dragonBonesDataMap:Object = {};
		/** 
		 * @private 
		 */
		protected const _textureAtlasDataMap:Object = {};
		/** 
		 * @private 
		 */
		protected var _dataParser:DataParser = null;
		/** 
		 * @private 
		 */
		public function BaseFactory(self:BaseFactory, dataParser:DataParser = null)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
			
			_dataParser = dataParser || _defaultDataParser;
		}
		/** 
		 * @private
		 */
		protected function _getTextureData(textureAtlasName:String, textureName:String):TextureData
		{
			var textureAtlasDataList:Vector.<TextureAtlasData> = _textureAtlasDataMap[textureAtlasName];
			if (textureAtlasDataList)
			{
				for (var i:uint = 0, l:uint = textureAtlasDataList.length; i < l; ++i)
				{
					var textureData:TextureData = textureAtlasDataList[i].getTexture(textureName);
					if (textureData)
					{
						return textureData;
					}
				}
			}
			
			if (autoSearch)
			{
				for each (textureAtlasDataList in _textureAtlasDataMap)
				{
					for (i = 0, l = textureAtlasDataList.length; i < l; ++i)
					{
						const textureAtlasData:TextureAtlasData = textureAtlasDataList[i];
						if (textureAtlasData.autoSearch)
						{
							textureData = textureAtlasData.getTexture(textureName);
							if (textureData)
							{
								return textureData;
							}
						}
					}
				}
			}
			
			return null;
		}
		/** 
		 * @private
		 */
		protected function _fillBuildArmaturePackage(dataPackage:BuildArmaturePackage, dragonBonesName:String, armatureName:String, skinName:String, textureAtlasName:String):Boolean
		{
			var dragonBonesData:DragonBonesData = null;
			var armatureData:ArmatureData = null;
			
			if (dragonBonesName)
			{
				dragonBonesData = _dragonBonesDataMap[dragonBonesName];
				if (dragonBonesData)
				{
					armatureData = dragonBonesData.getArmature(armatureName);
				}
			}
			
			if (!armatureData && (!dragonBonesName || autoSearch))
			{
				for (var eachDragonBonesName:String in _dragonBonesDataMap)
				{
					dragonBonesData = _dragonBonesDataMap[eachDragonBonesName];
					if (!dragonBonesName || dragonBonesData.autoSearch)
					{
						armatureData = dragonBonesData.getArmature(armatureName);
						if (armatureData)
						{
							dragonBonesName = eachDragonBonesName;
							break;
						}
					}
				}
			}
			
			if (armatureData)
			{
				dataPackage.dataName = dragonBonesName;
				dataPackage.textureAtlasName = textureAtlasName;
				dataPackage.data = dragonBonesData;
				dataPackage.armature = armatureData;
				dataPackage.skin = armatureData.getSkin(skinName);
				if (!dataPackage.skin) 
				{
					dataPackage.skin = armatureData.defaultSkin;
				}
				
				return true;
			}
			
			return false;
		}
		/** 
		 * @private
		 */
		protected function _buildBones(dataPackage:BuildArmaturePackage, armature:Armature):void
		{
			const bones:Vector.<BoneData> = dataPackage.armature.sortedBones;
			for (var i:uint = 0, l:uint = bones.length; i < l; ++i)
			{
				const boneData:BoneData = bones[i];
				const bone:Bone = BaseObject.borrowObject(Bone) as Bone;
				bone._init(boneData);
				
				if(boneData.parent)
				{
					armature._addBone(bone, boneData.parent.name);
				}
				else
				{
					armature._addBone(bone);
				}
				
				if (boneData.ik)
				{
					bone.ikBendPositive = boneData.bendPositive;
					bone.ikWeight = boneData.weight;
					bone._setIK(armature.getBone(boneData.ik.name), boneData.chain, boneData.chainIndex);
				}
			}
		}
		/**
		 * @private
		 */
		protected function _buildSlots(dataPackage:BuildArmaturePackage, armature:Armature):void
		{
			const currentSkin:SkinData = dataPackage.skin;
			const defaultSkin:SkinData = dataPackage.armature.defaultSkin;
			const slotDisplayDataSetMap:Object = {};
			
			for each (var skinSlotData:SkinSlotData in defaultSkin.slots)
			{
				slotDisplayDataSetMap[skinSlotData.slot.name] = skinSlotData;
			}
			
			if (currentSkin != defaultSkin)
			{
				for each (skinSlotData in currentSkin.slots)
				{
					slotDisplayDataSetMap[skinSlotData.slot.name] = skinSlotData;
				}
			}
			
			const slots:Vector.<SlotData> = dataPackage.armature.sortedSlots;
			for (var i:uint = 0, l:uint = slots.length; i < l; ++i) 
			{
				const slotData:SlotData = slots[i];
				skinSlotData = slotDisplayDataSetMap[slotData.name];
				if (!skinSlotData)
				{
					continue;
				}
				
				const slot:Slot = _generateSlot(dataPackage, skinSlotData, armature);
				if (slot)
				{
					armature._addSlot(slot, slotData.parent.name);
					slot._setDisplayIndex(slotData.displayIndex);
				}
			}
		}
		/**
		 * @private
		 */
		protected function _replaceSlotDisplay(dataPackage:BuildArmaturePackage, displayData:DisplayData, slot:Slot, displayIndex:int):void
		{
			if (displayIndex < 0) 
			{
				displayIndex = slot.displayIndex;
			}
			
			if (displayIndex >= 0) 
			{
				const displayList:Vector.<Object> = slot.displayList; // Copy.
				if (displayList.length <= displayIndex) 
				{
					displayList.length = displayIndex + 1;
				}
				
				if (slot._replacedDisplayDatas.length <= displayIndex) 
				{
					slot._replacedDisplayDatas.length = displayIndex + 1;
				}
				
				slot._replacedDisplayDatas[displayIndex] = displayData;
				
				if (displayData.type === DisplayType.Armature) 
				{
					const childArmature:Armature = buildArmature(displayData.path, dataPackage.dataName, null, dataPackage.textureAtlasName);
					displayList[displayIndex] = childArmature;
				}
				else 
				{
					if (!displayData.texture || dataPackage.textureAtlasName) 
					{
						displayData.texture = _getTextureData(dataPackage.textureAtlasName ? dataPackage.textureAtlasName : dataPackage.dataName, displayData.path);
					}
					
					const displayDatas:Vector.<DisplayData> = slot.skinSlotData.displays;
					if (
						displayData.mesh ||
						(displayIndex < displayDatas.length && displayDatas[displayIndex].mesh)
					) 
					{
						displayList[displayIndex] = slot.meshDisplay;
					}
					else 
					{
						displayList[displayIndex] = slot.rawDisplay;
					}
				}
				
				slot.displayList = displayList;
			}
		}
		/**
		 * @private
		 */
		protected function _generateTextureAtlasData(textureAtlasData:TextureAtlasData, textureAtlas:Object):TextureAtlasData
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
			return null;
		}
		/**
		 * @private
		 */
		protected function _generateArmature(dataPackage:BuildArmaturePackage):Armature
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
			return null;
		}
		/** 
		 * @private
		 */
		protected function _generateSlot(dataPackage:BuildArmaturePackage, slotDisplayDataSet:SkinSlotData, armature:Armature):Slot
		{
			throw new Error(DragonBones.ABSTRACT_METHOD_ERROR);
			return null;
		}
		/**
		 * @language zh_CN
		 * 解析并添加龙骨数据。
		 * @param rawData 需要解析的原始数据。 (JSON，如果是 merged data 则需要监听 Event.COMPLETE 事件，因为这是一个异步的过程)
		 * @param dragonBonesName 为数据指定一个名称，以便可以通过这个名称来获取数据，如果未设置，则使用数据中的名称。
		 * @return DragonBonesData
		 * @see #getDragonBonesData()
		 * @see #addDragonBonesData()
		 * @see #removeDragonBonesData()
		 * @see dragonBones.objects.DragonBonesData
		 * @version DragonBones 4.5
		 */
		public function parseDragonBonesData(rawData:Object, dragonBonesName:String = null, scale:Number = 1.0):DragonBonesData
		{
			//
			var isComplete:Boolean = true;
			if (rawData is ByteArray)
			{
				const decodeData:DecodedData = DecodedData.decode(rawData as ByteArray);
				if (decodeData)
				{
					_decodeDataList.push(decodeData);
					decodeData.name = dragonBonesName || "";
					decodeData.contentLoaderInfo.addEventListener(Event.COMPLETE, _loadTextureAtlasHandler);
					decodeData.loadBytes(decodeData.textureAtlasBytes, null);
					rawData = decodeData.dragonBonesData;
					isComplete = false;
				}
				else
				{
					return null;
				}
			}
			
			const dragonBonesData:DragonBonesData = _dataParser.parseDragonBonesData(rawData, scale);
			addDragonBonesData(dragonBonesData, dragonBonesName);
			
			//
			if (isComplete)
			{
				clearTimeout(_delayID);
				_delayID = setTimeout(dispatchEvent, 30, new Event(Event.COMPLETE));
			}
			
			return dragonBonesData;
		}
		/**
		 * @language zh_CN
		 * 解析并添加贴图集数据。
		 * @param rawData 需要解析的原始数据。 (JSON)
		 * @param textureAtlas 贴图。 (根据渲染引擎的不同而不同，通常是贴图或材质)
		 * @param name 为数据指定一个名称，以便可以通过这个名称来访问数据，如果未设置，则使用数据中的名称。
		 * @param scale 为贴图集设置一个缩放值。
		 * @return 贴图集数据
		 * @see #getTextureAtlasData()
		 * @see #addTextureAtlasData()
		 * @see #removeTextureAtlasData()
		 * @see dragonBones.textures.TextureAtlasData
		 * @version DragonBones 4.5
		 */
		public function parseTextureAtlasData(rawData:Object, textureAtlas:Object, name:String = null, scale:Number = 0.0, rawScale:Number = 0.0):TextureAtlasData
		{
			const textureAtlasData:TextureAtlasData = _generateTextureAtlasData(null, null);
			_dataParser.parseTextureAtlasData(rawData, textureAtlasData, scale, rawScale);
			
			if (textureAtlas is Bitmap)
			{
				textureAtlas = (textureAtlas as Bitmap).bitmapData;
			}
			else if (textureAtlas is DisplayObject)
			{
				const displayObject:DisplayObject = textureAtlas as DisplayObject;
				const rect:Rectangle = displayObject.getRect(displayObject);
				const matrix:Matrix = new Matrix();
				matrix.scale(textureAtlasData.scale, textureAtlasData.scale);
				textureAtlasData.bitmapData = new BitmapData(
					(rect.x + displayObject.width) * textureAtlasData.scale, 
					(rect.y + displayObject.height) * textureAtlasData.scale, 
					true, 
					0
				);
				
				textureAtlasData.bitmapData.draw(displayObject, matrix, null, null, null, smoothing);
				textureAtlas = textureAtlasData.bitmapData;
			}
			
			_generateTextureAtlasData(textureAtlasData, textureAtlas);
			addTextureAtlasData(textureAtlasData, name);
			
			return textureAtlasData;
		}
		/**
		 * @language zh_CN
		 * 获取指定名称的龙骨数据。
		 * @param name 数据名称
		 * @return DragonBonesData
		 * @see #parseDragonBonesData()
		 * @see #addDragonBonesData()
		 * @see #removeDragonBonesData()
		 * @see dragonBones.objects.DragonBonesData
		 * @version DragonBones 3.0
		 */
		public function getDragonBonesData(name:String):DragonBonesData
		{
			return _dragonBonesDataMap[name] as DragonBonesData;
		}
		/**
		 * @language zh_CN
		 * 添加龙骨数据。
		 * @param data 龙骨数据。
		 * @param dragonBonesName 为数据指定一个名称，以便可以通过这个名称来访问数据，如果未设置，则使用数据中的名称。
		 * @see #parseDragonBonesData()
		 * @see #getDragonBonesData()
		 * @see #removeDragonBonesData()
		 * @see dragonBones.objects.DragonBonesData
		 * @version DragonBones 3.0
		 */
		public function addDragonBonesData(data:DragonBonesData, dragonBonesName:String = null):void
		{
			if (data)
			{
				dragonBonesName = dragonBonesName || data.name;
				if (dragonBonesName)
				{
					if (!_dragonBonesDataMap[dragonBonesName])
					{
						_dragonBonesDataMap[dragonBonesName] = data;
					}
					else
					{
						throw new Error("Same name data.");
					}
				}
				else
				{
					throw new Error("Unnamed data.");
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
		/**
		 * @language zh_CN
		 * 移除龙骨数据。
		 * @param dragonBonesName 数据名称
		 * @param disposeData 是否释放数据。 [false: 不释放, true: 释放]
		 * @see #parseDragonBonesData()
		 * @see #getDragonBonesData()
		 * @see #addDragonBonesData()
		 * @see dragonBones.objects.DragonBonesData
		 * @version DragonBones 3.0
		 */
		public function removeDragonBonesData(dragonBonesName:String, disposeData:Boolean = true):void
		{
			const dragonBonesData:DragonBonesData = _dragonBonesDataMap[dragonBonesName];
			if (dragonBonesData)
			{
				if (disposeData)
				{
					dragonBonesData.returnToPool();
				}
				
				delete _dragonBonesDataMap[dragonBonesName];
			}
		}
		/**
		 * @language zh_CN
		 * 获取指定名称的贴图集数据列表。
		 * @param dragonBonesName 数据名称。
		 * @return 贴图集数据列表。
		 * @see #parseTextureAtlasData()
		 * @see #addTextureAtlasData()
		 * @see #removeTextureAtlasData()
		 * @see dragonBones.textures.TextureAtlasData
		 * @version DragonBones 3.0
		 */
		public function getTextureAtlasData(dragonBonesName:String):Vector.<TextureAtlasData>
		{
			return _textureAtlasDataMap[dragonBonesName] as Vector.<TextureAtlasData>;
		}
		/**
		 * @language zh_CN
		 * 添加贴图集数据。
		 * @param data 贴图集数据。
		 * @param dragonBonesName 为数据指定一个名称，以便可以通过这个名称来访问数据，如果未设置，则使用数据中的名称。
		 * @see #parseTextureAtlasData()
		 * @see #getTextureAtlasData()
		 * @see #removeTextureAtlasData()
		 * @see dragonBones.textures.TextureAtlasData
		 * @version DragonBones 3.0
		 */
		public function addTextureAtlasData(data:TextureAtlasData, dragonBonesName:String = null):void
		{
			if (data)
			{
				dragonBonesName = dragonBonesName || data.name;
				if (dragonBonesName)
				{
					const textureAtlasList:Vector.<TextureAtlasData> = _textureAtlasDataMap[dragonBonesName] = _textureAtlasDataMap[dragonBonesName] || new Vector.<TextureAtlasData>;		
					if (textureAtlasList.indexOf(data) < 0)
					{
						textureAtlasList.push(data);
					}
				}
				else
				{
					throw new Error("Unnamed data.");
				}
			}
			else
			{
				throw new ArgumentError();
			}
		}
		/**
		 * @language zh_CN
		 * 移除贴图集数据。
		 * @param dragonBonesName 数据名称。
		 * @param disposeData 是否释放数据。 [false: 不释放, true: 释放]
		 * @see #parseTextureAtlasData()
		 * @see #getTextureAtlasData()
		 * @see #addTextureAtlasData()
		 * @see dragonBones.textures.TextureAtlasData
		 * @version DragonBones 3.0
		 */
		public function removeTextureAtlasData(dragonBonesName:String, disposeData:Boolean = true):void
		{
			const textureAtlasDataList:Vector.<TextureAtlasData> = _textureAtlasDataMap[dragonBonesName] as Vector.<TextureAtlasData>;
			if (textureAtlasDataList)
			{
				if (disposeData)
				{
					for each (var textureAtlasData:TextureAtlasData in textureAtlasDataList)
					{
						textureAtlasData.returnToPool();
					}
				}
				
				delete _textureAtlasDataMap[dragonBonesName];
			}
		}
		/**
		 * @language zh_CN
		 * 清除所有的数据。
		 * @param disposeData 是否释放数据。
		 * @version DragonBones 4.5
		 */
		public function clear(disposeData:Boolean = true):void
		{
			for (var k:String  in _dragonBonesDataMap)
			{
				if (disposeData)
				{
					(_dragonBonesDataMap[k] as DragonBonesData).returnToPool();
				}
				
				delete _dragonBonesDataMap[k];
			}
			
			for (k in _textureAtlasDataMap)
			{
				if (disposeData)
				{
					const textureAtlasDataList:Vector.<TextureAtlasData> = _textureAtlasDataMap[k];
					for (var i:uint = 0, l:uint = textureAtlasDataList.length; i < l; ++i) 
					{
						textureAtlasDataList[i].returnToPool();
					}
				}
				
				delete _textureAtlasDataMap[k];
			}
		}
		/**
		 * @language zh_CN
		 * 创建一个指定名称的骨架。
		 * @param armatureName 骨架数据名称。
		 * @param dragonBonesName 龙骨数据名称，如果未设置，将检索所有的龙骨数据，当多个龙骨数据中包含同名的骨架数据时，可能无法创建出准确的骨架。
		 * @param skinName 皮肤名称，如果未设置，则使用默认皮肤。
		 * @param textureAtlasName 贴图集数据名称，如果未设置，则使用龙骨数据。
		 * @return 骨架。
		 * @see dragonBones.Armature
		 * @version DragonBones 3.0
		 */
		public function buildArmature(armatureName:String, dragonBonesName:String = null, skinName:String = null, textureAtlasName:String = null):Armature
		{
			const dataPackage:BuildArmaturePackage = new BuildArmaturePackage();
			if (_fillBuildArmaturePackage(dataPackage, dragonBonesName, armatureName, skinName, textureAtlasName))
			{
				const armature:Armature = _generateArmature(dataPackage);
				_buildBones(dataPackage, armature);
				_buildSlots(dataPackage, armature);
				
				armature.invalidUpdate(null, true);
				armature.advanceTime(0.0); // Update armature pose.
				return armature;
			}
			
			return null;
		}
		/**
		 * @language zh_CN
		 * 将指定骨架的动画替换成其他骨架的动画。 (通常这些骨架应该具有相同的骨架结构)
		 * @param toArmature 指定的骨架。
		 * @param fromArmatreName 其他骨架的名称。
		 * @param fromSkinName 其他骨架的皮肤名称，如果未设置，则使用默认皮肤。
		 * @param fromDragonBonesDataName 其他骨架属于的龙骨数据名称，如果未设置，则检索所有龙骨数据。
		 * @param ifRemoveOriginalAnimationList 是否移除原有的动画。 [true: 移除, false: 不移除]
		 * @return 是否替换成功。 [true: 成功, false: 不成功]
		 * @see dragonBones.Armature
		 * @version DragonBones 4.5
		 */
		public function copyAnimationsToArmature(
			toArmature:Armature, fromArmatreName:String, fromSkinName:String = null,
			fromDragonBonesDataName:String = null, ifRemoveOriginalAnimationList:Boolean = true
		):Boolean
		{
			const dataPackage:BuildArmaturePackage = new BuildArmaturePackage();
			if (_fillBuildArmaturePackage(dataPackage, fromDragonBonesDataName, fromArmatreName, fromSkinName, null))
			{
				const fromArmatureData:ArmatureData = dataPackage.armature;
				if (ifRemoveOriginalAnimationList)
				{
					toArmature.animation.animations = fromArmatureData.animations;
				}
				else
				{
					const animations:Object = {};
					var animationName:String = null;
					for (animationName in toArmature.animation.animations)
					{
						animations[animationName] = toArmature.animation.animations[animationName];
					}
					
					for (animationName in fromArmatureData.animations)
					{
						animations[animationName] = fromArmatureData.animations[animationName];
					}
					
					toArmature.animation.animations = animations;
				}
				
				if (dataPackage.skin)
				{
					const slots:Vector.<Slot> = toArmature.getSlots();
					for (var i:uint = 0, l:uint = slots.length; i < l; ++i) 
					{
						const toSlot:Slot = slots[i];
						const toSlotDisplayList:Vector.<Object> = toSlot.displayList;
						for (var iA:uint = 0, lA:uint = toSlotDisplayList.length; iA < lA; ++iA)
						{
							const toDisplayObject:Object = toSlotDisplayList[iA];
							if (toDisplayObject is Armature)
							{
								const displays:Vector.<DisplayData> = dataPackage.skin.getSlot(toSlot.name).displays;
								if (iA < displays.length)
								{
									const fromDisplayData:DisplayData = displays[iA];
									if (fromDisplayData.type == DisplayType.Armature)
									{
										copyAnimationsToArmature(toDisplayObject as Armature, fromDisplayData.path, fromSkinName, fromDragonBonesDataName, ifRemoveOriginalAnimationList);
									}
								}
							}
						}
					}
					
					return true;
				}
			}
			
			return false;
		}
		/**
		 * @language zh_CN
         * 用指定资源替换插槽的显示对象。
		 * @param dragonBonesName 指定的龙骨数据名称。
		 * @param armatureName 指定的骨架名称。
		 * @param slotName 指定的插槽名称。
		 * @param displayName 指定的显示对象名称。
		 * @param slot 指定的插槽实例。
		 * @param displayIndex 要替换的显示对象的索引，如果未设置，则替换当前正在显示的显示对象。
		 * @version DragonBones 4.5
		 */
		public function replaceSlotDisplay(dragonBonesName:String, armatureName:String, slotName:String, displayName:String, slot:Slot, displayIndex:int = -1):void
		{
			const dataPackage:BuildArmaturePackage = new BuildArmaturePackage();
			if (_fillBuildArmaturePackage(dataPackage, dragonBonesName, armatureName, null, null))
			{
				const skinSlotData:SkinSlotData = dataPackage.skin.getSlot(slotName);
				if (skinSlotData)
				{
					for (var i:uint = 0, l:uint = skinSlotData.displays.length; i < l; ++i) 
					{
						const displayData:DisplayData = skinSlotData.displays[i];
						if (displayData.name === displayName)
						{
							_replaceSlotDisplay(dataPackage, displayData, slot, displayIndex);
							break;
						}
					}
				}
			}
		}
		/**
		 * @language zh_CN
         * 用指定资源列表替换插槽的显示对象列表。
		 * @param dragonBonesName 指定的 DragonBonesData 名称。
		 * @param armatureName 指定的骨架名称。
		 * @param slotName 指定的插槽名称。
		 * @param slot 指定的插槽实例。
		 * @version DragonBones 4.5
		 */
		public function replaceSlotDisplayList(dragonBonesName:String, armatureName:String, slotName:String, slot:Slot):void
		{
			const dataPackage:BuildArmaturePackage = new BuildArmaturePackage();
			if (_fillBuildArmaturePackage(dataPackage, dragonBonesName, armatureName, null, null))
			{
				const skinSlotData:SkinSlotData = dataPackage.skin.getSlot(slotName);
				if (skinSlotData)
				{
					for (var i:uint = 0, l:uint = skinSlotData.displays.length; i < l; ++i) 
					{
						const displayData:DisplayData = skinSlotData.displays[i];
						_replaceSlotDisplay(dataPackage, displayData, slot, i);
					}
				}
			}
		}
		/** 
		 * @private 
		 */
		public function get allDragonBonesData():Object
		{
			return _dragonBonesDataMap;
		}
		/** 
		 * @private 
		 */
		public function get allTextureAtlasData():Object
		{
			return _textureAtlasDataMap;
		}
		
		/** 
		 * @language zh_CN
		 * Draw smoothing.
		 * @version DragonBones 3.0
		 */
		public var smoothing:Boolean = true;
		/** 
		 * @language zh_CN
		 * Scale for texture.
		 * @version DragonBones 3.0
		 */
		public var scaleForTexture:Number = 0;
		
		private var _delayID:uint = 0;
		private const _decodeDataList:Vector.<DecodedData> = new Vector.<DecodedData>;
		private function _loadTextureAtlasHandler(event:Event):void
		{
			const loaderInfo:LoaderInfo = event.target as LoaderInfo;
			const decodeData:DecodedData = loaderInfo.loader as DecodedData;
			loaderInfo.removeEventListener(Event.COMPLETE, _loadTextureAtlasHandler);
			parseTextureAtlasData(decodeData.textureAtlasData, decodeData.content, decodeData.name, scaleForTexture || 0, 1);
			decodeData.dispose();
			_decodeDataList.splice(_decodeDataList.indexOf(decodeData), 1);
			if (_decodeDataList.length == 0)
			{
				dispatchEvent(event);
			}
		}
	}
}