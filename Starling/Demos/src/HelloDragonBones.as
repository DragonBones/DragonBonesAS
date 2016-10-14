package
{
	/**
	 * How to use
	 * 1. Load data.
	 * 2. factory.parseDragonBonesData();
	 *    factory.parseTextureAtlasData();
	 * 3. armatureDisplay = factory.buildArmatureDisplay("armatureName");
	 * 4. armatureDisplay.animation.play("animationName");
	 * 5. addChild(armatureDisplay);
	 */
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import starling.core.Starling;
	
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
		private var _isHorizontalMoved:Boolean = false;
		private var _armatureIndex: Number = 0;
		private var _animationIndex: Number = 0;
		private var _currentArmatureScale: Number = 1;
		private var _currentAnimationScale: Number = 1;
		private var _prevArmatureScale: Number = 1;
		private var _prevAnimationScale: Number = 1;
		private const _startPoint:Point = new Point();
		
		public function HelloDragonBones()
		{
			// Render init.
			_flashInit();
			_starlingInit();
			
			// Add event listeners.
			this.stage.addEventListener(MouseEvent.MOUSE_UP, _mouseHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, _mouseHandler);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, _mouseHandler);
			
			// Add infomation.
			const text:TextField = new TextField();
			text.width = this.stage.stageWidth;
			text.height = 60;
			text.x = 0;
			text.y = this.stage.stageHeight - 60;
			text.autoSize = "center";
			text.text = "Touch screen left to change armature / right to change animation.\nTouch move to scale armature and animation.";
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
		
		/** 
		 * Touch event listeners.
		 * Touch to change armature and animation.
		 * Touch move to change armature and animation scale.
		 */
		private function _mouseHandler(event: MouseEvent): void
		{
			switch (event.type)
			{
				case MouseEvent.MOUSE_DOWN:
					_prevArmatureScale = (FlashRender.instance? FlashRender.instance: StarlingRender.instance).armatureDisplay.scaleX;
					_prevAnimationScale = (FlashRender.instance? FlashRender.instance: StarlingRender.instance).armatureDisplay.animation.timeScale;
					_startPoint.setTo(this.stage.mouseX, this.stage.mouseY);
					break;
				
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
								FlashRender.instance.changeArmature();
							}
							else
							{
								FlashRender.instance.changeAnimation();
							}
						}
						
						if (StarlingRender.instance)
						{
							if (StarlingRender.instance && StarlingRender.instance.dragonBonesData.armatureNames.length > 1 && !touchRight)
							{
								StarlingRender.instance.changeArmature();
							}
							else
							{
								StarlingRender.instance.changeAnimation();
							}
						}
					}
					
					break;
				
				case MouseEvent.MOUSE_MOVE:
					if (event.buttonDown)
					{
						const dX:Number = _startPoint.x - event.stageX;
						const dY:Number = _startPoint.y - event.stageY;
						
						if (!_isMoved) 
						{
							const dAX:Number = Math.abs(dX);
							const dAY:Number = Math.abs(dY);
							
							if (dAX > 5 || dAY > 5) 
							{
								_isMoved = true;
								_isHorizontalMoved = dAX > dAY;
							}
						}
						
						if (_isMoved)
						{
							if (_isHorizontalMoved) 
							{
								const currentAnimationScale:Number = Math.max(-dX / 200 + _prevAnimationScale, 0.01);
								
								if (FlashRender.instance)
								{
									FlashRender.instance.armatureDisplay.animation.timeScale = currentAnimationScale;
								}
								
								if (StarlingRender.instance)
								{
									StarlingRender.instance.armatureDisplay.animation.timeScale = currentAnimationScale;
								}
							} 
							else 
							{
								const currentArmatureScale:Number = Math.max(dY / 200 + _prevArmatureScale, 0.01);
								if (FlashRender.instance)
								{
									FlashRender.instance.armatureDisplay.scaleX = FlashRender.instance.armatureDisplay.scaleY = currentArmatureScale;
								}
								
								if (StarlingRender.instance)
								{
									StarlingRender.instance.armatureDisplay.scaleX = StarlingRender.instance.armatureDisplay.scaleY = currentArmatureScale;
								}
							}
						}
					}
					
					break;
			}
		}
	}
}

import flash.display.Sprite;
import flash.events.Event;

