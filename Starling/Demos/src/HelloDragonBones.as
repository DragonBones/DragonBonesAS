package
{
	import flash.display.Sprite;
	import flash.events.Event;

	import starling.core.Starling;

	import dragonBones.animation.WorldClock;

	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#cccccc")]
	public class HelloDragonBones extends Sprite
	{
		[Embed(source = "../assets/DragonBoy/DragonBoy.json", mimeType = "application/octet-stream")]
		public static const DBDataA: Class;

		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.json", mimeType = "application/octet-stream")]
		public static const TADataA1: Class;

		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.png")]
		public static const TextureA1: Class;

		public function HelloDragonBones()
		{
			_flashInit();
			_starlingInit();

			this.addEventListener(Event.ENTER_FRAME, _enterFrameHandler);
		}

		private function _flashInit(): void
		{
			const flashRender: FlashRender = new FlashRender();
			this.addChild(flashRender);
		}

		private function _starlingInit(): void
		{
			const starling: Starling = new Starling(StarlingRender, this.stage);
			starling.showStats = true;
			starling.start();
		}

		private function _enterFrameHandler(event: Event): void
		{
			WorldClock.clock.advanceTime(-1);
		}
	}
}


import dragonBones.Armature;
import dragonBones.animation.WorldClock;
import dragonBones.objects.DragonBonesData;


// Flash render
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.display.DisplayObject;

import dragonBones.flash.FlashFactory;
import dragonBones.flash.FlashArmatureDisplayContainer;

class FlashRender extends flash.display.Sprite
{
	private var _animationIndex:uint = 0;
	private var _armatrue:Armature = null;
	private var _armatrueDisplay:FlashArmatureDisplayContainer = null;
	private const _factory: FlashFactory = new FlashFactory();

	public function FlashRender()
	{
		this.addEventListener(flash.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private function _addToStageHandler(event: flash.events.Event): void
	{
		const dragonBonesData: DragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);

		_armatrueDisplay = _factory.buildArmatureDisplay(dragonBonesData.armatureNames[1]);
		_armatrue = _armatrueDisplay.armature;

		/*_armatrue = _factory.buildArmature(dragonBonesData.armatureNames[0]);
		_armatrueDisplay = _armatrue.display as FlashArmatureDisplayContainer;
		WorldClock.clock.add(_armatrue);*/

		_armatrueDisplay.x = 200;
		_armatrueDisplay.y = 400;
		_armatrueDisplay.scaleX = _armatrueDisplay.scaleY = 1;
		this.addChild(_armatrueDisplay);
		
		//_armatrueDisplay.animation.play(_armatrueDisplay.animation.animationNames[0], 0);
		_armatrue.animation.play(_armatrue.animation.animationNames[0], 0);

		this.stage.addEventListener(
			MouseEvent.CLICK,
			function (event: MouseEvent): void
			{
				const animationNames:Vector.<String> = _armatrue.animation.animationNames;
				_animationIndex++;
				if (_animationIndex >= animationNames.length)
				{
					_animationIndex = 0;
				}

				const animationName: String = animationNames[_animationIndex];
				_armatrue.animation.play(animationName, 0);
			}
		);
	}
}


// Starling render
import starling.display.Sprite;
import starling.display.DisplayObject;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.events.Event;

import dragonBones.starling.StarlingFactory;
import dragonBones.starling.StarlingArmatureDisplayContainer;

class StarlingRender extends starling.display.Sprite
{
	private var _animationIndex:uint = 0;
	private var _armatrue:Armature = null;
	private var _armatrueDisplay:StarlingArmatureDisplayContainer = null;
	private const _factory: StarlingFactory = new StarlingFactory();

	public function StarlingRender()
	{
		this.addEventListener(starling.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private function _addToStageHandler(event: starling.events.Event): void
	{
		// Load DragonBones Data
		const dragonBonesData: DragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);

		// a. Build Armature Display. (buildArmatureDisplay will advanceTime animation by Armature Display)
		_armatrueDisplay = _factory.buildArmatureDisplay(dragonBonesData.armatureNames[1]);
		_armatrue = _armatrueDisplay.armature;

		// b. Build Armature. (buildArmature will advanceTime animation by WorldClock)
		/*_armatrue = _factory.buildArmature(dragonBonesData.armatureNames[0]);
		_armatrueDisplay = _armatrue.display as StarlingArmatureDisplayContainer;
		WorldClock.clock.add(_armatrue);*/

		// Add Armature Display.
		_armatrueDisplay.x = 600;
		_armatrueDisplay.y = 400;
		_armatrueDisplay.scaleX = _armatrueDisplay.scaleY = 1;
		this.addChild(_armatrueDisplay);
		
		// Play animation.
		//_armatrueDisplay.animation.play(_armatrueDisplay.animation.animationNames[0], 0);
		_armatrue.animation.play(_armatrue.animation.animationNames[0], 0);

		// Touch to change Armature animation.
		this.stage.addEventListener(
			TouchEvent.TOUCH,
			function (event: TouchEvent): void
			{
				const touch: Touch = event.getTouch(stage);
				if (touch)
				{
					if (touch.phase == TouchPhase.ENDED)
					{
						const animationNames:Vector.<String> = _armatrue.animation.animationNames;
						_animationIndex++;
						if (_animationIndex >= animationNames.length)
						{
							_animationIndex = 0;
						}

						const animationName: String = animationNames[_animationIndex];
						_armatrue.animation.play(animationName);
					}
				}
			}
		);
	}
}