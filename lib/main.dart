import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'alarmpage.dart';
import 'structures.dart';

late AppManager appManager;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appManager = AppManager();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example Project Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RootPage(title: 'Alarm and Weather'),
    );
  }
}

class RootPage extends StatefulWidget {
  RootPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  var _counter = 0;
  var _selectedBottomIndex = 0;
  var _bottomCategoryList = <CategoryStructure>[];
  var _bottomNaviItemList = <BottomNavigationBarItem>[];
  var _naviPageList = <Widget>[];
  var _pageViewController = PageController();

  @override
  void initState() {
    // TODO: implement initState
    _bottomCategoryList.add(CategoryStructure(
        body: AlarmPage(), icon: Icon(Icons.alarm), label: 'Alarm'));
    _bottomCategoryList.add(CategoryStructure(
        body: WeatherPage(), icon: Icon(Icons.wb_sunny), label: 'Weather'));
    for (CategoryStructure item in _bottomCategoryList) {
      _bottomNaviItemList.add(item.bottomBarItem);
      _naviPageList.add(item.bodyWidget);
    }
    super.initState();
  }

  Future<void> _incrementCounter() async {
    debuggerLog('Increment counter!');
    await appManager.prefs.reload();
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: PageView(
        physics: BouncingScrollPhysics(),
        controller: _pageViewController,
        children: _naviPageList,
        onPageChanged: (_currentIndex) {
          setState(() {
            _selectedBottomIndex = _currentIndex;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: _bottomNaviItemList,
        currentIndex: _selectedBottomIndex,
        onTap: (_currentIndex) {
          setState(() {
            _selectedBottomIndex = _currentIndex;
            _pageViewController.animateToPage(_currentIndex,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOutSine);
          });
        },
      ),
    );
  }
}

class WeatherPage extends StatefulWidget {
  WeatherPage();
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            'data',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
          ),
          SizedBox(
            height: 20,
          ),
          Icon(Icons.wb_cloudy, size: 150, color: Colors.blue),
          SizedBox(
            height: 20,
          ),
          Text(
            'data2',
            style: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
          )
        ],
      ),
    );
  }
}
