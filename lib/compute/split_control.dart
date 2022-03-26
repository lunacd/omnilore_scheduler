import 'dart:core';
import 'dart:math';

import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/compute/overview_data.dart';
import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/store/people.dart';

/// This class implements an algorithm to find good and equal split among
/// a group of people
///
/// This algorithm is originally devised by John Taber of Omnilore and
/// implemented in Pascal
class SplitControl {
  /// The index into [_splitMatrix] where the number of people per row is stored
  static const numPeople = 20;

  /// The index into [_splitMatrix] where the number of unavailability per row
  /// is stored
  /// When number of people is 0, this index stores the index of the cluster
  /// this person is currently in
  static const numUnavail = 21;

  SplitControl(People people) : _peopleData = people.people;

  late final OverviewData _overviewData;
  late final CourseControl _courseControl;

  /// Late initialize overview data
  void initialize(OverviewData overviewData, CourseControl courseControl) {
    _overviewData = overviewData;
    _courseControl = courseControl;
  }

  /// Reset internal compute state, including clusters
  void resetState() {
    _clusters.clear();
  }

  /// Add the given set of people as one cluster
  /// All clusters passed to this function should be disjoint. If there is need
  /// to expand a previously added cluster, remove first and then add a new one
  void addCluster(Set<String> cluster) {
    _clusters.add(cluster);
  }

  /// Remove the cluster to which the given person belongs
  void removeCluster(String person) {
    for (var index = 0; index < _clusters.length; index++) {
      if (_clusters[index].contains(person)) {
        _clusters.removeAt(index);
      }
    }
  }

  /// Main split routine
  ///
  /// NOTE: This class does NOT support simultaneously splitting multiple
  /// classes, i.e. adding clusters for different classes and splitting one of
  /// them.
  /// The frontend needs to keep track of which class the user is currently
  /// splitting. If user starts to cluster another class, or if they split a
  /// class when they have pending clusters for another class, the frontend
  /// MUST call [resetState] before preceding.
  ///
  /// The given course MUST be a valid 3-digit course code
  void split(String course) {
    if (course.length != 3) throw UnexpectedFatalException();
    _people = List.from(_overviewData.getPeopleForResultingClass(course));
    _max = _courseControl.getMaxClassSize(course);
    _numSplits = (_people.length / _max).ceil();
    _maxSplitSize = (_people.length / _numSplits).ceil();
    _splitMatrix = List<List<int>>.filled(
        _people.length + _numSplits, List<int>.filled(22, 0));
    _clusterArray = List<int>.filled(_clusters.length, -1);
    _correlateMatrix = List<List<int>>.filled(
        _people.length, List<int>.filled(_people.length, 0));
    _testArray = List<int>.filled(_numSplits, 0);
    _baseOffset = _people.length;

    _loadSplitMatrix();
    _loadClusterArray();
    _sortSplitArray();
    _genPairMatrix();
    _generalCorrelate(1, 0);
    _moveBases();
    _formGroups();
    _assignRemnants();

    var result = List<Set<String>>.filled(_numSplits, {});
    for (var personIndex = 0; personIndex < _people.length; personIndex++) {
      if (_splitMatrix[personIndex][numPeople] != 0) {
        throw UnexpectedFatalException();
      }
      result[_splitMatrix[personIndex][numUnavail]].add(_people[personIndex]);
    }
  }

  int _max = 0;
  final List<Set<String>> _clusters = [];
  late List<String> _people;
  final Map<String, Person> _peopleData;
  late final int _numSplits;
  late final int _maxSplitSize;
  int _baseOffset = 0;
  int _saveTest = 0;

  /// Each person has a row
  /// Second last column holds the number of people in this row
  /// Last column holds the total number of can't attends
  late final List<List<int>> _splitMatrix;

  /// 0 index holds the index before (including) which the number of can't
  /// attends are 0
  late final List<int> _clusterArray;

