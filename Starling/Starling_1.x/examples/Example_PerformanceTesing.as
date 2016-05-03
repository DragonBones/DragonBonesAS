package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	import starling.core.Starling;

	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#cccccc")]
	public class Example_PerformanceTesing extends flash.display.Sprite
	{

		public static var changeHandler: Function;

		private var input: TextField;
		private var _starling: Starling;

		public function Example_PerformanceTesing()
		{
			starlingInit();
			addInputText();
		}

		private function starlingInit(): void
		{
			Starling.handleLostContext = true;
			_starling = new Starling(StarlingGame, stage);
			//_starling.antiAliasing = 1;
			_starling.showStats = true;
			_starling.start();

			stage.addEventListener(KeyboardEvent.KEY_UP, stage_onKeyUp);

			stage.addEventListener(Event.RESIZE, stateResizeHandler);
		}

		private function stateResizeHandler(e: Event): void
		{
			_starling.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			_starling.stage.stageWidth = stage.stageWidth;
			_starling.stage.stageHeight = stage.stageHeight;
		}

		private function addInputText(): void
		{
			input = new TextField();
			input.border = true;
			input.height = 20;
			input.type = TextFieldType.INPUT;
			input.y = 10;
			input.x = 600;
			input.width = 50;
			input.maxChars = 4;
			input.defaultTextFormat = new TextFormat("Verdana", 16);
			addChild(input);

			input.addEventListener(KeyboardEvent.KEY_UP, input_onKeyUp);
		}

		private function stage_onKeyUp(e: KeyboardEvent): void
		{
			if(e.charCode == Keyboard.SPACE)
			{
				StarlingGame.switchTesting();
			}
		}

		private function input_onKeyUp(e: KeyboardEvent): void
		{
			e.stopPropagation();
			if(e.charCode == Keyboard.ENTER && changeHandler != null)
			{
				stage.focus = null;
				if(int(input.text) < 0)
					input.text = "0";
				changeHandler(int(input.text));
			}
		}
	}
}

import flash.events.Event;

import dragonBones.animation.WorldClock;
import dragonBones.cache.AnimationCacheManager;
import dragonBones.fast.FastArmature;

import dragonBones.starling.StarlingFactory;
import starling.display.Sprite;
import starling.events.EnterFrameEvent;
import starling.text.TextField;

class StarlingGame extends Sprite
{
	[Embed(source = "assets/DragonWithClothes.png", mimeType = "application/octet-stream")]
	private static const ResourcesData: Class;

	private var factory: StarlingFactory;
	private var armatures: Array;
	private var instruction_txt: TextField;
	private var mResultText: TextField;

	private const WAIT_FRAME: int = 20;
	private const PADDING: int = 60;

	private var elapsedTime: Number = 0;
	private var elapsedFrame: int = 0;

	private var stageWidth: int;
	private var stageHeight: int;

	private static var isFailed: Boolean = false;
	private static var failCount: int = 0;
	private static var isTesting: Boolean = true;
	
	private var aniCachManager:AnimationCacheManager;
	
	public function StarlingGame()
	{
		factory = new StarlingFactory();
		factory.parseData(new ResourcesData());
		factory.addEventListener(Event.COMPLETE, textureCompleteHandler);
	}

	private function textureCompleteHandler(e: Event): void
	{
		stageWidth = stage.stageWidth;
		stageHeight = stage.stageHeight;

		armatures = [];
		Example_PerformanceTesing.changeHandler = changeNum;
		

		instruction_txt = new TextField(600, 60, "Press SPACE to pause/resume auto testing.\nInput a number and press ENTER to test manually.", "Verdana", 16, 0, true)
		instruction_txt.x = 60;
		instruction_txt.y = 0;
		instruction_txt.hAlign = "left";
		instruction_txt.vAlign = "top";
		addChild(instruction_txt);

		mResultText = new TextField(300, 100, "");
		mResultText.fontSize = 20;
		mResultText.color = 0xffff0000;
		mResultText.x = stageWidth / 2 - mResultText.width / 2;
		mResultText.y = stageHeight / 2 - mResultText.height / 2;
		addChild(mResultText);

		addObject();
		
		addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrameHandler);
	}

	private function changeNum(num: int): void
	{
		isTesting = false;
		var i: int;

		if(armatures.length == num)
			return;

		if(armatures.length > num)
		{
			for(i = armatures.length - 1; i >= num; i--)
			{
				WorldClock.clock.remove(armatures[i]);
				armatures[i].dispose();
				removeChild(armatures[i].display as Sprite);
			}
			armatures.length = num;
		}
		else
		{
			var stageWidth: int = stage.stageWidth;
			var stageHeight: int = stage.stageHeight;
			for(i = armatures.length; i < num; i++)
			{
				addObject();
			}
		}
	}

	public static function switchTesting(): void
	{
		isTesting = !isTesting;
		isFailed = false;
		failCount = 0;
	}

	private function addObject(): void
	{
		var count: int = armatures.length;
		var columnNum: int = 15;
		var paddingWidth: int = 50;
		var paddingHeight: int = 20;
		var paddingLeft: int = 25;
		var paddingTop: int = 125;
		var Dx: int = 25;

		mResultText.text = "";
		var _armature: FastArmature = factory.buildFastArmature("Dragon");
		_armature.display.scaleX = _armature.display.scaleY = 0.25;

		_armature.display.x = (count % columnNum) * paddingWidth + paddingLeft + ((int)(count / columnNum) % 2) * Dx;
		_armature.display.y = ((int)(count / columnNum)) * paddingHeight + paddingTop;

		
		if(!aniCachManager)
		{
			aniCachManager = _armature.enableAnimationCache(30);
		}
		else
		{
			aniCachManager.bindCacheUserArmature(_armature);
			_armature.enableCache = true;
		}
		
		_armature.animation.gotoAndPlay("walk");
		addChild(_armature.display as Sprite);
		armatures.push(_armature);
		WorldClock.clock.add(_armature);

	}

	private function removeLastObject(): void
	{
		if(armatures.length == 0)
		{
			return;
		}
		WorldClock.clock.remove(armatures[armatures.length - 1]);
		armatures[armatures.length - 1].dispose();
		removeChild(armatures[armatures.length - 1].display as Sprite);
		armatures.length--;
	}

	private function clearAllObjects(): void
	{
		var len: int = armatures.length;
		for(var i: int = 0; i < len; i++)
		{
			WorldClock.clock.remove(armatures[i]);
			armatures[i].dispose();
			removeChild(armatures[i].display as Sprite);
		}
		armatures.length = 0;
	}

	private function onEnterFrameHandler(_e: EnterFrameEvent): void
	{
		WorldClock.clock.advanceTime(-1);

		if(isTesting)
		{
			elapsedTime += _e.passedTime;
			elapsedFrame++;
			
			if(elapsedFrame % WAIT_FRAME == 0)
			{
				var fps: Number = elapsedFrame / elapsedTime;
				if(isTesting)
				{
					if(Math.ceil(fps) > 59)
					{
						addObject();
						isFailed = false;
					}
					else
					{
						removeLastObject();
						
						if(!isFailed)
						{
							failCount++;
						}
						isFailed = true;
						
						if(failCount == 10)
							benchmarkComplete();
					}
				}
				elapsedTime = elapsedFrame = 0;
			}
		}
		
	}

	private function benchmarkComplete(): void
	{
		isTesting = false;
		var desc: String = "Result: " + armatures.length + " armatures contains " + String(armatures.length * 18) + " bones with 60fps";
		clearAllObjects();

		mResultText.text = desc;
	}
}