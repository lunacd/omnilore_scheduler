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

  test('Status of processing', () async {
    var scheduling = Scheduling();
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 23);
    expect(scheduling.getStatusOfProcessing(), StatusOfProcessing.needPeople);
    expect(await scheduling.loadPeople('test/resources/people.txt'), 271);
    expect(
        scheduling.getStatusOfProcessing(), StatusOfProcessing.notImplemented);
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

  test('Get course rank', () async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');
    expect(scheduling.getNumChoices('SIS', 0), 4);
    expect(scheduling.getNumChoices('BRX', 0), 18);
    expect(scheduling.getNumChoices('QUR', 3), 3);
    expect(scheduling.getNumChoices('ABC', 0), null);
    expect(scheduling.getNumChoices('ABC', 5), null);
    expect(
        () => scheduling.getNumChoices('SIS', 6),
        throwsA(allOf([
          isA<InvalidClassRankException>(),
          hasMessage('6 is not a valid class rank')
        ])));
  });
}