  /// Matrix that stores the correlation between each pair of people
  /// Only half of the matrix is used but that's okay
  late final List<List<int>> _correlateMatrix;

  /// Sorted array of people's number of availabilities
  final List<int> _sortArray = [];

  /// Array of correlations
  late final List<int> _testArray;

  /// Currently discovered best _testArray
  List<int> _bestTestArray = [];

  int _rotNum = 0;

  /// Initializes _splitMatrix with people's can't attends
  void _loadSplitMatrix() {
    for (int i = 0; i < _people.length; i++) {
      var personData = _peopleData[_people[i]]!;
      var unavailableCount = 0;
      for (var week in WeekOfMonth.values) {
        for (var day in DayOfWeek.values) {
          for (var time in TimeOfDay.values) {
            if (!personData.availability.get(week, day, time)) {
              _splitMatrix[i][_getAvailabilityIndex(week, day, time)] = 1;
              unavailableCount += 1;
            }
          }
        }
      }
      _splitMatrix[i][numPeople] = 1;
      _splitMatrix[i][numUnavail] = unavailableCount;
    }
  }

  /// Load _clusterArray with given clusters
  void _loadClusterArray() {
    for (var clusterIndex = 0;
        clusterIndex < _clusters.length;
        clusterIndex++) {
      for (var person in _clusters[clusterIndex]) {
        var personIndex = _people.indexOf(person);
        if (personIndex == -1) throw UnexpectedFatalException();
        var clusterPosition = _clusterArray[clusterIndex];
        if (clusterPosition == -1) {
          _clusterArray[clusterIndex] = personIndex;
        } else {
          _putPersonInCluster(personIndex, clusterPosition);
        }
      }
    }
  }

  /// Put a given person in a given cluster
  void _putPersonInCluster(int personIndex, int clusterPosition) {
    var unavailableCount = 0;
    for (var timeIndex = 0; timeIndex < 20; timeIndex++) {
      if (_splitMatrix[personIndex][timeIndex] != 0) {
        if (_splitMatrix[clusterPosition][timeIndex] == 0) {
          unavailableCount += 1;
        }
        _splitMatrix[clusterPosition][timeIndex] += 1;
        _splitMatrix[personIndex][timeIndex] = 0;
      }
    }
    _splitMatrix[clusterPosition][numUnavail] += unavailableCount;
    _splitMatrix[clusterPosition][numPeople] += 1;
    _splitMatrix[personIndex][numPeople] = 0;
    _splitMatrix[personIndex][numUnavail] = clusterPosition;
    for (var i = 0; i < _people.length; i++) {
      if (_splitMatrix[i][numPeople] == 0 &&
          _splitMatrix[i][numUnavail] == personIndex) {
        _splitMatrix[i][numUnavail] = clusterPosition;
      }
    }
  }

  /// Sort the split array by the number of can't attends
  void _sortSplitArray() {
    _sortArray.clear();
    _sortArray.add(0);
    for (var splitIndex = 0; splitIndex < _splitMatrix.length; splitIndex++) {
      if (_splitMatrix[splitIndex][numPeople] > 0) {
        _sortArray.add(_splitMatrix[splitIndex][numUnavail] * 256 + splitIndex);
      }
    }
    // Sort in decreasing order of can't attends
    _sortArray.sort((int a, int b) {
      if (a < b) return 1;
      if (a == b) return 0;
      return -1;
    });
    // Find the index before which can't attends are all non-zero
    for (var i = _sortArray.length - 1; i > 0; i--) {
      if ((_sortArray[i] / 256).floor() != 0) {
        _sortArray[0] = i;
        break;
      }
    }
  }

  /// Generate a correlation matrix for each pair of people
  void _genPairMatrix() {
    for (var i = 1; i < _sortArray[0]; i++) {
      var person1 = _sortArray[i] % 256;
      for (var j = i + 1; j <= _sortArray[0]; j++) {
        var person2 = _sortArray[j] % 256;
        var value = _correlatePair(person1, person2);
        _correlateMatrix[min(person1, person2)][max(person1, person2)] = value;
      }
    }
  }

