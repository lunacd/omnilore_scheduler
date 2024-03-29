import 'dart:core';
import 'dart:math';

import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';
import 'package:tuple/tuple.dart';

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

  SplitControl(Courses courses, People people)
      : _people = people,
        _courses = courses;

  late final Scheduling _scheduling;

  int _max = 0;
  final List<Set<String>> _clusters = [];
  late List<String> _peopleToSplit;
  late List<String> _peopleInBackup;
  final People _people;
  final Courses _courses;
  late int _numSplits;
  late int _maxSplitSize;
  int _baseOffset = 0;
  int _backupOffset = 0;
  int _saveTest = 0;

  /// Keeps history of performed splits
  final List<Tuple2<List<Set<String>>, String>> _history = [];

  /// Each person has a row
  /// Second last column holds the number of people in this row
  /// Last column holds the total number of can't attends
  late List<List<int>> _splitMatrix;

  /// 0 index holds the index before (including) which the number of can't
  /// attends are 0
  late List<int> _clusterArray;

  /// Matrix that stores the correlation between each pair of people
  /// Only half of the matrix is used but that's okay
  late List<List<int>> _correlateMatrix;

  /// Sorted array of people's number of availabilities
  final List<int> _sortArray = [];
  int _nonZeroCount = 0;

  /// Array of correlations
  late List<int> _testArray;

  /// Currently discovered best _testArray
  List<int> _bestTestArray = [];

  /// Rotating priority
  late List<int> _rot;

  /// Late initialize Scheduling
  void initialize(Scheduling scheduling) {
    _scheduling = scheduling;
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

  /// Get split history
  List<Tuple2<List<Set<String>>, String>> getHistory() {
    return _history;
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
  void split(String course, {noCompute = false}) {
    var result = getSplitResult(course);
    if (result.isEmpty) return;

    // Update people's choices
    for (var splitIndex = 0; splitIndex < result.length; splitIndex++) {
      for (var person in result[splitIndex]) {
        var classIndex = _people.people[person]!.firstChoices
            .indexWhere((element) => element == course);
        if (classIndex != -1) {
          _people.people[person]!.firstChoices.replaceRange(
              classIndex, classIndex + 1, ['$course${splitIndex + 1}']);
        } else {
          classIndex = _people.people[person]!.backups
              .indexWhere((element) => element == course);
          _people.people[person]!.backups.replaceRange(
              classIndex, classIndex + 1, ['$course${splitIndex + 1}']);
        }
      }
    }

    // Update backups with correlation
    for (var i = 0; i < _peopleInBackup.length; i++) {
      var cluster = _findBestCluster(i + _backupOffset, false, true);
      var classIndex = _people.people[_peopleInBackup[i]]!.backups
          .indexWhere((element) => element == course);
      _people.people[_peopleInBackup[i]]!.backups.replaceRange(
          classIndex, classIndex + 1, ['$course${cluster - _baseOffset + 1}']);
    }

    // Update course data
    _courses.splitCourse(course, result.length);

    if (!noCompute) {
      _scheduling.compute(Change.course);
    }
    resetState();
  }

  /// Compute the result of splitting without implementing the split
  List<Set<String>> getSplitResult(String course) {
    var clusterData = List<Set<String>>.from(_clusters);
    _history.add(Tuple2(clusterData, course));

    if (course.length != 3) throw UnexpectedFatalException();
    _peopleToSplit = List.from(
        _scheduling.overviewData.getPeopleForResultingClass(course),
        growable: false);
    _peopleInBackup = _people.people.values
        .where((person) =>
            person.firstChoices.contains(course) ||
            person.backups.contains(course))
        .map((person) => person.getName())
        .where((name) => !_peopleToSplit.contains(name))
        .toList(growable: false);
    _max = _scheduling.courseControl.getMaxClassSize(course);
    _numSplits = (_peopleToSplit.length / _max).ceil();
    _maxSplitSize = (_peopleToSplit.length / _numSplits).ceil();
    _splitMatrix = List<List<int>>.generate(
        _peopleToSplit.length + _peopleInBackup.length + _numSplits,
        (_) => List<int>.filled(22, 0, growable: false),
        growable: false);
    _clusterArray = List<int>.filled(_clusters.length, -1, growable: false);
    _correlateMatrix = List<List<int>>.generate(_peopleToSplit.length,
        (_) => List<int>.filled(_peopleToSplit.length, 0, growable: false),
        growable: false);
    _testArray = List<int>.filled(_numSplits, 0, growable: false);
    _baseOffset = _peopleToSplit.length + _peopleInBackup.length;
    _backupOffset = _peopleToSplit.length;
    _rot = List<int>.generate(_numSplits, (index) => index);
    _bestTestArray.clear();

    if (_numSplits == 1) return [];

    _loadSplitMatrix();
    _loadClusterArray();
    _sortSplitArray();
    _genPairMatrix();
    _generalCorrelate(1, 0);
    _moveBases();
    _formGroups();
    _assignRemnants();

    var result = List<Set<String>>.generate(_numSplits, (_) => <String>{});
    for (var personIndex = 0;
        personIndex < _peopleToSplit.length;
        personIndex++) {
      if (_splitMatrix[personIndex][numPeople] != 0) {
        throw UnexpectedFatalException();
      }
      result[_splitMatrix[personIndex][numUnavail] - _baseOffset]
          .add(_peopleToSplit[personIndex]);
    }
    return result;
  }

  /// Get cluster index given a person's name
  int getClusterIndex(String person) {
    for (int i = 0; i < _clusters.length; i++) {
      if (_clusters[i].contains(person)) {
        return i;
      }
    }
    return -1;
  }

  /// Initializes _splitMatrix with people's can't attends
  void _loadSplitMatrix() {
    for (int i = 0; i < _peopleToSplit.length; i++) {
      var personData = _people.people[_peopleToSplit[i]]!;
      var unavailableCount = 0;
      for (var timeIdx = 0; timeIdx < 20; timeIdx++) {
        if (!personData.availability[timeIdx]) {
          _splitMatrix[i][timeIdx] = 1;
          unavailableCount += 1;
        }
      }

      _splitMatrix[i][numPeople] = 1;
      _splitMatrix[i][numUnavail] = unavailableCount;
    }
    for (int i = 0; i < _peopleInBackup.length; i++) {
      var personData = _people.people[_peopleInBackup[i]]!;
      var unavailableCount = 0;
      for (var timeIdx = 0; timeIdx < 20; timeIdx++) {
        if (!personData.availability[timeIdx]) {
          _splitMatrix[i + _backupOffset][timeIdx] = 1;
          unavailableCount += 1;
        }
      }

      _splitMatrix[i + _backupOffset][numPeople] = 1;
      _splitMatrix[i + _backupOffset][numUnavail] = unavailableCount;
    }
  }

  /// Load _clusterArray with given clusters
  void _loadClusterArray() {
    for (var clusterIndex = 0;
        clusterIndex < _clusters.length;
        clusterIndex++) {
      for (var person in _clusters[clusterIndex]) {
        var personIndex = _peopleToSplit.indexOf(person);
        if (personIndex == -1) continue;
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
    for (var i = 0; i < _peopleToSplit.length; i++) {
      if (_splitMatrix[i][numPeople] == 0 &&
          _splitMatrix[i][numUnavail] == personIndex) {
        _splitMatrix[i][numUnavail] = clusterPosition;
      }
    }
  }

  /// Sort the split array by the number of can't attends
  void _sortSplitArray() {
    _sortArray.clear();
    for (var splitIndex = 0; splitIndex < _peopleToSplit.length; splitIndex++) {
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
        _nonZeroCount = i + 1;
        break;
      }
    }
    for (var i = 0; i < _numSplits; i++) {
      _bestTestArray.add(_sortArray[i] % 256);
    }
  }

  /// Generate a correlation matrix for each pair of people
  void _genPairMatrix() {
    for (var i = 0; i < _nonZeroCount; i++) {
      var person1 = _sortArray[i] % 256;
      for (var j = i + 1; j < _nonZeroCount; j++) {
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
    var end = _nonZeroCount - _numSplits + level;
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
    for (var i = 0; i < _numSplits; i++) {
      var person1 = _testArray[i];
      for (var j = i + 1; j < _numSplits; j++) {
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
      _putPersonInCluster(person, personIndex + _baseOffset);
    }
  }

  /// Assign people with non-zero can't attends to the splits
  void _formGroups() {
    var finished = false;
    var firstRound = true;

    while (!finished) {
      finished = true;
      for (var i = 0; i < _nonZeroCount; i++) {
        var person = _sortArray[i] % 256;
        if (_splitMatrix[person][numPeople] != 0) {
          // Person has not been assigned yet
          finished = false;
          var clusterPos = _findBestCluster(person, firstRound, false);
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
  int _findBestCluster(int person, bool firstRound, bool bypass) {
    // First is split index, second is affected count, third is total count
    List<Tuple3<int, int, int>> rankings = [];

    for (var splitIndex = 0; splitIndex < _numSplits; splitIndex++) {
      var clusterPos = _baseOffset + splitIndex;
      var tempCount =
          _splitMatrix[clusterPos][numPeople] + _splitMatrix[person][numPeople];
      if (tempCount <= _maxSplitSize || bypass) {
        // Compute affected availability
        var affectedCount = 0;
        for (var timeIndex = 0; timeIndex < 20; timeIndex++) {
          if (_splitMatrix[clusterPos][timeIndex] == 0 &&
              _splitMatrix[person][timeIndex] != 0) {
            affectedCount += 1;
          }
        }
        var totalCount = affectedCount + _splitMatrix[clusterPos][numUnavail];
        rankings.add(Tuple3(clusterPos, affectedCount, totalCount));
      }
    }

    if (rankings.length < 2) {
      return rankings[0].item1;
    }

    // Sort rankings
    rankings.sort((Tuple3<int, int, int> a, Tuple3<int, int, int> b) {
      if (a.item2 < b.item2) {
        return -1;
      } else if (a.item2 == b.item2) {
        if (a.item3 < b.item3) {
          return -1;
        } else if (a.item3 == b.item3) {
          return _rot[a.item1 - _baseOffset]
              .compareTo(_rot[b.item1 - _baseOffset]);
        } else {
          return 1;
        }
      } else {
        return 1;
      }
    });

    // Determine split
    if (rankings[0].item2 == 0) {
      // If addition of this person does not affect a split's availability,
      // return the first in ranking
      // If the first is ambiguous on both affected and total count, rotate the
      // priority resolver
      if (rankings[0].item2 == rankings[1].item2 &&
          rankings[0].item3 == rankings[1].item3) {
        var first = _rot[0];
        _rot.removeAt(0);
        _rot.add(first);
      }
      return rankings[0].item1;
    } else {
      // If no zero affect choice is available, favor least number of total
      // unavailability
      rankings.sort((Tuple3<int, int, int> a, Tuple3<int, int, int> b) {
        if (a.item3 < b.item3) {
          return -1;
        } else if (a.item3 == b.item3) {
          if (a.item2 < b.item2) {
            return -1;
          } else if (a.item2 == b.item2) {
            return _rot[a.item1 - _baseOffset]
                .compareTo(_rot[b.item1 - _baseOffset]);
          } else {
            return 1;
          }
        } else {
          return 1;
        }
      });
      // If ambiguous, rotate priority resolver
      if (rankings[0].item2 == rankings[1].item2 &&
          rankings[0].item3 == rankings[1].item3) {
        if (firstRound) {
          // Delay decision in the first round
          return -1;
        } else {
          var first = _rot[0];
          _rot.removeAt(0);
          _rot.add(first);
        }
      }
      return rankings[0].item1;
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
      for (var personIndex = 0; personIndex < _backupOffset; personIndex++) {
        if (_splitMatrix[personIndex][numPeople] == maxNum &&
            _splitMatrix[personIndex][numUnavail] == 0) {
          var minSize = _peopleToSplit.length;
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
}
