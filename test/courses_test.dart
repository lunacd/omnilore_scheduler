import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/courses.dart';

import 'test_util.dart';

/// This file tests functionalities regarding loading courses.
void main() {
  test('Load courses: File not found', () {
    var courses = Courses();
    expect(() => courses.loadCourses('nonexistent'),
        throwsA(isA<FileSystemException>()));
  });

  test('Load courses: Malformed course file', () async {
    var courses = Courses();
    expect(
        () =>
            courses.loadCourses('test/resources/malformed_course_columns.txt'),
        throwsA(allOf([
          isA<MalformedCourseFileException>(),
          hasMessage('The course file is malformed: line 1')
        ])));
  });

  test('Load courses: Duplicate course code', () {
    var courses = Courses();
    expect(
        () => courses
            .loadCourses('test/resources/malformed_duplicate_course.txt'),
        throwsA(allOf([
          isA<DuplicateCourseCodeException>(),
          hasMessage('The course file contains duplicate course codes: COD')
        ])));
  });

  test('Load courses', () async {
    var courses = Courses();
    expect(await courses.loadCourses('test/resources/course.txt'), 24);
    expect(courses.getNumCourses(), 24);
    expect(
        courses.getCodes(),
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
        courses.getCourse('ILA'),
        const Course(
            code: 'ILA',
            name: 'The Invention of Los Angeles',
            reading:
                'The Mirage Factory: Illusion, Imagination, and the . . . , by Gary Krist'));
  });

  test('Load courses: whitespace', () async {
    var courses = Courses();
    expect(
        await courses.loadCourses('test/resources/course_whitespace.txt'), 23);
    expect(courses.getNumCourses(), 23);
    expect(
        courses.getCodes(),
        equals([
          'ASA',
          'BAD',
          'BIG',
          'BRX',
          'CHK',
          'EVC',
          'FAC',
          'GOO',
          'HCD',
          'ILA',
          'IMP',
          'LES',
          'OCN',
          'PRF',
          'QUR',
          'RAH',
          'REF',
          'RWD',
          'SAF',
          'SCH',
          'SHK',
          'SIS',
          'THK'
        ]));
    expect(
        courses.getCourse('ILA'),
        const Course(
            code: 'ILA',
            name: 'The Invention of Los Angeles',
            reading:
                'The Mirage Factory: Illusion, Imagination, and the . . . , by Gary Krist'));
    expect(courses.hasCourse('SIS'), true);
    expect(courses.hasCourse('KLL'), false);
  });
}
