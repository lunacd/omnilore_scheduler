import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';

import 'test_util.dart';

void main() {
  test('Status of processing: drop', () async {
    var scheduling = Scheduling();
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needPeople);
    expect(await scheduling.loadPeople('test/resources/people_drop.txt'), 1);
    expect(
        scheduling.overviewData.getStateOfProcessing(), StateOfProcessing.drop);
    expect(
        scheduling.overviewData.getStateOfProcessing(), StateOfProcessing.drop);
  });

  test('Status of processing: split', () async {
    var scheduling = Scheduling();
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course_split.txt'), 21);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needPeople);
    expect(await scheduling.loadPeople('test/resources/people_split.txt'), 270);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.split);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.split);
  });

  test('Status of processing: schedule', () async {
    var scheduling = Scheduling();
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course_split.txt'), 21);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needPeople);
    expect(
        await scheduling.loadPeople('test/resources/people_schedule.txt'), 267);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.schedule);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.schedule);
  });

  test('Get list of people for course rank', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.overviewData.getPeopleForClassRank('SIS', 0)!.length, 4);
    expect(scheduling.overviewData.getPeopleForClassRank('BRX', 0)!.length, 17);
    expect(scheduling.overviewData.getPeopleForClassRank('LES', 5)!.length, 0);
    expect(
        scheduling.overviewData.getPeopleForClassRank('SIS', 0),
        containsAll([
          'Marion Smith',
          'Donald Tlougan',
          'Kathleen Fitzgerald',
          'Jim Parkman'
        ]));
    expect(
        scheduling.overviewData.getPeopleForClassRank('BRX', 0),
        containsAll([
          'Janet Brown',
          'Sally Downie',
          'Sandra Pickar',
          'Lynn Solomita',
          'Ken Pickar',
          'Jim North',
          'Maria Ruiz',
          'Judy Close',
          'Gloria Dumais',
          'Ralph Brown',
          'Ken Meyer',
          'Elizabeth Brown',
          'Judy North',
          'Norman Stockwell',
          'Marilyn Landau',
          'Allan Conrad',
          'Helen Stockwell'
        ]));
    expect(scheduling.overviewData.getPeopleForClassRank('LES', 5), []);
    expect(scheduling.overviewData.getPeopleForClassRank('ABC', 0), null);
    expect(scheduling.overviewData.getPeopleForClassRank('ABC', 5), null);
    expect(
        () => scheduling.overviewData.getPeopleForClassRank('SIS', 6),
        throwsA(allOf([
          isA<InvalidClassRankException>(),
          hasMessage('6 is not a valid class rank')
        ])));
  });

  test('Get number of choices for course rank', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 0), 4);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 1), 4);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 2), 3);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 3), 1);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 4), 1);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 5), 3);

    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.overviewData.getNbrForClassRank('BRX', 0), 17);
    expect(scheduling.overviewData.getNbrForClassRank('LES', 5), 0);
    expect(scheduling.overviewData.getNbrForClassRank('ABC', 0), null);
    expect(scheduling.overviewData.getNbrForClassRank('ABC', 5), null);
    expect(
        () => scheduling.overviewData.getNbrForClassRank('SIS', 6),
        throwsA(allOf([
          isA<InvalidClassRankException>(),
          hasMessage('6 is not a valid class rank')
        ])));
  });

  test('Resulting class size', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.overviewData.getResultingClassSize('BIG'), 6);
    expect(scheduling.overviewData.getResultingClassSize('HCD'), 6);
    expect(scheduling.overviewData.getResultingClassSize('GOO'), 18);
    expect(scheduling.overviewData.getResultingClassSize('ABC'), null);

    scheduling.courseControl.drop('LES');
    scheduling.courseControl.drop('FOO');
    scheduling.courseControl.drop('GOO');
    expect(scheduling.overviewData.getResultingClassSize('BIG'), 7);
    expect(scheduling.overviewData.getResultingClassSize('HCD'), 10);
    expect(scheduling.overviewData.getResultingClassSize('GOO'), 18);
    expect(scheduling.overviewData.getResultingClassSize('ABC'), null);

    scheduling.courseControl.undrop('FOO');
    scheduling.courseControl.undrop('GOO');
    expect(scheduling.overviewData.getResultingClassSize('BIG'), 7);
    expect(scheduling.overviewData.getResultingClassSize('HCD'), 6);
    expect(scheduling.overviewData.getResultingClassSize('GOO'), 21);
    expect(scheduling.overviewData.getResultingClassSize('ABC'), null);

    scheduling.courseControl.undrop('LES');
    expect(scheduling.overviewData.getResultingClassSize('BIG'), 6);
    expect(scheduling.overviewData.getResultingClassSize('HCD'), 6);
    expect(scheduling.overviewData.getResultingClassSize('GOO'), 18);
    expect(scheduling.overviewData.getResultingClassSize('ABC'), null);
  });
}
