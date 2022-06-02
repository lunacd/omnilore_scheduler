import 'package:flutter/material.dart';

class DropRow extends TableRow {
  DropRow(List<bool> droppedList, void Function(int) onDroppedChanged)
      : super(children: [
          TableCell(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[Text('class dropped')])),
          for (int i = 0; i < droppedList.length; i++)
            Checkbox(
                checkColor: Colors.white,
                fillColor: null,
                value: droppedList[i],
                onChanged: (_) {
                  onDroppedChanged(i);
                })
        ]);
}