import dragonBones.events.EventObject;
import dragonBones.flash.FlashArmatureDisplay;
import dragonBones.flash.FlashEvent;
import dragonBones.flash.FlashFactory;
import dragonBones.objects.DragonBonesData;

class FlashRender extends flash.display.Sprite
{
	public static var instance: FlashRender = null;
	
	public var dragonBonesData: DragonBonesData = null;
	
	private var _armatureIndex: uint = 0;
	private var _animationIndex: uint = 0;
	private var _armatureDisplay: FlashArmatureDisplay = null;
	
	public function FlashRender()
	{
		instance = this;
		
		this.addEventListener(flash.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}
	
	public function get armatureDisplay(): FlashArmatureDisplay
	{
		return _armatureDisplay;
	}
	
	private function _addToStageHandler(event: flash.events.Event): void
	{
		// Parse data.
		dragonBonesData = FlashFactory.factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		FlashFactory.factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);
		
		if (dragonBonesData)
		{
			changeArmature();
		}
		else
		{
			throw new Error();
		}
	}
	
	/** 
	 * Change armature.
	 */
	public function changeArmature(): void
	{
		const armatureNames: Vector.<String> = dragonBonesData.armatureNames;
		if (armatureNames.length == 0)
		{
			return;
		}
		
		// Remove prev armature.
		if (_armatureDisplay)
		{
			// Remove listeners.
			_armatureDisplay.removeEventListener(EventObject.START, _animationHandler);
			_armatureDisplay.removeEventListener(EventObject.LOOP_COMPLETE, _animationHandler);
			_armatureDisplay.removeEventListener(EventObject.COMPLETE, _animationHandler);
			_armatureDisplay.removeEventListener(EventObject.FRAME_EVENT, _frameEventHandler);
			
			_armatureDisplay.dispose();
			this.removeChild(_armatureDisplay);
		}
		
		// Get next armature name.
		_animationIndex = 0;
		_armatureIndex++;
		if (_armatureIndex >= armatureNames.length)
		{
			_armatureIndex = 0;
		}
		
		const armatureName: String = armatureNames[_armatureIndex];
		
		// Build armature display. (buildArmatureDisplay will advanceTime animation by Armature Display)
		_armatureDisplay = FlashFactory.factory.buildArmatureDisplay(armatureName);
		// _armatureDisplay.armature.cacheFrameRate = 24; // Cache animation.
		
		// Add animation listener.
		_armatureDisplay.addEventListener(EventObject.START, _animationHandler);
		_armatureDisplay.addEventListener(EventObject.LOOP_COMPLETE, _animationHandler);
		_armatureDisplay.addEventListener(EventObject.COMPLETE, _animationHandler);
		// Add frame event listener.
		_armatureDisplay.addEventListener(EventObject.FRAME_EVENT, _frameEventHandler);
		
		// Add armature display.
		_armatureDisplay.x = this.stage.stageWidth * 0.5 - 200;
		_armatureDisplay.y = this.stage.stageHeight * 0.5 + 100;
		this.addChild(_armatureDisplay);
	}
	
	/** 
	 * Change armature animation.
	 */
	public function changeAnimation(): void
	{
		if (!_armatureDisplay) 
		{
			return;
		}
		
		const animationNames: Vector.<String> = _armatureDisplay.animation.animationNames;
		if (animationNames.length == 0)
		{
			return;
		}
		
		// Get next animation name.
		_animationIndex++;
		if (_animationIndex >= animationNames.length)
		{
			_animationIndex = 0;
		}
		
		const animationName: String = animationNames[_animationIndex];
		
		// Play animation.
		_armatureDisplay.animation.play(animationName);
	}
	
	/** 
	 * Animation listener.
	 */
	private function _animationHandler(event:FlashEvent): void 
	{
		const eventObject:EventObject = event.eventObject;
		trace(event.type, eventObject.animationState.name);
	}
	
	/** 
	 * Frame event listener. (If animation has frame event)
	 */
	private function _frameEventHandler(event:FlashEvent): void 
	{
		const eventObject:EventObject = event.eventObject;
		trace(event.type, eventObject.animationState.name, eventObject.name);
	}
}


// Starling render
import starling.display.Sprite;
import starling.events.Event;

import dragonBones.starling.StarlingFactory;
import dragonBones.starling.StarlingArmatureDisplay;

