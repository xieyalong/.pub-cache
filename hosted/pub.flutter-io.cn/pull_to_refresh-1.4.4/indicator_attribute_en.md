# Indicator properties

## Common header attributes (not every indicator, but most have these attributes)
* double  height: It refers to the height occupied by the indicator. This attribute has different meanings for different indicator styles.
  This property does not constrain the layout size, and sublayout can overflow the range of this value.
* refreshStyle: Styles used to define header refresh indicators,There is four style:Front,Behind,Follow,UnFollow
* completeDuration: stop time when state in success or fail

## common Footer attributes
* bool autoLoad: Whether to turn on the function of automatic loading at a certain distance


## ClassicHeader,ClassicFooter(Not Support Behind)
* String idleText:Text displayed when the indicator is idle
* Widget idleIcon:Icon displayed when the indicator is idle
* String  refreshingText:Text displayed when the indicator is refreshing
* Widget  refreshingIcon:Icon displayed when the indicator is refreshing
* .....the same above
* double spacing: Spacing between icons and text
* TextStyle textStyle: textStyle
* IconPosition iconPos:IconPosition(Left,Top,Right,Bottom)
* RefreshStyle refreshStyle,height,triggerDistance,autoLoad: the same Above
* decoration:  use to setting bg


## WaterDropHeader
* Color waterDropColor:WaterDrop Color
* Widget idleIcon:It refers to the middle part of the water droplet in the process of user dragging.
* Widget refresh: Content displayed during refresh
* Widget complete:Content displayed during complete
* Widget failed:Content displayed during fail

## MaterialClassicHeader,WaterDropMaterialHeader
This internal implementation is implemented with something inside the flutter RefreshIndicator.many of its attributes mean the same thing, so I won't list them.
* double distance:When preparing to trigger refresh, the indicator should be placed at a distance of not more than 100.0 from the top.

