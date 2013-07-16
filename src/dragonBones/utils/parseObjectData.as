package dragonBones.utils
{
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.utils.ConstValues;

	public function parseObjectData(object:Object):SkeletonData
	{
		var frameRate:uint = int(object[ConstValues.A_FRAME_RATE]);
		
		var data:SkeletonData = new SkeletonData();
		data.name = object[ConstValues.A_NAME];
		
		for each(var armatureObject:Object in object[ConstValues.ARMATURE])
		{
			data.addArmatureData(parseArmatureData(armatureObject, data, frameRate));
		}
		
		return data;
	}
}

import dragonBones.objects.AnimationData;
import dragonBones.objects.ArmatureData;
import dragonBones.objects.BoneData;
import dragonBones.objects.DBTransform;
import dragonBones.objects.DisplayData;
import dragonBones.objects.Frame;
import dragonBones.objects.SkeletonData;
import dragonBones.objects.SkinData;
import dragonBones.objects.SlotData;
import dragonBones.objects.Timeline;
import dragonBones.objects.TransformFrame;
import dragonBones.objects.TransformTimeline;
import dragonBones.utils.ConstValues;
import dragonBones.utils.DBDataUtil;

import flash.geom.ColorTransform;
import flash.geom.Point;

const ANGLE_TO_RADIAN:Number = Math.PI / 180;

function parseArmatureData(armatureObject:Object, data:SkeletonData, frameRate:uint):ArmatureData
{
	var armatureData:ArmatureData = new ArmatureData();
	armatureData.name = armatureObject[ConstValues.A_NAME];
	
	for each(var boneObject:Object in armatureObject[ConstValues.BONE])
	{
		armatureData.addBoneData(parseBoneData(boneObject));
	}
	
	for each(var skinObject:Object in armatureObject[ConstValues.SKIN])
	{
		armatureData.addSkinData(parseSkinData(skinObject, data));
	}
	
	DBDataUtil.transformArmatureData(armatureData);
	armatureData.sortBoneDataList();
	
	for each(var animationObject:Object in armatureObject[ConstValues.ANIMATION])
	{
		armatureData.addAnimationData(parseAnimationData(animationObject, armatureData, frameRate));
	}
	
	return armatureData;
}

function parseBoneData(boneObject:Object):BoneData
{
	var boneData:BoneData = new BoneData();
	boneData.name = boneObject[ConstValues.A_NAME];
	boneData.parent = boneObject[ConstValues.A_PARENT];
	
	parseTransform(boneObject[ConstValues.TRANSFORM], boneData.global, boneData.pivot);
	boneData.transform.copy(boneData.global);
	
	return boneData;
}

function parseSkinData(skinObject:Object, data:SkeletonData):SkinData
{
	var skinData:SkinData = new SkinData();
	skinData.name = skinObject[ConstValues.A_NAME];
	
	for each(var slotObject:Object in skinObject[ConstValues.SLOT])
	{
		skinData.addSlotData(parseSlotData(slotObject, data));
	}
	
	return skinData;
}

function parseSlotData(slotObject:Object, data:SkeletonData):SlotData
{
	var slotData:SlotData = new SlotData();
	slotData.name = slotObject[ConstValues.A_NAME];
	slotData.parent = slotObject[ConstValues.A_PARENT];
	slotData.zOrder = slotObject[ConstValues.A_Z_ORDER];
	for each(var displayObject:Object in slotObject[ConstValues.DISPLAY])
	{
		slotData.addDisplayData(parseDisplayData(displayObject, data));
	}
	
	return slotData;
}

function parseDisplayData(displayObject:Object, data:SkeletonData):DisplayData
{
	var displayData:DisplayData = new DisplayData();
	displayData.name = displayObject[ConstValues.A_NAME];
	displayData.type = displayObject[ConstValues.A_TYPE];
	
	displayData.pivot = data.addSubTexturePivot(
		0, 
		0, 
		displayData.name
	);
	
	parseTransform(displayObject[ConstValues.TRANSFORM], displayData.transform, displayData.pivot);
	
	return displayData;
}

function parseAnimationData(animationObject:Object, armatureData:ArmatureData, frameRate:uint):AnimationData
{
	var animationData:AnimationData = new AnimationData();
	animationData.name = animationObject[ConstValues.A_NAME];
	animationData.frameRate = frameRate;
	animationData.loop = int(animationObject[ConstValues.A_LOOP]);
	animationData.fadeInTime = Number(animationObject[ConstValues.A_FADE_IN_TIME]);
	animationData.duration = Number(animationObject[ConstValues.A_DURATION]) / frameRate;
	animationData.scale = Number(animationObject[ConstValues.A_SCALE]);
	animationData.tweenEasing = Number(animationObject[ConstValues.A_TWEEN_EASING]);
	
	parseTimeline(animationObject, animationData, parseMainFrame, frameRate);
	
	var timeline:TransformTimeline;
	var timelineName:String;
	for each(var timelineObject:Object in animationObject[ConstValues.TIMELINE])
	{
		timeline = parseTransformTimeline(timelineObject, animationData.duration, frameRate);
		timelineName = timelineObject[ConstValues.A_NAME];
		animationData.addTimeline(timeline, timelineName);
	}
	
	DBDataUtil.addHideTimeline(animationData, armatureData);
	DBDataUtil.transformAnimationData(animationData, armatureData);
	
	return animationData;
}

