import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/class_size.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';

import 'test_util.dart';

/// This file tests the overview data table.
void main() {

  test('Get list of people for course rank', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.overviewData.getPeopleForClassRank('SIS', 0).length, 4);
    expect(scheduling.overviewData.getPeopleForClassRank('BRX', 0).length, 19);
    expect(scheduling.overviewData.getPeopleForClassRank('LES', 5).length, 0);
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
          'Ken Meyer',
          'Helen Stockwell',
          'Elaine Endres',
          'Ralph Brown',
          'Janet Brown',
          'Sally Downie',
          'Sandra Pickar',
          'Helen Leven',
          'Lynn Solomita',
          'Norman Stockwell',
          'Gloria Dumais',
          'Elizabeth Brown',
          'Judy Close',
          'Marilyn Landau',
          'Ken Pickar',
          'Jim North',
          'Allan Conrad',
          'Judy North',
          'Maria Ruiz'
        ]));
    expect(scheduling.overviewData.getPeopleForClassRank('LES', 5), []);
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
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 0).size, 4);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 1).size, 6);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 2).size, 2);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 3).size, 0);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 4).size, 2);
    expect(scheduling.overviewData.getNbrForClassRank('SIS', 5).size, 2);
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
    expect(scheduling.overviewData.getResultingClassSize('BIG').size, 9);
    expect(scheduling.overviewData.getResultingClassSize('HCD').size, 10);
    expect(scheduling.overviewData.getResultingClassSize('GOO').size, 20);

    scheduling.courseControl.drop('LES');
    scheduling.courseControl.drop('FOO');
    scheduling.courseControl.drop('GOO');
    expect(scheduling.overviewData.getResultingClassSize('BIG').size, 13);
    expect(scheduling.overviewData.getResultingClassSize('HCD').size, 14);
    expect(scheduling.overviewData.getResultingClassSize('GOO').size, 0);

    scheduling.courseControl.undrop('FOO');
    scheduling.courseControl.undrop('GOO');
    expect(scheduling.overviewData.getResultingClassSize('BIG').size, 11);
    expect(scheduling.overviewData.getResultingClassSize('HCD').size, 10);
    expect(scheduling.overviewData.getResultingClassSize('GOO').state,
        ClassState.oversized);
    scheduling.courseControl.setMinMaxClassSizeForClass('GOO', 10, 25);
    expect(scheduling.overviewData.getResultingClassSize('GOO').state,
        ClassState.normal);
    expect(scheduling.overviewData.getResultingClassSize('GOO').size, 23);


    scheduling.courseControl.undrop('LES');
    expect(scheduling.overviewData.getResultingClassSize('BIG').size, 9);
    expect(scheduling.overviewData.getResultingClassSize('HCD').state,
        ClassState.normal);
    expect(scheduling.overviewData.getResultingClassSize('HCD').size, 10);
    scheduling.courseControl.setMinMaxClassSizeForClass('HCD', 4, 19);
    expect(scheduling.overviewData.getResultingClassSize('HCD').state,
        ClassState.normal);
    expect(scheduling.overviewData.getResultingClassSize('HCD').size, 10);
    expect(scheduling.overviewData.getResultingClassSize('GOO').state,
        ClassState.normal);
    expect(scheduling.overviewData.getResultingClassSize('GOO').size, 20);
    scheduling.courseControl.setMinMaxClassSizeForClass('GOO', 10, 15);
    expect(scheduling.overviewData.getResultingClassSize('GOO').state,
        ClassState.oversized);
    expect(scheduling.overviewData.getResultingClassSize('GOO').size, 20);
  });
}
