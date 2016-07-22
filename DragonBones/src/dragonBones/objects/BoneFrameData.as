package dragonBones.objects
{
	import dragonBones.geom.Transform;
	
	/**
	 * @private
	 */
	public final class BoneFrameData extends TweenFrameData
	{
		public var tweenScale:Boolean;
		public var tweenRotate:Number;
		public const transform:Transform = new Transform();
		
		public function BoneFrameData()
		{
			super(this);
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _onClear():void
		{
			super._onClear();
			
			tweenScale = false;
			tweenRotate = 0;
			transform.identity();
		}
	}
}