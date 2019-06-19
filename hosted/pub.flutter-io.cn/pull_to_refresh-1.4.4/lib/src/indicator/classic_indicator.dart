import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
/**
    Author: Jpeng
    Email: peng8350@gmail.com
    createTime:2018-05-14 17:39
 */

import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:flutter/widgets.dart';
import '../internals/indicator_wrap.dart';
import '../smart_refresher.dart';

enum IconPosition { left, right, top, bottom }

class ClassicHeader extends RefreshIndicator {
  final String releaseText, idleText, refreshingText, completeText, failedText;
  final Decoration decoration;
  final Widget releaseIcon, idleIcon, refreshingIcon, completeIcon, failedIcon;
  final double spacing;
  final IconPosition iconPos;

  final TextStyle textStyle;

  const ClassicHeader({
    Key key,
    RefreshStyle refreshStyle: default_refreshStyle,
    double height: default_height,
    Duration completeDuration: const Duration(milliseconds: 600),
    this.decoration: const BoxDecoration(),
    this.textStyle: const TextStyle(color: const Color(0xff555555)),
    this.releaseText: 'Refresh when release',
    this.refreshingText: 'Refreshing...',
    this.completeText: 'Refresh complete',
    this.failedText: 'Refresh failed',
    this.idleText: 'Pull down to refresh',
    this.iconPos: IconPosition.left,
    this.spacing: 15.0,
    this.refreshingIcon: const SizedBox(
      width: 25.0,
      height: 25.0,
      child: const CircularProgressIndicator(strokeWidth: 2.0),
    ),
    this.failedIcon: const Icon(Icons.error, color: Colors.grey),
    this.completeIcon: const Icon(Icons.done, color: Colors.grey),
    this.idleIcon = const Icon(Icons.arrow_downward, color: Colors.grey),
    this.releaseIcon = const Icon(Icons.arrow_upward, color: Colors.grey),
  }) : super(
          key: key,
          refreshStyle: refreshStyle,
          completeDuration: completeDuration,
          height: height,
        );

  const ClassicHeader.asSliver({
    Key key,
    @required OnRefresh onRefresh,
    ValueNotifier<RefreshStatus> mode,
    RefreshStyle refreshStyle: default_refreshStyle,
    this.decoration: const BoxDecoration(),
    double height: default_height,
    Duration completeDuration: const Duration(milliseconds: 600),
    this.textStyle: const TextStyle(color: const Color(0xff555555)),
    this.releaseText: 'Refresh when release',
    this.refreshingText: 'Refreshing...',
    this.completeText: 'Refresh complete',
    this.failedText: 'Refresh failed',
    this.idleText: 'Pull down to refresh',
    this.iconPos: IconPosition.left,
    this.spacing: 15.0,
    this.refreshingIcon: const SizedBox(
      width: 25.0,
      height: 25.0,
      child: const CircularProgressIndicator(strokeWidth: 2.0),
    ),
    this.failedIcon: const Icon(Icons.clear, color: Colors.grey),
    this.completeIcon: const Icon(Icons.done, color: Colors.grey),
    this.idleIcon = const Icon(Icons.arrow_downward, color: Colors.grey),
    this.releaseIcon = const Icon(Icons.arrow_upward, color: Colors.grey),
  }) : super(
            key: key,
            onRefresh: onRefresh,
            completeDuration: completeDuration,
            refreshStyle: refreshStyle,
            height: height);

  @override
  State createState() {
    // TODO: implement createState
    return _ClassicHeaderState();
  }
}

class _ClassicHeaderState extends RefreshIndicatorState<ClassicHeader> {
  Widget _buildText(mode) {
    return Text(
        mode == RefreshStatus.canRefresh
            ? widget.releaseText
            : mode == RefreshStatus.completed
                ? widget.completeText
                : mode == RefreshStatus.failed
                    ? widget.failedText
                    : mode == RefreshStatus.refreshing
                        ? widget.refreshingText
                        : widget.idleText,
        style: widget.textStyle);
  }

  Widget _buildIcon(mode) {
    Widget icon = mode == RefreshStatus.canRefresh
        ? widget.releaseIcon
        : mode == RefreshStatus.idle
            ? widget.idleIcon
            : mode == RefreshStatus.completed
                ? widget.completeIcon
                : mode == RefreshStatus.failed
                    ? widget.failedIcon
                    : widget.refreshingIcon;
    return icon ?? Container();
  }

