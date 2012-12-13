package dragonBones.objects
{
	import dragonBones.utils.dragonBones_internal;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.utils.ByteArray;
	
	use namespace dragonBones_internal;
	
	/**
	 * A set of texture data
	 */
	public class TextureAtlasData
	{
		public var movieClip:MovieClip;
		public var bitmapData:BitmapData;
		public var atfBytes:ByteArray;
		public var texture:Object;
		
		dragonBones_internal var _starlingTexture:Object;
		
		private var _starlingSubTextures:Object;
		private var _subTextureDataDic:Object;
		
		internal var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		internal var _width:int;
		public function get width():int
		{
			return _width;
		}
		
		internal var _height:int;
		public function get height():int
		{
			return _height;
		}
		
		public function TextureAtlasData()
		{
			_subTextureDataDic = {};
		}
		
		public function dispose():void
		{
			movieClip = null;
			
			if(bitmapData)
			{
				bitmapData.dispose();
			}
			bitmapData = null;
			
			if(atfBytes)
			{
				atfBytes.clear();
			}
			atfBytes = null;
			
			if(_starlingTexture && ("dispose" in _starlingTexture))
			{
				_starlingTexture.dispose();
			}
			_starlingTexture = null;
			
			for each(var starlingSubTexture:Object in _starlingSubTextures)
			{
				if("dispose" in starlingSubTexture)
				{
					starlingSubTexture.dispose();
				}
			}
			_starlingSubTextures = null;
			
			_subTextureDataDic = null;
		}
		
		public function movieClipToBitmapData():void
		{
			if (!bitmapData && movieClip)
			{
				movieClip.gotoAndStop(1);
				bitmapData = new BitmapData(_width, _height, true, 0xFF00FF);
				bitmapData.draw(movieClip);
				movieClip.gotoAndStop(movieClip.totalFrames);
			}
		}
		
		public function getSubTextureData(name:String):SubTextureData
		{
			return _subTextureDataDic[name];
		}
		
		internal function addSubTextureData(data:SubTextureData, name:String):void
		{
			if(name)
			{
				_subTextureDataDic[name] = data;
			}
		}
		
		dragonBones_internal function addStarlingSubTexture(name:String, data:Object):void
		{
			if(!_starlingSubTextures)
			{
				_starlingSubTextures = { };
			}
			_starlingSubTextures[name] = data;
		}
		
		dragonBones_internal function getStarlingSubTexture(name:String):Object
		{
			return _starlingSubTextures?_starlingSubTextures[name]:null;
		}
	}
}