  /// Return the "negative" correlation between two people's can't attends
  ///
  /// The result will be larger for pairs of less similar can't attends
  int _correlatePair(int person1, int person2) {
    var count1 = 0;
    var count2 = 0;
    for (var i = 0; i < 20; i++) {
      var bool1 = _splitMatrix[person1][i] == 0;
      var bool2 = _splitMatrix[person2][i] == 0;
      if (bool1 && !bool2) {
        count1 += 1;
      }
      if (!bool1 && bool2) {
        count2 += 1;
      }
    }
    return count1 * count2;
  }

  /// Recursive routine that finds _numSplits number of people as the split
  /// leaders
  ///
  /// It aims for people with the most diverse can't attend patterns
  void _generalCorrelate(int startIndex, int level) {
    var end = _sortArray[0] - _numSplits + level;
    for (var i = startIndex; i <= end; i++) {
      var person = _sortArray[i] % 256;
      _testArray[level] = person;
      if (level == _numSplits - 1) {
        _correlateAndSave();
      } else {
        _generalCorrelate(i + 1, level + 1);
      }
    }
  }

  /// Save the most diverse groups of split leaders
  void _correlateAndSave() {
    var sum = _correlateMultiple();
    if (sum > _saveTest) {
      _saveTest = sum;
      _bestTestArray = List<int>.from(_testArray);
    }
  }

  /// Calculate the total "negative" correlation between a group of people
  int _correlateMultiple() {
    var size = 0;
    for (var i = 1; i < _numSplits; i++) {
      var person1 = _testArray[i];
      for (var j = i + 1; j <= _numSplits; j++) {
        var person2 = _testArray[j];
        size += _correlateMatrix[min(person1, person2)][max(person1, person2)];
      }
    }
    return size;
  }

  /// Generate _numSplits number of records for splits
  void _moveBases() {
    for (var personIndex = 0; personIndex < _numSplits; personIndex++) {
      var person = _bestTestArray[personIndex];
      _splitMatrix.add(List<int>.from(_splitMatrix[person]));
      _splitMatrix[person][numPeople] = 0;
      _splitMatrix[person][numUnavail] = _baseOffset + personIndex;
      for (var i = 0; i < _people.length; i++) {
        if (_splitMatrix[i][numPeople] == 0 &&
            _splitMatrix[i][numUnavail] == person) {
          _splitMatrix[i][numUnavail] = _baseOffset + personIndex;
        }
      }
    }
  }

  /// Assign people with non-zero can't attends to the splits
  void _formGroups() {
    var finished = false;
    _rotNum = 0;
    var firstRound = true;

    while (!finished) {
      finished = true;
      for (var i = 1; i < _sortArray[0]; i++) {
        var person = _sortArray[i] % 256;
        if (_splitMatrix[person][numPeople] != 0) {
          // Person has not been assigned yet
          finished = false;
          var clusterPos = _findBestCluster(person, firstRound);
          if (clusterPos > 0) {
            // If found conclusive cluster
            _putPersonInCluster(person, clusterPos);
          }
        }
      }
      firstRound = false;
    }
  }

