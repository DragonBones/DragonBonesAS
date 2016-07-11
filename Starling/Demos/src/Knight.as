package
{
	import flash.display.Sprite;

	import starling.core.Starling;

	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#666666")]
	public class Knight extends flash.display.Sprite
	{
		public function Knight()
		{
			starlingInit();
		}

		private function starlingInit(): void
		{
			const starling: Starling = new Starling(Game, this.stage);
			starling.showStats = true;
			starling.start();
		}
	}
}

import flash.geom.Point;

import dragonBones.Armature;
import dragonBones.Bone;
import dragonBones.animation.WorldClock;
import dragonBones.events.EventObject;
import dragonBones.starling.StarlingFactory;
import dragonBones.starling.StarlingArmatureDisplay;

import starling.display.Sprite;
import starling.events.Event;
import starling.events.EnterFrameEvent;
import starling.events.KeyboardEvent;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;

class Game extends Sprite
{
	[Embed(source = "../assets/Knight/Knight.json", mimeType = "application/octet-stream")]
	private static const DBDataA: Class;

	[Embed(source = "../assets/Knight/Knight_texture_1.json", mimeType = "application/octet-stream")]
	private static const TADataA1: Class;

	[Embed(source = "../assets/Knight/Knight_texture_1.png")]
	private static const TextureA1: Class;
	public static const GROUND: int = 500;
	public static const G: Number = 0.6;
	public static var instance: Game = null;

	// Global factory
	public const factory: StarlingFactory = new StarlingFactory();

	private var _left: Boolean = false;
	private var _right: Boolean = false;
	private var _player: Hero = null;
	private const _bullets: Vector.<Bullet> = new Vector.<Bullet>();

	public function Game()
	{
		instance = this;
		this.addEventListener(Event.ADDED_TO_STAGE, _addToStageHandler);
	}

	public function addBullet(bullet: Bullet): void
	{
		_bullets.push(bullet);
	}

	private function _addToStageHandler(event: Event): void
	{
		factory.parseDragonBonesData(
			JSON.parse(new DBDataA())
		);
		factory.parseTextureAtlasData(
			JSON.parse(new TADataA1()),
			new TextureA1()
		);

		this.addEventListener(EnterFrameEvent.ENTER_FRAME, _enterFrameHandler);
		this.stage.addEventListener(KeyboardEvent.KEY_DOWN, _keyHandler);
		this.stage.addEventListener(KeyboardEvent.KEY_UP, _keyHandler);
		this.stage.addEventListener(TouchEvent.TOUCH, _mouseHandler);

		_player = new Hero();
		
		const text: TextField = new TextField(800, 60, "Press W/A/S/D to move. Press SPACE to switch weapen. Press Q/E to upgrade weapen.\nClick to attack.");
		text.x = 0;
		text.y = this.stage.stageHeight - 60;
		text.autoSize = "center";
		this.addChild(text);
	}

	private function _enterFrameHandler(event: EnterFrameEvent): void
	{
		_player.update();
		
		var i: int = _bullets.length;
		while (i--)
		{
			const bullet: Bullet = _bullets[i];
			if (bullet.update())
			{
				_bullets.splice(i, 1);
			}
		}

		WorldClock.clock.advanceTime(0.015);
	}

	private function _keyHandler(event: KeyboardEvent): void
	{
		const isDown:Boolean = event.type == KeyboardEvent.KEY_DOWN;
		switch (event.keyCode)
		{
			case 37:
			case 65:
				_left = isDown;
				_updateMove(-1);
				break;

			case 39:
			case 68:
				_right = isDown;
				_updateMove(1);
				break;

			case 38:
			case 87:
				if (isDown)
				{
					_player.jump();
				}
				break;

			case 83:
			case 40:
				break;

			case 81:
				if (isDown)
				{
					_player.upgradeWeapon(-1);
				}
				break;

			case 69:
				if (isDown)
				{
					_player.upgradeWeapon(1);
				}
				break;

			case 32:
				if (isDown)
				{
					_player.switchWeapon();
				}
				break;
		}
	}

	private function _mouseHandler(event: TouchEvent): void
	{
		const touch: Touch = event.getTouch(this.stage);
		if (touch)
		{
			if (touch.phase == TouchPhase.BEGAN)
			{
				_player.attack();
			}
		}
	}

