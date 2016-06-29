package
{
	import flash.display.Sprite;

	import starling.core.Starling;

	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#666666")]
	public class PerformanceTest extends Sprite
	{
		private var _starling: Starling = null;

		public function PerformanceTest()
		{
			_starlingInit();
		}

		private function _starlingInit(): void
		{
			const starling: Starling = new Starling(StarlingRender, this.stage);
			starling.showStats = true;
			starling.start();
		}
	}
}

// Starling render
import starling.display.Sprite;
import starling.events.Event;
import starling.events.EnterFrameEvent;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;

import dragonBones.Armature;
import dragonBones.animation.WorldClock;
import dragonBones.starling.StarlingFactory;
import dragonBones.objects.DragonBonesData;
import dragonBones.starling.StarlingArmatureDisplayContainer;

class StarlingRender extends Sprite
{
	[Embed(source = "../assets/DragonBoy/DragonBoy.json", mimeType = "application/octet-stream")]
	private static const DBDataA: Class;

	[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.json", mimeType = "application/octet-stream")]
	private static const TADataA1: Class;

	[Embed(source = "../assets/DragonBoy/DragonBoy_texture_1.png")]
	private static const TextureA1: Class;

	private var _addingArmature: Boolean = false;
	private var _removingArmature: Boolean = false;
	private var _dragonBonesData: DragonBonesData = null;
	private var _text:TextField = null;
	private const _factory: StarlingFactory = new StarlingFactory();
	private const _armatures: Vector.<Armature> = new Vector.<Armature>();

	public function StarlingRender()
	{
		this.addEventListener(Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private function _addToStageHandler(event: Event): void
	{
		_text = new TextField(800, 60, "");
		_text.x = 0;
		_text.y = this.stage.stageHeight - 60;
		_text.autoSize = "center";
		this.addChild(_text);
		
		_dragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new TADataA1()),
			new TextureA1()
		);
		
		if (_dragonBonesData)
		{
			this.addEventListener(EnterFrameEvent.ENTER_FRAME, _enterFrameHandler);
			this.stage.addEventListener(TouchEvent.TOUCH, _touchHandler);
			
			//
			for (var i:uint = 0; i < 100; ++i) {
				_addArmature();
			}

			_resetPosition();
		}
		else
		{
			throw new Error();
		}
	}

	private function _enterFrameHandler(event: EnterFrameEvent): void
	{
		if (_addingArmature)
		{
			_addArmature();
			_addArmature();
			_addArmature();
			_addArmature();
			_addArmature();
			_addArmature();
			_addArmature();
			_addArmature();
			_addArmature();
			_addArmature();
			_resetPosition();
		}

		if (_removingArmature)
		{
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_removeArmature();
			_resetPosition();
		}
		
		WorldClock.clock.advanceTime(-1);
	}

	private function _touchHandler(event: TouchEvent): void
	{
		const touch: Touch = event.getTouch(this.stage);
		if (touch)
		{
			if (touch.phase == TouchPhase.BEGAN)
			{
				const touchRight:Boolean = touch.globalX > this.stage.stageWidth * 0.5;
				_addingArmature = touchRight;
				_removingArmature = !touchRight;
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				_addingArmature = false;
				_removingArmature = false;
			}
		}
	}

	private function _addArmature(): void
	{
		const armature: Armature = _factory.buildArmature(_dragonBonesData.armatureNames[1]);
		const armatureDisplay: StarlingArmatureDisplayContainer = armature.display as StarlingArmatureDisplayContainer;

		armatureDisplay.scaleX = armatureDisplay.scaleY = 0.3;
		this.addChild(armatureDisplay);

		armature.cacheFrameRate = 24;
		armature.animation.play(armature.animation.animationNames[0], 0);
		WorldClock.clock.add(armature);

		_armatures.push(armature);
		_updateText();
	}

	private function _removeArmature(): void
	{
		if (_armatures.length == 0)
		{
			return;
		}

		const armature: Armature = _armatures.pop();
		const armatureDisplay: StarlingArmatureDisplayContainer = armature.display as StarlingArmatureDisplayContainer;
		this.removeChild(armatureDisplay);
		WorldClock.clock.remove(armature);
		armature.dispose();

		_updateText();
	}

	private function _resetPosition(): void
	{
		const count: uint = _armatures.length;
		if (!count)
		{
			return;
		}
		
		const paddingH: uint = 50;
		const paddingV: uint = 150;
		const columnNum: uint = 10;
		const dX: Number = (this.stage.stageWidth - paddingH * 2) / columnNum;
		const dY: Number = (this.stage.stageHeight - paddingV * 2) / Math.ceil(count / columnNum);

		for (var i: uint = 0, l: uint = _armatures.length; i < l; ++i)
		{
			const armature: Armature = _armatures[i];
			const armatureDisplay: StarlingArmatureDisplayContainer = armature.display as StarlingArmatureDisplayContainer;
			const lineY: uint = Math.floor(i / columnNum);

			armatureDisplay.x = (i % columnNum) * dX + paddingH;
			armatureDisplay.y = lineY * dY + paddingV;
		}
	}

	private function _updateText(): void
	{
		_text.text = "Count: " + _armatures.length + " \nTouch screen left to decrease count / right to increase count.";
	}
}