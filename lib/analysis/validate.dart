import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/courses.dart';

class Validate {
  /// Given a list of people and courses, determine whether they are consistent
  ///
  /// If they are consistent, returns null
  /// If they are not, an error message is returned
  static String? validatePeopleAgainstCourses(
      List<Person> people, Courses courses) {
    for (var person in people) {
      for (var classCode in person.classes) {
        if (!courses.hasCourse(classCode)) {
          return 'Invalid class choice: $classCode by ${person.fName} ${person.lName}';
        }
      }
    }
    return null;
  }
}
