import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

/// This file tests functionalities regarding loading courses.
void main() {
  test('Export: empty', () {
    var scheduling = Scheduling();
    scheduling.exportState('state.txt');
    var actual = File('state.txt').readAsStringSync();
    var expected =
        File('test/resources/gold/empty_state.txt').readAsStringSync();
    expect(actual, expected);
    File('state.txt').deleteSync();
  });
}
