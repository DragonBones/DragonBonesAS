package dragonBones.events{
	import flash.utils.Dictionary;

	public class EventDispatcher {
		private var eventListeners:Dictionary;

		public function EventDispatcher() {
			
		}

		public function hasEventListener(_type:String):Boolean {
			var _listeners:Vector.<Function> = eventListeners?eventListeners[_type]:null;
			return _listeners?_listeners.length > 0:false;
		}
		
		public function addEventListener(_type:String, _listener:Function):void {
			if (eventListeners == null) {
				eventListeners = new Dictionary();
			}
			var _listeners:Vector.<Function> = eventListeners[_type];
			if (_listeners == null) {
				eventListeners[_type] = new <Function>[_listener];
			} else if (_listeners.indexOf(_listener) == -1) {
				_listeners.push(_listener);
			}
		}

		public function removeEventListener(_type:String, _listener:Function):void {
			if (eventListeners) {
				var _listeners:Vector.<Function> = eventListeners[_type];
				if (_listeners) {
					var _index:int = _listeners.indexOf(_listener);
					if (_index >= 0) {
						_listeners.splice(_index, 1);
					}
				}
			}
		}
		
		public function removeEventListeners(_type:String = null):void {
			if (_type && eventListeners) {
				delete eventListeners[_type];
			} else {
				eventListeners = null;
			}
		}

		public function dispatchEvent(_event:Event):void {
			if (!hasEventListener(_event.type) || eventListeners == null) {
				return;
			}
			var _previousTarget:EventDispatcher = _event.target;
			_event.setTarget(this);
			invoke(_event);
			if (_previousTarget) {
				_event.setTarget(_previousTarget);
			}
		}

		public function dispatchEventWith(_type:String, _data:Object = null):void {
			if (hasEventListener(_type)) {
				var _event:Event = Event.fromPool(_type, _data);
				dispatchEvent(_event);
				Event.toPool(_event);
			}
		}

		private function invoke(_event:Event):void {
			var _listeners:Vector.<Function > = eventListeners ? eventListeners[_event.type]:null;
			var _countListeners:int = _listeners ?_listeners.length:0;

			if (_countListeners) {
				_event.setCurrentTarget(this);
				// we can enumerate directly over the vector, because:
				// when somebody modifies the list while we're looping, "addEventListener" is not
				// problematic, and "removeEventListener" will create a new Vector, anyway.

				for (var i:int = 0; i < _countListeners; ++i) {
					var _listener:Function = _listeners[i] as Function;
					var _countArgs:int = _listener.length;

					if (_countArgs == 0) {
						_listener();
					} else if (_countArgs == 1) {
						_listener(_event);
					} else {
						_listener(_event, _event.data);
					}
					if (_event.isStopPropagation) {
						return;
					}
				}
			}
		}
	}
}