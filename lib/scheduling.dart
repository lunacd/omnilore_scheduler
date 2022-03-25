import 'dart:io';

import 'package:omnilore_scheduler/compute/auxiliary_data.dart';
import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/compute/overview_data.dart';
import 'package:omnilore_scheduler/compute/split_control.dart';
import 'package:omnilore_scheduler/compute/validate.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class Scheduling {
  Scheduling() {
    auxiliaryData = AuxiliaryData(_courses, _people);
    overviewData = OverviewData(_courses, _people, _validate);
    courseControl = CourseControl(_courses, _people);
    splitControl = SplitControl(_people);

    courseControl.initialize(overviewData);
    overviewData.initialize(courseControl);
    auxiliaryData.initialize(courseControl);
    splitControl.initialize(overviewData, courseControl);
  }

  // Shared data
  final _courses = Courses();
  final _people = People();
  final _validate = Validate();

  // Compute modules
  late AuxiliaryData auxiliaryData;
  late OverviewData overviewData;
  late CourseControl courseControl;
  late SplitControl splitControl;

  /// Clear cache and reset compute state
  void resetState() {
    auxiliaryData.resetState();
    overviewData.resetState();
    courseControl.resetState();
  }

  /// Get an iterable list of course codes
  ///
  /// ```dart
  /// for (var code in scheduling.getCourseCodes()) {}
  /// ```
  Iterable<String> getCourseCodes() {
    return _courses.getCodes();
  }

  /// Get course information given a course code
  Course? getCourse(String code) {
    return _courses.getCourse(code);
  }

  /// need getter for people object for split_control initialization
  People getPeopleStruct() {
    return _people;
  }

  /// Loads courses from a text file
  ///
  /// Throws a [FileSystemException] when the given input file does not exist.
  /// Throws a [MalformedCourseFileException] when the input file is incorrectly
  /// formatted.
  /// Throws a [DuplicateCourseCodeException] when the input file specifies a
  /// course code more than once.
  /// Throws a [InconsistentCourseAndPeopleException] when people and the course
  /// schedule are inconsistent.
  ///
  /// Asynchronously returns the number of courses successfully read.
  /// ```dart
  /// int numCourses = await scheduling.loadCourses('/path/to/file');
  /// ```
  Future<int> loadCourses(String inputFile) async {
    int numCourses;
    numCourses = await _courses.loadCourses(inputFile);
    if (numCourses != 0) {
      resetState();
    }
    if (numCourses != 0 && _people.people.isNotEmpty) {
      var result =
          _validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        throw InconsistentCourseAndPeopleException(message: result);
      }
    }
    return numCourses;
  }

  /// Get a list of people, ordered as is presented in the input file
  Iterable<Person> getPeople() {
    return _people.people.values;
  }

  /// Get the number of people
  int getNumPeople() {
    return _people.people.length;
  }

  /// Load people from a text file
  ///
  /// Throws a [FileSystemException] when the given input file does not exist.
  /// Throws a [MalformedPeopleFileException] when the input file has wrong
  /// number of columns.
  /// Throws a [InvalidNumClassWantedException] when the input file specifies a
  /// number of classes wanted less than 0 or more than 6.
  /// Throws a [UnrecognizedAvailabilityException] when the input file specifies an
  /// availability value other than empty, 1, 2, or 3.
  /// Throws a [DuplicateClassSelectionException] when a person selects a class
  /// more than once.
  /// Throws a [InconsistentCourseAndPeopleException] when people and the course
  /// schedule are inconsistent.
  ///
  /// Asynchronously returns the number of people successfully read.
  ///
  /// ```dart
  /// int numPeople = await people.loadPeople('/path/to/file');
  /// ```
  Future<int> loadPeople(String inputFile) async {
    var numPeople = await _people.loadPeople(inputFile);
    if (numPeople != 0) {
      resetState();
    }
    if (numPeople != 0 && _courses.getNumCourses() != 0) {
      var result =
          _validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        throw InconsistentCourseAndPeopleException(message: result);
      }
    }
    return numPeople;
  }
}
