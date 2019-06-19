# 指示器属性说明

## 头部常见属性(不代表每个指示器都有,但是大多数都有这些属性)
* double  height: 指的是指示器占用多少高度。这个属性对于不同指示器风格意义不太一样。这个属性不会约束布局大小,子布局可以溢出这个值的范围。
* refreshStyle: 用于限定头部刷新指示器的风格,四种:Front,Behind,Follow,UnFollow
* completeDuration: 完成或者失败状态停留的时间


## 底部通用属性
* () => {} onClick：点击指示器的回调方法,用于手动进行加载数据或者reset没有数据的状态


## ClassicHeader,ClassicFooter(不支持背部)
* String idleText:指示器空闲时显示的文字
* Widget idleIcon:指示器空闲时显示的图标
* String  refreshingText:指示器刷新时显示的文字
* Widget  refreshingIcon:指示器刷新时显示的图标
* .....以此类推
* double spacing: 图标和文字的间距
* TextStyle textStyle: 设置文字的风格
* IconPosition iconPos:图标的位置,是位于文字左边,右边，上方，底部
* RefreshStyle refreshStyle,height,triggerDistance,autoLoad: 同顶部说明
* decoration: 用于设置背景或者颜色


## WaterDropHeader
* Color waterDropColor:水滴颜色
* Widget idleIcon:指的是用户拖动过程中水滴中间的部件
* Widget refresh: 刷新过程中显示内容
* Widget complete:刷新完成显示内容
* Widget failed:刷新失败显示的内容

## MaterialClassicHeader,WaterDropMaterialHeader
这个内部实现是拿flutter RefreshIndicator内部的东西来实现的，所以它里面很多属性意思是和它一样的，所以我就不列举出来
* double distance:当准备触发刷新时,指示器要放在距离顶部多少个距离,注意这个距离不能超过100.0
