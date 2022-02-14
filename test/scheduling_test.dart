import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';

import 'test_util.dart';

void main() {
  test('Get course info', () async {
    var scheduling = Scheduling();
    expect(await scheduling.loadPeople('test/resources/people.txt'), 267);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(scheduling.getCourseCodes().length, 24);
    expect(
        scheduling.getCourseCodes(),
        containsAll([
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
          'ILA',
          'FOO'
        ]));
    expect(
        scheduling.getCourse('ILA'),
        const Course(
            code: 'ILA',
            name: 'The Invention of Los Angeles',
            reading:
                'The Mirage Factory: Illusion, Imagination, and the . . . , by Gary Krist'));
    expect(scheduling.getNumCourses(), 24);
  });

  test('Get people', () async {
    var scheduling = Scheduling();
    expect(await scheduling.loadPeople('test/resources/people.txt'), 267);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(scheduling.getNumPeople(), 267);
    var person1 = scheduling
        .getPeople()
        .firstWhere((element) => element.getName() == 'Carol Johnson');
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
    var person2 = scheduling
        .getPeople()
        .firstWhere((element) => element.getName() == 'Stan Pleatman');
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
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
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
    expect(await scheduling.loadPeople('test/resources/people_split.txt'), 270);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.split);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.split);
  });

  test('Status of processing: schedule', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course_split.txt'), 21);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needPeople);
    expect(
        await scheduling.loadPeople('test/resources/people_schedule.txt'), 267);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.schedule);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.schedule);
  });

  test('Inconsistent people and course: course first', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needPeople);
    expect(
        scheduling.loadPeople('test/resources/people_inconsistent.txt'),
        throwsA(allOf([
          isA<InconsistentCourseAndPeopleException>(),
          hasMessage('Invalid class choice: SCI by Judi Jones')
        ])));
  });

  test('Inconsistent people and course: people first', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(
        await scheduling.loadPeople('test/resources/people_inconsistent.txt'),
        267);
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
    expect(scheduling.getPeopleForClassRank('SIS', 0)!.length, 4);
    expect(scheduling.getPeopleForClassRank('BRX', 0)!.length, 17);
    expect(scheduling.getPeopleForClassRank('LES', 5)!.length, 0);
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
    expect(scheduling.getNumChoicesForClassRank('BRX', 0), 17);
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
    expect(scheduling.getNumClassesWanted(), 306);
    expect(scheduling.getNumClassesGiven(), 306);
    await scheduling.loadCourses('test/resources/course.txt');
    expect(scheduling.getNumClassesGiven(), 306);
    expect(scheduling.getNumClassesWanted(), 306);
    expect(scheduling.getUnmetWants(), 0);
  });

  test('Drop classes', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    scheduling.drop('LES');
    expect(scheduling.getNumAddFromBackup('BIG'), 1);
    expect(scheduling.getPeopleAddFromBackup('BIG')!.length, 1);
    expect(scheduling.getPeopleAddFromBackup('BIG'),
        containsAll(['Bob Bacinski']));
    expect(scheduling.getNumAddFromBackup('FAC'), 2);
    expect(scheduling.getPeopleAddFromBackup('FAC')!.length, 2);
    expect(scheduling.getPeopleAddFromBackup('FAC'),
        containsAll(['Barbara Case', 'Sarah Jones']));
    expect(scheduling.getNumAddFromBackup('GOO'), 3);
    expect(scheduling.getPeopleAddFromBackup('GOO')!.length, 3);
    expect(scheduling.getPeopleAddFromBackup('GOO'),
        containsAll(['Ray Destabelle', 'Pettina Long', 'Suzanne Mann']));
    expect(scheduling.getNumAddFromBackup('LES'), 0);
    expect(scheduling.getPeopleAddFromBackup('LES')!.length, 0);
    expect(scheduling.getNumAddFromBackup('HCD'), 0);
    expect(scheduling.getPeopleAddFromBackup('HCD')!.length, 0);
  });

  test('Drop classes: drop with backup', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    scheduling.drop('LES');
    scheduling.drop('FOO');
    scheduling.drop('GOO');
    expect(scheduling.getNumAddFromBackup('LES'), 0);
    expect(scheduling.getPeopleAddFromBackup('LES')!.length, 0);
    expect(scheduling.getNumAddFromBackup('GOO'), 0);
    expect(scheduling.getPeopleAddFromBackup('GOO')!.length, 0);
    expect(scheduling.getNumAddFromBackup('BIG'), 1);
    expect(scheduling.getPeopleAddFromBackup('BIG')!.length, 1);
    expect(scheduling.getPeopleAddFromBackup('BIG'),
        containsAll(['Bob Bacinski']));
    expect(scheduling.getNumAddFromBackup('HCD'), 4);
    expect(scheduling.getPeopleAddFromBackup('HCD')!.length, 4);
    expect(
        scheduling.getPeopleAddFromBackup('HCD'),
        containsAll(
            ['Stan Nah', 'Ray Destabelle', 'Helen Nah', 'Suzanne Mann']));
    expect(scheduling.getNumAddFromBackup('ABC'), null);
    expect(scheduling.getPeopleAddFromBackup('ABC'), null);
    expect(scheduling.getNumAddFromBackup('FAC'), 4);
    expect(scheduling.getPeopleAddFromBackup('FAC')!.length, 4);
    expect(
        scheduling.getPeopleAddFromBackup('FAC'),
        containsAll(
            ['Barbara Case', 'Sarah Jones', 'Rich Gleerup', 'Dick Balsam']));
  });
}
