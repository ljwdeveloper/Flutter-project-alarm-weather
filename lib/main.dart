import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example Project Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RootPage(title: 'Alarm and Weather'),
    );
  }
}

class CategoryStructure {
  Icon iconWidget = Icon(Icons.more_horiz);
  String labelString = '';
  Widget bodyWidget;
  late BottomNavigationBarItem bottomBarItem;

  CategoryStructure({required Widget body, Icon? icon, String? label})
      : bodyWidget = body {
    if (icon != null) iconWidget = icon;
    if (label != null) labelString = label;
    bottomBarItem =
        BottomNavigationBarItem(icon: iconWidget, label: labelString);
  }
}

class RootPage extends StatefulWidget {
  RootPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
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
      body: Scaffold(
        body: Center(
          child: Text('Korea cool'),
        ),
      ),
    ));
    for (CategoryStructure item in _bottomCategoryList) {
      _bottomNaviItemList.add(item.bottomBarItem);
      _naviPageList.add(item.bodyWidget);
    }
    super.initState();
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
          print('selected bottom index : $_selectedBottomIndex');
        },
      ),
    );
  }
}

class AlarmPage extends StatefulWidget {
  AlarmPage();
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  var alarmList = <DateTime>[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('ohoh'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.alarm_add),
        onPressed: () {},
      ),
    );
  }
}
