import 'dart:collection';

import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/compute/validate.dart';
import 'package:omnilore_scheduler/model/change.dart';
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
  final _data = HashMap<String, CourseData>();
  int _unmetWants = 0;

  // Readonly access to CourseControl
  late final CourseControl _courseControl;

  /// Late initialize CourseControl
  void initialize(CourseControl courseControl) {
    _courseControl = courseControl;
  }

  /// Compute overview data
  ///
  /// Depends on course, people, drop
  void compute(Change change) {
    if (change.course) {
      _data.clear();
      for (var course in _courses.getCodes()) {
        _data[course] = CourseData();
      }
    }

    if (change.course || change.people || change.drop) {
      // Clear data
      for (var courseData in _data.values) {
        courseData.reset();
      }

      // Compute
      var dropped = _courseControl.getDropped();
      for (var person in _people.people.values) {
        var wanted = person.nbrClassWanted;
        for (var i = 0; i < person.backups.length; i++) {
          _data[person.backups[i]]!.backups[i].add(person.getName());
        }
        for (var course in person.firstChoices) {
          if (!dropped.contains(course)) {
            wanted -= 1;
            _data[course]!.firstChoices.add(person.getName());
          }
        }
        for (var i = 0; i < person.backups.length; i++) {
          if (wanted > 0 && !dropped.contains(person.backups[i])) {
            wanted -= 1;
            _data[person.backups[i]]!.addFromBackup.add(person.getName());
          }
        }
        if (wanted > 0) {
          _unmetWants += wanted;
        }
      }
    }
  }

  /// Get the number people who has listed a given course as their nth choice
  /// (rank)
  ///
  /// Throws [InvalidClassRankException] if the given rank is not in 0 to 5,
  /// inclusive.
  ///
  /// Will crash if course code does not exist.
  ///
  /// The first call to this function after a course/people load might take
  /// longer. All subsequent calls use cached results and will return
  /// instantaneously.
  ClassSize getNbrForClassRank(String course, int rank) {
    if (rank < 0 || rank > 5) {
      throw InvalidClassRankException(rank: rank);
    }
    int count;
    if (rank == 0) {
      count = _data[course]!.firstChoices.length;
    } else {
      count = _data[course]!.backups[rank - 1].length;
    }
    return _getClassSizeFromRaw(course, count);
  }

  /// Get a list of people who selected a given class as their nth choice (rank)
  ///
  /// Throws [InvalidClassRankException] if the given rank is not in 0 to 5,
  /// inclusive.
  ///
  /// Will crash if course code does not exist.
  ///
  /// The first call to this function after a course/people load might take
  /// longer. All subsequent calls use cached results and will return
  /// instantaneously.
  ///
  /// The frontend should NOT default to calling this function and use the
  /// length of the iterable as the number of choices. Query this only when the
  /// user want to see this info. This function is slower than
  /// [getNumChoicesForClassRank].
  Set<String> getPeopleForClassRank(String course, int rank) {
    if (rank < 0 || rank > 5) {
      throw InvalidClassRankException(rank: rank);
    }
    if (rank == 0) {
      return _data[course]!.firstChoices;
    } else {
      return _data[course]!.backups[rank - 1];
    }
  }

  /// Get the number of people added from backup for a course
  ///
  /// Will crash if course code does not exist.
  ///
  /// This is an alias to the function of the same name under CourseControl.
  /// Alias provided for consistency.
  int getNbrAddFromBackup(String course) {
    return _data[course]!.addFromBackup.length;
  }

  /// Get a list of people added from backup for a course
  ///
  /// Will crash if course code does not exist.
  ///
  /// This is an alias to the function of the same name under CourseControl.
  /// Alias provided for consistency.
  Set<String> getPeopleAddFromBackup(String course) {
    return _data[course]!.addFromBackup;
  }

  /// Get the resulting class size
  ///
  /// DO NOT call this on a dropped class. It will not return 0, which is the
  /// correct resulting class size. That edge case is not handled because the
  /// frontend should not ever need to know the resulting class size of a
  /// dropped class.
  ClassSize getResultingClassSize(String course) {
    return _getClassSizeFromRaw(course, _data[course]!.getResultingSize());
  }

  /// Get a list of people for a resulting course
  ///
  /// Will crash if course code does not exist
  Set<String> getPeopleForResultingClass(String course) {
    return _data[course]!.getResultingClass();
  }

  int getUnmetWants() {
    return _unmetWants;
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
    if (_hasUndersizeClasses(_courses)) {
      return StateOfProcessing.drop;
    }
    if (_hasOversizeClasses(_courses)) {
      return StateOfProcessing.split;
    }
    return StateOfProcessing.schedule;
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

  /// Get whether there is class to split
  bool _hasOversizeClasses(Courses courses) {
    for (var course in courses.getCodes()) {
      if (getNbrForClassRank(course, 0).state == ClassState.oversized) {
        return true;
      }
    }
    return false;
  }

  /// Get whether there is class to drop
  bool _hasUndersizeClasses(Courses courses) {
    for (var course in courses.getCodes()) {
      if (getNbrForClassRank(course, 0).state == ClassState.undersized) {
        return true;
      }
    }
    return false;
  }
}

class CourseData {
  Set<String> firstChoices = {};
  List<Set<String>> backups = [{}, {}, {}, {}, {}];
  Set<String> addFromBackup = {};

  /// Reset course data to zeros
  void reset() {
    backups = [{}, {}, {}, {}, {}];
    addFromBackup = {};
    firstChoices = {};
  }

  /// Get the number of people in the resulting class
  int getResultingSize() {
    return firstChoices.length + addFromBackup.length;
  }

  /// Get a set of people in the resulting class
  Set<String> getResultingClass() {
    return firstChoices.union(addFromBackup);
  }
}
