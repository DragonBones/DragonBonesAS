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
		 * 可以用于存储临时数据。
		 * @version DragonBones 3.0
		 */
		public var userData:Object;
		
		/**
		 * @language zh_CN
		 * 对象的名称。
		 * @version DragonBones 3.0
		 */
		public var name:String;
		
		/**
		 * @language zh_CN
		 * 相对于骨架坐标系的矩阵。
		 * @version DragonBones 3.0
		 */
		public var globalTransformMatrix:Matrix;
		
		/**
		 * @language zh_CN
		 * 相对于骨架坐标系的变换。
		 * @see dragonBones.geom.Transform
		 * @version DragonBones 3.0
		 */
		public const global:Transform = new Transform();
		
		/**
		 * @language zh_CN
		 * 相对于骨架或父骨骼坐标系的绑定变换。
		 * @see dragonBones.geom.Transform
		 * @version DragonBones 3.0
		 */
		public const origin:Transform = new Transform();
		
		/**
		 * @language zh_CN
		 * 相对于骨架或父骨骼坐标系的偏移变换。
		 * @see dragonBones.geom.Transform
		 * @version DragonBones 3.0
		 */
		public const offset:Transform = new Transform();
		
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
		protected const _globalTransformMatrix:Matrix = new Matrix(); 
		
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
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			userData = null;
			name = null;
			globalTransformMatrix = _globalTransformMatrix;
			global.identity();
			origin.identity();
			offset.identity();
			
			_armature = null;
			_parent = null;
			_globalTransformMatrix.identity();
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