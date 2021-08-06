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

class AlarmCellStructure {
  DateTime alarmTime;
  bool alarmOn;
  AlarmCellStructure({required DateTime alarmAt, bool alarmActive = false})
      : alarmTime = alarmAt,
        alarmOn = alarmActive;
  void setAlarmOn(bool alarmActive) {
    alarmOn = alarmActive;
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
        body: WeatherPage(), icon: Icon(Icons.wb_sunny), label: 'Weather'));
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
  var counter = 0;
  var alarmList = <AlarmCellStructure>[];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: alarmList.length,
          physics: BouncingScrollPhysics(),
          itemBuilder: (_, idx) {
            var _counter;
            var formatter = DateFormat('y-MM-dd HH:mm');
            return ListTile(
              leading: Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 5, 10),
                  child: Icon(
                    Icons.alarm,
                    size: 40,
                    color: alarmList.elementAt(idx).alarmOn
                        ? Colors.blue
                        : Colors.grey,
                  )),
              title: Text(formatter.format(alarmList.elementAt(idx).alarmTime)),
              subtitle: Text('알람'),
              trailing: Switch(
                value: alarmList.elementAt(idx).alarmOn,
                onChanged: (newValue) {
                  setState(() {
                    alarmList.elementAt(idx).setAlarmOn(newValue);
                  });
                },
              ),
              onLongPress: () {
                var alarmDeleteFuture = deleteAlarmDialog(context);
                alarmDeleteFuture.then((delete) {
                  print('alarm deleting.. delete? $delete');
                  if (delete) {
                    alarmList.removeAt(idx);
                    setState(() {});
                  }
                });
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.alarm_add),
        onPressed: () {
          alarmList.add(AlarmCellStructure(alarmAt: DateTime.now()));
          counter++;
          setState(() {});
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

Future deleteAlarmDialog(BuildContext context) {
  StateSetter _setState;
  Future deleteAlarm = showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          _setState = setState;
          return AlertDialog(
            title: Text('알람을 지우시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  //deleteAlarm = Future.value(true);
                  Navigator.pop(context, true);
                },
                child: Text('지우기', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                  onPressed: () {
                    //deleteAlarm = Future.value(false);
                    Navigator.pop(context);
                  },
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.grey),
                  ))
            ],
          );
        });
      });
  return deleteAlarm;
}
