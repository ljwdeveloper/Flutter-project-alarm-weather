import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'alarmpage.dart';
import 'structures.dart';
import 'package:rxdart/subjects.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
late AppManager appManager;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  /// Note: permissions aren't requested here just to demonstrate that can be
  /// done later
  final IOSInitializationSettings initializationSettingsIOS =
      IOSInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false);
  const MacOSInitializationSettings initializationSettingsMacOS =
      MacOSInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    macOS: initializationSettingsMacOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
  });

  appManager = AppManager();

  runApp(MyApp());
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addObserver(this);
    return MaterialApp(
      title: 'Example Project Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RootPage(title: 'Alarm and Weather'),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        debuggerLog('APP LIFE CYCLE resumed.');
        break;
      case AppLifecycleState.inactive:
        debuggerLog('APP LIFE CYCLE inactive.');
        break;
      case AppLifecycleState.detached:
        debuggerLog('APP LIFE CYCLE detached.');
        break;
      case AppLifecycleState.paused:
        debuggerLog('APP LIFE CYCLE paused.');
        break;
    }
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