	private function _updateMove(dir: int): void
	{
		if (_left && _right)
		{
			_player.move(dir);
		}
		else if (_left)
		{
			_player.move(-1);
		}
		else if (_right)
		{
			_player.move(1);
		}
		else
		{
			_player.move(0);
		}
	}
}

class Hero
{
	private static const MAX_WEAPON_LEVEL: uint = 3;
	private static const JUMP_SPEED: Number = -15;
	private static const MOVE_SPEED: Number = 4;
	private static const WEAPON_LIST: Array = ["sword", "pike", "axe", "bow"];

	private var _isJumping: Boolean = false;
	private var _isAttacking: Boolean = false;
	private var _hitCount: uint = 0;
	private var _weaponIndex: uint = 0;
	private var _weaponName: String = WEAPON_LIST[_weaponIndex];
	private var _weaponsLevel: Array = [0, 0, 0, 0];
	private var _faceDir: int = 1;
	private var _moveDir: int = 0;
	private var _speedX: Number = 0;
	private var _speedY: Number = 0;

	private var _armature: Armature = null;
	private var _armatureDisplay: StarlingArmatureDisplay = null;
	private var _armArmature: Armature = null;

	public function Hero()
	{
		_armature = Game.instance.factory.buildArmature("knight");
		_armatureDisplay = _armature.display as StarlingArmatureDisplay;
		_armatureDisplay.x = 400;
		_armatureDisplay.y = Game.GROUND;
		_armatureDisplay.scaleX = _armatureDisplay.scaleY = 1;

		_armArmature = _armature.getSlot("armOutside").childArmature;
		_armArmature.addEventListener(EventObject.COMPLETE, _armEventHandler);
		_armArmature.addEventListener(EventObject.FRAME_EVENT, _armEventHandler);

		_updateAnimation();

		WorldClock.clock.add(_armature);
		Game.instance.addChild(_armatureDisplay);
	}

	public function update(): void
	{
		_updatePosition();
	}

	public function move(dir: int): void
	{
		if (_moveDir == dir)
		{
			return;
		}

		_moveDir = dir;
		if (_moveDir)
		{
			if (_faceDir != _moveDir)
			{
				_faceDir = _moveDir;
				_armatureDisplay.scaleX *= -1;
			}
		}

		_updateAnimation();
	}

	public function jump(): void
	{
		if (_isJumping)
		{
			return;
		}

		_isJumping = true;
		_speedY = JUMP_SPEED;
		_armature.animation.fadeIn("jump");
	}
	
	public function attack():void
	{
		if(_isAttacking)
		{
			return;
		}
		
		_isAttacking = true;
		const animationName: String = "attack_" + _weaponName + "_" + (_hitCount + 1);
		_armArmature.animation.fadeIn(animationName);
	}

	public function switchWeapon(): void
	{
		_isAttacking = false;
		_hitCount = 0;
		
		_weaponIndex++;
		if (_weaponIndex >= WEAPON_LIST.length)
		{
			_weaponIndex = 0;
		}

		_weaponName = WEAPON_LIST[_weaponIndex];

		_armArmature.animation.fadeIn("ready_" + _weaponName);
	}

	public function upgradeWeapon(dir: int): void
	{
		var weaponLevel: int = _weaponsLevel[_weaponIndex] + dir;
		weaponLevel %= MAX_WEAPON_LEVEL;
		if (weaponLevel < 0)
		{
			weaponLevel = MAX_WEAPON_LEVEL + weaponLevel;
		}
		
		_weaponsLevel[_weaponIndex] = weaponLevel;
		
		// Replace display.
		if (_weaponName == "bow")
		{
			_armArmature.getSlot("bow").childArmature = Game.instance.factory.buildArmature("knightFolder/" + _weaponName + "_" + (weaponLevel + 1));
		}
		else
		{
			Game.instance.factory.replaceSlotDisplay(
				null, "weapons", "weapon", 
				"knightFolder/" + _weaponName + "_" + (weaponLevel + 1), 
				_armArmature.getSlot("weapon")
			);
		}
	}
	
	private static const _localPoint: Point = new Point();
	private static const _globalPoint: Point = new Point();
	
