import 'dart:isolate';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

const String countKey = 'count';
const String isolateName = 'isolate';

void debuggerLog(Object message) {
  var clockFormat = NumberFormat();
  clockFormat.minimumIntegerDigits = 2;
  var microFormat = NumberFormat();
  microFormat.minimumIntegerDigits = 3;
  var nowTime = DateTime.now();
  print(
      '${clockFormat.format(nowTime.hour)}:${clockFormat.format(nowTime.minute)}:${clockFormat.format(nowTime.second)}.${microFormat.format(nowTime.millisecond)}|   $message');
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

class Alarm {
  DateTime alarmTime;
  bool alarmOn; // 알람 새로 생성시 기본값은 true(활성)
  Alarm({required DateTime alarmAt, bool alarmActive = true})
      : alarmTime = alarmAt,
        alarmOn = alarmActive;
  void setAlarmOn(bool alarmActive) {
    alarmOn = alarmActive;
    // 알람 비활성화 f
    if (!alarmOn) {}
  }

  static Alarm decodeJson(Map<String, dynamic> oneEntity) {
    debuggerLog('f: decodeJson : $oneEntity');
    return Alarm(
        alarmAt: DateTime.parse(oneEntity['alarmTime']),
        alarmActive: oneEntity['alarmActive']);
  }

//안쓰임
  static Map<String, dynamic> toJson(Alarm oneEntity) {
    return {
      'alarmTime': oneEntity.alarmTime.toIso8601String(),
      'alarmActive': oneEntity.alarmOn
    };
  }

  Map<String, dynamic> toJsonString() {
    debuggerLog(
        'f: toJsonString : ${this.alarmTime.toIso8601String()}, ${this.alarmOn}');
    return {
      'alarmTime': this.alarmTime.toIso8601String(),
      'alarmActive': this.alarmOn
    };
  }
}

class AppManager {
  static final AppManager _instance = AppManager._internal();
  static SendPort? uiSendPort;
  List<Alarm> alarmList = [];
  List<String> alarmRawData = [];
  late SharedPreferences prefs;
  final ReceivePort port = ReceivePort();
  bool appManagerPrepared = false; // prepareAppManager가 두번 호출되는데, 플래그로 바이패스되도록.

  factory AppManager() => _instance;
  AppManager._internal() {
    debuggerLog('App Manager is created.');
  }

  Future<void> prepareAlarmList() async {
    appManagerPrepared = true;
    debuggerLog('f: prepareAppManager');
    AndroidAlarmManager.initialize();
    prefs = await SharedPreferences.getInstance();
    IsolateNameServer.registerPortWithName(port.sendPort, isolateName);
    await getSavedAlarmInfo();
  }

  Future<void> getSavedAlarmInfo() async {
    alarmRawData = prefs.getStringList('alarmData') ?? [];
    debuggerLog('saved alarm data : $alarmRawData');
    for (String alarmDataString in alarmRawData) {
      Map<String, dynamic> oneEntity = json.decode(alarmDataString);
      alarmList.add(Alarm.decodeJson(oneEntity));
    }
    debuggerLog('f: getSavedAlarmInfo $alarmList');
  }

//static, 즉 클래스 메서드여야 알람 콜백이 작동함.
//음악 넣어야함.
  static Future<void> callback() async {
    debuggerLog('Alarm fired!');

    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  Future<void> insertAlarmAt(DateTime alarmTime, {int? index}) async {
    if (index == null) {
      alarmList.add(Alarm(alarmAt: alarmTime));
      alarmRawData.add(json.encode(alarmList.last.toJsonString()));
      reserveAlarmFireOnOff(index: alarmList.length - 1);
    } else {
      alarmList.removeAt(index);
      alarmList.insert(index, Alarm(alarmAt: alarmTime));
      alarmRawData.removeAt(index);
      alarmRawData.insert(
          index, json.encode(alarmList.elementAt(index).toJsonString()));
      reserveAlarmFireOnOff(index: index);
    }
    debuggerLog('f: insertAlarmAt $alarmTime, ${index ?? alarmList.length}}');
    debuggerLog('f: insertAlarmAt $alarmRawData');
    await prefs.setStringList('alarmData', alarmRawData);
  }

  void reserveAlarmFireOnOff({required int index, bool? alarmActive}) {
    if (alarmActive != null) {
      alarmList.elementAt(index).setAlarmOn(alarmActive);
    }
    if (alarmList.elementAt(index).alarmOn) {
      AndroidAlarmManager.oneShotAt(
          alarmList.elementAt(index).alarmTime, index, callback);
    } else {
      AndroidAlarmManager.cancel(index);
    }
  }

  Future<void> deleteAlarmAt(int idx) async {
    debuggerLog(
        'f: deleteAlarmAt index $idx / list length ${alarmList.length}');
    alarmList.removeAt(idx);
    alarmRawData.removeAt(idx);
    // AndroidAlarmManager.....
    AndroidAlarmManager.cancel(idx);
    await prefs.setStringList('alarmData', alarmRawData);
  }
}
