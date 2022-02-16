import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

void main() {
  test('Get auxiliary data', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.auxiliaryData.getNbrPlacesAsked(), 306);
    expect(scheduling.auxiliaryData.getNbrPlacesGiven(), 306);
    await scheduling.loadCourses('test/resources/course.txt');
    expect(scheduling.auxiliaryData.getNbrPlacesGiven(), 306);
    expect(scheduling.auxiliaryData.getNbrPlacesAsked(), 306);
    expect(scheduling.auxiliaryData.getNbrUnmetWants(), 0);
    expect(scheduling.auxiliaryData.getNbrGoCourses(), 24);
  });
}
