import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

/// This file has basic tests for items on the auxiliary data panel.
void main() {
  test('Get auxiliary data', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.overviewData.getNbrCourseTakers(), 228);
    expect(scheduling.overviewData.getNbrOnLeave(), 39);
    expect(scheduling.overviewData.getNbrPlacesAsked(), 306);
    expect(scheduling.overviewData.getNbrPlacesGiven(), 306);
    expect(scheduling.overviewData.getNbrGoCourses(), 24);
    scheduling.courseControl.drop('HCD');
    expect(scheduling.overviewData.getNbrGoCourses(), 23);
    scheduling.courseControl.undrop('HCD');
    expect(scheduling.overviewData.getNbrGoCourses(), 24);
    expect(scheduling.overviewData.getNbrUnmetWants(), 0);
  });
}