	private function _armEventHandler(event: Event): void
	{
		const eventObject: EventObject = event.data as EventObject;
		switch (event.type)
		{
			case EventObject.COMPLETE:
				_isAttacking = false;
				_hitCount = 0;
				const animationName: String = "ready_" + _weaponName;
				_armArmature.animation.fadeIn(animationName);
				break;

			case EventObject.FRAME_EVENT:
				if(eventObject.name == "ready")
				{
					_isAttacking = false;
					_hitCount++;
				}
				else if (eventObject.name == "fire")
				{
					const firePointBone: Bone = eventObject.armature.getBone("bow");

					_localPoint.x = firePointBone.global.x;
					_localPoint.y = firePointBone.global.y;

					(eventObject.armature.display as StarlingArmatureDisplay).localToGlobal(_localPoint, _globalPoint);
					
					var radian:Number = 0;
					if(_faceDir > 0)
					{
						radian = firePointBone.global.rotation + (eventObject.armature.display as StarlingArmatureDisplay).rotation;
					}
					else
					{
						radian = Math.PI - (firePointBone.global.rotation + (eventObject.armature.display as StarlingArmatureDisplay).rotation);
					}
					
					switch (_weaponsLevel[_weaponIndex])
					{
						case 0:
							_fire(_globalPoint, radian);
							break;
						
						case 1:
							_fire(_globalPoint, radian + 3 / 180 * Math.PI);
							_fire(_globalPoint, radian - 3 / 180 * Math.PI);
							break;
						
						case 2:
							_fire(_globalPoint, radian + 6 / 180 * Math.PI);
							_fire(_globalPoint, radian);
							_fire(_globalPoint, radian - 6 / 180 * Math.PI);
							break;
					}
				}
				break;
		}
	}

	private function _fire(firePoint: Point, radian:Number): void
	{
		const bullet: Bullet = new Bullet("arrow", radian, 20, firePoint);
		Game.instance.addBullet(bullet);
	}

	private function _updateAnimation(): void
	{
		if (_isJumping)
		{
			return;
		}

		if (_moveDir == 0)
		{
			_speedX = 0;
			_armature.animation.fadeIn("stand");
		}
		else
		{
			_speedX = MOVE_SPEED * _moveDir;
			_armature.animation.fadeIn("run");
		}
	}

	private function _updatePosition(): void
	{
		if (_speedX != 0)
		{
			_armatureDisplay.x += _speedX;
			if (_armatureDisplay.x < 0)
			{
				_armatureDisplay.x = 0;
			}
			else if (_armatureDisplay.x > Game.instance.stage.stageWidth)
			{
				_armatureDisplay.x = Game.instance.stage.stageWidth;
			}
		}

		if (_speedY != 0)
		{
			if (_speedY < 0 && _speedY + Game.G >= 0)
			{
				_armature.animation.fadeIn("fall");
			}
			
			_speedY += Game.G;

			_armatureDisplay.y += _speedY;
			if (_armatureDisplay.y > Game.GROUND)
			{
				_armatureDisplay.y = Game.GROUND;
				_isJumping = false;
				_speedY = 0;
				_speedX = 0;
				_updateAnimation();
			}
		}
	}
}

class Bullet
{
	private var _speedX: Number = 0;
	private var _speedY: Number = 0;

	private var _armature: Armature = null;
	private var _armatureDisplay: StarlingArmatureDisplay = null;

	public function Bullet(armatureName: String, radian: Number, speed: Number, position: Point)
	{
		_speedX = Math.cos(radian) * speed;
		_speedY = Math.sin(radian) * speed;

		_armature = Game.instance.factory.buildArmature(armatureName);
		_armatureDisplay = _armature.display as StarlingArmatureDisplay;
		_armatureDisplay.x = position.x;
		_armatureDisplay.y = position.y;
		_armatureDisplay.rotation = radian;
		_armature.animation.play("idle");
		
		WorldClock.clock.add(_armature);
		Game.instance.addChild(_armatureDisplay);
	}

	public function update(): Boolean
	{
		_speedY += Game.G;
		
		_armatureDisplay.x += _speedX;
		_armatureDisplay.y += _speedY;
		_armatureDisplay.rotation = Math.atan2(_speedY, _speedX);

		if (
			_armatureDisplay.x < -100 || _armatureDisplay.x >= Game.instance.stage.stageWidth + 100 ||
			_armatureDisplay.y < -100 || _armatureDisplay.y >= Game.instance.stage.stageHeight + 100
		)
		{
			WorldClock.clock.remove(_armature);
			Game.instance.removeChild(_armatureDisplay);
			_armature.dispose();

			return true;
		}

		return false;
	}
}