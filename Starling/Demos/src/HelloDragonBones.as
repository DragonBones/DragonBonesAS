package
{
	import flash.display.Sprite;
	import flash.events.Event;

	import starling.core.Starling;

	import dragonBones.animation.WorldClock;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#666666")]
	public class HelloDragonBones extends Sprite
	{
		[Embed(source = "../assets/DragonBoy/DragonBoy.json", mimeType = "application/octet-stream")]
		public static const DBDataA: Class;

		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.json", mimeType = "application/octet-stream")]
		public static const TADataA1: Class;

		[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.png")]
		public static const TextureA1: Class;
		
		private var _isMoved:Boolean = false;
		private var _prevArmatureScale:Number = 1;
		private var _currentArmatureScale:Number = 1;
		private const _startPoint:Point = new Point();
		
		public function HelloDragonBones()
		{
			_flashInit();
			_starlingInit();

			this.addEventListener(Event.ENTER_FRAME, _enterFrameHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, _mouseHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, _mouseHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, _mouseHandler);
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

		private function _mouseHandler(event: MouseEvent): void
		{
			switch (event.type)
			{
				case MouseEvent.MOUSE_UP:
					if (_isMoved)
					{
						_isMoved = false;
					}
					else
					{
						const touchRight: Boolean = event.localX > stage.stageWidth * 0.5;

						if (FlashRender.instance)
						{
							if (FlashRender.instance && FlashRender.instance.dragonBonesData.armatureNames.length > 1 && !touchRight)
							{
								FlashRender.instance.changeArmature(_currentArmatureScale);
							}
							
							FlashRender.instance.changeAnimation();
						}
						
						if (StarlingRender.instance)
						{
							if (StarlingRender.instance && StarlingRender.instance.dragonBonesData.armatureNames.length > 1 && !touchRight)
							{
								StarlingRender.instance.changeArmature(_currentArmatureScale);
							}
							
							StarlingRender.instance.changeAnimation();
						}
					}
					
					break;
				
				case MouseEvent.MOUSE_DOWN:
					_prevArmatureScale = _currentArmatureScale;
					_startPoint.setTo(this.stage.mouseX, this.stage.mouseY);
					break;
				
				case MouseEvent.MOUSE_MOVE:
					if (event.buttonDown)
					{
						_isMoved = true;
						_currentArmatureScale = Math.max((_startPoint.y - this.stage.mouseY) / 200 + _prevArmatureScale, 0.1);
						if (FlashRender.instance)
						{
							FlashRender.instance.armatureScale = _currentArmatureScale;
						}
						
						if (StarlingRender.instance)
						{
							StarlingRender.instance.armatureScale = _currentArmatureScale;
						}
					}
					break;
			}
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
import dragonBones.flash.FlashArmatureDisplay;

class FlashRender extends flash.display.Sprite
{
	public static var instance: FlashRender = null;
	
	public var dragonBonesData: DragonBonesData = null;

	private var _armatureIndex: uint = 0;
	private var _animationIndex: uint = 0;
	private var _armature: Armature = null;
	private var _armatureDisplay: FlashArmatureDisplay = null;
	private const _factory: FlashFactory = new FlashFactory();

	public function FlashRender()
	{
		instance = this;

		this.addEventListener(flash.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private var _armatureScale: Number = 1;
	public function get armatureScale(): Number
	{
		return _armatureScale;
	}
	public function set armatureScale(value): void
	{
		_armatureScale = value;
		_armatureDisplay.scaleX = _armatureDisplay.scaleY = _armatureScale;
	}

	private function _addToStageHandler(event: flash.events.Event): void
	{
		dragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);

		if (dragonBonesData)
		{
			changeArmature(_armatureScale);
			changeAnimation();
		}
	}

	public function changeArmature(armatureScale:Number): void
	{
		const armatureNames: Vector.<String> = dragonBonesData.armatureNames;
		if (armatureNames.length == 0)
		{
			return;
		}
		
		// Remove prev Armature.
		if (_armature)
		{
			_armature.dispose();
			this.removeChild(_armatureDisplay);

			// b.
			// dragonBones.WorldClock.clock.remove(_armature);
		}

		// Get Next Armature name.
		_armatureIndex++;
		if (_armatureIndex >= armatureNames.length)
		{
			_armatureIndex = 0;
		}

		const armatureName: String = armatureNames[_armatureIndex];

		// a. Build Armature Display. (buildArmatureDisplay will advanceTime animation by Armature Display)
		_armatureDisplay = _factory.buildArmatureDisplay(armatureName);
		_armature = _armatureDisplay.armature;

		// b. Build Armature. (buildArmature will advanceTime animation by WorldClock)
		/*_armature = _factory.buildArmature(armatureName);
		_armatureDisplay = _armature.display as StarlingArmatureDisplay;
		WorldClock.clock.add(_armature);*/

		// Add Armature Display.
		_armatureDisplay.x = 200;
		_armatureDisplay.y = 400;
		this.armatureScale = armatureScale;
		this.addChild(_armatureDisplay);
		
		_animationIndex = 0;
	}

	public function changeAnimation(): void
	{
		const animationNames: Vector.<String> = _armatureDisplay.animation.animationNames;
		if (animationNames.length == 0)
		{
			return;
		}
		
		// Get next Animation name.
		_animationIndex++;
		if (_animationIndex >= animationNames.length)
		{
			_animationIndex = 0;
		}

		const animationName: String = animationNames[_animationIndex];

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
import starling.text.TextField;

import dragonBones.starling.StarlingFactory;
import dragonBones.starling.StarlingArmatureDisplay;

class StarlingRender extends starling.display.Sprite
{
	public static var instance: StarlingRender = null;
	
	public var dragonBonesData: DragonBonesData = null;

	private var _armatureIndex: uint = 0;
	private var _animationIndex: uint = 0;
	private var _armature: Armature = null;
	private var _armatureDisplay: StarlingArmatureDisplay = null;
	private const _factory: StarlingFactory = new StarlingFactory();

	public function StarlingRender()
	{
		instance = this;

		this.addEventListener(starling.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private var _armatureScale: Number = 1;
	public function get armatureScale(): Number
	{
		return _armatureScale;
	}
	public function set armatureScale(value): void
	{
		_armatureScale = value;
		_armatureDisplay.scaleX = _armatureDisplay.scaleY = _armatureScale;
	}

	private function _addToStageHandler(event: starling.events.Event): void
	{
		// Load DragonBones Data.
		dragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);

		if (dragonBonesData)
		{
			changeArmature(_armatureScale);
			changeAnimation();
		}
		else
		{
			throw new Error();
		}
		
		const text:TextField = new TextField(this.stage.stageWidth, 60, "");
		text.x = 0;
		text.y = this.stage.stageHeight - 60;
		text.autoSize = "center";
		text.text = "Touch screen left to change Armature / right to change Animation.";
		this.addChild(text);
	}

	public function changeArmature(armatureScale:Number): void
	{
		const armatureNames: Vector.<String> = dragonBonesData.armatureNames;
		if (armatureNames.length == 0)
		{
			return;
		}
		
		// Remove prev Armature.
		if (_armature)
		{
			_armature.dispose();
			this.removeChild(_armatureDisplay);

			// b.
			// dragonBones.WorldClock.clock.remove(_armature);
		}

		// Get Next Armature name.
		_armatureIndex++;
		if (_armatureIndex >= armatureNames.length)
		{
			_armatureIndex = 0;
		}

		const armatureName: String = armatureNames[_armatureIndex];

		// a. Build Armature Display. (buildArmatureDisplay will advanceTime animation by Armature Display)
		_armatureDisplay = _factory.buildArmatureDisplay(armatureName);
		_armature = _armatureDisplay.armature;

		// b. Build Armature. (buildArmature will advanceTime animation by WorldClock)
		/*_armature = _factory.buildArmature(armatureName);
		_armatureDisplay = _armature.display as StarlingArmatureDisplay;
		WorldClock.clock.add(_armature);*/

		// Add Armature Display.
		_armatureDisplay.x = 600;
		_armatureDisplay.y = 400;
		this.armatureScale = armatureScale;
		this.addChild(_armatureDisplay);
		
		_animationIndex = 0;
	}

	public function changeAnimation(): void
	{
		const animationNames: Vector.<String> = _armatureDisplay.animation.animationNames;
		if (animationNames.length == 0)
		{
			return;
		}
		
		// Get next Animation name.
		_animationIndex++;
		if (_animationIndex >= animationNames.length)
		{
			_animationIndex = 0;
		}

		const animationName: String = animationNames[_animationIndex];

		// Play animation.
		_armatureDisplay.animation.play(animationName);
		//_armature.animation.play(animationName);
	}
}