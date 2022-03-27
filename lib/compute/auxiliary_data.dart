import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class AuxiliaryData {
  AuxiliaryData(Courses courses, People people)
      : _courses = courses,
        _people = people;

  final Courses _courses;
  final People _people;

  late final Scheduling _scheduling;

  int _nbrRequested = 0;
  int _nbrOnLeave = 0;
  int _nbrCourseTakers = 0;
  int _nbrGoCourse = 0;

  void initialize(Scheduling scheduling) {
    _scheduling = scheduling;
  }

  /// Compute auxiliary data
  ///
  /// Depends on course, people, drop, and schedule
  void compute(Change change) {
    if (change.people || change.course) {
      _nbrCourseTakers =
          _people.people.values.fold<int>(0, (int previousValue, element) {
        if (element.nbrClassWanted > 0) {
          return previousValue + 1;
        }
        return previousValue;
      });
      _nbrOnLeave = _people.people.length - _nbrCourseTakers;
      _nbrRequested = 0;
      for (var person in _people.people.values) {
        _nbrRequested = _nbrRequested + person.nbrClassWanted;
      }
    }
    if (change.drop) {
      _nbrGoCourse =
          _courses.getNumCourses() - _scheduling.courseControl.getNbrDropped();
    }
    if (change.schedule) {
      // TODO: Update num course given
    }
  }

  /// Get the total number of course takers
  int getNbrCourseTakers() {
    return _nbrCourseTakers;
  }

  /// Get number of people on leave (not taking classes)
  int getNbrOnLeave() {
    return _nbrOnLeave;
  }

  /// Get the total number of courses
  int getNbrGoCourses() {
    return _nbrGoCourse;
  }

  /// Get the total number of classes asked
  int getNbrPlacesAsked() {
    return _nbrRequested;
  }

  /// Get the total number of classes given
  ///
  /// Before scheduling classes, this is always equal to the number of classes
  /// wanted.
  int getNbrPlacesGiven() {
    return _nbrRequested;
  }

  /// Get the total number of unmet wants
  int getNbrUnmetWants() {
    return getNbrPlacesAsked() - getNbrPlacesGiven();
  }
}
