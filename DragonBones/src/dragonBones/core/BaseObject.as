package dragonBones.core
{
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * @language zh_CN
	 * 基础对象。
	 * @version DragonBones 4.5
	 */
	public class BaseObject
	{
		private static var _hashCode:uint = 0;
		private static var _defaultMaxCount:uint = 5000;
		private static const _maxCountMap:Dictionary = new Dictionary();
		private static const _poolsMap:Dictionary = new Dictionary();
		
		private static function _returnObject(object:BaseObject):void
		{
			//const objectConstructor:Class = getDefinitionByName(getQualifiedClassName(object));
			const objectConstructor:Class = object["constructor"];
			const maxCount:uint = _maxCountMap[objectConstructor] == null? _defaultMaxCount: _maxCountMap[objectConstructor];
			const pool:Vector.<BaseObject> = _poolsMap[objectConstructor] = _poolsMap[objectConstructor] || new Vector.<BaseObject>;
			
			if (pool.length < maxCount)
			{
				if (pool.indexOf(object) < 0)
				{
					pool.push(object);
				}
				else
				{
					throw new Error();
				}
			}
		}
		
		/**
		 * @language zh_CN
		 * 设置每种对象池的最大缓存数量。
		 * @param objectConstructor 对象类。
		 * @param maxCount 最大缓存数量。 (设置为 0 则不缓存)
		 * @version DragonBones 4.5
		 */
		public static function setMaxCount(objectConstructor:Class, maxCount:uint):void
		{
			var i:uint = 0, l:uint = 0;
			var pool:Vector.<BaseObject> = null;
			
			if (objectConstructor)
			{
				_maxCountMap[objectConstructor] = maxCount;
				
				pool = _poolsMap[objectConstructor];
				if (pool && pool.length > maxCount)
				{
					pool.length = maxCount;
				}
			}
			else
			{
				_defaultMaxCount = maxCount;
				
				for (var classType:* in _poolsMap)
				{
					if (_maxCountMap[classType] == null)
					{
						continue;
					}
					
					pool = _poolsMap[classType];
					if (pool.length > maxCount)
					{
						pool.length = maxCount;
					}
				}
			}
		}
		
		/**
		 * @language zh_CN
		 * 清除所有对象池缓存的对象。
		 * @version DragonBones 4.5
		 */
		public static function clearPool(objectConstructor:Class = null):void
		{
			var pool:Vector.<BaseObject> = null;
			var object:BaseObject = null;
			
			if (objectConstructor)
			{
				pool = _poolsMap[objectConstructor];
				if (pool && pool.length)
				{
					pool.length = 0;
				}
			}
			else
			{
				for each (pool in _poolsMap)
				{
					pool.length = 0;
				}
			}
		}
		
		/**
		 * @language zh_CN
		 * 从对象池中创建指定对象。
		 * @version DragonBones 4.5
		 */
		public static function borrowObject(objectConstructor:Class):BaseObject
		{
			const pool:Vector.<BaseObject> = _poolsMap[objectConstructor];
			if (pool && pool.length)
			{
				return pool.pop();
			}
			else
			{
				const object:BaseObject = new objectConstructor();
				object._onClear();
				return object;
			}
		}
		
		/**
		 * @language zh_CN
		 * 对象的唯一标识。
		 * @version DragonBones 4.5
		 */
		public const hashCode:uint = BaseObject._hashCode++;
		
		/**
		 * @private
		 */
		public function BaseObject(self:BaseObject)
		{
			if (self != this)
			{
				throw new Error(DragonBones.ABSTRACT_CLASS_ERROR);
			}
		}
		
		/**
		 * @private
		 */
		protected function _onClear():void {}
		
		/**
		 * @language zh_CN
		 * 清除数据并返还对象池。
		 * @version DragonBones 4.5
		 */
		final public function returnToPool():void
		{
			_onClear();
			_returnObject(this);
		}
	}
}