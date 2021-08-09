import 'package:flutter/material.dart';

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
  AlarmCellStructure({required DateTime alarmAt, bool alarmActive = true})
      : alarmTime = alarmAt,
        alarmOn = alarmActive;
  void setAlarmOn(bool alarmActive) {
    alarmOn = alarmActive;
  }
/*
  factory AlarmCellStructure.fromJson(Map<String, dynamic> jsonData) {
    return AlarmCellStructure(
        alarmAt: jsonData['alarmTime'], alarmActive: jsonData['alarmActive']);
  }
  static Map<String, dynamic> toMap(AlarmCellStructure oneEntity) =>
      {'alarmTime': oneEntity.alarmTime, 'alarmActive': oneEntity.alarmOn};
  static String encode(List<AlarmCellStructure> oneEntity) =>
      json.encode(oneEntity.map((e) => AlarmCellStructure.toMap(e)).toList());
  static List<AlarmCellStructure> decode(String alarmList) =>
      (json.decode(alarmList) as List<dynamic>)
          .map((e) => AlarmCellStructure.fromJson(e))
          .toList();*/

  static AlarmCellStructure decodeJson(Map<String, dynamic> oneEntity) {
    return AlarmCellStructure(
        alarmAt: oneEntity['alarmTime'], alarmActive: oneEntity['alarmActive']);
  }

  static Map<String, dynamic> toJson(AlarmCellStructure oneEntity) {
    return {'alarmTime': oneEntity.alarmTime, 'alarmActive': oneEntity.alarmOn};
  }
}

class AppManager {
  static final AppManager _instance = AppManager._internal();
  late List<AlarmCellStructure> alarmList;

  factory AppManager() => _instance;
  AppManager._internal() {
    alarmList = [];
    print('App Manager is created.');
  }
}
