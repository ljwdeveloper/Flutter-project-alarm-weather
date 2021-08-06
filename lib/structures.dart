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
}
