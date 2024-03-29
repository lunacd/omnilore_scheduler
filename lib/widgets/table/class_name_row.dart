import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';

class ClassNameRow extends TableRow {
  ClassNameRow(
      List<String> courses, void Function(String, RowType) onCellPressed)
      : super(children: [
          const TableCell(child: Text('')),
          for (int i = 0; i < courses.length; i++)
            TextButton(
              child: Text(_formatClassCode(courses[i], 0)),
              onPressed: () => onCellPressed(courses[i], RowType.className),
            )
        ]);

  /// A helper function that format class codes to be shown vertically
  static String _formatClassCode(String code, int index) {
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
