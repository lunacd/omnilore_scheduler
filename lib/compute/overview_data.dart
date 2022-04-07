import 'dart:collection';

import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/compute/validate.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/class_size.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

enum PlacementResult { success, drop, time, full, dup }

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

  int _nbrRequested = 0;
  int _nbrOnLeave = 0;
  int _nbrCourseTakers = 0;
  int _nbrGoCourse = 0;
  int _nbrUnmetWants = 0;

  // Readonly access to CourseControl
  late final Scheduling _scheduling;

  /// Late initialize Scheduling
  void initialize(Scheduling scheduling) {
    _scheduling = scheduling;
  }

  /// Compute overview data
  ///
  /// Depends on course, people, drop
  void compute(Change change) {
    // Update course data
    if (change.course) {
      _data.clear();
      for (var course in _courses.getCodes()) {
        _data[course] = CourseData();
      }
    }

    var dropped = _scheduling.courseControl.getDropped();

    // Compute go courses
    if (change.course || change.drop) {
      _nbrGoCourse = 0;
      for (var course in _courses.getCodes()) {
        if (!dropped.contains(course)) {
          _nbrGoCourse += 1;
        }
      }
    }

    // Compute all statistics
    if (change.course || change.people || change.drop) {
      // Clear data
      for (var courseData in _data.values) {
        courseData.reset();
      }
      _nbrUnmetWants = 0;
      _nbrOnLeave = 0;
      _nbrCourseTakers = 0;
      _nbrRequested = 0;

      // Compute people stats
      var peopleData = _people.people.values.toList(growable: false);
      peopleData.sort((Person a, Person b) =>
          a.submissionOrder.compareTo(b.submissionOrder));
      for (var person in peopleData) {
        var hasClass = List<bool>.filled(20, false, growable: false);
        var wanted = person.nbrClassWanted;
        _nbrRequested += wanted;
        if (wanted == 0) {
          _nbrOnLeave += 1;
        } else {
          _nbrCourseTakers += 1;
        }
        // Count backups
        for (var i = 0; i < person.backups.length; i++) {
          _data[person.backups[i]]!.backups[i].add(person.getName());
        }
        // Count first choices
        for (var course in person.firstChoices) {
          if (_placePersonInCourse(person, course, dropped, true, hasClass) ==
              PlacementResult.success) {
            wanted -= 1;
          }
        }
        // Count add from backup
        for (var i = 0; i < person.backups.length && wanted > 0; i++) {
          if (_placePersonInCourse(
                  person, person.backups[i], dropped, false, hasClass) ==
              PlacementResult.success) {
            wanted -= 1;
          }
        }
        // Count unmet wants
        if (wanted > 0) {
          _nbrUnmetWants += wanted;
        }
      }
    }
  }

  /// Attempt to place person into the given course and return the result
  PlacementResult _placePersonInCourse(Person person, String course,
      Set<String> dropped, bool firstChoice, List<bool> hasClass) {
    if (dropped.contains(course)) {
      return PlacementResult.drop;
    }
    var time = _scheduling.scheduleControl.scheduledTimeFor(course);
    if (time != -1 && !person.availability[time]) {
      _data[course]!.dropTime.add(person.getName());
      return PlacementResult.time;
    }
    if (time != -1 && hasClass[time]) {
      _data[course]!.dropDup.add(person.getName());
      return PlacementResult.dup;
    }
    if (_scheduling.courseControl.getSplitMode(course) == SplitMode.limit &&
        _data[course]!.getResultingSize() >=
            _scheduling.courseControl.getMaxClassSize(course)) {
      _data[course]!.dropFull.add(person.getName());
      return PlacementResult.full;
    }
    if (firstChoice) {
      _data[course]!.firstChoices.add(person.getName());
    } else {
      _data[course]!.addFromBackup.add(person.getName());
    }
    if (time != -1) {
      hasClass[time] = true;
    }
    return PlacementResult.success;
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
  int getNbrAddFromBackup(String course) {
    return _data[course]!.addFromBackup.length;
  }

  /// Get a set of people added from backup for a course
  ///
  /// Will crash if course code does not exist.
  Set<String> getPeopleAddFromBackup(String course) {
    return _data[course]!.addFromBackup;
  }

  /// Get the number of people dropped because of availability
  ///
  /// Will crash if course code does not exist.
  int getNbrDropTime(String course) {
    return _data[course]!.dropTime.length;
  }

  /// Get a set of people dropped because of availability
  ///
  /// Will crash if course code does not exist.
  Set<String> getPeopleDropTime(String course) {
    return _data[course]!.dropTime;
  }

  /// Get the number of people dropped because of class full
  ///
  /// Will crash if course code does not exist.
  int getNbrDropFull(String course) {
    return _data[course]!.dropFull.length;
  }

  /// Get a set of people dropped because of class full
  ///
  /// Will crash if course code does not exist.
  Set<String> getPeopleDropFull(String course) {
    return _data[course]!.dropFull;
  }

  /// Get the number of people dropped because of duplicate class schedules
  ///
  /// Will crash if course code does not exist.
  int getNbrDropDup(String course) {
    return _data[course]!.dropDup.length;
  }

  /// Get a set of people dropped because of duplicate class schedules
  ///
  /// Will crash if course code does not exist.
  Set<String> getPeopleDropDup(String course) {
    return _data[course]!.dropDup;
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

  /// Get the total number of course takers
  int getNbrCourseTakers() {
    return _nbrCourseTakers;
  }

  /// Get number of people on leave (not taking classes)
  int getNbrOnLeave() {
    return _nbrOnLeave;
  }

  /// Get the total number of courses
  int getNbrGoCourses() {
    return _nbrGoCourse;
  }

  /// Get the total number of classes asked
  int getNbrPlacesAsked() {
    return _nbrRequested;
  }

  /// Get the total number of classes given
  ///
  /// Before scheduling classes, this is always equal to the number of classes
  /// wanted.
  int getNbrPlacesGiven() {
    return _nbrRequested;
  }

  /// Get the total number of unmet wants
  int getNbrUnmetWants() {
    return _nbrUnmetWants;
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
    if (size > _scheduling.courseControl.getMaxClassSize(course)) {
      return ClassSize(size: size, state: ClassState.oversized);
    } else if (size < _scheduling.courseControl.getMinClassSize(course)) {
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
  Set<String> dropTime = {};
  Set<String> dropFull = {};
  Set<String> dropDup = {};

  /// Reset course data to zeros
  void reset() {
    addFromBackup.clear();
    firstChoices.clear();
    dropTime.clear();
    dropFull.clear();
    dropDup.clear();
    for (var i = 0; i < backups.length; i++) {
      backups[i].clear();
    }
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
