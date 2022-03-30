import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

/// This file tests course split functionalities.
void main() {
  test('Split: 2015, 2 clusters', () async {
    Scheduling scheduling = Scheduling();
    expect(await scheduling.loadCourses('test/resources/2015-split/course.txt'),
        27);
    expect(await scheduling.loadPeople('test/resources/2015-split/people.txt'),
        296);
    scheduling.courseControl.drop('AIN');
    scheduling.courseControl.drop('AUG');
    scheduling.courseControl.drop('DOG');
    scheduling.courseControl.drop('FAK');
    scheduling.courseControl.drop('F2K');
    scheduling.courseControl.drop('GOV');
    scheduling.courseControl.drop('RAP');
    scheduling.courseControl.drop('UKR');
    expect(scheduling.overviewData.getNbrGoCourses(), 19);
    expect(scheduling.overviewData.getResultingClassSize('CRM').size, 16);
    expect(scheduling.overviewData.getResultingClassSize('DIP').size, 11);
    expect(scheduling.overviewData.getResultingClassSize('GFT').size, 13);
    expect(scheduling.overviewData.getResultingClassSize('GHG').size, 14);
    expect(scheduling.overviewData.getResultingClassSize('TED').size, 35);
    var result = scheduling.splitControl.split('TED');
  });
}
