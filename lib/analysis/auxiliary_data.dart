import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class AuxiliaryData {
  AuxiliaryData(Courses courses, People people)
      : _courses = courses,
        _people = people;

  final Courses _courses;
  final People _people;

  int? _numRequested;

  /// Reset compute state
  void resetState() {
    _numRequested = null;
  }

  /// Get the total number of courses
  int getNbrGoCourses() {
    return _courses.getNumCourses();
  }

  /// Get the total number of classes asked
  int getNbrPlacesAsked() {
    if (_numRequested != null) {
      return _numRequested!;
    } else {
      _numRequested = 0;
      for (var person in _people.people.values) {
        _numRequested = _numRequested! + person.numClassWanted;
      }
      return _numRequested!;
    }
  }

  /// Get the total number of classes given
  ///
  /// Before scheduling classes, this is always equal to the number of classes
  /// wanted.
  int getNbrPlacesGiven() {
    if (_numRequested != null) {
      return _numRequested!;
    } else {
      _numRequested = 0;
      for (var person in _people.people.values) {
        _numRequested = _numRequested! + person.numClassWanted;
      }
      return _numRequested!;
    }
  }

  /// Get the total number of unmet wants
  int getNbrUnmetWants() {
    return getNbrPlacesAsked() - getNbrPlacesGiven();
  }
}
