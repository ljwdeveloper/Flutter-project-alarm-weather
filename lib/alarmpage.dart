import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testproject_alarm_weather/main.dart';
import 'structures.dart';

class AlarmPage extends StatefulWidget {
  AlarmPage();
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  var _counter = 0;
  var alarmList = <AlarmCellStructure>[];

  @override
  void initState() {
    super.initState();
    AndroidAlarmManager.initialize();
    port.listen((message) => _incrementCounter());
  }

  Future<void> _incrementCounter() async {
    print('Increment counter!');
    await prefs.reload();
    setState(() {
      _counter++;
    });
  }

  static SendPort? uiSendPort;
  Future<void> callback() async {
    print('Alarm fired!');
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(countKey);
    await prefs.setInt(countKey, currentCount ?? 0 + 1);

    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: alarmList.length,
          physics: BouncingScrollPhysics(),
          itemBuilder: (_, idx) {
            var alarmDate = alarmList.elementAt(idx).alarmTime;
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
              onTap: () {
                Future<DateTime?> tempAlarmDate = pickAlarmDate(context);
                tempAlarmDate.then((dateValue) {
                  if (dateValue != null) {
                    DateTime tempDT = dateValue;
                    Future<TimeOfDay?> tempAlarmTime = pickAlarmTime(context);
                    tempAlarmTime.then((timeValue) {
                      if (timeValue != null) {
                        tempDT = DateTime(dateValue.year, dateValue.month,
                            dateValue.day, timeValue.hour, timeValue.minute);
                        alarmList.elementAt(idx).alarmTime = tempDT;
                        setState(() {});
                        AndroidAlarmManager.oneShotAt(
                            alarmList.elementAt(idx).alarmTime, idx, callback);
                      }
                    });
                  }
                });
              },
              onLongPress: () {
                var alarmDeleteFuture = deleteAlarmDialog(context);
                alarmDeleteFuture.then((delete) {
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
          setState(() {});
        },
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

Future<DateTime?> pickAlarmDate(BuildContext context) {
  return showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2999),
    builder: (BuildContext _context, Widget? child) {
      return Theme(data: ThemeData.fallback(), child: child!);
    },
  );
}

Future<TimeOfDay?> pickAlarmTime(BuildContext context) {
  return showTimePicker(context: context, initialTime: TimeOfDay.now());
}
