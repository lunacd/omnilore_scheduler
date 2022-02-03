import 'dart:io';

import 'package:omnilore_scheduler/analysis/validate.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class Scheduling {
  final Courses _courses = Courses();
  final People _people = People();
  bool _isValid = true;

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

  /// Get the total number of courses
  int getNumCourses() {
    return _courses.getNumCourses();
  }

  /// Loads courses from a text file
  ///
  /// Throws a [FileSystemException] when the given input file does not exist.
  /// Throws a [MalformedCourseFileException] when the input file is incorrectly
  /// formatted.
  /// Throws a [DuplicateCourseCodeException] when the input file specifies a
  /// course code more than once.
  /// Throws a [InconsistentCourseAndPeopleException] when people and the course
  /// schedule are inconsistent
  /// Asynchronously returns the number of courses successfully read.
  /// ```dart
  /// int numCourses = await scheduling.loadCourses('/path/to/file');
  /// ```
  Future<int> loadCourses(String inputFile) async {
    _isValid = true;
    int numCourses;
    numCourses = await _courses.loadCourses(inputFile);
    if (numCourses != 0 && _people.people.isNotEmpty) {
      var result =
          Validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        _isValid = false;
        throw InconsistentCourseAndPeopleException(message: result);
      }
    }
    return numCourses;
  }

  /// Get a list of people, ordered as is presented in the input file
  List<Person> getPeople() {
    return _people.people;
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
  ///
  /// Asynchronously returns the number of people successfully read.
  ///
  /// ```dart
  /// int numPeople = await people.loadPeople('/path/to/file');
  /// ```
  Future<int> loadPeople(String inputFile) async {
    _isValid = true;
    var numPeople = await _people.loadPeople(inputFile);
    if (numPeople != 0 && _courses.getNumCourses() != 0) {
      var result =
          Validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        _isValid = false;
        throw InconsistentCourseAndPeopleException(message: result);
      }
    }
    return numPeople;
  }

  /// Get a description of the current status of processing
  StatusOfProcessing getStatusOfProcessing() {
    if (!_isValid) {
      return StatusOfProcessing.inconsistent;
    }
    if (_courses.getNumCourses() == 0) {
      return StatusOfProcessing.needCourses;
    }
    if (_people.people.isEmpty) {
      return StatusOfProcessing.needPeople;
    }
    return StatusOfProcessing.notImplemented;
  }
}

enum StatusOfProcessing {
  needCourses,
  needPeople,
  inconsistent,
  notImplemented
}