  @override
  Widget buildContent(BuildContext context, RefreshStatus mode) {
    // TODO: implement buildContent
    Widget textWidget = _buildText(mode);
    Widget iconWidget = _buildIcon(mode);
    List<Widget> children = <Widget>[iconWidget, textWidget];
    final Widget container = Wrap(
      spacing: widget.spacing,
      textDirection: widget.iconPos == IconPosition.left
          ? TextDirection.ltr
          : TextDirection.rtl,
      direction: widget.iconPos == IconPosition.bottom ||
              widget.iconPos == IconPosition.top
          ? Axis.vertical
          : Axis.horizontal,
      crossAxisAlignment: WrapCrossAlignment.center,
      verticalDirection: widget.iconPos == IconPosition.bottom
          ? VerticalDirection.up
          : VerticalDirection.down,
      alignment: WrapAlignment.center,
      children: children,
    );
    return Container(
      height: widget.height,
      decoration: widget.decoration,
      child: Center(
        child: container,
      ),
    );
  }
}

class ClassicFooter extends LoadIndicator {
  final String idleText, loadingText, noDataText, failedText;

  final Decoration decoration;

  final Widget idleIcon, loadingIcon, noMoreIcon, failedIcon;

  final double height;

  final double spacing;

  final IconPosition iconPos;

  final TextStyle textStyle;

  const ClassicFooter({
    Key key,
    Function onClick,
    this.textStyle: const TextStyle(color: const Color(0xff555555)),
    this.loadingText: 'Loading...',
    this.noDataText: 'No more data',
    this.height: 60.0,
    this.decoration: const BoxDecoration(),
    this.noMoreIcon,
    this.idleText: 'Load More..',
    this.failedText: 'Load Failed,Click Retry!',
    this.failedIcon: const Icon(Icons.error, color: Colors.grey),
    this.iconPos: IconPosition.left,
    this.spacing: 15.0,
    this.loadingIcon: const SizedBox(
      width: 25.0,
      height: 25.0,
      child: const CircularProgressIndicator(
        strokeWidth: 2.0,
      ),
    ),
    this.idleIcon = const Icon(Icons.arrow_downward, color: Colors.grey),
  }) : super(
          key: key,
          onClick: onClick,
        );

  const ClassicFooter.asSliver({
    Key key,
    @required OnLoading onLoading,
    Function onClick,
    this.textStyle: const TextStyle(color: const Color(0xff555555)),
    this.decoration: const BoxDecoration(),
    this.loadingText: 'Loading...',
    this.noDataText: 'No more data',
    this.height: 60.0,
    this.noMoreIcon,
    this.idleText: 'Load More..',
    this.iconPos: IconPosition.left,
    this.failedText: 'Load Failed,Click Retry!',
    this.failedIcon: const Icon(Icons.error, color: Colors.grey),
    this.spacing: 15.0,
    this.loadingIcon: const SizedBox(
      width: 25.0,
      height: 25.0,
      child: const CircularProgressIndicator(
        strokeWidth: 2.0,
      ),
    ),
    this.idleIcon = const Icon(Icons.arrow_downward, color: Colors.grey),
  }) : super(
          key: key,
          onLoading: onLoading,
          onClick: onClick,
        );

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState

    return _ClassicFooterState();
  }
}

class _ClassicFooterState extends LoadIndicatorState<ClassicFooter> {
  Widget _buildText(LoadStatus mode) {
    return Text(
        mode == LoadStatus.loading
            ? widget.loadingText
            : LoadStatus.noMore == mode
                ? widget.noDataText
                : LoadStatus.failed == mode
                    ? widget.failedText
                    : widget.idleText,
        style: widget.textStyle);
  }

  Widget _buildIcon(LoadStatus mode) {
    Widget icon = mode == LoadStatus.loading
        ? widget.loadingIcon
        : mode == LoadStatus.noMore
            ? widget.noMoreIcon
            : mode == LoadStatus.failed ? widget.failedIcon : widget.idleIcon;
    return icon ?? Container();
  }

  @override
  Widget buildContent(BuildContext context, LoadStatus mode) {
    // TODO: implement buildChild
    Widget textWidget = _buildText(mode);
    Widget iconWidget = _buildIcon(mode);
    List<Widget> children = <Widget>[iconWidget, textWidget];
    final Widget container = Wrap(
      spacing: widget.spacing,
      textDirection: widget.iconPos == IconPosition.left
          ? TextDirection.ltr
          : TextDirection.rtl,
      direction: widget.iconPos == IconPosition.bottom ||
              widget.iconPos == IconPosition.top
          ? Axis.vertical
          : Axis.horizontal,
      crossAxisAlignment: WrapCrossAlignment.center,
      verticalDirection: widget.iconPos == IconPosition.bottom
          ? VerticalDirection.up
          : VerticalDirection.down,
      alignment: WrapAlignment.center,
      children: children,
    );
    return Container(
      height: widget.height,
      decoration: widget.decoration,
      child: Center(
        child: container,
      ),
    );
  }
}
