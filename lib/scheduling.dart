import 'dart:io';

import 'package:omnilore_scheduler/analysis/compute.dart';
import 'package:omnilore_scheduler/analysis/validate.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class Scheduling {
  final _courses = Courses();
  final _people = People();

  final validate = Validate();
  final compute = Compute();

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
      compute.resetState(_courses);
    }
    if (numCourses != 0 && _people.people.isNotEmpty) {
      var result =
          validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        throw InconsistentCourseAndPeopleException(message: result);
      }
    }
    return numCourses;
  }

  /// Get a list of people, ordered as is presented in the input file
  List<Person> getPeople() {
    return _people.people;
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
      compute.resetState(_courses);
    }
    if (numPeople != 0 && _courses.getNumCourses() != 0) {
      var result =
          validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        throw InconsistentCourseAndPeopleException(message: result);
      }
    }
    return numPeople;
  }

  /// Get the current status of processing
  StatusOfProcessing getStatusOfProcessing() {
    if (!validate.isValid()) {
      return StatusOfProcessing.inconsistent;
    }
    if (_courses.getNumCourses() == 0) {
      return StatusOfProcessing.needCourses;
    }
    if (_people.people.isEmpty) {
      return StatusOfProcessing.needPeople;
    }
    if (compute.hasUndersizeClassed(_courses, _people)) {
      return StatusOfProcessing.drop;
    }
    if (compute.hasOversizeClasses(_courses, _people)) {
      return StatusOfProcessing.split;
    }
    return StatusOfProcessing.schedule;
  }

  /// Get the number people who has listed a given course as their nth choice
  /// (rank)
  ///
  /// Throws [InvalidClassRankException] if the given rank is not in [0, 5].
  /// Throws [UnexpectedFatalException] if the people and course files are not
  /// consistent. This might happen if trying to query choices despite a
  /// [InconsistentCourseAndPeopleException] thrown in [loadPeople] or
  /// [loadCourses]. Frontend should prevent this.
  ///
  /// Returns null if course code does not exist
  ///
  /// The first call to this function after a course/people load might take
  /// longer. All subsequent calls use cached results and will return
  /// instantaneously.
  int? getNumChoices(String course, int rank) {
    return compute.getNumChoices(rank, course, _people);
  }

  /// Get the total number of classes wanted
  int getNumClassesWanted() {
    return compute.getNumClassesWanted(_people);
  }

  /// Get the total number of classes given
  int getNumClassesGiven() {
    return compute.getNumClassesGiven(_people);
  }

  /// Get the total number of unmet wants
  int getUnmetWants() {
    return getNumClassesWanted() - getNumClassesGiven();
  }
}

/// Enum for all possible statuses of processing
enum StatusOfProcessing {
  needCourses,
  needPeople,
  inconsistent,
  drop,
  split,
  schedule
}
