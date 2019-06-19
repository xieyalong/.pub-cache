import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Example3 extends StatefulWidget {
  Example3({Key key}) : super(key: key);

  @override
  Example3State createState() => Example3State();
}

class Example3State extends State<Example3>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
//  RefreshMode  refreshing = RefreshMode.idle;
//  LoadMode loading = LoadMode.idle;
  ValueNotifier<double> topOffsetLis = ValueNotifier(0.0);
  ValueNotifier<double> bottomOffsetLis = ValueNotifier(0.0);
  RefreshController _refreshController;
  ScrollController _scrollController;

  List<Widget> data = [];

  //test #68
  bool _enablePullUp = true, _enablePullDown = true;

  void _getDatas() {
    data.add(Row(
      children: <Widget>[
        FlatButton(
            onPressed: () {
              _refreshController.requestRefresh();
            },
            child: Text("请求刷新")),
        FlatButton(
            onPressed: () {
              _refreshController.requestLoading();
            },
            child: Text("请求加载数据"))
      ],
    ));
    for (int i = 0; i < 13; i++) {
      data.add(GestureDetector(
        child: Container(
          color: Color.fromARGB(255, 250, 250, 250),
          child: Card(
            margin:
                EdgeInsets.only(left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
            child: Center(
              child: Text('Data $i'),
            ),
          ),
        ),
        onTap: () {
          _refreshController.requestRefresh();
        },
      ));
    }
  }

  void enterRefresh() {
    _refreshController.requestLoading();
  }

  void _onOffsetCallback(bool isUp, double offset) {
    // if you want change some widgets state ,you should rewrite the callback
    if (mounted) setState(() {});
    if (isUp) {
      print(offset);
      bottomOffsetLis.value = offset;
    } else {
      print(offset);
      topOffsetLis.value = offset;
    }
  }

  @override
  void initState() {
    // TODO: implement initState

    // for test #68 true-> false ->true
    Future.delayed(Duration(milliseconds: 3000), () {
      _enablePullDown = false;
      _enablePullUp = false;
      if (mounted) setState(() {});
    });
    Future.delayed(Duration(milliseconds: 6000), () {
      _enablePullDown = true;
      _enablePullUp = true;
      if (mounted) setState(() {});
    });

//    // for test #68 false-> true ->false
//    Future.delayed(Duration(milliseconds: 3000),(){
//      _enablePullDown = false;
//      _enablePullUp = true;
//    if(mounted)
//      setState(() {
//
//      });
//    });
//    Future.delayed(Duration(milliseconds: 6000),(){
//      _enablePullDown = true;
//      _enablePullUp = false;
//    if(mounted)
//      setState(() {
//
//      });
//    });
//    Future.delayed(Duration(milliseconds: 3000),(){
//      _enablePullDown = true;
//      _enablePullUp = false;
//    if(mounted)
//      setState(() {
//
//      });
//    });
//    Future.delayed(Duration(milliseconds: 6000),(){
//      _enablePullDown = false;
//      _enablePullUp = true;
//    if(mounted)
//      setState(() {
//
//      });
//    });
    _getDatas();
    _refreshController = RefreshController(initialRefresh: true);
    super.initState();
  }

  Widget _headerCreate(BuildContext context, RefreshStatus mode) {
    return Image.asset(
      "images/animate.gif",
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      enablePullUp: true,
      enablePullDown: true,
      controller: _refreshController,
      header: MaterialClassicHeader(
      ),
      onRefresh: () {
        print("onRefresh");
        data.add(Container(
          child: Card(),
          height: 100.0,
        ));
        if (mounted) setState(() {});
        _refreshController.refreshFailed();
//        Future.delayed(const Duration(milliseconds: 2009)).then((val) {
////          data.add(Card());
//
//        });
      },
      child: Container(
        height: 395.0,
        child: PageView(
          children: <Widget>[Text("第一页"), Text("第二页"), Text("第三页")],
        ),
      ),
      onLoading: () {
        print("onload");

        Future.delayed(const Duration(milliseconds: 2000)).then((val) {
          data.add(Card());
          if (mounted) setState(() {});
          _refreshController.loadComplete();
        });
      },
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => false;
}

class CirclePainter extends CustomClipper<Path> {
  final double offset;
  final bool up;

  CirclePainter({this.offset, this.up});

  @override
  Path getClip(Size size) {
    // TODO: implement getClip
    final path = Path();
    if (!up) path.moveTo(0.0, size.height);
    path.cubicTo(
        0.0,
        up ? 0.0 : size.height,
        size.width / 2,
        up ? offset * 2.3 : size.height - offset * 2.3,
        size.width,
        up ? 0.0 : size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    // TODO: implement shouldReclip
    return oldClipper != this;
  }
}
