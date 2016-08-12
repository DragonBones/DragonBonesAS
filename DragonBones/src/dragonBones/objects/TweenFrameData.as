package dragonBones.objects
{
	import dragonBones.core.DragonBones;

	/**
	 * @private
	 */
	public class TweenFrameData extends FrameData
	{
		public static function samplingCurve(curve:Array, frameCount:uint):Vector.<Number>
		{
			if (curve.length == 0 || frameCount == 0)
			{
				return null;
			}
			
			const samplingTimes:uint = frameCount + 2;
			const samplingStep:Number = 1 / samplingTimes;
			const sampling:Vector.<Number> = new Vector.<Number>((samplingTimes - 1) * 2, true);
			
			//
			curve = curve.concat();
			curve.unshift(0, 0);
			curve.push(1, 1);
			
			var stepIndex:uint = 0;
			for (var i:uint = 0; i < samplingTimes - 1; ++i)
			{
				const step:Number = samplingStep * (i + 1);
				while (curve[stepIndex + 6] < step) // stepIndex + 3 * 2
				{
					stepIndex += 6; // stepIndex += 3 * 2
				}
				
				const x1:Number = curve[stepIndex];
				const x4:Number = curve[stepIndex + 6];
				
				const t:Number = (step - x1) / (x4 - x1);
				const l_t:Number = 1 - t;
				
				const powA:Number = l_t * l_t;
				const powB:Number = t * t;
				
				const kA:Number = l_t * powA;
				const kB:Number = 3 * t * powA;
				const kC:Number = 3 * l_t * powB;
				const kD:Number = t * powB;
				
				sampling[i * 2] = kA * x1 + kB * curve[stepIndex + 2] + kC * curve[stepIndex + 4] + kD * x4;
				sampling[i * 2 + 1] = kA * curve[stepIndex + 1] + kB * curve[stepIndex + 3] + kC * curve[stepIndex + 5] + kD * curve[stepIndex + 7];
			}
			
			return sampling;
		}
		
		public var tweenEasing:Number;
		public var curve:Vector.<Number>;
		
		public function TweenFrameData(self:TweenFrameData)
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
			super._onClear();
			
			tweenEasing = 0;
			curve = null;
		}
	}
}