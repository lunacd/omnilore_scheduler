import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/analysis/validate.dart';
import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';

void main() {
  test('Consistent people and course file', () async {
    var courses = Courses();
    await courses.loadCourses('test/resources/course.txt');
    var people = [
      Person(
          fName: 'test',
          lName: 'test',
          phone: 'test',
          numClassWanted: 1,
          availability: Availability(),
          classes: ['SIS'],
          submissionOrder: 1)
    ];
    expect(Validate.validatePeopleAgainstCourses(people, courses), null);
  });

  test('Inconsistent people and course file', () async {
    var courses = Courses();
    await courses.loadCourses('test/resources/course.txt');
    var people = [
      Person(
          fName: 'test',
          lName: 'test',
          phone: 'test',
          numClassWanted: 1,
          availability: Availability(),
          classes: ['SCI'],
          submissionOrder: 1)
    ];
    expect(Validate.validatePeopleAgainstCourses(people, courses),
        'Invalid class choice: SCI by test test');
  });
}
