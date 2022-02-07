import 'dart:collection';

import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class Compute {
  final _choices = HashMap<String, List<int?>>();

  /// Reset computing state
  void resetState(Courses courses) {
    _choices.clear();
    for (var code in courses.getCodes()) {
      _choices[code] = List<int?>.filled(6, null);
    }
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
  int? getNumChoices(int rank, String course, People people) {
    if (rank < 0 || rank > 5) {
      throw InvalidClassRankException(rank: rank);
    }
    var choices = _choices[course];
    if (choices == null) {
      return null;
    } else {
      if (choices[rank] == null) {
        _computeChoices(rank, people);
        return _choices[course]![rank];
      } else {
        return choices[rank];
      }
    }
  }

  /// Compute number of choices for all classes at at given rank
  void _computeChoices(int rank, People people) {
    for (var person in people.people) {
      if (rank < person.classes.length) {
        var course = person.classes[rank];
        if (_choices.containsKey(course)) {
          var choices = _choices[course]!;
          var rankChoices = choices[rank];
          if (rankChoices != null) {
            _choices[course]![rank] = rankChoices + 1;
          } else {
            _choices[course]![rank] = 1;
          }
        } else {
          // This should never happen
          throw UnexpectedFatalException(); // coverage:ignore-line
        }
      }
    }
  }
}
