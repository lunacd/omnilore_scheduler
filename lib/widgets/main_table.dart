import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:tuple/tuple.dart';

/// This Widget takes the resulting data from tableData and timeTableData and
/// produces the table widget displayed to the user by running buildInfo() and
/// buildTimeInfo()
class MainTable extends StatelessWidget {
  const MainTable(
      {Key? key,
      required this.state,
      required this.tableData,
      required this.timeTableData,
      required this.droppedList,
      required this.scheduleData,
      required this.onCellPressed,
      required this.onDroppedChanged,
      required this.onSchedule})
      : super(key: key);

  final StateOfProcessing state;
  final Tuple2<List<String>, List<List<String>>> tableData;
  final Tuple2<List<String>, List<List<String>>> timeTableData;
  final List<bool> droppedList;
  final void Function(String, String) onCellPressed;
  final void Function(int) onDroppedChanged;
  final void Function(String, String) onSchedule;
  final Map<String, int> scheduleData;

  @override
  Widget build(BuildContext context) {
    var infoTable = tableData;
    var timeTable = timeTableData;
    return Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.black),
          outside: const BorderSide(width: 1)),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: buildInfo(infoTable.item1, infoTable.item2) +
          buildTimeInfo(timeTable.item1, timeTable.item2),
    );
  }

  /// Generates the portion of the data table that contains class data returns
  /// a list of TableRow objects
  List<TableRow> buildInfo(
      // builds the list of table rows. I had to do it in a function because for
      // some reason state doesn't update if its done the other way
      List<String> growableList,
      List<List<String>> dataList) {
    List<TableRow> result = [];
    for (int i = 0; i < growableList.length; i++) {
      result.add(TableRow(children: [
        TableCell(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[Text(growableList[i].toString())])),
        for (int j = 0; j < dataList[i].length; j++)
          TextButton(
            child: Text(_formatClassCode(dataList[i][j], i)),
            //check if the course is dropped
            onPressed: () => onCellPressed(growableList[i], dataList[0][j]),
          )
      ]));
    }
    result.add(TableRow(children: [
      TableCell(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const <Widget>[Text('class dropped')])),
      for (int i = 0; i < droppedList.length; i++) droppedCheck(i)
    ]));

    result.add(TableRow(children: [
      TableCell(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[Text(growableList[0].toString())])),
      for (int j = 0; j < dataList[0].length; j++)
        Text(
          _formatClassCode(dataList[0][j], 0),
          textAlign: TextAlign.center,
        )
    ]));

    return result;
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
        onChanged: (_) {onDroppedChanged(i);});
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
    for (int i = 1; i < growableList.length; i++) {
      result.add(TableRow(children: [
        TableCell(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[Text(growableList[i].toString())])),
        for (int j = 0; j < dataList[i].length; j++)
          TextButton(
            child: Text(dataList[i][j].toString()),
            onPressed: droppedList[j] == false &&
                    (state == StateOfProcessing.schedule ||
                        state == StateOfProcessing.coordinator ||
                        state == StateOfProcessing.output)
                ? () {
                    onSchedule(dataList[0][j], growableList[i]);
                  }
                : null,
            style: (() {
              if (scheduleData[dataList[0][j]] ==
                  getTimeIndex(growableList[i])) {
                return ElevatedButton.styleFrom(primary: Colors.red);
              } else {
                return ElevatedButton.styleFrom(primary: Colors.transparent);
              }
            }()),
          )
      ]));
    }
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