function parseTimeline(timelineObject:Object, timeline:Timeline, frameParser:Function, frameRate:uint):void
{
	var position:Number = 0;
	var frame:Frame;
	for each(var frameObject:Object in timelineObject[ConstValues.FRAME])
	{
		frame = frameParser(frameObject, frameRate);
		frame.position = position;
		timeline.addFrame(frame);
		position += frame.duration;
	}
	if(frame)
	{
		frame.duration = timeline.duration - frame.position;
	}
}

function parseTransformTimeline(timelineObject:Object, duration:Number, frameRate:uint):TransformTimeline
{
	var timeline:TransformTimeline = new TransformTimeline();
	timeline.duration = duration;
	
	parseTimeline(timelineObject, timeline, parseTransformFrame, frameRate);
	
	timeline.scale = Number(timelineObject[ConstValues.A_SCALE]);
	timeline.offset = Number(timelineObject[ConstValues.A_OFFSET]);
	
	return timeline;
}

function parseFrame(frameObject:Object, frame:Frame, frameRate:uint):void
{
	frame.duration = Number(frameObject[ConstValues.A_DURATION]) / frameRate;
	frame.action = frameObject[ConstValues.A_ACTION];
	frame.event = frameObject[ConstValues.A_EVENT];
	frame.sound = frameObject[ConstValues.A_SOUND];
}

function parseMainFrame(frameObject:Object, frameRate:uint):Frame
{
	var frame:Frame = new Frame();
	parseFrame(frameObject, frame, frameRate);
	return frame;
}

function parseTransformFrame(frameObject:Object, frameRate:uint):TransformFrame
{
	var frame:TransformFrame = new TransformFrame();
	parseFrame(frameObject, frame, frameRate);
	
	frame.visible = uint(frameObject[ConstValues.A_HIDE]) != 1;
	frame.tweenEasing = Number(frameObject[ConstValues.A_TWEEN_EASING]);
	frame.tweenRotate = Number(frameObject[ConstValues.A_TWEEN_ROTATE]);
	frame.displayIndex = Number(frameObject[ConstValues.A_DISPLAY_INDEX]);
	frame.zOrder = Number(frameObject[ConstValues.A_Z_ORDER]);
	
	parseTransform(frameObject[ConstValues.TRANSFORM], frame.global, frame.pivot);
	frame.transform.copy(frame.global);
	
	var colorTransformObject:Object = frameObject[ConstValues.COLOR_TRANSFORM];
	if(colorTransformObject)
	{
		frame.color = new ColorTransform();
		frame.color.alphaOffset = Number(colorTransformObject[ConstValues.A_ALPHA_OFFSET]);
		frame.color.redOffset = Number(colorTransformObject[ConstValues.A_RED_OFFSET]);
		frame.color.greenOffset = Number(colorTransformObject[ConstValues.A_GREEN_OFFSET]);
		frame.color.blueOffset = Number(colorTransformObject[ConstValues.A_BLUE_OFFSET]);
		
		frame.color.alphaMultiplier = Number(colorTransformObject[ConstValues.A_ALPHA_MULTIPLIER]) * 0.01;
		frame.color.redMultiplier = Number(colorTransformObject[ConstValues.A_RED_MULTIPLIER]) * 0.01;
		frame.color.greenMultiplier = Number(colorTransformObject[ConstValues.A_GREEN_MULTIPLIER]) * 0.01;
		frame.color.blueMultiplier = Number(colorTransformObject[ConstValues.A_BLUE_MULTIPLIER]) * 0.01;
	}
	
	return frame;
}

function parseTransform(transformObject:Object, transform:DBTransform, pivot:Point):void
{
	if(transformObject)
	{
		if(transform)
		{
			transform.x = Number(transformObject[ConstValues.A_X]);
			transform.y = Number(transformObject.@[ConstValues.A_Y]);
			transform.skewX = Number(transformObject[ConstValues.A_SKEW_X]) * ANGLE_TO_RADIAN;
			transform.skewY = Number(transformObject[ConstValues.A_SKEW_Y]) * ANGLE_TO_RADIAN;
			transform.scaleX = Number(transformObject[ConstValues.A_SCALE_X]);
			transform.scaleY = Number(transformObject[ConstValues.A_SCALE_Y]);
		}
		if(pivot)
		{
			pivot.x = Number(transformObject[ConstValues.A_PIVOT_X]);
			pivot.y = Number(transformObject[ConstValues.A_PIVOT_Y]);
		}
	}
}