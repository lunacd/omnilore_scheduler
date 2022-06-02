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
}
