import 'dart:io';

import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/compute/overview_data.dart';
import 'package:omnilore_scheduler/compute/split_control.dart';
import 'package:omnilore_scheduler/compute/validate.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class Scheduling {
  Scheduling() {
    overviewData = OverviewData(_courses, _people, _validate);
    courseControl = CourseControl();
    splitControl = SplitControl(_people, _courses);

    courseControl.initialize(this);
    overviewData.initialize(courseControl);
    splitControl.initialize(this);
  }

  // Shared data
  final _courses = Courses();
  final _people = People();
  final _validate = Validate();

  // Compute modules
  late OverviewData overviewData;
  late CourseControl courseControl;
  late SplitControl splitControl;

  /// Compute all submodules
  void compute(Change change) {
    overviewData.compute(change);
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
    if (_courses.getNumCourses() != 0) {
      throw UnexpectedFatalException();
    }
    int numCourses;
    numCourses = await _courses.loadCourses(inputFile);
    if (numCourses != 0) {
      compute(Change(course: true));
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
  /// Throws a [UnexpectedFatalException] if loaded people before course or if
  /// has loaded people already.
  ///
  /// Asynchronously returns the number of people successfully read.
  ///
  /// ```dart
  /// int numPeople = await people.loadPeople('/path/to/file');
  /// ```
  Future<int> loadPeople(String inputFile) async {
    if (_courses.getNumCourses() == 0 || _people.people.isNotEmpty) {
      throw UnexpectedFatalException();
    }
    var numPeople = await _people.loadPeople(inputFile);
    if (numPeople != 0) {
      var result =
          _validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        throw InconsistentCourseAndPeopleException(message: result);
      }
      compute(Change(people: true));
    }
    return numPeople;
  }
}
