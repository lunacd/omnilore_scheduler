import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';

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

class ScheduleRow extends TableRow {
  ScheduleRow(
      int timeIndex,
      List<String> courses,
      List<int> data,
      List<int> scheduleData,
      StateOfProcessing state,
      List<bool> droppedList,
      void Function(String, int) onSchedule)
      : super(children: [
          TableCell(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[Text(scheduleRows[timeIndex])])),
          for (int i = 0; i < data.length; i++)
            TextButton(
              onPressed: droppedList[i] == false &&
                      (state == StateOfProcessing.schedule ||
                          state == StateOfProcessing.coordinator ||
                          state == StateOfProcessing.output)
                  ? () {
                      onSchedule(courses[i], timeIndex);
                    }
                  : null,
              style: (() {
                if (scheduleData[i] == timeIndex) {
                  return ElevatedButton.styleFrom(backgroundColor: Colors.red);
                } else {
                  return ElevatedButton.styleFrom(backgroundColor: Colors.transparent);
                }
              }()),
              child: Text(data[i].toString()),
            )
        ]);
}
