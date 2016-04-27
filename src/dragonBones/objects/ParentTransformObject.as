package dragonBones.objects 
{
 	import flash.geom.Matrix;
 	
 	/**
	 * optimized by freem-trg
 	 * Intermediate class for store the results of the parent transformation
 	 */
 	public class ParentTransformObject 
 	{
 		
 		public var parentGlobalTransform:DBTransform;
 		public var parentGlobalTransformMatrix:Matrix;
 		
 		/// Object pool to reduce GC load
 		private static var _pool:Vector.<ParentTransformObject> = new Vector.<ParentTransformObject>();
 		private static var _poolSize:int = 0;
 		
 		public function ParentTransformObject() 
 		{
 		}
 		
 		[inline]
 		/// Method to set properties after its creation/pooling
 		public final function setTo(parentGlobalTransform:DBTransform, parentGlobalTransformMatrix:Matrix):ParentTransformObject
 		{
 			this.parentGlobalTransform = parentGlobalTransform;
 			this.parentGlobalTransformMatrix = parentGlobalTransformMatrix;
 			return this
 		}
 		
 		[inline]
 		/// Cleanup object and return it to the object pool
 		public final function release():void
 		{
 			dispose(this);
 		}
 		
 		[inline]
 		/// Create/take new clean object from the object pool
 		public static function create():ParentTransformObject
 		{
 			if (_poolSize > 0)
 			{
 				_poolSize--;
 				return _pool.pop();
 			}
 			
 			return new ParentTransformObject();
 		}
 		
 		[inline]
 		/// Cleanup object and return it to the object pool
 		public static function dispose(parentTransformObject:ParentTransformObject):void
 		{
 			parentTransformObject.parentGlobalTransform = null;
 			parentTransformObject.parentGlobalTransformMatrix = null;
 			_pool[_poolSize++] = parentTransformObject;
 		}
 		
 	}
 
} 