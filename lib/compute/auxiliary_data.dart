import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class AuxiliaryData {
  AuxiliaryData(Courses courses, People people)
      : _courses = courses,
        _people = people;

  final Courses _courses;
  final People _people;

  late final CourseControl _courseControl;

  int? _nbrRequested;
  int? _nbrCourseTakers;

  void initialize(CourseControl courseControl) {
    _courseControl = courseControl;
  }

  /// Reset compute state
  void resetState() {
    _nbrRequested = null;
    _nbrCourseTakers = null;
  }

  /// Get the total number of course takers
  int getNbrCourseTakers() {
    if (_nbrCourseTakers != null) {
      return _nbrCourseTakers!;
    } else {
      _nbrCourseTakers =
          _people.people.values.fold<int>(0, (int previousValue, element) {
        if (element.numClassWanted > 0) {
          return previousValue + 1;
        }
        return previousValue;
      });
      return _nbrCourseTakers!;
    }
  }

  /// Get number of people on leave (not taking classes)
  int getNbrOnLeave() {
    return _people.people.length - getNbrCourseTakers();
  }

  /// Get the total number of courses
  int getNbrGoCourses() {
    return _courses.getNumCourses() - _courseControl.getNbrDropped();
  }

  /// Get the total number of classes asked
  int getNbrPlacesAsked() {
    if (_nbrRequested != null) {
      return _nbrRequested!;
    } else {
      _nbrRequested = 0;
      for (var person in _people.people.values) {
        _nbrRequested = _nbrRequested! + person.numClassWanted;
      }
      return _nbrRequested!;
    }
  }

  /// Get the total number of classes given
  ///
  /// Before scheduling classes, this is always equal to the number of classes
  /// wanted.
  int getNbrPlacesGiven() {
    if (_nbrRequested != null) {
      return _nbrRequested!;
    } else {
      _nbrRequested = 0;
      for (var person in _people.people.values) {
        _nbrRequested = _nbrRequested! + person.numClassWanted;
      }
      return _nbrRequested!;
    }
  }

  /// Get the total number of unmet wants
  int getNbrUnmetWants() {
    return getNbrPlacesAsked() - getNbrPlacesGiven();
  }
}
