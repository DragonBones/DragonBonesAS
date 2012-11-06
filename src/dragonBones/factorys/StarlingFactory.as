package dragonBones.factorys {
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.display.StarlingBridgeImage;
	import dragonBones.objects.Node;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.TextureData;
	import dragonBones.utils.BytesType;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.skeletonNamespace;
	
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.SubTexture;
	import starling.textures.Texture;
	
	use namespace skeletonNamespace;
	
	/**
	 *
	 * @author Akdcl
	 */
	public class StarlingFactory extends BaseFactory {
		public static function getTextureDisplay(_textureData:TextureData, _fullName:String):Image {
			var _subTextureXML:XML = _textureData.getSubTextureXML(_fullName);
			if (_subTextureXML) {
				var _subTexture:SubTexture = _textureData.subTextures[_fullName];
				if(!_subTexture){
					var _rect:Rectangle = new Rectangle(
						int(_subTextureXML.attribute(ConstValues.A_X)),
						int(_subTextureXML.attribute(ConstValues.A_Y)),
						int(_subTextureXML.attribute(ConstValues.A_WIDTH)),
						int(_subTextureXML.attribute(ConstValues.A_HEIGHT))
					);
					_subTexture = new SubTexture(_textureData.texture as Texture, _rect);
					_textureData.subTextures[_fullName] = _subTexture;
				}
				var _img:StarlingBridgeImage = new StarlingBridgeImage(_subTexture);
				_img.pX = int(_subTextureXML.attribute(ConstValues.A_PIVOT_X));
				_img.pY = int(_subTextureXML.attribute(ConstValues.A_PIVOT_Y));
				return _img;
			}
			return null;
		}
		
		override public function set textureData(_textureData:TextureData):void{
			super.textureData = _textureData;
			if(textureData){
				textureData.bitmap;
			}
		}
		
		public var autoDisposeBitmapData:Boolean = true;
		
		public function StarlingFactory(_skeletonData:SkeletonData = null, _textureData:TextureData = null):void {
			super(_skeletonData, _textureData);
		}
		
		override protected function generateArmature(_armatureName:String, _animationName:String = null):Armature {
			if (!textureData.texture) {
				if(textureData.dataType == BytesType.ATF){
					textureData.texture = Texture.fromAtfData(textureData.rawData);
				}else{
					textureData.texture = Texture.fromBitmap(textureData.bitmap);
					//no need to keep the bitmapData
					if (autoDisposeBitmapData) {
						textureData.bitmap.bitmapData.dispose();
					}
				}
			}
			
			var _armature:Armature = new Armature(new Sprite());
			_armature.addDisplayChild = addDisplayChild;
			_armature.removeDisplayChild = removeDisplayChild;
			_armature.updateDisplay = updateDisplay;
			return _armature;
		}
		
		override public function generateBoneDisplay(_armature:Armature, _bone:Bone, _imageName:String):Object {
			return getTextureDisplay(textureData, _imageName);
		}
		
		private static function addDisplayChild(_child:Object, _parent:Object, _index:int = -1):void {
			if (_parent) {
				if(_index < 0){
					_parent.addChild(_child);
				}else{
					_parent.addChildAt(_child, Math.min(_index, _parent.numChildren));
				}
			}
		}
		
		private static function removeDisplayChild(_child:Object):void {
			if(_child.parent){
				_child.parent.removeChild(_child);
			}
		}
		
		private static function updateDisplay(_display:Object, matrix:Matrix):void {
			_display.transformationMatrix = matrix;
		}
	}
}