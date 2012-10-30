package dragonBones.events{
	public class Event{
		public static const TEXTURE_COMPLETE:String = "textureComplete";
		
		public static const MOVEMENT_CHANGE:String = "movementChange";
		public static const START:String = "start";
		public static const COMPLETE:String = "complete";
		public static const LOOP_COMPLETE:String = "loopComplete";
		
		public static const MOVEMENT_EVENT_FRAME:String = "movementEventFrame";
		public static const BONE_EVENT_FRAME:String = "boneEventFrame";
		
		public static const SOUND_FRAME:String = "soundFrame";
		
		private static var eventPool:Vector.<Event> = new <Event>[];
		
		internal var isStopPropagation:Boolean;

		private var __target:EventDispatcher;
		public function get target():EventDispatcher {
			return __target;
		}

		private var __currentTarget:EventDispatcher;
		public function get currentTarget():EventDispatcher {
			return __currentTarget;
		}
		
		private var __type:String;
		public function get type():String {
			return __type;
		}
		
		private var __data:Object;
		public function get data():Object {
			return __data;
		}

		public function Event(_type:String, _data:Object = null) {
			__type = _type;
			__data = _data;
		}
		
		public function dispose():void {
			__target = null;
			__currentTarget = null;
			__data = null;
		}

		public function stopPropagation():void {
			isStopPropagation = true;
		}

		internal function setTarget(_tartet:EventDispatcher):void {
			__target = _tartet;
		}

		internal function setCurrentTarget(_tartet:EventDispatcher):void {
			__currentTarget = _tartet;
		}
		
		internal function reset(_type:String, _data:Object = null):Event {
			dispose();
			__type = _type;
			__data = _data;
			isStopPropagation = false;
			return this;
		}

		internal static function fromPool(_type:String, _data:Object = null):Event {
			if (eventPool.length) {
				return eventPool.pop().reset(_type, _data);
			} else {
				return new Event(_type, _data);
			}
		}

		internal static function toPool(_event:Event):void {
			_event.dispose();
			if(eventPool.indexOf(_event) == -1){
				eventPool.push(_event);
			}
		}
	}
}