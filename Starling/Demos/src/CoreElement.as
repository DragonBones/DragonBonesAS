package
{
	import flash.display.Sprite;

	import starling.core.Starling;

	[SWF(width = "800", height = "600", frameRate = "60", backgroundColor = "#cccccc")]
	public class CoreElement extends flash.display.Sprite
	{
		public function CoreElement()
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
import dragonBones.animation.Animation;
import dragonBones.animation.AnimationState;
import dragonBones.animation.AnimationFadeOutMode;
import dragonBones.animation.WorldClock;
import dragonBones.events.EventObject;
import dragonBones.starling.StarlingFactory;
import dragonBones.starling.StarlingArmatureDisplayContainer;

import starling.display.Sprite;
import starling.events.Event;
import starling.events.EnterFrameEvent;
import starling.events.KeyboardEvent;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;
import dragonBones.starling.StarlingEvent;

class Game extends Sprite
{
	[Embed(source = "../assets/CoreElement/CoreElement.json", mimeType = "application/octet-stream")]
	private static const DBDataA: Class;

	[Embed(source = "../assets/CoreElement/CoreElement_texture_1.json", mimeType = "application/octet-stream")]
	private static const TADataA1: Class;

	[Embed(source = "../assets/CoreElement/CoreElement_texture_1.png")]
	private static const TextureA1: Class;
	public static const GROUND: int = 500;
	public static const G: Number = 0.6;

	public static var instance: Game = null;

	// Global factory
	public const factory: StarlingFactory = new StarlingFactory();

	private var _left: Boolean = false;
	private var _right: Boolean = false;
	private var _mecha: Mecha = null;

	private const _text: TextField = new TextField(800, 60, "Press W/A/S/D to move. Press Q/E/SPACE to switch weapens.\nMove mouse to aim. Click to fire.");
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

		_mecha = new Mecha();

		_text.x = 0;
		_text.y = this.stage.stageHeight - 60;
		_text.wordWrap = false;
		_text.autoSize = "center";
		this.addChild(_text);
	}

	private function _keyHandler(event: KeyboardEvent): void
	{
		switch (event.keyCode)
		{
			case 37:
			case 65:
				_left = event.type == KeyboardEvent.KEY_DOWN;
				_updateMove(-1);
				break;

			case 39:
			case 68:
				_right = event.type == KeyboardEvent.KEY_DOWN;
				_updateMove(1);
				break;

			case 38:
			case 87:
				if (event.type == KeyboardEvent.KEY_DOWN)
				{
					_mecha.jump();
				}
				break;

			case 83:
			case 40:
				_mecha.squat(event.type == KeyboardEvent.KEY_DOWN);
				break;

			case 81:
				if (event.type == KeyboardEvent.KEY_UP)
				{
					_mecha.switchWeaponR();
				}
				break;

			case 69:
				if (event.type == KeyboardEvent.KEY_UP)
				{
					_mecha.switchWeaponL();
				}
				break;

			case 32:
				if (event.type == KeyboardEvent.KEY_UP)
				{
					_mecha.switchWeaponR();
					_mecha.switchWeaponL();
				}
				break;
		}
	}

	private function _mouseHandler(event: TouchEvent): void
	{
		const touch: Touch = event.getTouch(this.stage);
		if (touch)
		{
			_mecha.aim(touch.getLocation(this.stage));

			if (touch.phase == TouchPhase.BEGAN)
			{
				_mecha.attack(true);
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				_mecha.attack(false);
			}
		}
	}

	private function _enterFrameHandler(event: EnterFrameEvent): void
	{
		_mecha.update();
		
		var i: int = _bullets.length;
		while (i--)
		{
			const bullet: Bullet = _bullets[i];
			if (bullet.update())
			{
				_bullets.splice(i, 1);
			}
		}

		WorldClock.clock.advanceTime(-1);
	}

	private function _updateMove(dir: int): void
	{
		if (_left && _right)
		{
			_mecha.move(dir);
		}
		else if (_left)
		{
			_mecha.move(-1);
		}
		else if (_right)
		{
			_mecha.move(1);
		}
		else
		{
			_mecha.move(0);
		}
	}
}

class Mecha
{
	private static const NORMAL_ANIMATION_GROUP: String = "normalAnimationGroup";
	private static const AIM_ANIMATION_GROUP: String = "aimAnimationGroup";
	private static const ATTACK_ANIMATION_GROUP: String = "attackAnimationGroup";
	private static const JUMP_SPEED: Number = 20;
	private static const NORMALIZE_MOVE_SPEED: Number = 3.6;
	private static const MAX_MOVE_SPEED_FRONT: Number = NORMALIZE_MOVE_SPEED * 1.4;
	private static const MAX_MOVE_SPEED_BACK: Number = NORMALIZE_MOVE_SPEED * 1.0;

	private static const WEAPON_R_LIST: Array = ["weapon_1502b_r", "weapon_1005", "weapon_1005b", "weapon_1005c", "weapon_1005d", "weapon_1005e"];
	private static const WEAPON_L_LIST: Array = ["weapon_1502b_l", "weapon_1005", "weapon_1005b", "weapon_1005c", "weapon_1005d"];

	private var _isJumpingA: Boolean = false;
	private var _isJumpingB: Boolean = false;
	private var _isSquating: Boolean = false;
	private var _isAttacking: Boolean = false;
	private var _isFiring: Boolean = false;
	private var _weaponRIndex: uint = 0;
	private var _weaponLIndex: uint = 0;
	private var _aimDir: int = 0;
	private var _moveDir: int = 0;
	private var _faceDir: int = 1;
	private var _aimRadian: Number = 0;
	private var _speedX: Number = 0;
	private var _speedY: Number = 0;

	private var _armature: Armature = null;
	private var _armatureDisplay: StarlingArmatureDisplayContainer = null;

	private var _weaponR: Armature = null;
	private var _weaponL: Armature = null;

	private var _aimState: AnimationState = null;
	private var _walkState: AnimationState = null;
	private var _attackState: AnimationState = null;

	private const _target: Point = new Point();

	public function Mecha()
	{
		_armature = Game.instance.factory.buildArmature("mecha_1502b");
		_weaponR = _armature.getSlot("weapon_r").childArmature;
		_weaponL = _armature.getSlot("weapon_l").childArmature;
		_armatureDisplay = _armature.display as StarlingArmatureDisplayContainer;
		_armatureDisplay.x = 400;
		_armatureDisplay.y = Game.GROUND;
		_armatureDisplay.scaleX = _armatureDisplay.scaleY = 1;

		// mecha effects only controled by normalAnimation
		_armature.getSlot("effects_1").displayController = NORMAL_ANIMATION_GROUP;
		_armature.getSlot("effects_2").displayController = NORMAL_ANIMATION_GROUP;

		_armature.addEventListener(EventObject.FADE_IN_COMPLETE, _animationEventHandler);
		_armature.addEventListener(EventObject.FADE_OUT_COMPLETE, _animationEventHandler);
		_weaponR.addEventListener(EventObject.FRAME_EVENT, _frameEventHandler);
		_weaponL.addEventListener(EventObject.FRAME_EVENT, _frameEventHandler);

		_updateAnimation();

		WorldClock.clock.add(_armature);
		Game.instance.addChild(_armatureDisplay);
	}

	public function update(): void
	{
		_updatePosition();
		_updateAim();
		_updateFire();
	}

	public function move(dir: int): void
	{
		if (_moveDir == dir)
		{
			return;
		}

		_moveDir = dir;
		_updateAnimation();
	}

	public function jump(): void
	{
		if (_isJumpingA)
		{
			return;
		}

		_isJumpingA = true;
		_armature.animation.fadeIn("jump_1", -1, -1, 0, NORMAL_ANIMATION_GROUP);
		_walkState = null;
	}

	public function squat(isDown: Boolean): void
	{
		if (_isSquating == isDown)
		{
			return;
		}

		_isSquating = isDown;
		_updateAnimation();
	}

	public function aim(target: Point): void
	{
		if (_aimDir == 0)
		{
			_aimDir = 10;
		}

		_target.copyFrom(target);
	}

	public function attack(isAttacking: Boolean): void
	{
		if (_isAttacking == isAttacking)
		{
			return;
		}

		_isAttacking = isAttacking;
	}

	public function switchWeaponR(): void
	{
		_weaponRIndex++;
		if (_weaponRIndex >= WEAPON_R_LIST.length)
		{
			_weaponRIndex = 0;
		}

		_weaponR.removeEventListener(EventObject.FRAME_EVENT, _frameEventHandler);

		const weaponName: String = WEAPON_R_LIST[_weaponRIndex];
		_weaponR = Game.instance.factory.buildArmature(weaponName);
		_armature.getSlot("weapon_r").childArmature = _weaponR;
		_weaponR.addEventListener(EventObject.FRAME_EVENT, _frameEventHandler);
	}

	public function switchWeaponL(): void
	{
		_weaponLIndex++;
		if (_weaponLIndex >= WEAPON_L_LIST.length)
		{
			_weaponLIndex = 0;
		}

		_weaponL.removeEventListener(EventObject.FRAME_EVENT, _frameEventHandler);

		const weaponName: String = WEAPON_L_LIST[_weaponLIndex];
		_weaponL = Game.instance.factory.buildArmature(weaponName);
		_armature.getSlot("weapon_l").childArmature = _weaponL;
		_weaponL.addEventListener(EventObject.FRAME_EVENT, _frameEventHandler);
	}

	private function _animationEventHandler(event: Event): void
	{
		const eventObject: EventObject = event.data as EventObject;
		switch (event.type)
		{
			case EventObject.FADE_IN_COMPLETE:
				if (eventObject.animationState.name == "jump_1")
				{
					_isJumpingB = true;
					_speedY = -JUMP_SPEED;
					_armature.animation.fadeIn("jump_2", -1, -1, 0, NORMAL_ANIMATION_GROUP);
				}
				else if (eventObject.animationState.name == "jump_4")
				{
					_updateAnimation();
				}
				break;

			case EventObject.FADE_OUT_COMPLETE:
				if (eventObject.animationState.name == "attack_01")
				{
					_isFiring = false;
					_attackState = null;
				}
				break;
		}
	}

	private static const _localPoint: Point = new Point();
	private static const _globalPoint: Point = new Point();

	private function _frameEventHandler(event: Event): void
	{
		const eventObject: EventObject = event.data as EventObject;
		if (eventObject.name == "onFire")
		{
			const firePointBone: Bone = eventObject.armature.getBone("firePoint");

			_localPoint.x = firePointBone.global.x;
			_localPoint.y = firePointBone.global.y;

			(eventObject.armature.display as StarlingArmatureDisplayContainer).localToGlobal(_localPoint, _globalPoint);

			_fire(_globalPoint);
		}
	}

	private function _fire(firePoint: Point): void
	{
		firePoint.x += Math.random() * 2 - 1;
		firePoint.y += Math.random() * 2 - 1;

		const radian: Number = _faceDir < 0 ? Math.PI - _aimRadian : _aimRadian;
		const bullet: Bullet = new Bullet("bullet_01", "fireEffect_01", radian + Math.random() * 0.02 - 0.01, 40, firePoint);

		Game.instance.addBullet(bullet);
	}

	private function _updateAnimation(): void
	{
		if (_isJumpingA)
		{
			return;
		}

		if (_isSquating)
		{
			_speedX = 0;
			_armature.animation.fadeIn("squat", -1, -1, 0, NORMAL_ANIMATION_GROUP);
			_walkState = null;
			return;
		}

		if (_moveDir == 0)
		{
			_speedX = 0;
			_armature.animation.fadeIn("idle", -1, -1, 0, NORMAL_ANIMATION_GROUP);
			_walkState = null;
		}
		else
		{
			if (!_walkState)
			{
				_walkState = _armature.animation.fadeIn("walk", -1, -1, 0, NORMAL_ANIMATION_GROUP);
			}

			if (_moveDir * _faceDir > 0)
			{
				_walkState.timeScale = MAX_MOVE_SPEED_FRONT / NORMALIZE_MOVE_SPEED;
			}
			else
			{
				_walkState.timeScale = -MAX_MOVE_SPEED_BACK / NORMALIZE_MOVE_SPEED;
			}

			if (_moveDir * _faceDir > 0)
			{
				_speedX = MAX_MOVE_SPEED_FRONT * _faceDir;
			}
			else
			{
				_speedX = -MAX_MOVE_SPEED_BACK * _faceDir;
			}
		}
	}

	private function _updateFire(): void
	{
		if (!_isAttacking || _isFiring)
		{
			return;
		}

		_isFiring = true;

		//Animation Mixing.
		_attackState = _armature.animation.fadeIn(
			"attack_01", -1, -1,
			0, ATTACK_ANIMATION_GROUP, AnimationFadeOutMode.SameGroup
		);

		_attackState.autoFadeOutTime = _attackState.fadeTotalTime;
		_attackState.addBoneMask("pelvis");
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

		if (_isJumpingB)
		{
			if (_speedY < 5 && _speedY + Game.G >= 5)
			{
				_armature.animation.fadeIn("jump_3", -1, -1, 0, NORMAL_ANIMATION_GROUP);
			}

			_speedY += Game.G;

			_armatureDisplay.y += _speedY;
			if (_armatureDisplay.y > Game.GROUND)
			{
				_armatureDisplay.y = Game.GROUND;
				_isJumpingA = false;
				_isJumpingB = false;
				_speedY = 0;
				_speedX = 0;
				_armature.animation.fadeIn("jump_4", -1, -1, 0, NORMAL_ANIMATION_GROUP);
				if (_isJumpingA || _isSquating || _moveDir)
				{
					_updateAnimation();
				}
			}
		}
	}

	private function _updateAim(): void
	{
		if (_aimDir == 0)
		{
			return;
		}

		_faceDir = _target.x > _armatureDisplay.x ? 1 : -1;
		if (_armatureDisplay.scaleX * _faceDir < 0)
		{
			_armatureDisplay.scaleX *= -1;
			if (_moveDir)
			{
				_updateAnimation();
			}
		}

		const aimOffsetY: Number = _armature.getBone("chest").global.y;

		if (_faceDir > 0)
		{
			_aimRadian = Math.atan2(_target.y - _armatureDisplay.y - aimOffsetY, _target.x - _armatureDisplay.x);
		}
		else
		{
			_aimRadian = Math.PI - Math.atan2(_target.y - _armatureDisplay.y - aimOffsetY, _target.x - _armatureDisplay.x);
			if (_aimRadian > Math.PI)
			{
				_aimRadian -= Math.PI * 2;
			}
		}

		var aimDir: int = 0;
		if (_aimRadian > 0)
		{
			aimDir = -1;
		}
		else
		{
			aimDir = 1;
		}

		if (_aimDir != aimDir)
		{
			_aimDir = aimDir;

			// Animation Mixing.
			if (_aimDir >= 0)
			{
				_aimState = _armature.animation.fadeIn(
					"aimUp", 0, 1,
					0, AIM_ANIMATION_GROUP, AnimationFadeOutMode.SameGroup
				);
			}
			else
			{
				_aimState = _armature.animation.fadeIn(
					"aimDown", 0, 1,
					0, AIM_ANIMATION_GROUP, AnimationFadeOutMode.SameGroup
				);
			}

			// Add bone Mask.
			//_aimState.addBoneMask("pelvis");
		}

		_aimState.weight = Math.abs(_aimRadian / Math.PI * 2);

		//_armature.invalidUpdate("pelvis"); // Only Update bone Mask.
		_armature.invalidUpdate();
	}
}

class Bullet
{
	private var _speedX: Number = 0;
	private var _speedY: Number = 0;

	private var _effect: Armature = null;
	private var _armature: Armature = null;
	private var _armatureDisplay: StarlingArmatureDisplayContainer = null;

	public function Bullet(armatureName: String, effectArmatureName: String, radian: Number, speed: Number, position: Point)
	{
		_speedX = Math.cos(radian) * speed;
		_speedY = Math.sin(radian) * speed;

		_armature = Game.instance.factory.buildArmature(armatureName);
		_armatureDisplay = _armature.display as StarlingArmatureDisplayContainer;
		_armatureDisplay.rotation = radian;
		_armatureDisplay.x = position.x;
		_armatureDisplay.y = position.y;
		_armature.animation.play("idle");

		if (effectArmatureName)
		{
			_effect = Game.instance.factory.buildArmature(effectArmatureName);
			const effectDisplay: StarlingArmatureDisplayContainer = _effect.display as StarlingArmatureDisplayContainer;
			WorldClock.clock.add(_effect);
			Game.instance.addChild(effectDisplay);

			effectDisplay.rotation = radian;
			effectDisplay.x = position.x;
			effectDisplay.y = position.y;
			effectDisplay.scaleY = 1 + Math.random() * 0.5;
			effectDisplay.scaleX = 1 + Math.random() * 1;
			if (Math.random() < 0.5)
			{
				effectDisplay.scaleY *= -1;
			}
			_effect.animation.play("idle");
		}

		WorldClock.clock.add(_armature);
		Game.instance.addChild(_armatureDisplay);
	}

	public function update(): Boolean
	{
		_armatureDisplay.x += _speedX;
		_armatureDisplay.y += _speedY;

		if (
			_armatureDisplay.x < -100 || _armatureDisplay.x >= Game.instance.stage.stageWidth + 100 ||
			_armatureDisplay.y < -100 || _armatureDisplay.y >= Game.instance.stage.stageHeight + 100
		)
		{
			WorldClock.clock.remove(_armature);
			Game.instance.removeChild(_armatureDisplay);
			_armature.dispose();

			if (_effect)
			{
				WorldClock.clock.remove(_effect);
				Game.instance.removeChild(_effect.display as StarlingArmatureDisplayContainer);
				_effect.dispose();
			}

			return true;
		}

		return false;
	}
}