import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

/// This file tests course split functionalities.
void main() {
  test('Split: 2015, 2 clusters', () async {
    Scheduling scheduling = Scheduling();
    expect(await scheduling.loadCourses('test/resources/2015-split/course.txt'), 27);
    expect(await scheduling.loadPeople('test/resources/2015-split/people.txt'), 296);
  });
}
