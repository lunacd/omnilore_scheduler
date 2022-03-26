import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';

import 'test_util.dart';

void main() {
  test('Drop classes: no backup dropped', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    scheduling.courseControl.drop('LES');
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG').length, 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG'),
        containsAll(['Pettina Long', 'Leslie Schettler']));
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC').length, 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC'),
        containsAll(['Sarah Jones', 'Sydell Weiner']));
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO').length, 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO'),
        containsAll(['Ray Destabelle', 'Suzanne Mann', 'Bob Bacinski']));
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD').length, 0);

    scheduling.courseControl.undrop('LES');
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD').length, 0);
  });

  test('Drop classes: drop with backup', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    scheduling.courseControl.drop('LES');
    scheduling.courseControl.drop('FOO');
    scheduling.courseControl.drop('GOO');
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 4);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG').length, 4);
    expect(
        scheduling.overviewData.getPeopleAddFromBackup('BIG'),
        containsAll([
          'Pettina Long',
          'Leslie Schettler',
          'Steve Miller',
          'Rich Gleerup'
        ]));
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 4);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD').length, 4);
    expect(
        scheduling.overviewData.getPeopleAddFromBackup('HCD'),
        containsAll(
            ['Stan Nah', 'Ray Destabelle', 'Helen Nah', 'Suzanne Mann']));
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC').length, 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC'),
        containsAll(['Dick Balsam', 'Sarah Jones', 'Sydell Weiner']));

    scheduling.courseControl.undrop('FOO');
    scheduling.courseControl.undrop('GOO');
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG').length, 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG'),
        containsAll(['Pettina Long', 'Leslie Schettler']));
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC').length, 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC'),
        containsAll(['Sarah Jones', 'Sydell Weiner']));
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO').length, 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO'),
        containsAll(['Ray Destabelle', 'Suzanne Mann', 'Bob Bacinski']));
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES').length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD').length, 0);
  });

  test('Class size control', () async {
    var scheduling = Scheduling();
    expect(scheduling.courseControl.getMaxClassSize('SIS'), 19);
    expect(scheduling.courseControl.getMinClassSize('SIS'), 10);
    expect(scheduling.courseControl.getMaxClassSize('GOO'), 19);
    expect(scheduling.courseControl.getMinClassSize('GOO'), 10);

    scheduling.courseControl.setMinMaxClassSize(0, 2000);
    expect(scheduling.courseControl.getMaxClassSize('SIS'), 2000);
    expect(scheduling.courseControl.getMinClassSize('SIS'), 0);
    expect(scheduling.courseControl.getMaxClassSize('GOO'), 2000);
    expect(scheduling.courseControl.getMinClassSize('GOO'), 0);

    scheduling.courseControl.setMinMaxClassSizeForClass('SIS', 1000, 3000);
    expect(scheduling.courseControl.getMaxClassSize('SIS'), 3000);
    expect(scheduling.courseControl.getMinClassSize('SIS'), 1000);
    expect(scheduling.courseControl.getMaxClassSize('GOO'), 2000);
    expect(scheduling.courseControl.getMinClassSize('GOO'), 0);

    scheduling.courseControl.setMinMaxClassSizeForClass('SIS', null, null);
    expect(scheduling.courseControl.getMaxClassSize('SIS'), 2000);
    expect(scheduling.courseControl.getMinClassSize('SIS'), 0);

    expect(
        () => scheduling.courseControl.setMinMaxClassSize(20, 10),
        throwsA(allOf([
          isA<MinLargerThanMaxException>(),
          hasMessage('Min: 20 is larger than max: 10')
        ])));

    expect(
        () =>
            scheduling.courseControl.setMinMaxClassSizeForClass('ABC', 20, 10),
        throwsA(allOf([
          isA<MinLargerThanMaxException>(),
          hasMessage('Min: 20 is larger than max: 10')
        ])));
  });
}
