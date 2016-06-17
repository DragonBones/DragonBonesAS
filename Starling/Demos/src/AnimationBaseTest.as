package
{
	import flash.display.Sprite;
	import starling.core.Starling;

	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#cccccc")]
	public class AnimationBaseTest extends Sprite
	{
		public function AnimationBaseTest()
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
import starling.display.DisplayObject;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.events.Event;

import dragonBones.Armature;
import dragonBones.animation.WorldClock;
import dragonBones.objects.DragonBonesData;
import dragonBones.starling.StarlingFactory;
import dragonBones.starling.StarlingArmatureDisplayContainer;
import dragonBones.events.EventObject;

class StarlingRender extends Sprite
{
	[Embed(source = "../assets/AnimationBaseTest/AnimationBaseTest.json", mimeType = "application/octet-stream")]
	public static const DBDataA: Class;

	[Embed(source = "../assets/AnimationBaseTest/texture.json", mimeType = "application/octet-stream")]
	public static const TADataA1: Class;

	[Embed(source = "../assets/AnimationBaseTest/texture.png")]
	public static const TextureA1: Class;

	private var _touched:Boolean = false;
	private var _armatrue: Armature = null;
	private var _armatrueDisplay: StarlingArmatureDisplayContainer = null;
	private const _factory: StarlingFactory = new StarlingFactory();

	public function StarlingRender()
	{
		this.addEventListener(Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	private function _addToStageHandler(event: Event): void
	{
		// Load DragonBones Data
		const dragonBonesData: DragonBonesData = _factory.parseDragonBonesData(
			JSON.parse(new DBDataA())
		);
		_factory.parseTextureAtlasData(
			JSON.parse(new TADataA1()),
			new TextureA1()
		);

		_armatrueDisplay = _factory.buildArmatureDisplay(dragonBonesData.armatureNames[0]);
		_armatrue = _armatrueDisplay.armature;

		_armatrueDisplay.x = 400;
		_armatrueDisplay.y = 300;
		_armatrueDisplay.scaleX = _armatrueDisplay.scaleY = 1;
		this.addChild(_armatrueDisplay);

		// Test animation event
		_armatrue.addEventListener(EventObject.START, _animationEventHandler);
		_armatrue.addEventListener(EventObject.LOOP_COMPLETE, _animationEventHandler);
		_armatrue.addEventListener(EventObject.COMPLETE, _animationEventHandler);
		_armatrue.addEventListener(EventObject.FADE_IN, _animationEventHandler);
		_armatrue.addEventListener(EventObject.FADE_IN_COMPLETE, _animationEventHandler);
		_armatrue.addEventListener(EventObject.FADE_OUT, _animationEventHandler);
		_armatrue.addEventListener(EventObject.FADE_OUT_COMPLETE, _animationEventHandler);

		// Test frame event
		_armatrue.display.addEvent(EventObject.FRAME_EVENT, _animationEventHandler);

		// Test animation API
		this.stage.addEventListener(
			TouchEvent.TOUCH,
			function (event: TouchEvent): void
			{
				const touch: Touch = event.getTouch(stage);
				if (touch)
				{
					const progress: Number = Math.min(Math.max((touch.globalX - _armatrueDisplay.x + 300) / 600, 0), 1);
					
					switch (touch.phase)
					{
						case TouchPhase.BEGAN:
							_touched = true;
						
							//_armatrue.animation.gotoAndPlayByTime("idle", 0, 1);
							//_armatrue.animation.gotoAndStopByTime("idle", 2);
						
							//_armatrue.animation.gotoAndPlayByFrame("idle", 50, 2);
							//_armatrue.animation.gotoAndStopByFrame("idle", 50);
						
							_armatrue.animation.gotoAndPlayByProgress("idle", progress, 3);
							//_armatrue.animation.gotoAndStopByProgress("idle", progress);
							break;
						
						case TouchPhase.ENDED:
							_touched = false;
							break;
						
						case TouchPhase.MOVED:
							if (_touched && _armatrue.animation.getState("idle") && !_armatrue.animation.getState("idle").isPlaying)
							{
								_armatrue.animation.gotoAndStopByProgress("idle", progress);
							}
							break;
					}
				}
			}
		);
	}

	private function _animationEventHandler(event: Event): void
	{
		const eventObject: EventObject = event.data as EventObject;

		trace(eventObject.animationState.name, event.type, eventObject.name ? eventObject.name : "");
	}
}