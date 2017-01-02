package dragonBones.core
{
	import flash.geom.Matrix;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.geom.Transform;
	
	use namespace dragonBones_internal;
	
	/**
	 * @language zh_CN
	 * 基础变换对象。
	 * @version DragonBones 4.5
	 */
	public class TransformObject extends BaseObject
	{
		/**
		 * @language zh_CN
		 * 对象的名称。
         * @readOnly
		 * @version DragonBones 3.0
		 */
		public var name:String;
		/**
		 * @language zh_CN
		 * 相对于骨架坐标系的矩阵。
         * @readOnly
		 * @version DragonBones 3.0
		 */
		public const globalTransformMatrix:Matrix = new Matrix();
		/**
		 * @language zh_CN
		 * 相对于骨架坐标系的变换。
         * @readOnly
		 * @see dragonBones.geom.Transform
		 * @version DragonBones 3.0
		 */
		public const global:Transform = new Transform();
		/**
		 * @language zh_CN
		 * 相对于骨架或父骨骼坐标系的偏移变换。
		 * @see dragonBones.geom.Transform
		 * @version DragonBones 3.0
		 */
		public const offset:Transform = new Transform();
		/**
		 * @language zh_CN
		 * 相对于骨架或父骨骼坐标系的绑定变换。
         * @readOnly
		 * @see dragonBones.geom.Transform
		 * @version DragonBones 3.0
		 */
		public var origin:Transform;
		/**
		 * @language zh_CN
		 * 可以用于存储临时数据。
		 * @version DragonBones 3.0
		 */
		public var userData:Object;
		/**
		 * @private
		 */
		dragonBones_internal var _armature:Armature;
		/**
		 * @private
		 */
		dragonBones_internal var _parent:Bone;
		/**
		 * @private
		 */
		public function TransformObject(self:TransformObject)
		{
			super(this);
			
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		/**
		 * @private
		 */
		override protected function _onClear():void
		{
			name = null;
			globalTransformMatrix.identity();
			global.identity();
			offset.identity();
			origin = null;
			userData = null;
			
			_armature = null;
			_parent = null;
		}
		/**
		 * @private
		 */
		dragonBones_internal function _setArmature(value:Armature):void
		{
			_armature = value;
		}
		/**
		 * @private
		 */
		dragonBones_internal function _setParent(value:Bone):void
		{
			_parent = value;
		}
		/**
		 * @language zh_CN
		 * 所属的骨架。
		 * @see dragonBones.Armature
		 * @version DragonBones 3.0
		 */
		public function get armature():Armature
		{
			return _armature;
		}
		/**
		 * @language zh_CN
		 * 所属的父骨骼。
		 * @see dragonBones.Bone
		 * @version DragonBones 3.0
		 */
		public function get parent():Bone
		{
			return _parent;
		}
	}
}