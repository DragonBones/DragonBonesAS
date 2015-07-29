DragonBones AS Lib V4.1 Release Notes
======================
最近更新时间：2015年7月29日  
### 概述
DragonBones AS Lib V4.1 是配合DragonBones4.1发布的AS版本的语言库。在这个版本中，我们主要做的是，增加FastArmature极速模式。极速模式是通过关闭某些功能，同时开启动画数据缓存的方式提高动画运行效率。经测试，使用 Starling开启极速模式能够提高动画运行速度300%。  
如果您对DragonBones有任何意见和建议，欢迎发邮件至dragonbonesteam@gmail.com。  

### 更新内容  
##### 增加FastArmature极速模式  
* 重构骨架动画体系，关闭某些功能
* 增加动画数据缓存的支持
* 将soundManager加回

##### 极速模式和普通模式的性能和功能对比

```

Compare                  | Armature | FastArmature | FastArmature+数据缓存
------------------------ | -------- | ------------ | ------------
Performance              | 100      | 120          | 300 
Animation Blending       | √        | √            | √ 
Animation Tween          | √        | √            | √ 
Dynamic Animation Tween  | √        | ×            | ×
Color Transform          | √        | √            | √ 
Sequence Frame Animation | √        | √            | √ 
Animation Time Scale     | √        | √            | √ 
Change Slot Image        | √        | √            | √ 
Change Skin              | √        | ×            | × 
Dynamic Add/Remove Bone  | √        | ×            | × 
Animation Bone Mask      | √        | ×            | × 
Animation Mixing         | √        | ×            | × 
Timeline Event           | √        | √            | √ 

```

