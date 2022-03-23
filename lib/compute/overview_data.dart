import 'dart:collection';

import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/compute/validate.dart';
import 'package:omnilore_scheduler/model/class_size.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class OverviewData {
  OverviewData(Courses courses, People people, Validate validate)
      : _courses = courses,
        _people = people,
        _validate = validate;

  // Global data
  final People _people;
  final Courses _courses;
  final Validate _validate;

  // Internal states
  final _choices = HashMap<String, List<HashSet<String>?>>();

  // Readonly access to CourseControl
  late final CourseControl _courseControl;

  /// Late initialize CourseControl
  void initialize(CourseControl courseControl) {
    _courseControl = courseControl;
  }

  /// Reset computing state
  void resetState() {
    _choices.clear();
    for (var code in _courses.getCodes()) {
      _choices[code] = List<HashSet<String>?>.filled(6, null, growable: false);
    }
  }

  /// Get the number people who has listed a given course as their nth choice
  /// (rank)
  ///
  /// Throws [InvalidClassRankException] if the given rank is not in 0 to 5,
  /// inclusive.
  /// Throws [UnexpectedFatalException] if the people and course files are not
  /// consistent. This might happen if trying to query choices despite a
  /// [InconsistentCourseAndPeopleException] thrown in [loadPeople] or
  /// [loadCourses]. Frontend should prevent this.
  ///
  /// Returns null if course code does not exist.
  ///
  /// The first call to this function after a course/people load might take
  /// longer. All subsequent calls use cached results and will return
  /// instantaneously.
  ClassSize? getNbrForClassRank(String course, int rank) {
    if (rank < 0 || rank > 5) {
      throw InvalidClassRankException(rank: rank);
    }
    if (!_choices.containsKey(course)) {
      return null;
    } else {
      var choices = _choices[course]![rank];
      if (choices == null) {
        _computeChoices(rank, _people);
        return _getClassSizeFromRaw(course, _choices[course]![rank]!.length);
      } else {
        return _getClassSizeFromRaw(course, choices.length);
      }
    }
  }

  /// Compute number of choices for all classes at at given rank
  void _computeChoices(int rank, People people) {
    for (var person in people.people.values) {
      if (rank < person.classes.length) {
        var course = person.classes[rank];
        if (_choices.containsKey(course)) {
          if (_choices[course]![rank] == null) {
            _choices[course]![rank] = HashSet<String>();
          }
          _choices[course]![rank]!.add(person.getName());
        } else {
          // This should never happen
          throw UnexpectedFatalException(); // coverage:ignore-line
        }
      }
    }
    for (var course in _choices.keys) {
      if (_choices[course]![rank] == null) {
        _choices[course]![rank] = HashSet<String>();
      }
    }
  }

  /// Get a list of people who selected a given class as their nth choice (rank)
  ///
  /// Throws [InvalidClassRankException] if the given rank is not in 0 to 5,
  /// inclusive.
  /// Throws [UnexpectedFatalException] if the people and course files are not
  /// consistent. This might happen if trying to query choices despite a
  /// [InconsistentCourseAndPeopleException] thrown in [loadPeople] or
  /// [loadCourses]. Frontend should prevent this.
  ///
  /// Returns null if course code does not exist.
  ///
  /// The first call to this function after a course/people load might take
  /// longer. All subsequent calls use cached results and will return
  /// instantaneously.
  ///
  /// The frontend should NOT default to calling this function and use the
  /// length of the iterable as the number of choices. Query this only when the
  /// user want to see this info. This function is slower than
  /// [getNumChoicesForClassRank].
  Iterable<String>? getPeopleForClassRank(String course, int rank) {
    if (rank < 0 || rank > 5) {
      throw InvalidClassRankException(rank: rank);
    }
    if (!_choices.containsKey(course)) {
      return null;
    } else {
      var choices = _choices[course]![rank];
      if (choices == null) {
        _computeChoices(rank, _people);
        return _choices[course]![rank]!.toList(growable: false);
      } else {
        return choices.toList(growable: false);
      }
    }
  }

  /// Get the current status of processing
  StateOfProcessing getStateOfProcessing() {
    if (!_validate.isValid()) {
      return StateOfProcessing.inconsistent;
    }
    if (_courses.getNumCourses() == 0) {
      return StateOfProcessing.needCourses;
    }
    if (_people.people.isEmpty) {
      return StateOfProcessing.needPeople;
    }
    if (_courseControl.hasUndersizeClasses(_courses, _people)) {
      return StateOfProcessing.drop;
    }
    if (_courseControl.hasOversizeClasses(_courses, _people)) {
      return StateOfProcessing.split;
    }
    return StateOfProcessing.schedule;
  }

  /// Get the number of people added from backup for a course
  ///
  /// Returns null if course code does not exist.
  ///
  /// This is an alias to the function of the same name under CourseControl.
  /// Alias provided for consistency.
  int? getNbrAddFromBackup(String course) {
    return _courseControl.getNbrAddFromBackup(course);
  }

  /// Get a list of people added from backup for a course
  ///
  /// Returns null if course code does not exist.
  ///
  /// This is an alias to the function of the same name under CourseControl.
  /// Alias provided for consistency.
  Iterable<String>? getPeopleAddFromBackup(String course) {
    return _courseControl.getPeopleAddFromBackup(course);
  }

  /// Get the resulting class size
  ///
  /// DO NOT call this on a dropped class. It will not return 0, which is the
  /// correct resulting class size. That edge case is not handled because the
  /// frontend should not ever need to know the resulting class size of a
  /// dropped class.
  ClassSize? getResultingClassSize(String course) {
    int? firstChoice = getNbrForClassRank(course, 0)?.size;
    if (firstChoice == null) return null;
    int addFromBackup = getNbrAddFromBackup(course)!;
    return _getClassSizeFromRaw(course, firstChoice + addFromBackup);
  }

  /// Get a list of people for a resulting course
  ///
  ///  Returns null if course code does not exist
  Iterable<String>? getPeopleForResultingClass(String course) {
    Iterable<String>? firstChoices = getPeopleForClassRank(course, 0);
    Iterable<String>? addFromBackups = getPeopleAddFromBackup(course);
    if (firstChoices == null || addFromBackups == null) {
      return null;
    } else {
      return List.from(firstChoices)..addAll(addFromBackups);
    }
  }

  /// Helper function that generates ClassSize object from raw integer
  ClassSize _getClassSizeFromRaw(String course, int size) {
    if (size > _courseControl.getMaxClassSize(course)) {
      return ClassSize(size: size, state: ClassState.oversized);
    } else if (size < _courseControl.getMinClassSize(course)) {
      return ClassSize(size: size, state: ClassState.undersized);
    }
    return ClassSize(size: size, state: ClassState.normal);
  }
}
