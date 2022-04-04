import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';

import 'test_util.dart';

/// This file tests the coordination between submodules, mostly loading people
/// and course.
void main() {
  test('Wrong order', () async {
    var scheduling = Scheduling();
    expect(() => scheduling.loadPeople('test/resources/people.txt'),
        throwsA(isA<UnexpectedFatalException>()));
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(() => scheduling.loadCourses('test/resources/course.txt'),
        throwsA(isA<UnexpectedFatalException>()));
    expect(await scheduling.loadPeople('test/resources/people.txt'), 267);
    expect(() => scheduling.loadPeople('test/resources/people.txt'),
        throwsA(isA<UnexpectedFatalException>()));
  });

  test('Get course info', () async {
    var scheduling = Scheduling();
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(await scheduling.loadPeople('test/resources/people.txt'), 267);
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
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(await scheduling.loadPeople('test/resources/people.txt'), 267);
    expect(scheduling.getNumPeople(), 267);
    var person1 = scheduling
        .getPeople()
        .firstWhere((element) => element.getName() == 'Carol Johnson');
    expect(person1.lName, 'Johnson');
    expect(person1.fName, 'Carol');
    expect(person1.phone, '372-8535');
    expect(person1.nbrClassWanted, 1);
    expect(person1.availability, [
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
    ]);
    expect(person1.firstChoices, ['CHK']);
    expect(person1.backups, ['FAC', 'IMP', 'ILA', 'PRF']);
    expect(person1.submissionOrder, 108);
    var person2 = scheduling
        .getPeople()
        .firstWhere((element) => element.getName() == 'Stan Pleatman');
    expect(person2.lName, 'Pleatman');
    expect(person2.fName, 'Stan');
    expect(person2.phone, '709-2404');
    expect(person2.nbrClassWanted, 0);
    expect(person2.availability, [
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
    ]);
    expect(person2.firstChoices, []);
    expect(person2.submissionOrder, 259);
    var person3 = scheduling
        .getPeople()
        .firstWhere((element) => element.getName() == 'Fran Brown');
    expect(person3.lName, 'Brown');
    expect(person3.fName, 'Fran');
    expect(person3.phone, '377-5252');
    expect(person3.nbrClassWanted, 2);
    expect(person3.availability, [
      false,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      true,
      false,
      true
    ]);
    expect(person3.firstChoices, ['IMP', 'BAD']);
    expect(person3.submissionOrder, 9);
  });

  test('Inconsistent people and course: course first', () async {
    var scheduling = Scheduling();
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needCourses);
    expect(await scheduling.loadCourses('test/resources/course.txt'), 24);
    expect(scheduling.overviewData.getStateOfProcessing(),
        StateOfProcessing.needPeople);
    expect(
        scheduling
            .loadPeople('test/resources/malformed_people_inconsistent.txt'),
        throwsA(allOf([
          isA<InconsistentCourseAndPeopleException>(),
          hasMessage('Invalid class choice: SCI by Judi Jones')
        ])));
  });
}
