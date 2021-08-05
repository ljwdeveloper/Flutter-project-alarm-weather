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
      home: MyHomePage(title: 'Alarm and Weather'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _selectedIndex = 0;
  var _widgetOptions = <GoodNavigationBarItem>[
    GoodNavigationBarItem(
        bodyWidget: ListView.builder(itemBuilder: alarmListBuilder),
        icon: Icon(Icons.alarm),
        label: 'Alarm'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _widgetOptions.elementAt(_selectedIndex).bodyWidget,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarm'),
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Weather'),
        ],
        onTap: (currentIndex) {
          setState(() {
            _selectedIndex = currentIndex;
          });
        },
      ),
    );
  }
}

class GoodNavigationBarItem {
  Icon _icon = Icon(Icons.more_horiz);
  String _label = '';
  late ListView bodyWidget;
  var naviItem;
  GoodNavigationBarItem({required bodyWidget, icon, label});

  void makeNavigationBarItem() {
    naviItem = BottomNavigationBarItem(icon: _icon, label: _label);
  }
}

Widget alarmListBuilder(BuildContext context, int position) {
  return ListTile();
}