  /// Find and return the best split for a person to be assigned to
  ///
  /// Returns -1 when it wants to postpone the decision. Only possible when
  /// firstRound = true
  int _findBestCluster(int person, bool firstRound) {
    // 21 is used as "infinity" as the count below is 20 max
    var baseOffset = _people.length;

    // Store the two least increase in the number of availabilities
    var splitAffected = List<int>.filled(2, 21, growable: false);

    // Store the two least total number of availabilities
    var totSplit = List<int>.filled(2, 21, growable: false);

    // lastSplit[0] stores the split with least increase in unavailability
    // lastSplit[1] stores the split with least total unavailability
    List<int> lastSplit = [0, _rotNum % _numSplits + baseOffset];

    for (var splitIndex = 0; splitIndex < _numSplits; splitIndex++) {
      var currentSplit = (splitIndex + _rotNum) % _numSplits + baseOffset;
      var tempCount = _splitMatrix[currentSplit][numPeople] +
          _splitMatrix[person][numPeople];
      if (tempCount < _maxSplitSize) {
        // Compute affected availability
        var affectedCount = 0;
        for (var timeIndex = 0; timeIndex < 20; timeIndex++) {
          if (_splitMatrix[currentSplit][timeIndex] == 0 &&
              _splitMatrix[person][timeIndex] != 0) {
            affectedCount += 1;
          }
        }

        // Update splitSum and totSplit
        if (affectedCount < splitAffected[0]) {
          splitAffected[1] = splitAffected[0];
          splitAffected[0] = affectedCount;
          lastSplit[0] = currentSplit;
        } else if (affectedCount < splitAffected[1]) {
          splitAffected[1] = affectedCount;
        }
        var totalCount = affectedCount + _splitMatrix[currentSplit][numUnavail];
        if (totalCount < totSplit[0]) {
          totSplit[1] = totSplit[0];
          totSplit[0] = totalCount;
          lastSplit[1] = currentSplit;
        } else if (totalCount < totSplit[1]) {
          totSplit[1] = totalCount;
        }
      }
    }

    // Determine split
    if (splitAffected[0] == 0 && splitAffected[2] != 0) {
      // If addition of this person does not affect a split's availability and
      // such a split is unambiguous
      return lastSplit[0];
    } else if (splitAffected[0] == 0 && splitAffected[1] == 0) {
      // If addition of this person does not affect a split's availability but
      // such a split is unambiguous
      if (totSplit[0] < totSplit[1]) {
        // If total amount of availabilities are unambiguous
        return lastSplit[1];
      } else {
        // Pick lastSplit[0] and rotate
        // Incrementing rotNum will result in the next call inspecting splits
        // in different order, and thus breaking ties differently.
        _rotNum += 1;
        return lastSplit[0];
      }
    } else {
      // If no zero affect choice is available
      if (totSplit[0] < totSplit[1]) {
        // Favor least number of total unavailability
        return lastSplit[1];
      } else {
        // If least number of total unavailability is ambiguous
        if (splitAffected[0] < splitAffected[1]) {
          return lastSplit[0];
        } else {
          if (firstRound) {
            // In first round, delay decision
            return -1;
          } else {
            _rotNum += 1;
            return lastSplit[1];
          }
        }
      }
    }
  }

  /// Assign the remaining people with zero can't attends to the splits
  void _assignRemnants() {
    var maxNum = 0;
    var clusterPos = 0;
    // Find largest cluster size
    for (var personIndex = 0;
        personIndex < _splitMatrix.length;
        personIndex++) {
      if (_splitMatrix[personIndex][numPeople] != 0 &&
          _splitMatrix[personIndex][numUnavail] == 0) {
        var addNum = _splitMatrix[personIndex][numPeople];
        if (addNum > maxNum) {
          maxNum = addNum;
        }
      }
    }
    // Process clusters from the largest to the smallest
    while (maxNum > 0) {
      for (var personIndex = 0;
          personIndex < _splitMatrix.length;
          personIndex++) {
        if (_splitMatrix[personIndex][numPeople] == maxNum &&
            _splitMatrix[personIndex][numUnavail] == 0) {
          var minSize = _people.length;
          for (var splitIndex = 0; splitIndex < _numSplits; splitIndex++) {
            var theSplit = splitIndex + _baseOffset;
            var splitSize = _splitMatrix[theSplit][numPeople];
            if (splitSize < minSize) {
              minSize = splitSize;
              clusterPos = theSplit;
            }
          }
          _putPersonInCluster(personIndex, clusterPos);
        }
      }
      maxNum -= 1;
    }
  }

  int _getAvailabilityIndex(WeekOfMonth week, DayOfWeek day, TimeOfDay time) {
    return week.index * 10 + day.index * 2 + time.index;
  }
}
