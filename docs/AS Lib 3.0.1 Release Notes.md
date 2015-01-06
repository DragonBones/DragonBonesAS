DragonBones AS Lib V3.0.1 Release Notes
======================
中文版往后看

Jan 5th, 2015

DragonBones AS Lib V3.0.1 is a community experience version (minor version) after V3.0.0. In this version, we primary focused on 3.0 data format standard support as well as animation flexibility improvement.  
All these features will be hold in community experience version for months before merge to stable version based on customer feedback. If you have any ideas or suggestions, please email us dragonbonesteam@gmail.com.  

### New Features  
##### 3.0 data format standard support 
* Support parent coordinate data format.  
* Unify the default value parse with 3.0 data format standard.  
* See 3.0 data format standard details in  [DragonBonesDataFormatSpec_V3.0_en.xml](https://github.com/DragonBones/DesignPanel/blob/dev/docs/DragonBonesDataFormatSpec_V3.0_en.xml)

##### Add three new properties "applyOffsetTranslationToChild", "applyOffsetRotationToChild", "applyOffsetScaleToChild" in Bone to improve animation flexibility.  
* These three properties can be used to switch if the Bone.offset impact its child bones.
* The default value of these three properties are:
applyOffsetTranslationToChild = true  
applyOffsetRotationToChild = true  
applyOffsetScaleToChild = false  

##### Redefine the DBObject.inheritScale property.  
* In previous version, DBObject.inheritScale means if the DBObject will be impacted with its parent bone's offset.scale. For now it mean if the DBObject will be impacted with its parent bone's global.scale, which means if DBObject.inheritScale=false, its scale will be totally independent.  
* This property usually be used in dynamically add bones case. A similar property is DBObject.inheritRotation. When developers add bones dynamically at runtime and do not want the bone's parent influence it, they can set the two properties to false. In Knight example, there is a fire effect on horse's eyes. It set the inheritRotation=false to achieve n matter how the horse head rotate, the flame is upward.

最近更新时间：2014年1月5日  
### 概述
DragonBones AS Lib V3.0.1 是V3.0.0之后的一个社区体验版(小版本)。在这个版本中，我们主要做的是，增加3.0数据格式标准的支持，同时增加一些属性使动画的控制更加灵活。  
这个部分的功能会在社区体验版中过渡一段时间，之后基于用户反馈决定是否加入正式版。如果您对DragonBones有任何意见和建议，欢迎发邮件至dragonbonesteam@gmail.com。  

### 更新内容  
##### 支持3.0数据格式标准  
* 支持基于父坐标系的数据格式
* 数据的默认值和3.0数据格式标准中保持统一
* 详细的数据标准文档参见： [DragonBonesDataFormatSpec_V3.0_cn.xml](https://github.com/DragonBones/DesignPanel/blob/dev/docs/DragonBonesDataFormatSpec_V3.0_cn.xml)

##### 在Bone上增加applyOffsetTranslationToChild, applyOffsetRotationToChild, applyOffsetScaleToChild三个属性，使动画的控制更加灵活
* 开发者可以通过设置Bone.offset实现通过代码对Bone的显示进行调整。有的时候这个调整希望能同时影响Bone的子骨骼，有的时候希望只影响Bone本身，这三个属性就是用来控制这个的开关。
* 为了保持显示效果的向下兼容，这三个属性的默认值分别为：  
applyOffsetTranslationToChild = true  
applyOffsetRotationToChild = true  
applyOffsetScaleToChild = false  
也就是说对父骨骼的平移和旋转属性进行调整的时候，默认是影响子骨骼的，对缩放属性进行调整的时候默认是不影响子骨骼的。  

##### 对DBObject上的inheritScale属性进行重新定义
* 在老板本中, DBObject.inheritScale属性代表是否继承父骨骼的Offset值, 默认是false. 新版本中改为是否继承父骨骼的世界坐标, 也就是说如果设为false, 子骨骼的scale将完全不受父骨骼的影响.
* inheritScale默认值为true. 
* 这个属性主要用于动态添加的骨骼，与之类似的属性是DBObject.inheritRotation. 当开发者在运行时动态添加骨骼同时又不希望该骨骼收父级影响时，可以设置这两个属性。在Knight的例子中，马的眼睛上的火的效果，就设置了inheritRotation=false, 用来实现不论马头如何旋转火苗都是向上的效果.  


