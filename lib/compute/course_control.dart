import 'dart:collection';

import 'package:omnilore_scheduler/compute/overview_data.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/courses.dart';

class CourseControl {
  CourseControl(Courses courses) : _courses = courses;

  // Config
  int _classMinSize = 10;
  int _classMaxSize = 19;
  final HashMap<String, int> _classMaxSizeMap = HashMap<String, int>();
  final HashMap<String, int> _classMinSizeMap = HashMap<String, int>();

  // Shared data
  final Courses _courses;

  // Internal states
  final _dropped = HashSet<String>();
  final _backupAdd = HashMap<String, HashMap<String, int>>();
  final _affectedMembers = HashMap<String, List<String>>();

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
  }

  /// Get the number of dropped courses
  int getNbrDropped() {
    return _dropped.length;
  }

  /// Drop class
  void drop(String course) {
    _dropped.add(course);
    _overviewData.compute(Change(drop: true));
  }

  /// Undrop class
  void undrop(String course) {
    _dropped.remove(course);
    _overviewData.compute(Change(drop: true));
  }

  Set<String> getDropped() {
    return _dropped;
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

  /// Set global minimum and maximum class size
  ///
  /// Throws [MinLargerThanMaxException] if minSize is larger than maxSize
  void setMinMaxClassSize(int minSize, int maxSize) {
    if (minSize > maxSize) {
      throw MinLargerThanMaxException(min: minSize, max: maxSize);
    }
    _classMaxSize = maxSize;
    _classMinSize = minSize;
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
