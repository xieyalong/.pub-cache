/*
 * Author: Jpeng
 * Email: peng8350@gmail.com
 * Time: 2019/5/5 下午6:10
 */

import 'package:flutter/material.dart'
    hide RefreshIndicator, RefreshIndicatorState;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/scheduler.dart';
import '../../Item.dart';

class IndicatorActivity extends StatefulWidget {
  final String title;

  final RefreshIndicator header;

  final LoadIndicator footer;

  final bool enableOverScroll;
  final bool reverse;

  IndicatorActivity(
      {this.title,
      this.header,
      this.reverse: false,
      this.footer,
      this.enableOverScroll: true});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _IndicatorActivityState();
  }
}

class _IndicatorActivityState extends State<IndicatorActivity> {
  List<Widget> items = [];
  RefreshController _refreshController;

  void _init() {
    for (int i = 0; i < 5; i++) {
      items.add(Item(
        title: "Data$i",
      ));
    }
  }

  ScrollController _scrollController;

  @override
  void initState() {
    // TODO: implement initState
    _scrollController = new ScrollController();
    _refreshController = RefreshController();
    Future.delayed(Duration(milliseconds: 3000)).then((_) {
//      _jumpTo(0.0);
    });
    _init();

    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: LayoutBuilder(builder: (BuildContext context, b) {
        final double totalHeight = items.length * 100.0;
        final double lIstHeight = b.biggest.height;
        return SmartRefresher(
            child: ListView.builder(
              itemBuilder: (c, i) => items[i],
              itemExtent: 100.0,
              controller: _scrollController,
              reverse: widget.reverse,
              itemCount: items.length,
            ),
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            header: widget.header,
            footer: widget.footer,
            enablePullDown: true,
            enablePullUp: totalHeight > lIstHeight,
            controller: _refreshController);
      }),
    );
  }

  _onRefresh() {
    print("onRefresh");
    Future.delayed(Duration(milliseconds: 1000)).then((_) {
      items.add(Item(title: "Data"));
      if (mounted) setState(() {});
      _refreshController.refreshCompleted();
    });
  }

  _onLoading() {
    print("onLoading");
    Future.delayed(Duration(milliseconds: 1000)).then((_) {
      int index = items.length;
      if (mounted) setState(() {});
      items.add(Item(
        title: "Data$index",
      ));
      ;
      _refreshController.loadComplete();
    });
  }
}
