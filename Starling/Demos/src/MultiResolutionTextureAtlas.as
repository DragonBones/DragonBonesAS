package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	
	import starling.core.Starling;
	
	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#666666")]
	public class MultiResolutionTextureAtlas extends Sprite
	{
		[Embed(source = "../assets/DragonBoy/DragonBoy.json", mimeType = "application/octet-stream")]
		public static const DBDataA: Class;
		
		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1_HD.json", mimeType = "application/octet-stream")]
		public static const TADataA1HD: Class;
		
		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1_HD.png")]
		public static const TextureA1HD: Class;
		
		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.json", mimeType = "application/octet-stream")]
		public static const TADataA1: Class;
		
		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.png")]
		public static const TextureA1: Class;
		
		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1_SD.json", mimeType = "application/octet-stream")]
		public static const TADataA1SD: Class;
		
		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1_SD.png")]
		public static const TextureA1SD: Class;
		
		public function MultiResolutionTextureAtlas()
		{
			// Render init.
			_flashInit();
			_starlingInit();
			
			// Add infomation.
			const text:TextField = new TextField();
			text.width = this.stage.stageWidth;
			text.height = 60;
			text.x = 0;
			text.y = this.stage.stageHeight - 60;
			text.autoSize = "center";
			text.text = "Multi Resolution TextureAtlas.\nHD (2X) / NORM (1X) / SD (0.5X)";
			this.addChild(text);
		}
		
		private function _flashInit(): void
		{
			const flashRender: FlashRender = new FlashRender();
			this.addChild(flashRender);
		}
		
		private function _starlingInit(): void
		{
			const starling: Starling = new Starling(StarlingRender, this.stage);
			starling.start();
		}
	}
}

import flash.display.Sprite;
import flash.events.Event;

import dragonBones.flash.FlashArmatureDisplay;
import dragonBones.flash.FlashFactory;

class FlashRender extends flash.display.Sprite
{
	public function FlashRender()
	{
		this.addEventListener(flash.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}
	
	private function _addToStageHandler(event: flash.events.Event): void
	{
		FlashFactory.factory.parseDragonBonesData(
			JSON.parse(new MultiResolutionTextureAtlas.DBDataA()), "DBData"
		);
		
		// HD
		FlashFactory.factory.parseTextureAtlasData(
			JSON.parse(new MultiResolutionTextureAtlas.TADataA1HD()),
			new MultiResolutionTextureAtlas.TextureA1HD(), "HD", 2
		);
		
		// NORM
		FlashFactory.factory.parseTextureAtlasData(
			JSON.parse(new MultiResolutionTextureAtlas.TADataA1()),
			new MultiResolutionTextureAtlas.TextureA1(), "NORM"
		);
		
		// SD
		FlashFactory.factory.parseTextureAtlasData(
			JSON.parse(new MultiResolutionTextureAtlas.TADataA1SD()),
			new MultiResolutionTextureAtlas.TextureA1SD(), "SD", 0.5
		);
		
		var armatureDisplay:FlashArmatureDisplay = null;
		
		// HD
		armatureDisplay = FlashFactory.factory.buildArmatureDisplay("DragonBoy", "DBData", null, "HD");
		armatureDisplay.x = this.stage.stageWidth * 0.5 - 200;
		armatureDisplay.y = this.stage.stageHeight * 0.5;
		armatureDisplay.animation.play();
		this.addChild(armatureDisplay);
		
		// NORM
		armatureDisplay = FlashFactory.factory.buildArmatureDisplay("DragonBoy", "DBData", null, "NORM");
		armatureDisplay.x = this.stage.stageWidth * 0.5;
		armatureDisplay.y = this.stage.stageHeight * 0.5;
		armatureDisplay.animation.play();
		this.addChild(armatureDisplay);
		
		// SD
		armatureDisplay = FlashFactory.factory.buildArmatureDisplay("DragonBoy", "DBData", null, "SD");
		armatureDisplay.x = this.stage.stageWidth * 0.5 + 200;
		armatureDisplay.y = this.stage.stageHeight * 0.5;
		armatureDisplay.animation.play();
		this.addChild(armatureDisplay);
	}
}


// Starling render
import starling.display.Sprite;
import starling.events.Event;

import dragonBones.starling.StarlingFactory;
import dragonBones.starling.StarlingArmatureDisplay;

class StarlingRender extends starling.display.Sprite
{
	public function StarlingRender()
	{
		this.addEventListener(starling.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}
	
	private function _addToStageHandler(event: starling.events.Event): void
	{
		StarlingFactory.factory.parseDragonBonesData(
			JSON.parse(new MultiResolutionTextureAtlas.DBDataA()), "DBData"
		);
		
		// HD
		StarlingFactory.factory.parseTextureAtlasData(
			JSON.parse(new MultiResolutionTextureAtlas.TADataA1HD()),
			new MultiResolutionTextureAtlas.TextureA1HD(), "HD", 2
		);
		
		// NORM
		StarlingFactory.factory.parseTextureAtlasData(
			JSON.parse(new MultiResolutionTextureAtlas.TADataA1()),
			new MultiResolutionTextureAtlas.TextureA1(), "NORM"
		);
		
		// SD
		StarlingFactory.factory.parseTextureAtlasData(
			JSON.parse(new MultiResolutionTextureAtlas.TADataA1SD()),
			new MultiResolutionTextureAtlas.TextureA1SD(), "SD", 0.5
		);
		
		var armatureDisplay:StarlingArmatureDisplay = null;
		
		// HD
		armatureDisplay = StarlingFactory.factory.buildArmatureDisplay("DragonBoy", "DBData", null, "HD");
		armatureDisplay.x = this.stage.stageWidth * 0.5 - 200;
		armatureDisplay.y = this.stage.stageHeight * 0.5 + 200;
		armatureDisplay.animation.play();
		this.addChild(armatureDisplay);
		
		// NORM
		armatureDisplay = StarlingFactory.factory.buildArmatureDisplay("DragonBoy", "DBData", null, "NORM");
		armatureDisplay.x = this.stage.stageWidth * 0.5;
		armatureDisplay.y = this.stage.stageHeight * 0.5 + 200;
		armatureDisplay.animation.play();
		this.addChild(armatureDisplay);
		
		// SD
		armatureDisplay = StarlingFactory.factory.buildArmatureDisplay("DragonBoy", "DBData", null, "SD");
		armatureDisplay.x = this.stage.stageWidth * 0.5 + 200;
		armatureDisplay.y = this.stage.stageHeight * 0.5 + 200;
		armatureDisplay.animation.play();
		this.addChild(armatureDisplay);
	}
}