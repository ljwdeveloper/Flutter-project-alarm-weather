import 'dart:isolate';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';

const String countKey = 'count';
const String isolateName = 'isolate';
enum AlarmState { disabled, active, firing, passed }

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
  int alarmid;
  DateTime alarmTime;
  bool alarmOn; // 알람 새로 생성시 기본값은 true(활성)
  AlarmState alarmState; //
  Alarm(
      {required DateTime alarmAt,
      bool alarmActive = true,
      int alarmStackId = 0,
      AlarmState state = AlarmState.active})
      : alarmTime = alarmAt,
        alarmOn = alarmActive,
        alarmState = state,
        alarmid = alarmStackId;
  void setAlarmOn(bool alarmActive) {
    alarmOn = alarmActive;
    // 알람 비활성화 f
    if (alarmOn) {
      if (this.alarmTime.isBefore(DateTime.now())) {
        alarmState = AlarmState.passed;
      } else {
        alarmState = AlarmState.active;
      }
    } else {
      alarmState = AlarmState.disabled;
    }
  }

  static Alarm decodeJson(Map<String, dynamic> oneEntity) {
    debuggerLog('f: decodeJson : $oneEntity');
    var aa = AlarmState.values
        .firstWhere((e) => e.toString() == oneEntity['alarmState']);

    return Alarm(
        alarmAt: DateTime.parse(oneEntity['alarmTime']),
        alarmActive: oneEntity['alarmActive'],
        alarmStackId: oneEntity['alarmid'],
        state: aa);
  }

  Map<String, dynamic> toJsonString() {
    debuggerLog(
        'f: toJsonString : ${this.alarmTime.toIso8601String()}, ${this.alarmOn}');
    return {
      'alarmTime': this.alarmTime.toIso8601String(),
      'alarmActive': this.alarmOn,
      'alarmid': this.alarmid,
      'alarmState': this.alarmState.toString()
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

  factory AppManager() => _instance;
  AppManager._internal() {
    debuggerLog('App Manager is created.');
  }

  Future<void> prepareAlarmList(Function alarmCallbackAfter) async {
    debuggerLog('f: prepareAppManager');
    AndroidAlarmManager.initialize();
    prefs = await SharedPreferences.getInstance();
    IsolateNameServer.registerPortWithName(port.sendPort, isolateName);
    await getSavedAlarmInfo();
    port.listen((message) {
      debuggerLog('port listened : $message');
      int alarmid = message['alarmid'];
      var aa = AlarmState.values
          .firstWhere((e) => e.toString() == message['alarmState']);
      bool alarmActive = message['alarmActive'];
      for (Alarm oneEntity in alarmList) {
        if (oneEntity.alarmid == alarmid) {
          oneEntity.alarmState = aa;
          oneEntity.alarmOn = alarmActive;
        }
      }
      alarmCallbackAfter();
    });
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
//foreground 작동성공.
//background (최소화된) 작동성공.
//sleep (종료이후) 에러상황.
  static Future<void> callback(int value) async {
    final player = AudioPlayer();
    var message = {
      'alarmid': value,
      'alarmState': AlarmState.firing.toString(),
      'alarmActive': true
    };
    debuggerLog('alarm fired! value : $value');
    var duration = await player.setAsset('audios/bts_idol.mp3');
    player.play();
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(message);
    Future.delayed(Duration(seconds: 15)).then((value) {
      player.pause();
      message['alarmState'] = AlarmState.passed.toString();
      message['alarmActive'] = false;
      debuggerLog('player paused as 15sec passed.. message sending : $message');
      uiSendPort?.send(message);
    });
  }

  Future<void> insertAlarmAt(DateTime alarmTime, {int? index}) async {
    var newElement = Alarm(alarmAt: alarmTime);
    newElement.alarmid = newElement.hashCode;
    if (index == null) {
      alarmList.add(newElement);
      alarmRawData.add(json.encode(alarmList.last.toJsonString()));
      reserveAlarmFireOnOff(index: alarmList.length - 1);
    } else {
      alarmList.removeAt(index);
      alarmList.insert(index, newElement);
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
    Alarm target = alarmList.elementAt(index);
    debuggerLog('f: reserveAlarm / alarm id : ${target.alarmid}');
    if (alarmActive != null) {
      target.setAlarmOn(alarmActive);
    }
    if (target.alarmOn) {
      if (target.alarmTime.isBefore(DateTime.now())) {
        target.alarmState = AlarmState.passed;
      } else {
        target.alarmState = AlarmState.active;
        AndroidAlarmManager.oneShotAt(
            target.alarmTime, target.alarmid, callback,
            alarmClock: true,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true);
      }
    } else {
      AndroidAlarmManager.cancel(target.alarmid);
    }
  }

  Future<void> deleteAlarmAt(int idx) async {
    int alarmid = alarmList.elementAt(idx).alarmid;
    debuggerLog(
        'f: deleteAlarmAt index $idx / list length ${alarmList.length} / alarmid $alarmid');
    alarmList.removeAt(idx);
    alarmRawData.removeAt(idx);
    AndroidAlarmManager.cancel(alarmid);
    await prefs.setStringList('alarmData', alarmRawData);
  }
}
