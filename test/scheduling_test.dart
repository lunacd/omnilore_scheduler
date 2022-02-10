import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';

import 'test_util.dart';

void main() {
  test('Get course info', () async {
    var scheduling = Scheduling();
    expect(await scheduling.loadPeople('test/resources/people.txt'), 271);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 23);
    expect(scheduling.getCourseCodes(), [
      'BAD',
      'THK',
      'BIG',
      'BRX',
      'SCH',
      'CHK',
      'ASA',
      'RAH',
      'OCN',
      'IMP',
      'REF',
      'EVC',
      'HCD',
      'QUR',
      'SAF',
      'GOO',
      'SHK',
      'SIS',
      'LES',
      'RWD',
      'PRF',
      'FAC',
      'ILA'
    ]);
    expect(
        scheduling.getCourse('ILA'),
        const Course(
            code: 'ILA',
            name: 'The Invention of Los Angeles',
            reading:
                'The Mirage Factory: Illusion, Imagination, and the . . . , by Gary Krist'));
    expect(scheduling.getNumCourses(), 23);
  });

  test('Get people', () async {
    var scheduling = Scheduling();
    expect(await scheduling.loadPeople('test/resources/people.txt'), 271);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 23);
    expect(scheduling.getNumPeople(), 271);
    var person1 = scheduling.getPeople()[111];
    expect(person1.lName, 'Johnson');
    expect(person1.fName, 'Carol');
    expect(person1.phone, '372-8535');
    expect(person1.numClassWanted, 1);
    expect(
        person1.availability
            .get(WeekOfMonth.firstThird, DayOfWeek.friday, TimeOfDay.morning),
        false);
    expect(
        person1.availability.get(
            WeekOfMonth.secondFourth, DayOfWeek.tuesday, TimeOfDay.afternoon),
        true);
    expect(person1.classes, ['CHK', 'FAC', 'IMP', 'ILA', 'PRF']);
    expect(person1.submissionOrder, 108);
    var person2 = scheduling.getPeople()[201];
    expect(person2.lName, 'Pleatman');
    expect(person2.fName, 'Stan');
    expect(person2.phone, '709-2404');
    expect(person2.numClassWanted, 0);
    expect(
        person2.availability
            .get(WeekOfMonth.firstThird, DayOfWeek.friday, TimeOfDay.morning),
        true);
    expect(
        person2.availability.get(
            WeekOfMonth.secondFourth, DayOfWeek.tuesday, TimeOfDay.afternoon),
        true);
    expect(person2.classes, []);
    expect(person2.submissionOrder, 259);
  });

  test('Status of processing: drop', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 23);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needPeople);
    expect(await scheduling.loadPeople('test/resources/people_drop.txt'), 1);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.drop);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.drop);
  });

  test('Status of processing: split', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course_split.txt'), 21);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needPeople);
    expect(await scheduling.loadPeople('test/resources/people_split.txt'), 271);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.split);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.split);
  });

  test('Status of processing: schedule', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course_split.txt'), 21);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needPeople);
    expect(
        await scheduling.loadPeople('test/resources/people_schedule.txt'), 268);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.schedule);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.schedule);
  });

  test('Inconsistent people and course', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 23);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needPeople);
    expect(
        scheduling.loadPeople('test/resources/people_inconsistent.txt'),
        throwsA(allOf([
          isA<InconsistentCourseAndPeopleException>(),
          hasMessage('Invalid class choice: SCI by Judi Jones')
        ])));
  });

  test('Inconsistent people and course', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(
        scheduling.loadPeople('test/resources/people_inconsistent.txt'),
        throwsA(allOf([
          isA<InconsistentCourseAndPeopleException>(),
          hasMessage('Invalid class choice: SCI by Judi Jones')
        ])));
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(
        scheduling.loadCourses('test/resources/course.txt'),
        throwsA(allOf([
          isA<InconsistentCourseAndPeopleException>(),
          hasMessage('Invalid class choice: SCI by Judi Jones')
        ])));
  });

  test('Get list of people for course rank', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(
        scheduling.getPeopleForClassRank('SIS', 0),
        containsAll([
          'Marion Smith',
          'Donald Tlougan',
          'Kathleen Fitzgerald',
          'Jim Parkman'
        ]));
    expect(
        scheduling.getPeopleForClassRank('BRX', 0),
        containsAll([
          'Allan Conrad',
          'Jim North',
          'Norman Stockwell',
          'Rick Spillane',
          'Helen Stockwell',
          'Ken Meyer',
          'Gloria Dumais',
          'Judy North',
          'Elizabeth Brown',
          'Marilyn Landau',
          'Judy Close',
          'Janet Brown',
          'Ralph Brown',
          'Maria Ruiz',
          'Sally Downie',
          'Ken Pickar',
          'Sandra Pickar',
          'Lynn Solomita'
        ]));
    expect(scheduling.getPeopleForClassRank('LES', 5), []);
    expect(scheduling.getPeopleForClassRank('ABC', 0), null);
    expect(scheduling.getPeopleForClassRank('ABC', 5), null);
    expect(
        () => scheduling.getPeopleForClassRank('SIS', 6),
        throwsA(allOf([
          isA<InvalidClassRankException>(),
          hasMessage('6 is not a valid class rank')
        ])));
  });

  test('Get number of choices for course rank', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.getNumChoicesForClassRank('SIS', 0), 4);
    expect(scheduling.getNumChoicesForClassRank('BRX', 0), 18);
    expect(scheduling.getNumChoicesForClassRank('LES', 5), 0);
    expect(scheduling.getNumChoicesForClassRank('ABC', 0), null);
    expect(scheduling.getNumChoicesForClassRank('ABC', 5), null);
    expect(
        () => scheduling.getNumChoicesForClassRank('SIS', 6),
        throwsA(allOf([
          isA<InvalidClassRankException>(),
          hasMessage('6 is not a valid class rank')
        ])));
  });

  test('Get auxiliary data', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.getNumClassesWanted(), 318);
    expect(scheduling.getNumClassesGiven(), 318);
    await scheduling.loadCourses('test/resources/course.txt');
    expect(scheduling.getNumClassesGiven(), 318);
    expect(scheduling.getNumClassesWanted(), 318);
    expect(scheduling.getUnmetWants(), 0);
  });
}
