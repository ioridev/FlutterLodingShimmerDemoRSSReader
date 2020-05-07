import 'package:flutter/material.dart';

import 'dart:convert' show utf8;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webfeed/webfeed.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RssFeed _feed;
  String rssurl = 'https://www.lifehacker.jp/feed/index.xml';

  static const String placeholderImg = 'images/no_image.png';
  GlobalKey<RefreshIndicatorState> _refreshKey;

  Future<void> openFeed(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: true,
        forceWebView: false,
      );
      return;
    }
  }

  Future<void> load() async {
    await loadFeed().then((result) async {
      if (null == result || result.toString().isEmpty) {
        return;
      }
      setState(() {
        _feed = result;
      });
    });
  }

  Future<RssFeed> loadFeed() async {
    try {
      final client = http.Client();
      final response = await client.get(rssurl);
      final responseBody = utf8.decode(response.bodyBytes);
      return RssFeed.parse(responseBody);
    } on Exception {
      //
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refreshKey = GlobalKey<RefreshIndicatorState>();
    load();
  }

  Widget list() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
      shrinkWrap: true,
      itemCount: _feed.items.length,
      itemBuilder: (BuildContext context, int index) {
        final item = _feed.items[index];
        return GestureDetector(
          onTap: () => openFeed(item.link),
          child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Shimmer.fromColors(
                          baseColor: Colors.grey[100],
                          highlightColor: Colors.grey[400],
                          child: Container(
                            width: 384,
                            height: 180,
                            color: Colors.black,
                          ),
                        ),
                        CachedNetworkImage(
                          placeholder: (context, url) =>
                              Image.asset(placeholderImg),
                          imageUrl: item.enclosure.url,
                          alignment: Alignment.center,
                          fit: BoxFit.fill,
                        ),
                      ],
                    ),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          item.pubDate,
                          style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w100),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  ],
                ),
              )),
        );
      },
    );
  }

  bool isFeedEmpty() {
    return null == _feed || null == _feed.items;
  }

  Widget body() {
    return isFeedEmpty()
        ? ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(children: <Widget>[
                      Shimmer.fromColors(
                        baseColor: Colors.grey[100],
                        highlightColor: Colors.grey[400],
                        child: Container(
                          width: 350,
                          height: 200,
                          color: Colors.black,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[100],
                          highlightColor: Colors.grey[400],
                          child: Container(
                            width: 350,
                            height: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ])),
              );
            })
        : RefreshIndicator(
            key: _refreshKey,
            child: list(),
            onRefresh: () async => load(),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RSSフィールド'),
      ),
      body: body(),
    );
  }
}
