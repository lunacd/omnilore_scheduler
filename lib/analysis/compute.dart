import 'dart:collection';

import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class Compute {
  final int _classMinSize = 10;
  final int _classMaxSize = 19;

  final _choices = HashMap<String, List<HashSet<String>>?>();
  bool? _undersize;
  bool? _oversize;
  final _dropped = HashSet<String>();
  final _backupAdd = HashMap<String, HashMap<String, int>>();

  /// Reset computing state
  void resetState(Courses courses) {
    _choices.clear();
    for (var code in courses.getCodes()) {
      _choices[code] = null;
      _backupAdd[code] = HashMap<String, int>();
    }
    _oversize = null;
    _undersize = null;
  }

  /// Get the number people who has listed a given course as their nth choice
  /// (rank)
  ///
  /// Throws [InvalidClassRankException] if the given rank is not in 0 to 5,
  /// inclusive.
  /// Throws [UnexpectedFatalException] if the people and course files are not
  /// consistent.
  ///
  /// Returns null if course code does not exist.
  ///
  /// The first call to this function after a course/people load might take
  /// longer. All subsequent calls use cached results and will return
  /// instantaneously.
  int? getNumChoices(int rank, String course, People people) {
    if (rank < 0 || rank > 5) {
      throw InvalidClassRankException(rank: rank);
    }
    if (!_choices.containsKey(course)) {
      return null;
    } else {
      var choices = _choices[course];
      if (choices == null) {
        _computeChoices(rank, people);
        return _choices[course]![rank].length;
      } else {
        return choices[rank].length;
      }
    }
  }

  /// Compute number of choices for all classes at at given rank
  void _computeChoices(int rank, People people) {
    for (var person in people.people.values) {
      if (rank < person.classes.length) {
        var course = person.classes[rank];
        if (_choices.containsKey(course)) {
          if (_choices[course] == null) {
            _choices[course] = List<HashSet<String>>.generate(
                6, (index) => HashSet<String>(),
                growable: false);
          }
          _choices[course]![rank].add(person.getName());
        } else {
          // This should never happen
          throw UnexpectedFatalException(); // coverage:ignore-line
        }
      }
    }
    for (var course in _choices.keys) {
      if (_choices[course] == null) {
        _choices[course] = List<HashSet<String>>.generate(
            6, (index) => HashSet<String>(),
            growable: false);
      }
    }
  }

  /// Get a list of people who selected a given class as their nth choice (rank)
  ///
  /// Throws [InvalidClassRankException] if the given rank is not in 0 to 5,
  /// inclusive.
  /// Throws [UnexpectedFatalException] if the people and course files are not
  /// consistent.
  ///
  /// Returns null if course code does not exist.
  ///
  /// The first call to this function after a course/people load might take
  /// longer. All subsequent calls use cached results and will return
  /// instantaneously.
  Iterable<String>? getPeopleForClassRank(
      int rank, String course, People people) {
    if (rank < 0 || rank > 5) {
      throw InvalidClassRankException(rank: rank);
    }
    if (!_choices.containsKey(course)) {
      return null;
    } else {
      var choices = _choices[course];
      if (choices == null) {
        _computeChoices(rank, people);
        return _choices[course]![rank].toList(growable: false);
      } else {
        return choices[rank].toList(growable: false);
      }
    }
  }

  /// Get the number of people added from backup for a course
  ///
  /// Returns null if course code does not exist.
  int? getNumAddFromBackup(String course) {
    return _backupAdd[course]?.length;
  }

  /// Get a list of people added from backup for a course
  ///
  /// Returns null if course code does not exist.
  Iterable<MapEntry<String, int>>? getPeopleAddFromBackup(String course) {
    return _backupAdd[course]?.entries;
  }

  /// Get whether there is class to split
  bool hasOversizeClasses(Courses courses, People people) {
    if (_oversize != null) {
      return _oversize!;
    } else {
      for (var course in courses.getCodes()) {
        if (getNumChoices(0, course, people)! > _classMaxSize) {
          _oversize = true;
          return true;
        }
      }
      _oversize = false;
      return false;
    }
  }

  /// Get whether there is class to drop
  bool hasUndersizeClassed(Courses courses, People people) {
    if (_undersize != null) {
      return _undersize!;
    } else {
      for (var course in courses.getCodes()) {
        if (getNumChoices(0, course, people)! < _classMinSize) {
          _undersize = true;
          return true;
        }
      }
      _undersize = false;
      return false;
    }
  }

  /// Drop class
  void drop(String course, People people) {
    _dropped.add(course);
    var affectedFirstChoice = getPeopleForClassRank(0, course, people);
    if (affectedFirstChoice == null) {
      return;
    }
    var affectedBackup =
        List<MapEntry<String, int>>.from(getPeopleAddFromBackup(course)!);

    for (var name in affectedFirstChoice) {
      var person = people.people[name]!;
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
      var person = people.people[entry.key]!;
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
}
