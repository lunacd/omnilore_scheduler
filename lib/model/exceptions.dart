/// Exception for duplicate course codes in course input file
class DuplicateCourseCodeException implements Exception {
  const DuplicateCourseCodeException({required this.duplicatedCode});

  final String duplicatedCode;

  @override
  String toString() {
    return 'The course file contains duplicate course codes: $duplicatedCode';
  }
}

/// Exception for incorrectly formatted course input file
class MalformedCourseFileException implements Exception {
  const MalformedCourseFileException({required this.malformedLine});

  final int malformedLine;

  @override
  String toString() {
    return 'The course file is malformed: line $malformedLine';
  }
}

/// Exception for incorrectly formatted people input file
class MalformedPeopleFileException implements Exception {
  const MalformedPeopleFileException({required this.malformedLine});

  final int malformedLine;

  @override
  String toString() {
    return 'The people file is malformed: line $malformedLine';
  }
}

/// Exception for unrecognized availability value
class InvalidNumClassWantedException implements Exception {
  const InvalidNumClassWantedException(
      {required this.malformedLine, required this.numClassWanted});

  final int malformedLine;
  final int numClassWanted;

  @override
  String toString() {
    return 'People file specifies invalid number of classes wanted: $numClassWanted at line $malformedLine';
  }
}

/// Exception for unrecognized availability value
class UnrecognizedAvailabilityException implements Exception {
  const UnrecognizedAvailabilityException(
      {required this.malformedLine, required this.availability});

  final int malformedLine;
  final String availability;

  @override
  String toString() {
    return 'People file specifies unrecognized availability value: $availability at line $malformedLine';
  }
}

/// Exception for choosing a class more than once
class DuplicateClassSelectionException implements Exception {
  const DuplicateClassSelectionException(
      {required this.malformedLine, required this.classCode});

  final int malformedLine;
  final String classCode;

  @override
  String toString() {
    return 'A class is chosen more than once: $classCode at line $malformedLine';
  }
}

/// Exception for having inconsistencies between courses and people
class InconsistentCourseAndPeopleException implements Exception {
  const InconsistentCourseAndPeopleException({required this.message});

  final String message;

  @override
  String toString() {
    return message;
  }
}
