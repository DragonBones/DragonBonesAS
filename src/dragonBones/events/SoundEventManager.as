package dragonBones.events
{
	import flash.errors.IllegalOperationError;
	
	/**
	 * 
	 * @author Akdcl
	 */
	public final class SoundEventManager extends EventDispatcher
	{
		private static var instance:SoundEventManager;
		public static function getInstance():SoundEventManager{
			if(!instance){
				instance = new SoundEventManager();
			}
			return instance;
		}
		
		public function SoundEventManager()
		{
			super();
			if (instance) {
				throw new IllegalOperationError("Singleton already constructed!");
			}
		}
	}
}