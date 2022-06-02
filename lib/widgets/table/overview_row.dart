import 'package:flutter/material.dart';

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

class OverviewRow extends TableRow {
  OverviewRow(int rowIndex, List<String> courses, List<int> data,
      void Function(String, int) onCellPressed)
      : super(children: [
          TableCell(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[Text(overviewRows[rowIndex])])),
          for (int i = 0; i < data.length; i++)
            TextButton(
                onPressed: () => onCellPressed(courses[i], rowIndex + 1),
                child: Text(data[i].toString()))
        ]);
}
