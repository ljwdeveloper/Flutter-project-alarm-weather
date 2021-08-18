import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:testproject_alarm_weather/main.dart';

const String countKey = 'count';
const String isolateName = 'isolate';
const Duration alarmFiringDurationInSeconds = Duration(seconds: 120);
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
      bool? alarmActive,
      int alarmStackId = 0,
      AlarmState state = AlarmState.active})
      : alarmTime = alarmAt,
        alarmOn = alarmActive ?? true,
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
  List<Alarm> alarmList = [];
  List<String> alarmRawData = [];
  late SharedPreferences prefs;
  final ReceivePort port = ReceivePort();
  static SendPort? uiSendPort;
  static final AudioPlayer audioPlayer = AudioPlayer();

  factory AppManager() => _instance;
  AppManager._internal() {
    debuggerLog(
        'App Manager is created. audio player : ${audioPlayer.toString()} / ${audioPlayer.hashCode}');
  }

  Future<void> prepareAlarmList(Function alarmCallbackAfter) async {
    debuggerLog('f: prepareAppManager');
    AndroidAlarmManager.initialize();
    tz.initializeTimeZones();
    prefs = await SharedPreferences.getInstance();
    IsolateNameServer.registerPortWithName(port.sendPort, isolateName);
    await getSavedAlarmInfo();
    port.listen((message) {
      debuggerLog('port listened : $message');
      int alarmid = message['alarmid'];
      var aa = AlarmState.values
          .firstWhere((e) => e.toString() == message['alarmState']);
      bool alarmActive = message['alarmActive'];
      Alarm? theEntity;
      for (Alarm oneEntity in alarmList) {
        if (oneEntity.alarmid == alarmid) {
          theEntity = oneEntity;
          break;
        }
      }
      if (theEntity == null) {
        debuggerLog('the alarm is not in the list.');
        alarmCallbackAfter();
      } else {
        if (theEntity.alarmState == AlarmState.disabled) {
        } else if (theEntity.alarmTime
            .add(alarmFiringDurationInSeconds)
            .isBefore(DateTime.now())) {
          theEntity.alarmState = AlarmState.passed;
        } else if (theEntity.alarmTime.isBefore(DateTime.now())) {
          theEntity.alarmState = AlarmState.firing;
        }
        theEntity.alarmState = aa;
        theEntity.alarmOn = alarmActive;
        int index = alarmList.indexOf(theEntity);
        alarmRawData.removeAt(index);
        alarmRawData.insert(index, json.encode(theEntity.toJsonString()));
        debuggerLog(
            'alarm searched in the list and json updated.\n$alarmRawData');
        alarmCallbackAfter();
      }
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

  static Future<void> callback(int value) async {
    var message = {
      'alarmid': value,
      'alarmState': AlarmState.firing.toString(),
      'alarmActive': true
    };
    debuggerLog(
        'f: callback / alarm fired! value : $value.. audio playing? ${audioPlayer.playing}');
    debuggerLog(
        'f: callback / audio player : ${audioPlayer.toString()} / ${audioPlayer.hashCode}');
    var duration = await audioPlayer.setAsset('audios/bts_idol.mp3');
    audioPlayer.play();
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(message);
    debuggerLog('audio playing? ${audioPlayer.playing}');
    debuggerLog(
        'audio player : ${audioPlayer.toString()} / ${audioPlayer.hashCode}');
    Future.delayed(alarmFiringDurationInSeconds).then((value) {
      debuggerLog('callback delayed! audio playing? ${audioPlayer.playing}');
      audioPlayer.stop();
      audioPlayer.dispose();
      debuggerLog('callback delayed! audio playing? ${audioPlayer.playing}');
      message['alarmState'] = AlarmState.passed.toString();
      message['alarmActive'] = false;
      debuggerLog(
          'player paused as ${alarmFiringDurationInSeconds.inSeconds}sec passed.. message sending : $message');
      uiSendPort?.send(message);
    });
  }

//스위치 위젯에서 호출시 alarmTime:null / index:non-null / alarmActive:non-null
//알람추가버튼 호출시 alarmTime:non-null / index:null / alarmActive:null
//기존알람재설정시 alarmTime:non-null / index:non-null / alarmActive:null
  Future<void> insertReserveAlarm(
      {DateTime? alarmTime, int? index, bool? alarmActive}) async {
    Alarm newElement;
//Alarm 객체에 시간&스위치&ID 할당
    if (index == null) {
      newElement = Alarm(alarmAt: alarmTime!);
      newElement.alarmid = newElement.hashCode;
    } else {
      newElement = alarmList.elementAt(index);
      if (alarmTime != null) newElement.alarmTime = alarmTime;
      if (alarmActive != null) newElement.alarmOn = alarmActive;
    }
    //Alarm 객체가 ON 일 때 state 처리와 알람매니저 등록
    if (newElement.alarmOn) {
      if (newElement.alarmTime
          .add(alarmFiringDurationInSeconds)
          .isBefore(DateTime.now())) {
        newElement.alarmState = AlarmState.passed;
      } else if (newElement.alarmTime.isBefore(DateTime.now())) {
        newElement.alarmState = AlarmState.firing;
        AndroidAlarmManager.oneShotAt(
            DateTime.now(), newElement.alarmid, callback,
            alarmClock: true,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true);
        await flutterLocalNotificationsPlugin.show(
            newElement.alarmid,
            '알람 :',
            '${DateTime.now().toString()}',
            NotificationDetails(
                //android: androidPlatformChannelSpecifics,
                android: AndroidNotificationDetails(
                    'your channel id', '알람', '${DateTime.now().toString()}',
                    importance: Importance.max,
                    priority: Priority.high,
                    showWhen: false)));
      } else {
        newElement.alarmState = AlarmState.active;
        AndroidAlarmManager.oneShotAt(
            newElement.alarmTime, newElement.alarmid, callback,
            alarmClock: true,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true);
        await flutterLocalNotificationsPlugin.zonedSchedule(
            newElement.alarmid,
            '알람 :',
            '${newElement.alarmTime.toString()}',
            tz.TZDateTime.from(newElement.alarmTime, tz.local),
            NotificationDetails(
                //android: androidPlatformChannelSpecifics,
                android: AndroidNotificationDetails('your channel id', '알람',
                    '${newElement.alarmTime.toString()}',
                    importance: Importance.max,
                    priority: Priority.high,
                    showWhen: false)),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidAllowWhileIdle: true);
      }
    } else {
      debuggerLog(
          'f: insertreserve / ${newElement.alarmid} alarm OFF.. audio playing? ${audioPlayer.playing}');
      debuggerLog(
          'f: insertreserve / audio player : ${audioPlayer.toString()} / ${audioPlayer.hashCode}');
      //Alarm 객체가 OFF 일 때 알람매니저 제거
      newElement.alarmState = AlarmState.disabled;
      AndroidAlarmManager.cancel(newElement.alarmid);
      await audioPlayer.stop();
      await audioPlayer.dispose();
      await flutterLocalNotificationsPlugin.cancel(newElement.alarmid);
    }

//리스트 모델구조 처리, shared-preference 에 저장.
    if (index == null) {
      alarmList.add(newElement);
      alarmRawData.add(json.encode(alarmList.last.toJsonString()));
    } else {
      alarmRawData.removeAt(index);
      alarmRawData.insert(index, json.encode(newElement.toJsonString()));
    }
    debuggerLog('f: insertReserveAlarm $alarmRawData');
    await prefs.setStringList('alarmData', alarmRawData);
  }

  Future<void> deleteAlarmAt(int idx) async {
    int alarmid = alarmList.elementAt(idx).alarmid;
    debuggerLog(
        'f: deleteAlarmAt index $idx / list length ${alarmList.length} / alarmid $alarmid');
    alarmList.removeAt(idx);
    alarmRawData.removeAt(idx);
    AndroidAlarmManager.cancel(alarmid);
    await flutterLocalNotificationsPlugin.cancel(alarmid);
    await prefs.setStringList('alarmData', alarmRawData);
  }
}
