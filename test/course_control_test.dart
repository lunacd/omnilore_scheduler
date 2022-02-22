import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

void main() {
  test('Drop classes', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    scheduling.courseControl.drop('LES');
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 1);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG')!.length, 1);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG'),
        containsAll(['Bob Bacinski']));
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC')!.length, 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC'),
        containsAll(['Barbara Case', 'Sarah Jones']));
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO')!.length, 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO'),
        containsAll(['Ray Destabelle', 'Pettina Long', 'Suzanne Mann']));
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD')!.length, 0);
    
    scheduling.courseControl.undrop('LES');
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD')!.length, 0);
  });

  test('Drop classes: drop with backup', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    scheduling.courseControl.drop('LES');
    scheduling.courseControl.drop('FOO');
    scheduling.courseControl.drop('GOO');
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 1);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG')!.length, 1);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG'),
        containsAll(['Bob Bacinski']));
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 4);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD')!.length, 4);
    expect(
        scheduling.overviewData.getPeopleAddFromBackup('HCD'),
        containsAll(
            ['Stan Nah', 'Ray Destabelle', 'Helen Nah', 'Suzanne Mann']));
    expect(scheduling.overviewData.getNbrAddFromBackup('ABC'), null);
    expect(scheduling.overviewData.getPeopleAddFromBackup('ABC'), null);
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 4);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC')!.length, 4);
    expect(
        scheduling.overviewData.getPeopleAddFromBackup('FAC'),
        containsAll(
            ['Barbara Case', 'Sarah Jones', 'Rich Gleerup', 'Dick Balsam']));

    scheduling.courseControl.undrop('SOMETHING');
    scheduling.courseControl.undrop('FOO');
    scheduling.courseControl.undrop('GOO');
    expect(scheduling.overviewData.getNbrAddFromBackup('BIG'), 1);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG')!.length, 1);
    expect(scheduling.overviewData.getPeopleAddFromBackup('BIG'),
        containsAll(['Bob Bacinski']));
    expect(scheduling.overviewData.getNbrAddFromBackup('FAC'), 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC')!.length, 2);
    expect(scheduling.overviewData.getPeopleAddFromBackup('FAC'),
        containsAll(['Barbara Case', 'Sarah Jones']));
    expect(scheduling.overviewData.getNbrAddFromBackup('GOO'), 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO')!.length, 3);
    expect(scheduling.overviewData.getPeopleAddFromBackup('GOO'),
        containsAll(['Ray Destabelle', 'Pettina Long', 'Suzanne Mann']));
    expect(scheduling.overviewData.getNbrAddFromBackup('LES'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('LES')!.length, 0);
    expect(scheduling.overviewData.getNbrAddFromBackup('HCD'), 0);
    expect(scheduling.overviewData.getPeopleAddFromBackup('HCD')!.length, 0);
  });
}
