package dragonBones.objects
{
	/** @private */
	public class MovementBoneData
	{
		private var _frameList:Vector.<FrameData>;
		
		public function get totalFrames():int
		{
			return _frameList.length;
		}
		
		public var scale:Number;
		public var delay:Number;
		
		public function MovementBoneData()
		{
			scale = 1;
			delay = 0;
			
			_frameList = new Vector.<FrameData>;
		}
		
		public function dispose():void
		{
			_frameList.length = 0;
		}
		
		public function setValues(scale:Number = 1, delay:Number = 0):void
		{
			this.scale = scale > 0?scale:1;
			this.delay = (delay || 0) % 1;
			if (this.delay > 0)
			{
				this.delay -= 1;
			}
			this.delay *= -1;
		}
		
		public function getFrameDataAt(index:int):FrameData
		{
			return _frameList.length > index?_frameList[index]:null;
		}
		
		internal function addFrameData(data:FrameData):void
		{
			if(_frameList.indexOf(data) < 0)
			{
				_frameList.push(data);
			}
		}
		
	}
	
}