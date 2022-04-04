import 'dart:collection';

import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';

class CourseControl {
  CourseControl();

  // Config
  int _classMinSize = 10;
  int _classMaxSize = 19;
  final HashMap<String, int> _classMaxSizeMap = HashMap<String, int>();
  final HashMap<String, int> _classMinSizeMap = HashMap<String, int>();

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
}