class StarlingRender extends starling.display.Sprite
{
	public static var instance: StarlingRender = null;
	
	public var dragonBonesData: DragonBonesData = null;
	
	private var _armatureIndex: uint = 0;
	private var _animationIndex: uint = 0;
	private var _armatureDisplay: StarlingArmatureDisplay = null;
	
	public function StarlingRender()
	{
		instance = this;
		
		this.addEventListener(starling.events.Event.ADDED_TO_STAGE, _addToStageHandler);
	}
	
	public function get armatureDisplay(): StarlingArmatureDisplay
	{
		return _armatureDisplay;
	}
	
	private function _addToStageHandler(event: starling.events.Event): void
	{
		// Parse data.
		dragonBonesData = StarlingFactory.factory.parseDragonBonesData(
			JSON.parse(new HelloDragonBones.DBDataA())
		);
		StarlingFactory.factory.parseTextureAtlasData(
			JSON.parse(new HelloDragonBones.TADataA1()),
			new HelloDragonBones.TextureA1()
		);
		
		if (dragonBonesData)
		{
			// Add armature.
			changeArmature();
		}
		else
		{
			throw new Error();
		}
	}
	
	/** 
	 * Change armature.
	 */
	public function changeArmature(): void
	{
		const armatureNames: Vector.<String> = dragonBonesData.armatureNames;
		if (armatureNames.length == 0)
		{
			return;
		}
		
		// Remove prev armature.
		if (_armatureDisplay)
		{
			// Remove listeners.
			_armatureDisplay.removeEventListener(EventObject.START, _animationHandler);
			_armatureDisplay.removeEventListener(EventObject.LOOP_COMPLETE, _animationHandler);
			_armatureDisplay.removeEventListener(EventObject.COMPLETE, _animationHandler);
			_armatureDisplay.removeEventListener(EventObject.FRAME_EVENT, _frameEventHandler);
			
			_armatureDisplay.dispose();
			this.removeChild(_armatureDisplay);
		}
		
		// Get next armature name.
		_animationIndex = 0;
		_armatureIndex++;
		if (_armatureIndex >= armatureNames.length)
		{
			_armatureIndex = 0;
		}
		
		const armatureName: String = armatureNames[_armatureIndex];
		
		// Build armature display. (buildArmatureDisplay will advanceTime animation by Armature Display)
		_armatureDisplay = StarlingFactory.factory.buildArmatureDisplay(armatureName);
		// _armatureDisplay.armature.cacheFrameRate = 24; // Cache animation.
		
		// Add animation listener.
		_armatureDisplay.addEventListener(EventObject.START, _animationHandler);
		_armatureDisplay.addEventListener(EventObject.LOOP_COMPLETE, _animationHandler);
		_armatureDisplay.addEventListener(EventObject.COMPLETE, _animationHandler);
		// Add frame event listener.
		_armatureDisplay.addEventListener(EventObject.FRAME_EVENT, _frameEventHandler);
		
		// Add armature display.
		_armatureDisplay.x = this.stage.stageWidth * 0.5 + 200;
		_armatureDisplay.y = this.stage.stageHeight * 0.5 + 100;
		this.addChild(_armatureDisplay);
	}
	
	/** 
	 * Change armature animation.
	 */
	public function changeAnimation(): void
	{
		if (!_armatureDisplay) 
		{
			return;
		}
		
		const animationNames: Vector.<String> = _armatureDisplay.animation.animationNames;
		if (animationNames.length == 0)
		{
			return;
		}
		
		// Get next animation name.
		_animationIndex++;
		if (_animationIndex >= animationNames.length)
		{
			_animationIndex = 0;
		}
		
		const animationName: String = animationNames[_animationIndex];
		
		// Play animation.
		_armatureDisplay.animation.play(animationName);
	}
	
	/** 
	 * Animation listener.
	 */
	private function _animationHandler(event:starling.events.Event): void 
	{
		const eventObject:EventObject = event.data as EventObject;
		trace(event.type, eventObject.animationState.name);
	}
	
	/** 
	 * Frame event listener. (If animation has frame event)
	 */
	private function _frameEventHandler(event: starling.events.Event): void 
	{
		const eventObject:EventObject = event.data as EventObject;
		trace(event.type, eventObject.animationState.name, eventObject.name);
	}
}