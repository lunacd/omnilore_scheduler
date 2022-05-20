import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';

const overviewRows = <String>[
  'First Choices',
  'First backup',
  'Second backup',
  'Third backup',
  'Add from BUs',
  'Drop, bad time',
  'Drop, dup class',
  'Drop class full',
  'Resulting Size'
];

const scheduleRows = <String>[
  '1st/3rd Mon AM',
  '1st/3rd Mon PM',
  '1st/3rd Tue AM',
  '1st/3rd Tue PM',
  '1st/3rd Wed AM',
  '1st/3rd Wed PM',
  '1st/3rd Thu AM',
  '1st/3rd Thu PM',
  '1st/3rd Fri AM',
  '1st/3rd Fri PM',
  '2nd/4th Mon AM',
  '2nd/4th Mon PM',
  '2nd/4th Tue AM',
  '2nd/4th Tue PM',
  '2nd/4th Wed AM',
  '2nd/4th Wed PM',
  '2nd/4th Thu AM',
  '2nd/4th Thu PM',
  '2nd/4th Fri AM',
  '2nd/4th Fri PM'
];

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
  final void Function(String, String) onCellPressed;
  final void Function(int) onDroppedChanged;
  final void Function(String, String) onSchedule;
  final Map<String, int> scheduleData;

  @override
  Widget build(BuildContext context) {
    List<TableRow> rows = [];
    rows.add(TableRow(children: [
      const TableCell(child: Text('')),
      for (int i = 0; i < courses.length; i++)
        TextButton(
          child: Text(_formatClassCode(courses[i], 0)),
          onPressed: () => onCellPressed('', courses[i]),
        )
    ]));
    for (int i = 0; i < overviewRows.length; i++) {
      rows.add(TableRow(children: [
        TableCell(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[Text(overviewRows[i].toString())])),
        for (int j = 0; j < overviewMatrix[i].length; j++)
          TextButton(
              onPressed: () => onCellPressed(overviewRows[i], courses[j]),
              child: Text(overviewMatrix[i][j].toString()))
      ]));
    }
    rows.add(TableRow(children: [
      TableCell(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const <Widget>[Text('class dropped')])),
      for (int i = 0; i < droppedList.length; i++) droppedCheck(i)
    ]));

    rows.add(TableRow(children: [
      const TableCell(child: Text('')),
      for (int i = 0; i < courses.length; i++)
        TextButton(
          child: Text(_formatClassCode(courses[i], 0)),
          onPressed: () => onCellPressed('', courses[i]),
        )
    ]));

    for (int i = 0; i < scheduleRows.length; i++) {
      rows.add(TableRow(children: [
        TableCell(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[Text(scheduleRows[i])])),
        for (int j = 0; j < scheduleMatrix[i].length; j++)
          TextButton(
            child: Text(scheduleMatrix[i][j].toString()),
            onPressed: droppedList[j] == false &&
                    (state == StateOfProcessing.schedule ||
                        state == StateOfProcessing.coordinator ||
                        state == StateOfProcessing.output)
                ? () {
                    onSchedule(courses[j], scheduleRows[i]);
                  }
                : null,
            style: (() {
              if (scheduleData[courses[j]] == i) {
                return ElevatedButton.styleFrom(primary: Colors.red);
              } else {
                return ElevatedButton.styleFrom(primary: Colors.transparent);
              }
            }()),
          )
      ]));
    }

    return Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.black),
          outside: const BorderSide(width: 1)),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: rows,
    );
  }

  /// Creates a checkbox widget to be used in the class data portion of the main
  /// check if the course is dropped
  /// data table. The checkbox will be linked to a given colum index i. When
  /// selected the corresponding class at index i will be dropped which will
  /// be reflected in the front end and backend data structures
  Widget droppedCheck(int i) {
    // makes a checkmark widget that corresponds to the passed index of dropped
    // list
    return Checkbox(
        checkColor: Colors.white,
        fillColor: null,
        value: droppedList[i],
        onChanged: (_) {
          onDroppedChanged(i);
        });
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

  /// A helper function that format class codes to be shown vertically
  String _formatClassCode(String code, int index) {
    if (code.isEmpty) {
      return '';
    }
    if (index != 0) {
      return code;
    }
    String testCode = '';
    for (int i = 0; i < code.length - 1; i++) {
      testCode += code[i];
      testCode += '\n';
    }
    testCode += code[code.length - 1];
    return testCode;
  }
}
