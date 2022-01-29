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
    return _courses.keys;
  }

  /// Get course information given a course code
  Course? getCourse(String code) {
    return _courses[code];
  }

  /// Get the total number of courses
  int getNumCourses() {
    return _courses.length;
  }

  /// Loads courses
  ///
  /// Throws a [FileSystemException] when the given input file does not exist.
  /// Throws a [MalformedCourseFileException] when the input file is incorrectly
  /// formatted.
  /// Throws a [DuplicateCourseCodeException] when the input file specifies a
  /// course code more than once.
  /// Asynchronously returns the number of courses successfully read.
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
      var tokens = line.split('\t');
      if (tokens.length != 3) {
        _courses.clear();
        throw MalformedCourseFileException(malformedLine: line);
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
}
