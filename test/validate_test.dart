import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/compute/validate.dart';
import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';

void main() {
  test('Consistent people and course file', () async {
    var courses = Courses();
    var validator = Validate();
    await courses.loadCourses('test/resources/course.txt');
    var people = HashMap<String, Person>();
    people['test test'] = Person(
        fName: 'test',
        lName: 'test',
        phone: 'test',
        nbrClassWanted: 1,
        availability: Availability(),
        firstChoices: ['SIS'],
        backups: [],
        submissionOrder: 1);
    expect(validator.validatePeopleAgainstCourses(people, courses), null);
  });

  test('Inconsistent people and course file', () async {
    var courses = Courses();
    var validator = Validate();
    await courses.loadCourses('test/resources/course.txt');
    var people = HashMap<String, Person>();
    people['test test'] = Person(
        fName: 'test',
        lName: 'test',
        phone: 'test',
        nbrClassWanted: 1,
        availability: Availability(),
        firstChoices: ['SCI'],
        backups: [],
        submissionOrder: 1);
    expect(validator.validatePeopleAgainstCourses(people, courses),
        'Invalid class choice: SCI by test test');
    people['test test'] = Person(
        fName: 'test',
        lName: 'test',
        phone: 'test',
        nbrClassWanted: 1,
        availability: Availability(),
        firstChoices: [],
        backups: ['SCI'],
        submissionOrder: 1);
    expect(validator.validatePeopleAgainstCourses(people, courses),
        'Invalid class choice: SCI by test test');
  });
}
