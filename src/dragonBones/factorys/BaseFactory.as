package dragonBones.factorys {
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.display.PivotBitmap;
	import dragonBones.events.Event;
	import dragonBones.events.EventDispatcher;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.DisplayData;
	import dragonBones.objects.FrameData;
	import dragonBones.objects.Node;
	import dragonBones.objects.SkeletonAndTextureRawData;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.TextureData;
	import dragonBones.utils.ConstValues;
	import dragonBones.utils.skeletonNamespace;
	import dragonBones.utils.uncompressionData;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	use namespace skeletonNamespace;
	
	/** Dispatched when the textureData init completed. */
	[Event(name="textureComplete", type="dragonBones.events.Event")]
	
	/**
	 *
	 * @author Akdcl
	 */
	public class BaseFactory extends EventDispatcher {
		public static function getTextureDisplay(_textureData:TextureData, _fullName:String):PivotBitmap {
			var _subTextureXML:XML = _textureData.getSubTextureXML(_fullName);
			if (_subTextureXML) {
				var _rect:Rectangle = new Rectangle(
					int(_subTextureXML.attribute(ConstValues.A_X)),
					int(_subTextureXML.attribute(ConstValues.A_Y)),
					int(_subTextureXML.attribute(ConstValues.A_WIDTH)),
					int(_subTextureXML.attribute(ConstValues.A_HEIGHT))
				);
				var _img:PivotBitmap = new PivotBitmap(_textureData.bitmap.bitmapData);
				_img.smoothing = true;
				_img.scrollRect = _rect;
				_img.pX = int(_subTextureXML.attribute(ConstValues.A_PIVOT_X));
				_img.pY = int(_subTextureXML.attribute(ConstValues.A_PIVOT_Y));
				return _img;
			}
			return null;
		}
		
		private var __skeletonData:SkeletonData;
		public function get skeletonData():SkeletonData {
			return __skeletonData;
		}
		public function set skeletonData(_skeletonData:SkeletonData):void {
			__skeletonData = _skeletonData;
		}
		
		private var __textureData:TextureData;
		public function get textureData():TextureData {
			return __textureData;
		}
		public function set textureData(_textureData:TextureData):void {
			if(__textureData){
				__textureData.removeEventListener(Event.TEXTURE_COMPLETE, textureCompleteHandler);
			}
			__textureData = _textureData;
			if(__textureData){
				__textureData.addEventListener(Event.TEXTURE_COMPLETE, textureCompleteHandler);
			}
		}
		
		public function BaseFactory(_skeletonData:SkeletonData = null, _textureData:TextureData = null):void {
			super();
			skeletonData = _skeletonData;
			textureData = _textureData;
		}
		
		public function fromRawData(_data:ByteArray, _completeCallback:Function = null):void{
			var _sat:SkeletonAndTextureRawData = uncompressionData(_data);
			skeletonData = new SkeletonData(_sat.skeletonXML);
			textureData = new TextureData(_sat.textureAtlasXML, _sat.textureBytes, _completeCallback);
			_sat.dispose();
		}
		
		public function dispose():void{
			removeEventListeners();
			skeletonData = null;
			textureData = null;
		}
		
		public function buildArmature(_armatureName:String, _animationName:String = null):Armature {
			var _armatureData:ArmatureData = skeletonData.getArmatureData(_armatureName);
			if(!_armatureData){
				return null;
			}
			var _animationData:AnimationData = skeletonData.getAnimationData(_animationName || _armatureName);
			var _armature:Armature = generateArmature(_armatureName, _animationName);
			if (_armature) {
				_armature.origin.name = _armatureName;
				_armature.animation.setData(_animationData);
				for each(var _boneName:String in _armatureData.getSearchList()) {
					generateBone(_armature, _armatureData, _boneName);
				}
			}
			return _armature;
		}
		
		protected function generateArmature(_armatureName:String, _animationName:String = null):Armature {
			var _display:Sprite = new Sprite();
			var _armature:Armature = new Armature(_display);
			_armature.addDisplayChild = addDisplayChild;
			_armature.removeDisplayChild = removeDisplayChild;
			_armature.updateDisplay = updateDisplay;
			return _armature;
		}
		
		protected function generateBone(_armature:Armature, _armatureData:ArmatureData, _boneName:String):Bone {
			if(_armature.getBone(_boneName)){
				return null;
			}
			var _boneData:BoneData = _armatureData.getData(_boneName);
			var _parentName:String = _boneData.parent;
			if (_parentName) {
				generateBone(_armature, _armatureData, _parentName);
			}
			
			var _bone:Bone = new Bone();
			_bone.addDisplayChild = _armature.addDisplayChild;
			_bone.removeDisplayChild = _armature.removeDisplayChild;
			_bone.updateDisplay = _armature.updateDisplay;
			_bone.origin.copy(_boneData);
			
			_armature.addBone(_bone, _boneName, _parentName);
			
			var _length:uint = _boneData.displayLength;
			var _displayData:DisplayData;
			for(var _i:int = 0;_i < _length;_i ++){
				_displayData = _boneData.getDisplayData(_i);
				_bone.changeDisplay(_i);
				if (_displayData.isArmature) {
					var _childArmature:Armature = buildArmature(_displayData.name);
					if(this["constructor"] == BaseFactory){
						_childArmature.display.mouseChildren = false;
					}
					_bone.display = _childArmature;
				}else {
					_bone.display = generateBoneDisplay(_armature, _bone, _displayData.name);
				}
			}
			return _bone;
		}
		
		public function generateBoneDisplay(_armature:Armature, _bone:Bone, _imageName:String):Object {
			var _display:Object;
			var _clip:MovieClip = textureData.clip;
			if (_clip) {
				_clip.gotoAndStop(_clip.totalFrames);
				_clip.gotoAndStop(String(_imageName));
				if (_clip.numChildren > 0) {
					_display = _clip.getChildAt(0);
					if (_display) {
						_display.mouseChildren = false;
						_display.x = 0;
						_display.y = 0;
					}else{
						//trace("无法获取影片剪辑，请确认骨骼 FLA 源文件导出 player 版本，与当前程序版本一致！");
					}
				}
			}else if(textureData.bitmap){
				_display = getTextureDisplay(textureData, _imageName);
			}
			return _display;
		}
		
		private function textureCompleteHandler(_e:Event):void{
			dispatchEvent(_e);
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
			if (_display is PivotBitmap)
				_display.update(matrix);
			else
				_display.transform.matrix = matrix;
		}
	}
}