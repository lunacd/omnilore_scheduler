import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/courses.dart';

import 'test_util.dart';

void main() {
  test("Load courses: File not found", () {
    var courses = Courses();
    expect(() => courses.loadCourses("nonexistent"),
        throwsA(isA<FileSystemException>()));
  });

  test("Load courses: Malformed course file", () async {
    var courses = Courses();
    expect(
        () => courses.loadCourses("test/resources/malformed_course.txt"),
        throwsA(allOf([
          isA<MalformedCourseFileException>(),
          hasMessage(
              "The course file is malformed: COD\tCourse without reading")
        ])));
  });

  test("Load courses: Duplicate course code", () {
    var courses = Courses();
    expect(
        () => courses.loadCourses("test/resources/duplicate_course.txt"),
        throwsA(allOf([
          isA<DuplicateCourseCodeException>(),
          hasMessage("The course file contains duplicate course codes: COD")
        ])));
  });

  test("Load courses", () async {
    var courses = Courses();
    expect(await courses.loadCourses("test/resources/course.txt"), 23);
    expect(courses.getNumCourses(), 23);
    expect(
        courses.getCodes(),
        equals([
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
        ]));
  });
}
