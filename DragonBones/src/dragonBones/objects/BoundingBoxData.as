package dragonBones.objects
{
	import flash.geom.Point;
	
	import dragonBones.core.BaseObject;
	import dragonBones.enum.BoundingBoxType;
	
	/**
	 * @language zh_CN
	 * 自定义包围盒数据。
	 * @version DragonBones 5.0
	 */
	public final class BoundingBoxData extends BaseObject
	{
		/**
		 * Cohen–Sutherland algorithm https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
		 * ----------------------
		 * | 0101 | 0100 | 0110 |
		 * ----------------------
		 * | 0001 | 0000 | 0010 |
		 * ----------------------
		 * | 1001 | 1000 | 1010 |
		 * ----------------------
		 */
		private static const OutCode_InSide:uint = 0; // 0000
		private static const OutCode_Left:uint = 0; // 0001
		private static const OutCode_Right:uint = 0; // 0010
		private static const OutCode_Top:uint = 0; // 0100
		private static const OutCode_Bottom:uint = 0; // 1000
		/**
		 * Compute the bit code for a point (x, y) using the clip rectangle
		 */
		private static function _computeOutCode(x: Number, y: Number, xMin: Number, yMin: Number, xMax: Number, yMax: Number): uint 
		{
			var code:uint = OutCode_InSide; // initialised as being inside of [[clip window]]
			
			if (x < xMin) // to the left of clip window
			{
				code |= OutCode_Left;
			}
			else if (x > xMax) // to the right of clip window
			{
				code |= OutCode_Right;
			}
			
			if (y < yMin) // below the clip window
			{
				code |= OutCode_Top;
			}
			else if (y > yMax) // above the clip window
			{
				code |= OutCode_Bottom;
			}
			
			return code;
		}
		/**
		 * @private
		 */
		public static function segmentIntersectsRectangle(
			xA: Number, yA: Number, xB: Number, yB: Number,
			xMin: Number, yMin: Number, xMax: Number, yMax: Number,
			intersectionPointA: Point = null,
			intersectionPointB: Point = null,
			normalRadians: Point = null
		): int 
		{
			const inSideA:Boolean = xA > xMin && xA < xMax && yA > yMin && yA < yMax;
			const inSideB:Boolean = xB > xMin && xB < xMax && yB > yMin && yB < yMax;
			
			if (inSideA && inSideB) 
			{
				return -1;
			}
			
			var intersectionCount:int = 0;
			var outcode0:uint = BoundingBoxData._computeOutCode(xA, yA, xMin, yMin, xMax, yMax);
			var outcode1:uint = BoundingBoxData._computeOutCode(xB, yB, xMin, yMin, xMax, yMax);
			
			while (true) 
			{
				if (!(outcode0 | outcode1)) // Bitwise OR is 0. Trivially accept and get out of loop
				{   
					intersectionCount = 2;
					break;
				}
				else if (outcode0 & outcode1) // Bitwise AND is not 0. Trivially reject and get out of loop
				{
					break;
				}
				
				// failed both tests, so calculate the line segment to clip
				// from an outside point to an intersection with clip edge
				var x:Number = 0.0;
				var y:Number = 0.0;
				var normalRadian:Number = 0.0;
				
				// At least one endpoint is outside the clip rectangle; pick it.
				const outcodeOut:uint = outcode0 ? outcode0 : outcode1;
				
				// Now find the intersection point;
				if (outcodeOut & OutCode_Top) // point is above the clip rectangle
				{
					x = xA + (xB - xA) * (yMin - yA) / (yB - yA);
					y = yMin;
					
					if (normalRadians) 
					{
						normalRadian = -Math.PI * 0.5;
					}
				}
				else if (outcodeOut & OutCode_Bottom) // point is below the clip rectangle
				{
					x = xA + (xB - xA) * (yMax - yA) / (yB - yA);
					y = yMax;
					
					if (normalRadians) 
					{
						normalRadian = Math.PI * 0.5;
					}
				}
				else if (outcodeOut & OutCode_Right) // point is to the right of clip rectangle
				{
					y = yA + (yB - yA) * (xMax - xA) / (xB - xA);
					x = xMax;
					
					if (normalRadians) 
					{
						normalRadian = 0;
					}
				}
				else if (outcodeOut & OutCode_Left) // point is to the left of clip rectangle
				{
					y = yA + (yB - yA) * (xMin - xA) / (xB - xA);
					x = xMin;
					
					if (normalRadians) 
					{
						normalRadian = Math.PI;
					}
				}
				
				// Now we move outside point to intersection point to clip
				// and get ready for next pass.
				if (outcodeOut === outcode0) 
				{
					xA = x;
					yA = y;
					outcode0 = BoundingBoxData._computeOutCode(xA, yA, xMin, yMin, xMax, yMax);
					
					if (normalRadians) 
					{
						normalRadians.x = normalRadian;
					}
				}
				else {
					xB = x;
					yB = y;
					outcode1 = BoundingBoxData._computeOutCode(xB, yB, xMin, yMin, xMax, yMax);
					
					if (normalRadians) 
					{
						normalRadians.y = normalRadian;
					}
				}
			}
			
			if (intersectionCount) 
			{
				if (inSideA) 
				{
					intersectionCount = 2; // 10
					
					if (intersectionPointA) 
					{
						intersectionPointA.x = xB;
						intersectionPointA.y = yB;
					}
					
					if (intersectionPointB) 
					{
						intersectionPointB.x = xB;
						intersectionPointB.y = xB;
					}
					
					if (normalRadians) {
						normalRadians.x = normalRadians.y + Math.PI;
					}
				}
				else if (inSideB) {
					intersectionCount = 1; // 01
					
					if (intersectionPointA) {
						intersectionPointA.x = xA;
						intersectionPointA.y = yA;
					}
					
					if (intersectionPointB) {
						intersectionPointB.x = xA;
						intersectionPointB.y = yA;
					}
					
					if (normalRadians) {
						normalRadians.y = normalRadians.x + Math.PI;
					}
				}
				else {
					intersectionCount = 3; // 11
					if (intersectionPointA) {
						intersectionPointA.x = xA;
						intersectionPointA.y = yA;
					}
					
					if (intersectionPointB) {
						intersectionPointB.x = xB;
						intersectionPointB.y = yB;
					}
				}
			}
			
			return intersectionCount;
		}
		/**
		 * @private
		 */
		public static function segmentIntersectsEllipse(
			xA: Number, yA: Number, xB: Number, yB: Number,
			xC: Number, yC: Number, widthH: Number, heightH: Number,
			intersectionPointA: Point = null,
			intersectionPointB: Point = null,
			normalRadians: Point = null
		): int 
		{
			const d:Number = widthH / heightH;
			const dd:Number = d * d;
			
			yA *= d;
			yB *= d;
			
			const dX:Number = xB - xA;
			const dY:Number = yB - yA;
			const lAB:Number = Math.sqrt(dX * dX + dY * dY);
			const xD:Number = dX / lAB;
			const yD:Number = dY / lAB;
			const a:Number = (xC - xA) * xD + (yC - yA) * yD;
			const aa:Number = a * a;
			const ee:Number = xA * xA + yA * yA;
			const rr:Number = widthH * widthH;
			const dR:Number = rr - ee + aa;
			var intersectionCount:int = 0;
			
			if (dR >= 0) 
			{
				const dT:Number = Math.sqrt(dR);
				const sA:Number = a - dT;
				const sB:Number = a + dT;
				const inSideA:int = sA < 0.0 ? -1 : (sA <= lAB ? 0 : 1);
				const inSideB:int = sB < 0.0 ? -1 : (sB <= lAB ? 0 : 1);
				const sideAB:int = inSideA * inSideB;
				
				if (sideAB < 0) 
				{
					return -1;
				}
				else if (sideAB === 0) 
				{
					if (inSideA === -1) 
					{
						intersectionCount = 2; // 10
						xB = xA + sB * xD;
						yB = (yA + sB * yD) / d;
						
						if (intersectionPointA) 
						{
							intersectionPointA.x = xB;
							intersectionPointA.y = yB;
						}
						
						if (intersectionPointB) 
						{
							intersectionPointB.x = xB;
							intersectionPointB.y = yB;
						}
						
						if (normalRadians) 
						{
							normalRadians.x = Math.atan2(yB / rr * dd, xB / rr);
							normalRadians.y = normalRadians.x + Math.PI;
						}
					}
					else if (inSideB === 1) 
					{
						intersectionCount = 1; // 01
						xA = xA + sA * xD;
						yA = (yA + sA * yD) / d;
						
						if (intersectionPointA) 
						{
							intersectionPointA.x = xA;
							intersectionPointA.y = yA;
						}
						
						if (intersectionPointB) 
						{
							intersectionPointB.x = xA;
							intersectionPointB.y = yA;
						}
						
						if (normalRadians) 
						{
							normalRadians.x = Math.atan2(yA / rr * dd, xA / rr);
							normalRadians.y = normalRadians.x + Math.PI;
						}
					}
					else 
					{
						intersectionCount = 3; // 11
						
						if (intersectionPointA) 
						{
							intersectionPointA.x = xA + sA * xD;
							intersectionPointA.y = (yA + sA * yD) / d;
							
							if (normalRadians) 
							{
								normalRadians.x = Math.atan2(intersectionPointA.y / rr * dd, intersectionPointA.x / rr);
							}
						}
						
						if (intersectionPointB) 
						{
							intersectionPointB.x = xA + sB * xD;
							intersectionPointB.y = (yA + sB * yD) / d;
							
							if (normalRadians) 
							{
								normalRadians.y = Math.atan2(intersectionPointB.y / rr * dd, intersectionPointB.x / rr);
							}
						}
					}
				}
			}
			
			return intersectionCount;
		}
		/**
		 * @private
		 */
		public static function segmentIntersectsPolygon(
			xA: Number, yA: Number, xB: Number, yB: Number,
			vertices: Vector.<Number>,
			intersectionPointA: Point = null,
			intersectionPointB: Point = null,
			normalRadians: Point = null
		): int
		{
			if (xA === xB)
			{
				xA = xB + 0.01;
			}
			
			if (yA === yB)
			{
				yA = yB + 0.01;
			}
			
			const l:uint = vertices.length;
			const dXAB:Number = xA - xB
			const dYAB:Number = yA - yB;
			const llAB:Number = xA * yB - yA * xB;
			var intersectionCount:int = 0;
			var xC:Number = vertices[l - 2];
			var yC:Number = vertices[l - 1];
			var dMin:Number = 0.0;
			var dMax:Number = 0.0;
			var xMin:Number = 0.0;
			var yMin:Number = 0.0;
			var xMax:Number = 0.0;
			var yMax:Number = 0.0;
			
			for (var i:uint = 0; i < l; i += 2) 
			{
				const xD:Number = vertices[i];
				const yD:Number = vertices[i + 1];
				
				if (xC === xD) 
				{
					xC = xD + 0.01;
				}
				
				if (yC === yD) 
				{
					yC = yD + 0.01;
				}
				
				const dXCD:Number = xC - xD;
				const dYCD:Number = yC - yD;
				const llCD:Number = xC * yD - yC * xD;
				const ll:Number = dXAB * dYCD - dYAB * dXCD;
				const x:Number = (llAB * dXCD - dXAB * llCD) / ll;
				
				if (((x >= xC && x <= xD) || (x >= xD && x <= xC)) && (dXAB === 0 || (x >= xA && x <= xB) || (x >= xB && x <= xA))) 
				{
					const y:Number = (llAB * dYCD - dYAB * llCD) / ll;
					if (((y >= yC && y <= yD) || (y >= yD && y <= yC)) && (dYAB === 0 || (y >= yA && y <= yB) || (y >= yB && y <= yA))) 
					{
						if (intersectionPointB) 
						{
							var d:Number = x - xA;
							if (d < 0.0) 
							{
								d = -d;
							}
							
							if (intersectionCount === 0) 
							{
								dMin = d;
								dMax = d;
								xMin = x;
								yMin = y;
								xMax = x;
								yMax = y;
								
								if (normalRadians) 
								{
									normalRadians.x = Math.atan2(yD - yC, xD - xC) - Math.PI * 0.5;
									normalRadians.y = normalRadians.x;
								}
							}
							else 
							{
								if (d < dMin) 
								{
									dMin = d;
									xMin = x;
									yMin = y;
									
									if (normalRadians) 
									{
										normalRadians.x = Math.atan2(yD - yC, xD - xC) - Math.PI * 0.5;
									}
								}
								
								if (d > dMax) 
								{
									dMax = d;
									xMax = x;
									yMax = y;
									
									if (normalRadians) 
									{
										normalRadians.y = Math.atan2(yD - yC, xD - xC) - Math.PI * 0.5;
									}
								}
							}
							
							intersectionCount++;
						}
						else 
						{
							xMin = x;
							yMin = y;
							xMax = x;
							yMax = y;
							intersectionCount++;
							
							if (normalRadians) 
							{
								normalRadians.x = Math.atan2(yD - yC, xD - xC) - Math.PI * 0.5;
								normalRadians.y = normalRadians.x;
							}
							break;
						}
					}
				}
				
				xC = xD;
				yC = yD;
			}
			
			if (intersectionCount === 1) 
			{
				if (intersectionPointA) 
				{
					intersectionPointA.x = xMin;
					intersectionPointA.y = yMin;
				}
				
				if (intersectionPointB) 
				{
					intersectionPointB.x = xMin;
					intersectionPointB.y = yMin;
				}
				
				if (normalRadians) 
				{
					normalRadians.y = normalRadians.x + Math.PI;
				}
			}
			else if (intersectionCount > 1) 
			{
				intersectionCount++;
				
				if (intersectionPointA) 
				{
					intersectionPointA.x = xMin;
					intersectionPointA.y = yMin;
				}
				
				if (intersectionPointB) 
				{
					intersectionPointB.x = xMax;
					intersectionPointB.y = yMax;
				}
			}
			
			return intersectionCount;
		}
		/**
		 * @language zh_CN
		 * 包围盒类型。
		 * @see dragonBones.enum.BoundingBoxType
		 * @version DragonBones 5.0
		 */
		public var type: int;
		/**
		 * @language zh_CN
		 * 包围盒颜色。
		 * @version DragonBones 5.0
		 */
		public var color: uint;
		
		public var x: Number; // Polygon min x.
		public var y: Number; // Polygon min y.
		public var width: Number; // Polygon max x.
		public var height: Number; // Polygon max y.
		/**
		 * @language zh_CN
		 * 自定义多边形顶点。
		 * @version DragonBones 5.0
		 */
		public var vertices: Vector.<Number> = new Vector.<Number>();
		/**
		 * @private
		 */
		public function BoundingBoxData()
		{
			super(this);
		}
		/**
		 * @private
		 */
		override protected function _onClear(): void 
		{
			type = BoundingBoxType.None;
			color = 0x000000;
			x = 0.0;
			y = 0.0;
			width = 0.0;
			height = 0.0;
			vertices.fixed = false;
			vertices.length = 0;
		}
		/**
		 * @language zh_CN
		 * 是否包含点。
		 * @version DragonBones 5.0
		 */
		public function containsPoint(pX: Number, pY: Number): Boolean 
		{
			var isInSide:Boolean = false;
			
			if (type === BoundingBoxType.Polygon) 
			{
				if (pX >= x && pX <= width && pY >= y && pY <= height) 
				{
					for (var i:uint = 0, l:uint = vertices.length, iP:uint = l - 2; i < l; i += 2) 
					{
						const yA:Number = vertices[iP + 1];
						const yB:Number = vertices[i + 1];
						if ((yB < pY && yA >= pY) || (yA < pY && yB >= pY)) 
						{
							const xA:Number = vertices[iP];
							const xB:Number = vertices[i];
							if ((pY - yB) * (xA - xB) / (yA - yB) + xB < pX) 
							{
								isInSide = !isInSide;
							}
						}
						
						iP = i;
					}
				}
			}
			else 
			{
				const widthH:Number = width * 0.5;
				if (pX >= -widthH && pX <= widthH) 
				{
					const heightH:Number = height * 0.5;
					if (pY >= -heightH && pY <= heightH) 
					{
						if (type === BoundingBoxType.Ellipse) 
						{
							pY *= widthH / heightH;
							isInSide = Math.sqrt(pX * pX + pY * pY) <= widthH;
						}
						else {
							isInSide = true;
						}
					}
				}
			}
			
			return isInSide;
		}
		/**
		 * @language zh_CN
		 * 是否与线段相交。
		 * @version DragonBones 5.0
		 */
		public function intersectsSegment(
			xA: Number, yA: Number, xB: Number, yB: Number,
			intersectionPointA: Point = null,
			intersectionPointB: Point = null,
			normalRadians: Point = null
		): int 
		{
			var intersectionCount:int = 0;
			
			switch (type) 
			{
				case BoundingBoxType.Rectangle:
					const widthH:Number = width * 0.5;
					const heightH:Number = height * 0.5;
					intersectionCount = segmentIntersectsRectangle(
						xA, yA, xB, yB,
						-widthH, -heightH, widthH, heightH,
						intersectionPointA, intersectionPointB, normalRadians
					);
					break;
				
				case BoundingBoxType.Ellipse:
					intersectionCount = segmentIntersectsEllipse(
						xA, yA, xB, yB,
						0.0, 0.0, width * 0.5, height * 0.5,
						intersectionPointA, intersectionPointB, normalRadians
					);
					break;
				
				case BoundingBoxType.Polygon:
					if (segmentIntersectsRectangle(xA, yA, xB, yB, x, y, width, height, null, null) !== 0) 
					{
						intersectionCount = segmentIntersectsPolygon(
							xA, yA, xB, yB,
							vertices,
							intersectionPointA, intersectionPointB, normalRadians
						);
					}
					break;
				
				default:
					break;
			}
			
			return intersectionCount;
		}
	}
}