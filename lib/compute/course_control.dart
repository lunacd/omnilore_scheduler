import 'dart:collection';

import 'package:omnilore_scheduler/compute/overview_data.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class CourseControl {
  CourseControl(Courses courses, People people)
      : _courses = courses,
        _people = people;

  // Shared data
  final People _people;
  final Courses _courses;

  // Internal states
  final _dropped = HashSet<String>();
  final _backupAdd = HashMap<String, HashMap<String, int>>();

  // Readonly access to OverviewData
  late final OverviewData _overviewData;

  /// Late initialize pointer to overviewData
  void initialize(OverviewData overviewData) {
    _overviewData = overviewData;
  }

  /// Reset computing state
  void resetState() {
    for (var code in _courses.getCodes()) {
      _backupAdd[code] = HashMap<String, int>();
    }
  }

  /// Drop class
  void drop(String course) {
    _dropped.add(course);
    var affectedFirstChoice = _overviewData.getPeopleForClassRank(course, 0);
    if (affectedFirstChoice == null) {
      return;
    }
    var affectedBackup = List<MapEntry<String, int>>.from(
        _getPeopleAndDataAddFromBackup(course)!);

    for (var name in affectedFirstChoice) {
      var person = _people.people[name]!;
      var index = 1;
      while (index < person.classes.length &&
          _dropped.contains(person.classes[index])) {
        index++;
      }
      if (index < person.classes.length) {
        _backupAdd[person.classes[index]]![name] = index;
      }
    }
    for (var entry in affectedBackup) {
      var person = _people.people[entry.key]!;
      var index = entry.value + 1;
      while (index < person.classes.length &&
          _dropped.contains(person.classes[index])) {
        index++;
      }
      if (index < person.classes.length) {
        _backupAdd[person.classes[index]]![entry.key] = index;
      }
      _backupAdd[course]!.remove(entry.key);
    }
  }

  /// Get a list of people added from backup for a course, accompanied by the
  /// rank of the current backup course
  ///
  /// Returns null if course code does not exist.
  Iterable<MapEntry<String, int>>? _getPeopleAndDataAddFromBackup(
      String course) {
    return _backupAdd[course]?.entries;
  }

  /// Get the number of people added from backup for a course
  ///
  /// Returns null if course code does not exist.
  int? getNbrAddFromBackup(String course) {
    return _backupAdd[course]?.length;
  }

  /// Get a list of people added from backup for a course
  ///
  /// Returns null if course code does not exist.
  Iterable<String>? getPeopleAddFromBackup(String course) {
    return _backupAdd[course]?.keys;
  }
}
