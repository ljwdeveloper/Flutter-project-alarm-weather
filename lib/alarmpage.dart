import 'dart:isolate';
import 'dart:ui';
import 'dart:convert';

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
  AppManager appManager = AppManager();

  @override
  void initState() {
    super.initState();
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

  Future<void> getSavedAlarmInfo() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? alarmData = prefs.getStringList('alarmData');
    if (alarmData != null) {
      for (String alarmDataString in alarmData) {
        Map<String, dynamic> oneEntity = json.decode(alarmDataString);
        appManager.alarmList.add(AlarmCellStructure.decodeJson(oneEntity));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
          itemCount: appManager.alarmList.length,
          physics: BouncingScrollPhysics(),
          itemBuilder: (_, idx) {
            var alarmDate = appManager.alarmList.elementAt(idx).alarmTime;
            var formatter = DateFormat('y-MM-dd HH:mm');
            return ListTile(
              leading: Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 5, 10),
                  child: Icon(
                    Icons.alarm,
                    size: 40,
                    color: appManager.alarmList.elementAt(idx).alarmOn
                        ? Colors.blue
                        : Colors.grey,
                  )),
              title: Text(formatter
                  .format(appManager.alarmList.elementAt(idx).alarmTime)),
              subtitle: Text('알람'),
              trailing: Switch(
                value: appManager.alarmList.elementAt(idx).alarmOn,
                onChanged: (newValue) {
                  setState(() {
                    appManager.alarmList.elementAt(idx).setAlarmOn(newValue);
                  });
                },
              ),
              onTap: () {
                setAlarm(context, appManager.alarmList, idx, () {
                  setState(() {});
                });
              },
              onLongPress: () {
                var alarmDeleteFuture = deleteAlarmDialog(context);
                alarmDeleteFuture.then((delete) {
                  if (delete) {
                    appManager.alarmList.removeAt(idx);
                    setState(() {});
                  }
                });
              },
            );
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.alarm_add),
        onPressed: () {
          appManager.alarmList.add(AlarmCellStructure(alarmAt: DateTime.now()));
          setAlarm(
              context, appManager.alarmList, appManager.alarmList.length - 1,
              () {
            setState(() {});
          });
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
                  Navigator.pop(context, true);
                },
                child: Text('지우기', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                  onPressed: () {
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

void setAlarm(BuildContext context, List<AlarmCellStructure> alarmList, int idx,
    void Function() finished) {
  Future<DateTime?> tempAlarmDate = pickAlarmDate(context);
  tempAlarmDate.then((dateValue) {
    if (dateValue != null) {
      DateTime tempDT = dateValue;
      Future<TimeOfDay?> tempAlarmTime = pickAlarmTime(context);
      tempAlarmTime.then((timeValue) {
        if (timeValue != null) {
          tempDT = DateTime(dateValue.year, dateValue.month, dateValue.day,
              timeValue.hour, timeValue.minute);
          alarmList.elementAt(idx).alarmTime = tempDT;
          AndroidAlarmManager.oneShotAt(
              alarmList.elementAt(idx).alarmTime, idx, () {});
          finished();
        }
      });
    }
  });
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
