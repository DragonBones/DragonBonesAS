package dragonBones.events
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;

	public class EventDispatcher extends flash.events.EventDispatcher
	{
		private var _captureEventListeners:Object;
		private var _unCaptureEventListeners:Object;

		public function EventDispatcher(target:IEventDispatcher = null)
		{
			super(target || this);
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			if(!useWeakReference)
			{
				var eventListeners:Object;
				if(useCapture)
				{
					if (_captureEventListeners == null) 
					{
						_captureEventListeners = { };
					}
					eventListeners = _captureEventListeners;
				}
				else
				{
					if (_unCaptureEventListeners == null) 
					{
						_unCaptureEventListeners = { };
					}
					eventListeners = _unCaptureEventListeners;
				}
				
				var listeners:Vector.<Function> = eventListeners[type];
				if(listeners == null)
				{
					eventListeners[type] = new <Function>[listener];
				}
				else if(listeners.indexOf(listener) < 0)
				{
					listeners.push(listener);
				}
			}
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			super.removeEventListener(type, listener, useCapture);
			var eventListeners:Object;
			if(useCapture)
			{
				eventListeners = _captureEventListeners;
			}
			else
			{
				eventListeners = _unCaptureEventListeners;
			}
			
			if(eventListeners)
			{
				var listeners:Vector.<Function> = eventListeners[type];
				if(listeners)
				{
					var index:int = listeners.indexOf(listener);
					if (index >= 0) 
					{
						listeners.splice(index, 1);
					}
				}
			}
		}
		
		public function removeEventListeners(type:String = null):void 
		{
			if (type) 
			{
				if(_captureEventListeners)
				{
					delete _captureEventListeners[type];
				}
				if(_unCaptureEventListeners)
				{
					delete _unCaptureEventListeners[type];
				}
			} 
			else 
			{
				_captureEventListeners = null;
				_unCaptureEventListeners = null;
			}
		}
		
	}
	
}