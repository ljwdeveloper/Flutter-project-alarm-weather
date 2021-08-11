import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    appManager.prepareAlarmList(() {
      debuggerLog(
          'f: RootPageState.initState() / prepareAppManager / alarmCallbackAfter');
      setState(() {});
    }).then((_) {
      debuggerLog('f: RootPageState.initState() / prepareAppManager / then');
      if (appManager.alarmList.length == 0) {
      } else {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: appManager.alarmList.length < 1
          ? Center(
              child: IconButton(
                  icon: Icon(Icons.alarm_add),
                  iconSize: 80,
                  color: Colors.blueAccent,
                  onPressed: () {
                    setAlarm(context, finished: () {
                      setState(() {});
                    });
                  }),
            )
          : ListView.builder(
              itemCount: appManager.alarmList.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (_, idx) {
                var oneEntity = appManager.alarmList.elementAt(idx);
                var formatter = DateFormat('y-MM-dd HH:mm');
                var subTitleString;
                var iconColor;
                switch (oneEntity.alarmState) {
                  case AlarmState.disabled:
                    subTitleString = '비활성';
                    iconColor = Colors.blueGrey[600];
                    break;
                  case AlarmState.active:
                    subTitleString = '예약된 알람';
                    iconColor = Colors.blue;
                    break;
                  case AlarmState.firing:
                    subTitleString = '진행중';
                    iconColor = Colors.red;
                    break;
                  case AlarmState.passed:
                    subTitleString = '지난 알람';
                    iconColor = Colors.blueGrey[100];
                    break;
                }
                return ListTile(
                  leading: Padding(
                      padding: EdgeInsets.fromLTRB(10, 10, 5, 10),
                      child: Icon(
                        Icons.alarm,
                        size: 40,
                        color: iconColor,
                      )),
                  title: Text(formatter.format(oneEntity.alarmTime)),
                  subtitle: Text(subTitleString),
                  trailing: Switch(
                    value: appManager.alarmList.elementAt(idx).alarmOn,
                    onChanged: (newValue) {
                      setState(() {
                        //appManager.alarmList.elementAt(idx).setAlarmOn(newValue);
                        appManager.reserveAlarmFireOnOff(
                            index: idx, alarmActive: newValue);
                      });
                    },
                  ),
                  onTap: () {
                    setAlarm(context, index: idx, finished: () {
                      setState(() {});
                    });
                  },
                  onLongPress: () {
                    var alarmDeleteFuture = deleteAlarmDialogAt(idx, context);
                    alarmDeleteFuture.then((needUIUpdate) {
                      if (needUIUpdate) {
                        setState(() {});
                      }
                    });
                  },
                );
              }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.alarm_add),
        onPressed: () {
          setAlarm(context, finished: () {
            setState(() {});
          });
        },
      ),
    );
  }
}

Future deleteAlarmDialogAt(int idx, BuildContext context) {
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
                  //알람 지우는 f
                  appManager.deleteAlarmAt(idx);
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

void setAlarm(BuildContext context,
    {int? index, required void Function() finished}) {
  Future<DateTime?> tempAlarmDate = pickAlarmDate(context);
  tempAlarmDate.then((dateValue) {
    if (dateValue != null) {
      DateTime tempDT = dateValue;
      Future<TimeOfDay?> tempAlarmTime = pickAlarmTime(context);
      tempAlarmTime.then((timeValue) {
        if (timeValue != null) {
          tempDT = DateTime(dateValue.year, dateValue.month, dateValue.day,
              timeValue.hour, timeValue.minute);
          appManager.insertAlarmAt(tempDT, index: index);
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
