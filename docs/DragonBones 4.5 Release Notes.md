DragonBones AS Lib V4.5 Release Notes
======================
Latest update time: May 13, 2016 （中文版见后面）
### Overview
DragonBones 4.5 a large update after 4.0. Data format added lots of features. Data version upgrade to 4.5. At the same time, we give full consideration about the compatibility. It support backward compatibility as well as forward compatibility.
If you have any comments or suggestions on DragonBones, welcome to https://trello.com/b/oooKrTH8/dragonbones-idea-collection and leave message.

### Updates
##### Support Mesh and FFD(Free-FormDeformation) Animation
* Mesh and FFD is the a huge new feature of DB 4.5. Using mesh and FFD, can achieve such cloak fluttered the soft body animation and face a range of the rotation of the Pseudo 3D facial animation.
* Mesh means to allow users to define the image of the rectangle within the boundaries of the polygon. On the one hand, he can improve the space usage of the final texture map, because the pixels outside the polygon will be ignored, this optimization is particularly important for mobile devices.
* FFD allows you to move Mesh points to deformation picture, can achieve grid drawing, extrusion, bending, rebounding, some rectangular images can not realize the function. Including the current transfer function of the pseudo 3D game, can also be achieved through the free deformation of the animation.

##### Support IK Constraint
* In most cases, skeletal animation follows FK, which is the parent bone that drives the child to skeletal movement, such as the big arm to drive the arm, and the thigh to drive the leg. And in some special scenarios need IK, also is skeleton driven parent skeleton driven by the parent bone, such as doing push ups, hands braced on the ground, support from the body.
* IK Constraint refers to set a point shaped fixed point as a child bone, regardless of the parent bone how to exercise, skeletal always point to the point. At the same time, the bone will traction parent bone do follow the action.


##### Support skewing scale.
* 4.0 is non-skewing scale logic, that regardless of the child bone relative to the parent bone rotation angle is much, the parent bone in its X axis scaling inheritance to skeletal effect is also the son of bones in its X axis scaling.
* Skewing scale inheritance logic makes the results more natural, more able to use in practical application scenarios, such as figure about flip effect can also be achieved.

##### Support inherit scale and inherit rotation
* You can set whether the bone is affected by the scaling or rotation of the parent.
* Make parent bone zoom animation, do not want to affect the child bones, you can close the child bones' inherited scale.
* Want a bone always pointing to a particular direction (e.g. making characters on the leg by the effect of gravity sag, regardless of body how to rotate, leg forever toward), will close the leg bones inherit rotation.

##### Support controll nested armature play specific animation
* You can control the nested armature play specific animation.

DragonBones AS Lib V4.5 Release Notes
======================
最近更新时间：2016年5月13日  
### 概述
DragonBones 4.5是继4.0之后最大规模的一次更新，数据格式也有较多的功能增加，数据版本从4.0升级到4.5，同时我们充分考虑到了兼容性的问题，既支持向后兼容也支持向前兼容，也就是说不但4.5的库能播放4.0格式的动画，同时4.0的库也可以最大限度的兼容播放DBPro 4.5制作的动画。
如果您对DragonBones有任何意见和建议，欢迎到这里发表https://trello.com/b/oooKrTH8/dragonbones-idea-collection

### 更新内容  
##### 支持网格(Mesh)和自由变形动画  
* 网格和自由变形动画是DB 4.5新增的重量级功能。利用网格和自由变形动画，可以实现例如披风飘动这类的柔体动画和面部一定范围内的转动这种伪3D的转面动画。  
* 网格又叫Mesh，名称基本是直译，意思就是允许用户在图片的矩形边界内定义多边形。一方面他能提高最终纹理贴图集的空间使用率，因为在多边形外的像素将被忽略掉，这种优化对移动设备来特别重要。
* 自由变形英文全称是 Free-FormDeformation，自由变形允许你通过移动网格点来变形图片，能实现网格的拉伸、挤压、弯曲、反弹，等一些矩形图片无法实现的功能。包括目前伪3D游戏中的转面功能，也能能够通过自由变形动画实现的。

##### 支持反向动力学约束（IK Constraint）
* 大部分情况下，骨骼动画遵循正向动力学，也就是父骨骼带动子骨骼运动，例如大臂带动小臂，大腿带动小腿。而在有些特殊场景中则需要反向动力学，也就是子骨骼带动父骨骼带动父骨骼，例如做俯卧撑时，手撑住地面，支起身体。
* 反向动力学约束，就是指为子骨骼设置一个指向形的固定点，不论父骨骼如何运动，子骨骼始终指向这个点，同时子骨骼会牵引父骨骼做跟随性的动作。

##### 改进骨骼缩放的叠加效果，支持骨架整体的非等比缩放和反转。
* 4.0使用的是非斜切的缩放继承逻辑，也就是说不论子骨骼相对父骨骼旋转角度多大，父骨骼的在自身x轴上的缩放继承到子骨骼上影响的也是子骨骼在自身x轴上的缩放。
* 斜切的缩放继承逻辑使得结果更加自然，更加能在实际应用场景中使用,例如图中左右翻转的效果也能实现。

##### 增加骨骼的继承缩放和继承旋转功能。
* 可以设置骨骼是否受到父亲的缩放或者旋转的影响。
* 为父骨骼制作缩放动画，不希望影响子骨骼，可以将子骨骼的继承缩放开关关闭。
* 希望某个骨骼永远指向某个特定方向（例如制作人物腿部受重力下垂的效果，不管身体如何旋转，腿部永远朝下），可以将腿部的骨骼的继承旋转开关关闭。

##### 增加子元件的播放动画设置。
* 可以控制子骨架播放制定动画。

