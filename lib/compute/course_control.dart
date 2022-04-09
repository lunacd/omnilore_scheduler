import 'dart:collection';

import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/model/coordinators.dart';

enum SplitMode { split, limit }

class CourseControl {
  CourseControl();

  // Config
  int _classMinSize = 8;
  int _classMaxSize = 19;
  final _classMaxSizeMap = HashMap<String, int>();
  final _classMinSizeMap = HashMap<String, int>();
  final _classSplitModeMap = HashMap<String, SplitMode>();
  final _coordinatorsMap = HashMap<String, Coordinators>();

  // Internal states
  final _dropped = HashSet<String>();

  // Readonly access to OverviewData
  late final Scheduling _scheduling;

  /// Late initialize Scheduling
  void initialize(Scheduling scheduling) {
    _scheduling = scheduling;
  }

  /// Drop class
  void drop(String course) {
    _dropped.add(course);
    _scheduling.compute(Change(drop: true));
  }

  /// Undrop class
  void undrop(String course) {
    _dropped.remove(course);
    _scheduling.compute(Change(drop: true));
  }

  Set<String> getDropped() {
    return _dropped;
  }

  /// Set global minimum and maximum class size
  /// Calling this function will overwrite all previously added class-specific
  /// min/max sizes
  ///
  /// Throws [MinLargerThanMaxException] if minSize is larger than maxSize
  void setGlobalMinMaxClassSize(int minSize, int maxSize) {
    if (minSize > maxSize) {
      throw MinLargerThanMaxException(min: minSize, max: maxSize);
    }
    _classMaxSizeMap.clear();
    _classMinSizeMap.clear();
    _classMaxSize = maxSize;
    _classMinSize = minSize;
  }

  /// Set maximum class size for a specific class
  ///
  /// This will overwrite the global configuration.
  ///
  /// Throws [MinLargerThanMaxException] if minSize is larger than maxSize
  void setMinMaxClassSizeForClass(String course, int minSize, int maxSize) {
    if (minSize > maxSize) {
      throw MinLargerThanMaxException(min: minSize, max: maxSize);
    }
    if (maxSize != _classMaxSize) {
      _classMaxSizeMap[course] = maxSize;
    }
    if (minSize != _classMinSize) {
      _classMinSizeMap[course] = minSize;
    }
  }

  /// Determine whether the min class size is mixed for current classes
  bool isMinSizeMixed() {
    return _classMinSizeMap.isNotEmpty;
  }

  /// Determine whether the max class size is mixed for current classes
  bool isMaxSizeMixed() {
    return _classMaxSizeMap.isNotEmpty;
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

  /// Set split mode of a class to the given mode
  void setSplitMode(String course, SplitMode mode) {
    _classSplitModeMap[course] = mode;
  }

  /// Query the current split mode of a class
  SplitMode getSplitMode(String course) {
    return _classSplitModeMap[course] ?? SplitMode.split;
  }

  /// Set main / co-coordinator
  void setMainCoCoordinator(String course, String name) {
    if (_coordinatorsMap.containsKey(course)) {
      if (_coordinatorsMap[course]!.equal) {
        throw const InvalidArgument(
            message: 'Cannot set co-coordinator with equal coordinators set');
      }
      _coordinatorsMap[course]!.coordinators[1] = name;
    }
    _coordinatorsMap[course] = Coordinators(equal: false);
    _coordinatorsMap[course]!.coordinators[0] = name;
  }

  /// Set equal coordinators
  void setEqualCoCoordinator(String course, String name) {
    if (_coordinatorsMap.containsKey(course)) {
      if (!_coordinatorsMap[course]!.equal) {
        throw const InvalidArgument(
            message: 'Cannot set equal co-coordinator with a coordinator set');
      }
      _coordinatorsMap[course]!.coordinators[1] = name;
    }
    _coordinatorsMap[course] = Coordinators(equal: true);
    _coordinatorsMap[course]!.coordinators[0] = name;
  }
}
