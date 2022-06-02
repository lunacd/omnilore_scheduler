import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/widgets/table/class_name_row.dart';
import 'package:omnilore_scheduler/widgets/table/drop_row.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';
import 'package:omnilore_scheduler/widgets/table/schedule_row.dart';

/// This Widget takes the resulting data from tableData and timeTableData and
/// produces the table widget displayed to the user by running buildInfo() and
/// buildTimeInfo()
class MainTable extends StatelessWidget {
  const MainTable(
      {Key? key,
      required this.state,
      required this.courses,
      required this.overviewMatrix,
      required this.scheduleMatrix,
      required this.droppedList,
      required this.scheduleData,
      required this.onCellPressed,
      required this.onDroppedChanged,
      required this.onSchedule})
      : super(key: key);

  final StateOfProcessing state;
  final List<String> courses;
  final List<List<int>> overviewMatrix;
  final List<List<int>> scheduleMatrix;
  final List<bool> droppedList;
  final void Function(String, int) onCellPressed;
  final void Function(int) onDroppedChanged;
  final void Function(String, int) onSchedule;
  final List<int> scheduleData;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.black),
          outside: const BorderSide(width: 1)),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: [
        ClassNameRow(courses, onCellPressed),
        for (int i = 0; i < overviewRows.length; i++)
          OverviewRow(i, courses, overviewMatrix[i], onCellPressed),
        DropRow(droppedList, onDroppedChanged),
        ClassNameRow(courses, onCellPressed),
        for (int i = 0; i < scheduleRows.length; i++)
          ScheduleRow(i, courses, scheduleMatrix[i], scheduleData, state,
              droppedList, onSchedule)
      ],
    );
  }

  /// translation function that will take a time slot and return the correct
  /// index used by input files. Returns -1 on an unknown timeslot name
  int getTimeIndex(String c) {
    int timeIndex = -1;
    if (c == '1st/3rd Mon AM') {
      timeIndex = 0;
    } else if (c == '1st/3rd Mon PM') {
      timeIndex = 1;
    } else if (c == '1st/3rd Tue AM') {
      timeIndex = 2;
    } else if (c == '1st/3rd Tue PM') {
      timeIndex = 3;
    } else if (c == '1st/3rd Wed AM') {
      timeIndex = 4;
    } else if (c == '1st/3rd Wed PM') {
      timeIndex = 5;
    } else if (c == '1st/3rd Thu AM') {
      timeIndex = 6;
    } else if (c == '1st/3rd Thu PM') {
      timeIndex = 7;
    } else if (c == '1st/3rd Fri AM') {
      timeIndex = 8;
    } else if (c == '1st/3rd Fri PM') {
      timeIndex = 9;
    } else if (c == '2nd/4th Mon AM') {
      timeIndex = 10;
    } else if (c == '2nd/4th Mon PM') {
      timeIndex = 11;
    } else if (c == '2nd/4th Tue AM') {
      timeIndex = 12;
    } else if (c == '2nd/4th Tue PM') {
      timeIndex = 13;
    } else if (c == '2nd/4th Wed AM') {
      timeIndex = 14;
    } else if (c == '2nd/4th Wed PM') {
      timeIndex = 15;
    } else if (c == '2nd/4th Thu AM') {
      timeIndex = 16;
    } else if (c == '2nd/4th Thu PM') {
      timeIndex = 17;
    } else if (c == '2nd/4th Fri AM') {
      timeIndex = 18;
    } else if (c == '2nd/4th Fri PM') {
      timeIndex = 19;
    }
    return timeIndex;
  }

  /// creates the scheduling portion of the main data table returns a list of
  /// TableRow objects
  List<TableRow> buildTimeInfo(
      // builds the list of table rows. I had to do it in a function because for
      // some reason state doesn't update if its done the other way
      List<String> growableList,
      List<List<String>> dataList) {
    List<TableRow> result = [];

    return result;
  }
}
