/// Exception for duplicate course codes in course input file
class DuplicateCourseCodeException extends Error {
  DuplicateCourseCodeException({required this.duplicatedCode});

  String duplicatedCode;

  @override
  String toString() {
    return "The course file contains duplicate course codes: $duplicatedCode";
  }
}

/// Exception for incorrectly formatted course input file
class MalformedCourseFileException extends Error {
  MalformedCourseFileException({required this.malformedLine});

  String malformedLine;

  @override
  String toString() {
    return "The course file is malformed: $malformedLine";
  }
}
