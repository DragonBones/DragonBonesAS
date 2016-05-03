package dragonBones.fast
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import dragonBones.objects.IKData;
	import dragonBones.utils.TransformUtil;
	
	public class FastIKConstraint
	{
		private var ikdata:IKData;
		private var armature:FastArmature;
		
		public var bones:Vector.<FastBone>;
		public var target:FastBone;
		public var bendDirection:int;
		public var weight:Number;
		
		public var animationCacheBend:int=0;		
		public var animationCacheWeight:Number=-1;	
		
		public function FastIKConstraint(data:IKData,armatureData:FastArmature)
		{
			this.ikdata = data;
			this.armature = armatureData
				
			weight = data.weight;
			bendDirection = (data.bendPositive?1:-1);
			bones = new Vector.<FastBone>();
			var bone:FastBone;
			if(data.chain){
				bone = armatureData.getBone(data.bones).parent;
				bone.isIKConstraint = true;
				bones.push(bone);
			}
			bone = armatureData.getBone(data.bones);
			bone.isIKConstraint = true;
			bones.push(bone);
			target = armatureData.getBone(data.target);
		}
		public function dispose():void
		{
			
		}
		public function compute():void
		{
			switch (bones.length) {
				case 1:
					var weig1:Number = animationCacheWeight>=0?animationCacheWeight:weight;
					compute1(bones[0], target, weig1);
					break;
				case 2:
					var bend:int = animationCacheBend!=0?animationCacheBend:bendDirection;
					var weig:Number = animationCacheWeight>=0?animationCacheWeight:weight;
					var tt:Point = compute2(bones[0],bones[1],target.global.x,target.global.y, bend, weig);
					bones[0].rotationIK = bones[0].origin.rotation+(tt.x-bones[0].origin.rotation)*weig+bones[0].parent.rotationIK;
					bones[1].rotationIK = bones[1].origin.rotation+(tt.y-bones[1].origin.rotation)*weig+bones[0].rotationIK;
					break;
			}
		}
		public function compute1 (bone:FastBone, target:FastBone, weightA:Number) : void {
			var parentRotation:Number = (!bone.inheritRotation || bone.parent == null) ? 0 : bone.parent.global.rotation;
			var rotation:Number = bone.global.rotation;
			var rotationIK:Number = Math.atan2(target.global.y - bone.global.y, target.global.x - bone.global.x);
			bone.rotationIK = rotation + (rotationIK - rotation) * weightA;
		}
		public function compute2(parent:FastBone, child:FastBone, targetX:Number,targetY:Number, bendDirection:int, weightA:Number):Point
		{
			if (weightA == 0) {
				return new Point(parent.global.rotation,child.global.rotation);
			}
			var tt:Point = new Point();
			var p1:Point = new Point(parent.global.x,parent.global.y);
			var p2:Point = new Point(child.global.x,child.global.y);
			var matrix:Matrix = new Matrix();
			TransformUtil.transformToMatrix(parent.parent.global,matrix);
			var tempMatrix:Matrix = matrix.clone();
			tempMatrix.invert();
			var targetPoint:Point = TransformUtil.applyMatrixToPoint(new Point(targetX,targetY),tempMatrix,true);
			targetX = targetPoint.x;
			targetY = targetPoint.y;
			p1 = TransformUtil.applyMatrixToPoint(p1,tempMatrix,true);
			p2 = TransformUtil.applyMatrixToPoint(p2,tempMatrix,true);
			var psx:Number = parent.origin.scaleX;
			var psy:Number = parent.origin.scaleY;
			var csx:Number = child.origin.scaleX;
			var childX:Number = p2.x-p1.x;
			var childY:Number = p2.y-p1.y;
			var len1:Number = Math.sqrt(childX * childX + childY* childY);
			var parentAngle:Number;
			var childAngle:Number;
			var sign:int = 1;
			var offset1:Number = 0;
			var offset2:Number = 0;
			if (psx < 0) {
				psx = -psx;
				offset1 = Math.PI;
				sign = -1;
			} else {
				offset1 = 0;
				sign = 1;
			}
			if (psy < 0) {
				psy = -psy;
				sign = -sign;
			}
			if (csx < 0) {
				csx = -csx;
				offset2 = Math.PI;
			} else{
				offset2 = 0;
			}
			bendDirection = sign*bendDirection;
			outer:
			if (Math.abs(psx - psy) <= 0.001) {
				var childlength:Number = child.length;
				var len2:Number = childlength*csx;
				targetX = targetX-p1.x;
				targetY = targetY-p1.y;
				var cosDenom:Number = 2 * len1 * len2;
				var cos:Number = (targetX * targetX + targetY * targetY - len1 * len1 - len2 * len2) / cosDenom;
				if (cos < -1)
					cos = -1;
				else if (cos > 1)
					cos = 1;
				childAngle = Math.acos(cos) * bendDirection;
				var adjacent:Number = len1 + len2 * cos;
				var opposite:Number = len2 * Math.sin(childAngle);
				parentAngle = Math.atan2(targetY * adjacent - targetX * opposite, targetX * adjacent + targetY * opposite);
			}else{
				var l1:Number = len1;
				var tx:Number = targetX-p1.x;
				var ty:Number = targetY-p1.y;
				var l2:Number = child.length*child.origin.scaleX;
				var a:Number = psx * l2;
				var b:Number = psy * l2;
				var ta:Number = Math.atan2(ty, tx);
				var aa:Number = a * a;
				var bb:Number = b * b;
				var ll:Number = l1 * l1;
				var dd:Number = tx * tx + ty * ty;
				var c0:Number = bb * ll + aa * dd - aa * bb;
				var c1:Number = -2 * bb * l1;
				var c2:Number = bb - aa;
				var d:Number = c1 * c1 - 4 * c2 * c0;
				if (d >= 0) {
					var q:Number =Math.sqrt(d);
					if (c1 < 0) q = -q;
					q = -(c1 + q) / 2;
					var r0:Number = q / c2
					var r1:Number = c0 / q;
					var r:Number = Math.abs(r0) < Math.abs(r1) ? r0 : r1;
					if (r * r <= dd) {
						var y1:Number = Math.sqrt(dd - r * r) * bendDirection;
						parentAngle = ta - Math.atan2(y1, r);
						childAngle = Math.atan2(y1 / psy, (r - l1) / psx);
						break outer;
					}
				}
				var minAngle:Number = 0;
				var minDist:Number = Number.MAX_VALUE;
				var minX:Number = 0;
				var minY:Number = 0;
				var maxAngle:Number = 0;
				var maxDist:Number = 0;
				var maxX:Number = 0;
				var maxY:Number = 0;
				var x2:Number = l1 + a;
				var dist:Number = x2 * x2;
				if (dist > maxDist) {
					maxAngle = 0;
					maxDist = dist;
					maxX = x2;
				}
				x2 = l1 - a;
				dist = x2 * x2;
				if (dist < minDist) {
					minAngle = Math.PI;
					minDist = dist;
					minX = x2;
				}
				var angle1:Number = Math.acos(-a * l1 / (aa - bb));
				x2 = a * Math.cos(angle1) + l1;
				var y2:Number = b * Math.sin(angle1);
				dist = x2 * x2 + y2 * y2;
				if (dist < minDist) {
					minAngle = angle1;
					minDist = dist;
					minX = x2;
					minY = y2;
				}
				if (dist > maxDist) {
					maxAngle = angle1;
					maxDist = dist;
					maxX = x2;
					maxY = y2;
				}
				if (dd <= (minDist + maxDist) / 2) {
					parentAngle = ta - Math.atan2(minY * bendDirection, minX);
					childAngle = minAngle * bendDirection;
				} else {
					parentAngle = ta - Math.atan2(maxY * bendDirection, maxX);
					childAngle = maxAngle * bendDirection;
				}
			}
			var cx:Number = child.origin.x;
			var cy:Number = child.origin.y*psy;
			var initalRotation:Number = Math.atan2(cy, cx)*sign;
			tt.x = parentAngle -initalRotation+offset1;
			tt.y = (childAngle+initalRotation)*sign + offset2;
			normalize(tt.x);
			normalize(tt.y);
			return tt;
		}
		private function normalize(rotation:Number):void
		{
			if (rotation > Math.PI)
				rotation -= Math.PI*2;
			else if (rotation < -Math.PI)
				rotation += Math.PI*2;
		}
	}
}