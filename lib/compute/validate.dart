import 'dart:collection';

import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';

class Validate {
  var _isValid = true;

  /// Given a list of people and courses, determine whether they are consistent
  ///
  /// If they are consistent, returns null
  /// If they are not, an error message is returned
  String? validatePeopleAgainstCourses(
      HashMap<String, Person> people, Courses courses) {
    for (var person in people.values) {
      for (var classCode in person.classes) {
        if (!courses.hasCourse(classCode)) {
          _isValid = false;
          return 'Invalid class choice: $classCode by ${person.fName} ${person.lName}';
        }
      }
    }
    _isValid = true;
    return null;
  }

  /// Returns the current validity of processing
  bool isValid() {
    return _isValid;
  }
}
