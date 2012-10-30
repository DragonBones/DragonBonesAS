package dragonBones.objects {
	
	/**
	 * ...
	 * @author Akdcl
	 */
	final public class FrameData extends Node {
		public var duration:int;
		
		public var tweenEasing:Number;
		
		public var displayIndex:int;
		public var movement:String;
		
		public var event:String;
		
		public var sound:String;
		public var soundEffect:String;
		
		public function FrameData() {
			super();
			
			duration = 1;
			//为NaN则不会补间，-1~0~1~2淡出、线性、淡入、淡入淡出
			tweenEasing = 0;
		}
	}
	
}