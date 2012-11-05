package dragonBones.objects
{
	import dragonBones.errors.UnknownDataError;
	import dragonBones.events.Event;
	import dragonBones.events.EventDispatcher;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	/** Dispatched when the textureData init completed. */
	[Event(name="textureComplete", type="dragonBones.events.Event")]
	
	/**
	 * ...
	 * @author Akdcl
	 */
	public class TextureData extends EventDispatcher {
		public var name:String;
		
		public var rawData:ByteArray;
		
		public var clip:MovieClip;
		
		private var __bitmap:Bitmap;
		
		private var _subTextureXMLs:Object;
		
		public function get bitmap():Bitmap{
			if (!__bitmap && clip) {
				clip.gotoAndStop(1);
				__bitmap = new Bitmap();
				__bitmap.bitmapData = new BitmapData(width, height, true, 0xFF00FF);
				__bitmap.bitmapData.draw(clip);
				clip.gotoAndStop(clip.totalFrames);
			}
			return __bitmap;
		}
		
		private var __dataType:String;
		public function get dataType():String{
			return __dataType;
		}
		
		public var texture:Object;
		
		public var subTextures:Object;
		
		private var width:uint;
		private var height:uint;
		
		private var __xml:XML;
		public function get xml():XML{
			return __xml;
		}
		
		private var callback:Function;
		
		public function TextureData(_textureAtlasXML:XML, _byteArray:ByteArray, _completeCallback:Function = null) {
			__xml = _textureAtlasXML;
			rawData = _byteArray;
			callback = _completeCallback;
			
			subTextures = {};
			
			init();
		}
		
		private function init():void{
			name = __xml.attribute(ConstValues.A_NAME);
			width = uint(__xml.attribute(ConstValues.A_WIDTH));
			height = uint(__xml.attribute(ConstValues.A_HEIGHT));
			_subTextureXMLs = new Object;
			
			for each(var subTexture:XML in __xml.elements(ConstValues.SUB_TEXTURE))
			{
				_subTextureXMLs[String(subTexture.attribute(ConstValues.A_NAME))] = subTexture;
			}
			
			__dataType = BytesType.getType(rawData);
			
			switch(__dataType){
				case BytesType.SWF:
				case BytesType.PNG:
				case BytesType.JPG:
					var _loader:Loader = new Loader();
					var _loaderContext:LoaderContext = new LoaderContext(false);
					_loaderContext.allowCodeImport = true;
					_loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, loaderCompleteHandler);
					_loader.loadBytes(rawData, _loaderContext);
					break;
				case BytesType.ATF:
					completeHandler();
					break;
				default:
					throw new UnknownDataError();
					break;
			}
		}
		
		public function getSubTextureXML(_id:String):XML {
			return _subTextureXMLs[_id];
		}
		
		public function dispose():void{
			removeEventListeners();
			name = null;
			__xml = null;
			clip = null;
			
			if(__bitmap && __bitmap.bitmapData){
				__bitmap.bitmapData.dispose();
			}
			__bitmap = null;
			
			if(texture && ("dispose" in texture)){
				texture.dispose();
			}
			texture = null;
			
			for each(var _subTexture:Object in subTextures){
				if("dispose" in _subTexture){
					_subTexture.dispose();
				}
			}
			subTextures = null;
		}
		
		private function loaderCompleteHandler(_e:flash.events.Event):void {
			_e.target.removeEventListener(flash.events.Event.COMPLETE, loaderCompleteHandler);
			var _loader:Loader = _e.target.loader;
			var _content:Object = _e.target.content;
			_loader.unloadAndStop();
			
			if (_content is Bitmap) {
				__bitmap = _content as Bitmap;
			}else {
				clip = _content.getChildAt(0) as MovieClip;
				clip.gotoAndStop(clip.totalFrames);
			}
			completeHandler();
		}
		
		private function completeHandler():void{
			if(callback != null){
				switch(callback.length){
					case 0:
						callback();
						break;
					case 1:
					default:
						callback(this);
						break;
				}
			}
			callback = null;
			
			dispatchEventWith(dragonBones.events.Event.TEXTURE_COMPLETE);
			removeEventListeners();
		}
	}
}