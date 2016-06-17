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
	private var _armatureIndex: uint = 0;
	private var _animationIndex: uint = 0;
	private var _dragonBonesData:DragonBonesData = null;
	private var _armature: Armature = null;
	private var _armatureDisplay: FlashArmatureDisplayContainer = null;
	private const _factory: FlashFactory = new FlashFactory();

	public function FlashRender()
	{
		this.addEventListener(flash.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private function _addToStageHandler(event: flash.events.Event): void
	{
		_dragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);
		
		if (_dragonBonesData)
		{
			_changeArmature();
			_changeAnimation();
			
			this.stage.addEventListener(
				MouseEvent.CLICK,
				function (event: MouseEvent): void
				{
					const touchRight:Boolean = event.localX > stage.stageWidth * 0.5;
							
					if (_dragonBonesData.armatureNames.length > 1 && !touchRight)
					{
						_changeArmature();
					}

					_changeAnimation();
				}
			);
		}
	}

	private function _changeArmature(): void
	{
		// Remove prev Armature.
		if (_armature)
		{
			_armature.dispose();
			this.removeChild(_armatureDisplay);

			// b.
			// dragonBones.WorldClock.clock.remove(_armature);
		}

		// Get Next Armature name.
		const armatureNames:Vector.<String> = _dragonBonesData.armatureNames;
		_armatureIndex++;
		if (_armatureIndex >= armatureNames.length)
		{
			_armatureIndex = 0;
		}

		const armatureName:String = armatureNames[_armatureIndex];
	
		// a. Build Armature Display. (buildArmatureDisplay will advanceTime animation by Armature Display)
		_armatureDisplay = _factory.buildArmatureDisplay(armatureName);
		_armature = _armatureDisplay.armature;

		// b. Build Armature. (buildArmature will advanceTime animation by WorldClock)
		/*_armature = _factory.buildArmature(armatureName);
		_armatureDisplay = _armature.display as StarlingArmatureDisplayContainer;
		WorldClock.clock.add(_armature);*/

		// Add Armature Display.
		_armatureDisplay.x = 200;
		_armatureDisplay.y = 400;
		_armatureDisplay.scaleX = _armatureDisplay.scaleY = 1;
		this.addChild(_armatureDisplay);
	}

	private function _changeAnimation(): void
	{
		// Get next Animation name.
		const animationNames:Vector.<String> = _armatureDisplay.animation.animationNames;
		_animationIndex++;
		if (_animationIndex >= animationNames.length)
		{
			_animationIndex = 0;
		}

		const animationName:String = animationNames[_animationIndex];

		// Play animation.
		_armatureDisplay.animation.play(animationName);
		//_armature.animation.play(animationName);
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
	private var _armatureIndex: uint = 0;
	private var _animationIndex: uint = 0;
	private var _dragonBonesData:DragonBonesData = null;
	private var _armature: Armature = null;
	private var _armatureDisplay: StarlingArmatureDisplayContainer = null;
	private const _factory: StarlingFactory = new StarlingFactory();

	public function StarlingRender()
	{
		this.addEventListener(starling.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private function _addToStageHandler(event: starling.events.Event): void
	{
		// Load DragonBones Data.
		_dragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);
		
		if (_dragonBonesData)
		{
			_changeArmature();
			_changeAnimation();
			
			this.stage.addEventListener(
				TouchEvent.TOUCH,
				function (event: TouchEvent): void
				{
					const touch: Touch = event.getTouch(stage);
					if (touch)
					{
						if (touch.phase == TouchPhase.ENDED)
						{
							const touchRight:Boolean = touch.globalX > stage.stageWidth * 0.5;
							
							if (_dragonBonesData.armatureNames.length > 1 && !touchRight)
							{
								_changeArmature();
							}

							_changeAnimation();
						}
					}
				}
			);
		}
		else 
		{
			throw new Error();
		}
	}

	private function _changeArmature(): void
	{
		// Remove prev Armature.
		if (_armature)
		{
			_armature.dispose();
			this.removeChild(_armatureDisplay);

			// b.
			// dragonBones.WorldClock.clock.remove(_armature);
		}

		// Get Next Armature name.
		const armatureNames:Vector.<String> = _dragonBonesData.armatureNames;
		_armatureIndex++;
		if (_armatureIndex >= armatureNames.length)
		{
			_armatureIndex = 0;
		}

		const armatureName:String = armatureNames[_armatureIndex];
	
		// a. Build Armature Display. (buildArmatureDisplay will advanceTime animation by Armature Display)
		_armatureDisplay = _factory.buildArmatureDisplay(armatureName);
		_armature = _armatureDisplay.armature;

		// b. Build Armature. (buildArmature will advanceTime animation by WorldClock)
		/*_armature = _factory.buildArmature(armatureName);
		_armatureDisplay = _armature.display as StarlingArmatureDisplayContainer;
		WorldClock.clock.add(_armature);*/

		// Add Armature Display.
		_armatureDisplay.x = 600;
		_armatureDisplay.y = 400;
		_armatureDisplay.scaleX = _armatureDisplay.scaleY = 1;
		this.addChild(_armatureDisplay);
	}

	private function _changeAnimation(): void
	{
		// Get next Animation name.
		const animationNames:Vector.<String> = _armatureDisplay.animation.animationNames;
		_animationIndex++;
		if (_animationIndex >= animationNames.length)
		{
			_animationIndex = 0;
		}

		const animationName:String = animationNames[_animationIndex];

		// Play animation.
		_armatureDisplay.animation.play(animationName);
		//_armature.animation.play(animationName);
	}
}