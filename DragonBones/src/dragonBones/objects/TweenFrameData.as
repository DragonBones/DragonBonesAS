package dragonBones.objects
{
	import flash.geom.Point;
	
	import dragonBones.core.DragonBones;
	
	/**
	 * @private
	 */
	public class TweenFrameData extends FrameData
	{
		private static function _getCurvePoint(x1: Number, y1: Number, x2: Number, y2: Number, x3: Number, y3: Number, x4: Number, y4: Number, t: Number, result: Point): void
		{
			const l_t:Number = 1 - t;
			const powA:Number = l_t * l_t;
			const powB:Number = t * t;
			const kA:Number = l_t * powA;
			const kB:Number = 3.0 * t * powA;
			const kC:Number = 3.0 * l_t * powB;
			const kD:Number = t * powB;
			
			result.x = kA * x1 + kB * x2 + kC * x3 + kD * x4;
			result.y = kA * y1 + kB * y2 + kC * y3 + kD * y4;
		}
		
		public static function samplingEasingCurve(curve:Array, samples:Vector.<Number>): void
		{
			const curveCount:uint = curve.length;
			const result:Point = new Point();
			
			var stepIndex:int = -2;
			for (var i:uint = 0, l:uint = samples.length; i < l; ++i) 
			{
				var t:Number = (i + 1) / (l + 1);
				while ((stepIndex + 6 < curveCount ? curve[stepIndex + 6] : 1) < t) // stepIndex + 3 * 2
				{
					stepIndex += 6;
				}
				
				const isInCurve:Boolean = stepIndex >= 0 && stepIndex + 6 < curveCount;
				const x1:Number = isInCurve ? curve[stepIndex] : 0.0;
				const y1:Number = isInCurve ? curve[stepIndex + 1] : 0.0;
				const x2:Number = curve[stepIndex + 2];
				const y2:Number = curve[stepIndex + 3];
				const x3:Number = curve[stepIndex + 4];
				const y3:Number = curve[stepIndex + 5];
				const x4:Number = isInCurve ? curve[stepIndex + 6] : 1.0;
				const y4:Number = isInCurve ? curve[stepIndex + 7] : 1.0;
				
				var lower:Number = 0.0;
				var higher:Number = 1.0;
				while (higher - lower > 0.01) 
				{
					const percentage:Number = (higher + lower) / 2.0;
					_getCurvePoint(x1, y1, x2, y2, x3, y3, x4, y4, percentage, result);
					if (t - result.x > 0.0) 
					{
						lower = percentage;
					} 
					else 
					{
						higher = percentage;
					}
				}
				
				samples[i] = result.y;
			}
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
		
		override protected function _onClear():void
		{
			super._onClear();
			
			tweenEasing = 0.0;
			curve = null;
		}
	}
}