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

/// Exception for asking for an invalid class rank
class InvalidClassRankException implements Exception {
  const InvalidClassRankException({required this.rank});

  final int rank;

  @override
  String toString() {
    return '$rank is not a valid class rank';
  }
}

/// Exception for members wanting more class than they listed
class WantingMoreThanListedException implements Exception {
  const WantingMoreThanListedException(
      {required this.fName, required this.lName});

  final String fName;
  final String lName;

  @override
  String toString() {
    return '$fName $lName wanted more class than they listed';
  }
}

/// Exception for members still listing classes when they want 0
class ListingWhenWantingZeroException implements Exception {
  const ListingWhenWantingZeroException(
      {required this.fName, required this.lName});

  final String fName;
  final String lName;

  @override
  String toString() {
    return '$fName $lName still listed classes when wanting 0';
  }
}

/// Exception for a person to have duplicate records in the people file
class DuplicateRecordsException implements Exception {
  const DuplicateRecordsException({required this.fName, required this.lName});

  final String fName;
  final String lName;

  @override
  String toString() {
    return '$fName $lName has more than one record';
  }
}

/// Exception for passing a min larger than max
class MinLargerThanMaxException implements Exception {
  const MinLargerThanMaxException({required this.min, required this.max});

  final int min;
  final int max;

  @override
  String toString() {
    return 'Min: $min is larger than max: $max';
  }
}

/// Fatal errors that should not have happened
class UnexpectedFatalException implements Exception {
  // Ignoring this in coverage because this exception should never be thrown
  // coverage:ignore-start
  @override
  String toString() {
    return 'Fatal Error: This should not have occurred. Try restarting the program.';
  }
// coverage:ignore-end
}
