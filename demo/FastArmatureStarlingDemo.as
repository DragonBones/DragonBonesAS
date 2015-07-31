package demo {
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	import starling.core.Starling;

    [SWF(width="1024", height="768", frameRate="60", backgroundColor="#cccccc")]
	public class FastArmatureStarlingDemo extends flash.display.Sprite {

		public function FastArmatureStarlingDemo() {
			starlingInit();
			stage.addEventListener(MouseEvent.CLICK, switchAnimation);
		}
		
		private function switchAnimation(e:MouseEvent):void 
		{
			StarlingGame.instance.switchAnimation();
		}
		
		
		private function starlingInit():void {
			Starling.handleLostContext = true;
			var _starling:Starling = new Starling(StarlingGame, stage);
			_starling.showStats = true;
			_starling.start();
		}
	}
}
import dragonBones.Armature;
import dragonBones.Bone;
import dragonBones.animation.WorldClock;
import dragonBones.cache.AnimationCacheManager;
import dragonBones.events.AnimationEvent;
import dragonBones.events.FrameEvent;
import dragonBones.factories.StarlingFactory;
import dragonBones.fast.FastArmature;
import dragonBones.objects.DataParser;
import dragonBones.objects.DragonBonesData;
import dragonBones.textures.StarlingTextureAtlas;

import starling.display.Sprite;
import starling.events.EnterFrameEvent;
import starling.events.Event;
import starling.text.TextField;
import starling.textures.Texture;

class StarlingGame extends Sprite {
	[Embed(source = "../assets/Robot/skeleton.json", mimeType = "application/octet-stream")]
	public static const SkeletonJSONData:Class;
	
	[Embed(source = "../assets/Robot/texture.json", mimeType = "application/octet-stream")]
	public static const TextureJSONData:Class;
	
	[Embed(source = "../assets/Robot/texture.png")]
	public static const TextureData:Class;
		
		
	public static var instance:StarlingGame;

	private var factory:StarlingFactory;
	private var armatures:Array = [];
	private var armature:FastArmature;
	private var textField:TextField;

	public function StarlingGame() {
		instance = this;

		factory = new StarlingFactory();
		factory.scaleForTexture = 2;
		
		var skeletonJson:Object = JSON.parse(new SkeletonJSONData());
		skeletonName = skeletonJson.armature[0].name;
		var skeletonData:DragonBonesData = DataParser.parseData(skeletonJson);
		factory.addSkeletonData(skeletonData, skeletonName);
		
		var textureAtlas:StarlingTextureAtlas = new StarlingTextureAtlas(
			Texture.fromBitmapData(new TextureData().bitmapData, false, false, 1), 
			JSON.parse(new TextureJSONData())
		);
		factory.addTextureAtlas(textureAtlas, skeletonName);
		this.addEventListener(Event.ADDED_TO_STAGE, addToStageHandler);
	}

	private var aniCachManager:AnimationCacheManager;
	private function addObject(index:int, cacheUser:Boolean = false):void
	{
		var columnNum:int = 40;
		var paddingWidth:int = 24;
		var paddingHeight:int = 50;
		var paddingLeft:int = 25;
		var paddingTop:int = 100;
		var Dx:int = 25;
		
		var _armature:FastArmature = factory.buildFastArmature(skeletonName);
		armatures.push(_armature);
		
		_armature.display.x = (index % columnNum)*paddingWidth + paddingLeft + ((int)(index/columnNum)%2)*Dx;
		_armature.display.y = ((int)(index/columnNum))*paddingHeight + paddingTop;
		_armature.display.scaleX = _armature.display.scaleY = 0.5;
		
		if(cacheUser)
		{
			animationList = _armature.animation.animationList;
			aniCachManager = _armature.enableAnimationCache(30);
		}
		else
		{
			aniCachManager.bindCacheUserArmature(_armature);
			_armature.enableCache = true;
		}
		
		addChild(_armature.display as Sprite);
		WorldClock.clock.add(_armature);
		
	}
	
	private function armature_onAnimationEvent(event:FrameEvent):void
	{
		trace(event.frameLabel);
	}

	
	
	private function addToStageHandler(_e:Event):void {
		
		addObject(0, true)
		for (var i:int = 1; i < 500; i++)
		{
			addObject(i);
		}
		switchAnimation();
		addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrameHandler);
	}
	
	private var animationIndex:int = 0;
	private var animationList:Vector.<String>;
	private var skeletonName:String;
	public function switchAnimation():void
	{
		animationIndex = animationIndex == animationList.length-1 ? 0 : animationIndex+1;
		for each(var armature:FastArmature in armatures)
		{
			trace("switchAnimation: ",animationList[animationIndex]);
			armature.animation.gotoAndPlay(animationList[animationIndex], 0.3, -1,0);
		}
	}
	
	
	private function onEnterFrameHandler(_e:EnterFrameEvent):void {
		WorldClock.clock.advanceTime(-1);
	}
}