import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
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

  test('Inconsistent people and course: course first', () async {
    var scheduling = Scheduling();
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needPeople);
    expect(
        scheduling.loadPeople('test/resources/people_inconsistent.txt'),
        throwsA(allOf([
          isA<InconsistentCourseAndPeopleException>(),
          hasMessage('Invalid class choice: SCI by Judi Jones')
        ])));
  });

  test('Inconsistent people and course: people first', () async {
    var scheduling = Scheduling();
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needCourses);
    expect(
        await scheduling.loadPeople('test/resources/people_inconsistent.txt'),
        267);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needCourses);
    expect(
        scheduling.loadCourses('test/resources/course.txt'),
        throwsA(allOf([
          isA<InconsistentCourseAndPeopleException>(),
          hasMessage('Invalid class choice: SCI by Judi Jones')
        ])));
  });
}
