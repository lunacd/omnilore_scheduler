import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';

class Courses {
  final HashMap<String, Course> _courses = HashMap<String, Course>();

  /// Get an iterable list of course codes
  ///
  /// ```dart
  /// for (var code in courses.getCodes()) {}
  /// ```
  Iterable<String> getCodes() {
    var result = _courses.keys.toList(growable: false);
    result.sort((String a, String b) => a.compareTo(b));
    return result;
  }

  /// Get course information given a course code
  Course? getCourse(String code) {
    return _courses[code];
  }

  /// Check whether a given course exists
  bool hasCourse(String code) {
    return _courses.containsKey(code);
  }

  /// Get the total number of courses
  int getNumCourses() {
    return _courses.length;
  }

  /// Loads courses from a text file
  ///
  /// Throws a [FileSystemException] when the given input file does not exist.
  /// Throws a [MalformedCourseFileException] when the input file is incorrectly
  /// formatted.
  /// Throws a [DuplicateCourseCodeException] when the input file specifies a
  /// course code more than once.
  ///
  /// Asynchronously returns the number of courses successfully read.
  ///
  /// ```dart
  /// int numCourses = await courses.loadCourses('/path/to/file');
  /// ```
  Future<int> loadCourses(String inputFile) async {
    _courses.clear();
    var file = File(inputFile);
    var lines =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());
    var numLines = 0;
    await for (var line in lines) {
      if (line.isEmpty) continue;
      var tokens = line.split('\t').map((e) => e.trim()).toList();
      if (tokens.length != 3) {
        _courses.clear();
        throw MalformedCourseFileException(malformedLine: numLines + 1);
      }
      var code = tokens[0];
      var name = tokens[1];
      var reading = tokens[2];
      if (_courses.containsKey(code)) {
        _courses.clear();
        throw DuplicateCourseCodeException(duplicatedCode: code);
      }
      _courses[code] = Course(code: code, name: name, reading: reading);
      numLines++;
    }
    return numLines;
  }

  void splitCourse(String course, int numSplits) {
    for (var splitIndex = 0; splitIndex < numSplits; splitIndex++) {
      _courses['$course$splitIndex'] = _courses[course]!;
    }
    _courses.remove(course);
  }
}
