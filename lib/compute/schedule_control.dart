import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class ScheduleControl {
  ScheduleControl(Courses courses, People people)
      : _courses = courses,
        _people = people;

  final Courses _courses;
  final People _people;
  late final Scheduling _scheduling;

  int _nbrClassrooms = 2;
  final List<List<String>> _schedule =
      List<List<String>>.generate(20, (_) => <String>[], growable: false);
  final Map<String, List<int>> _unavailables = {};

  /// Late initialize Scheduling
  void initialize(Scheduling scheduling) {
    _scheduling = scheduling;
  }

  /// Update internal states in response to changes
  void compute(Change change) {
    // If courses have changed, clear all scheduled times
    if (change.course) {
      for (var i = 0; i < _schedule.length; i++) {
        _schedule[i].clear();
      }
    }
    // If people or course has changed, compute unavailables
    if (change.course || change.people) {
      _unavailables.clear();
      for (var course in _courses.getCodes()) {
        _unavailables[course] = List<int>.filled(20, 0);
        var resultingPeople =
            _scheduling.overviewData.getPeopleForResultingClass(course);
        for (var person in resultingPeople) {
          var personData = _people.people[person]!;
          for (var timeIndex = 0; timeIndex < 20; timeIndex++) {
            if (!personData.availability[timeIndex]) {
              _unavailables[course]![timeIndex] += 1;
            }
          }
        }
      }
    }
  }

  /// Get current number of classrooms
  ///
  /// This determines how many courses can be scheduled together at one time
  /// slot.
  int getNbrClassrooms() {
    return _nbrClassrooms;
  }

  /// Get current number of classrooms
  ///
  /// This determines how many courses can be scheduled together at one time
  /// slot.
  void setNbrClassrooms(int nbr) {
    if (nbr <= 0) {
      throw const InvalidArgument(
          message: 'Number of classrooms have to be larger than 0');
    }
    _nbrClassrooms = nbr;
  }

  /// Query if a class have been scheduled at a given time index
  ///
  /// Course is a 3-digit course code, time index is an index to the time slot
  /// from 0 to 19.
  /// Returns true if course is scheduled at that time slot.
  bool isScheduledAt(String course, int timeIndex) {
    if (timeIndex >= _schedule.length || timeIndex < 0) {
      throw const InvalidArgument(message: 'Time index should be from 0 to 19');
    }
    return _schedule[timeIndex].contains(course);
  }

  /// Query which time slot has the course been scheduled to
  ///
  /// Returns -1 if the course does not exist or if the course has not been
  /// scheduled.
  int scheduledTimeFor(String course) {
    for (var timeIndex = 0; timeIndex < _schedule.length; timeIndex++) {
      if (_schedule[timeIndex].contains(course)) {
        return timeIndex;
      }
    }
    return -1;
  }

  /// Schedule a course to a given time slot
  ///
  /// Course is a 3-digit course code, time index is an index to the time slot
  /// from 0 to 19.
  /// Does nothing if no more classes can be scheduled at the requested time
  /// slot.
  void schedule(String course, int timeIndex) {
    // Check for error
    if (timeIndex >= _schedule.length || timeIndex < 0) {
      throw const InvalidArgument(message: 'Time index should be from 0 to 19');
    }
    if (!_courses.getCodes().contains(course)) {
      throw const InvalidArgument(message: 'Given course does not exist');
    }
    if (_schedule[timeIndex].length >= _nbrClassrooms) {
      return;
    }

    // Remove current assignment
    for (var i = 0; i < _schedule.length; i++) {
      if (_schedule[i].contains(course)) {
        _schedule[i].remove(course);
      }
    }
    
    // Add new assignment
    _schedule[timeIndex].add(course);
    _scheduling.compute(Change(schedule: true));
  }

  /// Unschedule a course at a given time slot
  /// 
  /// Does nothing if the given course is not scheduled at that time slot
  void unschedule(String course, int timeIndex) {
    _schedule[timeIndex].remove(course);
  }

  /// Get the number of people who are unavailable for a given course and time
  /// index
  int getNbrUnavailable(String course, int timeIndex) {
    return _unavailables[course]![timeIndex];
  }
}
