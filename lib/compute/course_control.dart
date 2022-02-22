import 'dart:collection';

import 'package:omnilore_scheduler/compute/overview_data.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class CourseControl {
  CourseControl(Courses courses, People people)
      : _courses = courses,
        _people = people;

  // Config
  int _classMinSize = 10;
  int _classMaxSize = 19;
  final HashMap<String, int> _classMaxSizeMap = HashMap<String, int>();
  final HashMap<String, int> _classMinSizeMap = HashMap<String, int>();

  // Shared data
  final People _people;
  final Courses _courses;

  // Internal states
  final _dropped = HashSet<String>();
  final _backupAdd = HashMap<String, HashMap<String, int>>();
  final _affectedMembers = HashMap<String, List<String>>();

  bool? _undersize;
  bool? _oversize;

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
      _affectedMembers[code] = [];
    }
    _undersize = null;
    _oversize = null;
  }

  /// Drop class
  ///
  /// Will do nothing if:
  /// 1. the course is already dropped
  /// 2. the given course does not exist
  void drop(String course) {
    if (_dropped.contains(course)) return;
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
        _affectedMembers[person.classes[index]]!.add(name);
        index++;
      }
      if (index < person.classes.length) {
        _backupAdd[person.classes[index]]![name] = index;
      }
      _affectedMembers[course]!.add(name);
    }
    for (var entry in affectedBackup) {
      var person = _people.people[entry.key]!;
      var index = entry.value + 1;
      while (index < person.classes.length &&
          _dropped.contains(person.classes[index])) {
        _affectedMembers[person.classes[index]]!.add(entry.key);
        index++;
      }
      if (index < person.classes.length) {
        _backupAdd[person.classes[index]]![entry.key] = index;
      }
      _backupAdd[course]!.remove(entry.key);
      _affectedMembers[course]!.add(entry.key);
    }
  }

  /// Undrop class
  ///
  /// Will do nothing if:
  /// 1. the course is already dropped
  /// 2. the given course does not exist
  void undrop(String course) {
    if (!_dropped.contains(course)) return;
    _dropped.remove(course);
    for (var name in _affectedMembers[course]!) {
      var person = _people.people[name]!;
      for (var index = 0; index < person.classes.length; index++) {
        if (!_dropped.contains(person.classes[index])) {
          if (person.classes[index] == course) {
            if (index > 0) {
              _backupAdd[person.classes[index]]![name] = index;
            }
          } else {
            _backupAdd[person.classes[index]]!.remove(name);
            break;
          }
        }
      }
    }
    _affectedMembers[course]!.clear();
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

  /// Get whether there is class to split
  bool hasOversizeClasses(Courses courses, People people) {
    if (_oversize != null) {
      return _oversize!;
    } else {
      for (var course in courses.getCodes()) {
        if (_overviewData.getNbrForClassRank(course, 0)!.size > _classMaxSize) {
          _oversize = true;
          return true;
        }
      }
      _oversize = false;
      return false;
    }
  }

  /// Get whether there is class to drop
  bool hasUndersizeClasses(Courses courses, People people) {
    if (_undersize != null) {
      return _undersize!;
    } else {
      for (var course in courses.getCodes()) {
        if (_overviewData.getNbrForClassRank(course, 0)!.size < _classMinSize) {
          _undersize = true;
          return true;
        }
      }
      _undersize = false;
      return false;
    }
  }

  /// Set global minimum and maximum class size
  ///
  /// Throws [MinLargerThanMaxException] if minSize is larger than maxSize
  void setMinMaxClassSize(int minSize, int maxSize) {
    if (minSize > maxSize) {
      throw MinLargerThanMaxException(min: minSize, max: maxSize);
    }
    _classMaxSize = maxSize;
    _classMinSize = minSize;
    _oversize = null;
    _undersize = null;
  }

  /// Set maximum class size for a specific class
  ///
  /// This will overwrite the global configuration. To cancel the specific
  /// class size configuration for a class, pass null for both minSize and
  /// maxSize to this function (I don't think this will be needed).
  ///
  /// Throws [MinLargerThanMaxException] if minSize is larger than maxSize
  void setMinMaxClassSizeForClass(String course, int? minSize, int? maxSize) {
    if (maxSize != null && minSize != null) {
      if (minSize > maxSize) {
        throw MinLargerThanMaxException(min: minSize, max: maxSize);
      }
    }
    if (maxSize == null) {
      _classMaxSizeMap.remove(course);
    } else {
      _classMaxSizeMap[course] = maxSize;
    }
    if (minSize == null) {
      _classMinSizeMap.remove(course);
    } else {
      _classMinSizeMap[course] = minSize;
    }
    _undersize = null;
    _oversize = null;
  }

  /// Get the maximum class size for a class
  ///
  /// Returns the global maximum class size if no specific class size is set for
  /// the class.
  int getMaxClassSize(String course) {
    return _classMaxSizeMap[course] ?? _classMaxSize;
  }

  /// Get the minimum class size for a class
  ///
  /// Returns the global minimum class size if no specific class size is set for
  /// the class.
  int getMinClassSize(String course) {
    return _classMinSizeMap[course] ?? _classMinSize;
  }
}
