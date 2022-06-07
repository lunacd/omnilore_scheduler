import 'dart:io';

import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/compute/overview_data.dart';
import 'package:omnilore_scheduler/compute/schedule_control.dart';
import 'package:omnilore_scheduler/compute/split_control.dart';
import 'package:omnilore_scheduler/compute/validate.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/course.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/store/courses.dart';
import 'package:omnilore_scheduler/store/people.dart';

class Scheduling {
  Scheduling() {
    overviewData = OverviewData(_courses, _people);
    courseControl = CourseControl(_courses);
    splitControl = SplitControl(_courses, _people);
    scheduleControl = ScheduleControl(_courses, _people);

    courseControl.initialize(this);
    overviewData.initialize(this);
    splitControl.initialize(this);
    scheduleControl.initialize(this);
  }

  // Shared data
  final _courses = Courses();
  final _people = People();
  final _validate = Validate();

  // Compute modules
  late OverviewData overviewData;
  late CourseControl courseControl;
  late SplitControl splitControl;
  late ScheduleControl scheduleControl;

  StateOfProcessing _state = StateOfProcessing.needCourses;

  /// Compute all submodules
  void compute(Change change) {
    overviewData.compute(change);
    scheduleControl.compute(change);
    courseControl.compute(change);
    _updateStateOfProcessing();
  }

  /// Get an iterable list of course codes
  ///
  /// ```dart
  /// for (var code in scheduling.getCourseCodes()) {}
  /// ```
  Iterable<String> getCourseCodes() {
    return _courses.getCodes();
  }

  /// Get course information given a course code
  Course? getCourse(String code) {
    return _courses.getCourse(code);
  }

  /// Loads courses from a text file
  ///
  /// Throws a [FileSystemException] when the given input file does not exist.
  /// Throws a [MalformedCourseFileException] when the input file is incorrectly
  /// formatted.
  /// Throws a [DuplicateCourseCodeException] when the input file specifies a
  /// course code more than once.
  /// Throws a [InconsistentCourseAndPeopleException] when people and the course
  /// schedule are inconsistent.
  ///
  /// Asynchronously returns the number of courses successfully read.
  /// ```dart
  /// int numCourses = await scheduling.loadCourses('/path/to/file');
  /// ```
  Future<int> loadCourses(String inputFile) async {
    if (_courses.getNumCourses() != 0) {
      throw UnexpectedFatalException();
    }
    int numCourses;
    numCourses = await _courses.loadCourses(inputFile);
    if (numCourses != 0) {
      compute(Change.course);
    }
    return numCourses;
  }

  /// Get a list of people, ordered as is presented in the input file
  Iterable<Person> getPeople() {
    return _people.people.values;
  }

  /// Get the number of people
  int getNumPeople() {
    return _people.people.length;
  }

  /// Load people from a text file
  ///
  /// Throws a [FileSystemException] when the given input file does not exist.
  /// Throws a [MalformedPeopleFileException] when the input file has wrong
  /// number of columns.
  /// Throws a [InvalidNumClassWantedException] when the input file specifies a
  /// number of classes wanted less than 0 or more than 6.
  /// Throws a [UnrecognizedAvailabilityException] when the input file specifies an
  /// availability value other than empty, 1, 2, or 3.
  /// Throws a [DuplicateClassSelectionException] when a person selects a class
  /// more than once.
  /// Throws a [InconsistentCourseAndPeopleException] when people and the course
  /// schedule are inconsistent.
  ///
  /// Throws a [UnexpectedFatalException] if loaded people before course or if
  /// has loaded people already.
  ///
  /// Asynchronously returns the number of people successfully read.
  ///
  /// ```dart
  /// int numPeople = await people.loadPeople('/path/to/file');
  /// ```
  Future<int> loadPeople(String inputFile) async {
    if (_courses.getNumCourses() == 0 || _people.people.isNotEmpty) {
      throw UnexpectedFatalException();
    }
    var numPeople = await _people.loadPeople(inputFile);
    if (numPeople != 0) {
      var result =
          _validate.validatePeopleAgainstCourses(_people.people, _courses);
      if (result != null) {
        throw InconsistentCourseAndPeopleException(message: result);
      }
      compute(Change.people);
    }
    return numPeople;
  }

  /// Get the current state of processing
  StateOfProcessing getStateOfProcessing() {
    return _state;
  }

  void _updateStateOfProcessing() {
    if (!_validate.isValid()) {
      _state = StateOfProcessing.inconsistent;
    } else if (_courses.getNumCourses() == 0) {
      _state = StateOfProcessing.needCourses;
    } else if (_people.people.isEmpty) {
      _state = StateOfProcessing.needPeople;
    } else if (overviewData.hasUndersizeClasses(_courses)) {
      _state = StateOfProcessing.drop;
    } else if (overviewData.hasOversizeClasses(_courses)) {
      _state = StateOfProcessing.split;
    } else if (!scheduleControl.allClassScheduled()) {
      _state = StateOfProcessing.schedule;
    } else if (!courseControl.allCourseHasCoordinators()) {
      _state = StateOfProcessing.coordinator;
    } else {
      _state = StateOfProcessing.output;
    }
  }

  /// Output roster with CC information
  void outputRosterCC(String path) {
    if (getStateOfProcessing() != StateOfProcessing.output) return;
    var content = '';
    var goCourses = courseControl.getGo().toList(growable: false);
    goCourses.sort((a, b) => a.compareTo(b));
    for (var course in goCourses) {
      var courseData = _courses.getCourse(course);
      int timeSlot = scheduleControl.scheduledTimeFor(course);
      var people = overviewData
          .getPeopleForResultingClass(course)
          .map((name) => _people.people[name]!)
          .toList(growable: false);
      people.sort((a, b) => a.getReversedName().compareTo(b.getReversedName()));
      var cc = courseControl.getCoordinators(course)!;

      content += '${courseData.name}\n';
      content += '$course\t${getTimeslotDescription(timeSlot)}\n\n';

      for (var person in people) {
        if (person.getName() == cc.coordinators[0] && !cc.equal) {
          content += '${person.getReversedName()} (C)\n';
        } else if (person.getName() == cc.coordinators[0] ||
            person.getName() == cc.coordinators[1]) {
          content += '${person.getReversedName()} (CC)\n';
        } else {
          content += '${person.getReversedName()}\n';
        }
      }
      if (course != goCourses.last) {
        content += '\n\n';
      }
    }
    var output = File(path);
    output.writeAsStringSync(content);
  }

  /// Output roster with phone number
  void outputRosterPhone(String path) {
    var state = getStateOfProcessing();
    if (state != StateOfProcessing.coordinator &&
        state != StateOfProcessing.output) return;
    var content = '';
    var goCourses = courseControl.getGo().toList(growable: false);
    goCourses.sort((a, b) => a.compareTo(b));
    for (var course in goCourses) {
      var courseData = _courses.getCourse(course);
      int timeSlot = scheduleControl.scheduledTimeFor(course);
      var people = overviewData
          .getPeopleForResultingClass(course)
          .map((name) => _people.people[name]!)
          .toList(growable: false);
      people.sort((a, b) => a.getReversedName().compareTo(b.getReversedName()));

      content += '${courseData.name}\n';
      content += '$course\t${getTimeslotDescription(timeSlot)}\n\n';
      for (var person in people) {
        var personString = person.getReversedName();
        content += personString;
        var padding = ' ' * (_people.maxLength - personString.length);
        content += padding;
        content += person.phone;
        content += '\n';
      }
      if (course != goCourses.last) {
        content += '\n\n';
      }
    }
    var output = File(path);
    output.writeAsStringSync(content);
  }

  /// Output mail merge file
  void outputMM(String path) {
    if (getStateOfProcessing() != StateOfProcessing.output) return;
    Map<String, List<String>> coursesGiven = {};
    for (var person in _people.people.keys) {
      coursesGiven[person] = <String>[];
    }
    for (var course in courseControl.getGo()) {
      var resultingClass = overviewData.getPeopleForResultingClass(course);
      for (var person in resultingClass) {
        coursesGiven[person]!.add(course);
      }
    }
    var output = File(path);
    // This truncates existing file
    output.writeAsStringSync('');

    // Output one line for each person
    for (var person in _people.people.keys) {
      var line = List<String>.generate(33, (_) => '');
      line[0] = person;
      var personData = _people.people[person]!;
      line[1] = personData.nbrClassWanted.toString();
      var coursesGivenToPerson = coursesGiven[person]!;
      line[2] = coursesGivenToPerson.length.toString();
      var countGot = 0;

      // Wanted course info
      for (var i = 0;
          i < personData.firstChoices.length + personData.backups.length;
          i++) {
        String course;
        if (i < personData.firstChoices.length) {
          course = personData.firstChoices[i];
        } else {
          course = personData.backups[i - personData.firstChoices.length];
        }
        var courseData = _courses.getCourse(course);
        line[3 + i * 2] = '$course  ${courseData.name}';
        if (coursesGivenToPerson.contains(course)) {
          line[4 + i * 2] = 'OK';
          countGot += 1;
        } else if (countGot < personData.nbrClassWanted) {
          line[4 + i * 2] = 'Dropped';
        } else {
          line[4 + i * 2] = 'Not needed';
        }
      }

      // Given course info
      for (var i = 0; i < coursesGivenToPerson.length; i++) {
        var course = coursesGivenToPerson[i];
        var courseData = _courses.getCourse(course);
        line[15 + i * 3] =
            '$course  ${getTimeslotDescription(scheduleControl.scheduledTimeFor(course))}';
        var coordinators = courseControl.getCoordinators(course);
        if (coordinators!.coordinators[1].isEmpty) {
          line[16 + i * 3] = coordinators.coordinators[0];
        } else {
          line[16 + i * 3] =
              '${coordinators.coordinators[0]} & ${coordinators.coordinators[1]}';
        }
        line[17 + i * 3] = courseData.reading;
      }
      output.writeAsStringSync(line.join('\t'), mode: FileMode.append);
    }
  }

  /// Get timeslot description for time index
  String getTimeslotDescription(int timeIndex) {
    if (timeIndex < 0 || timeIndex > 19) {
      throw const InvalidArgument(message: 'Invalid time index');
    }
    String result = '';
    if (timeIndex < 10) {
      result += '1 & 3';
    } else {
      result += '2 & 4';
    }
    switch (((timeIndex % 10) / 2).floor()) {
      case 0:
        result += ' Mon';
        break;
      case 1:
        result += ' Tue';
        break;
      case 2:
        result += ' Wed';
        break;
      case 3:
        result += ' Thu';
        break;
      case 4:
        result += ' Fri';
        break;
    }
    if (timeIndex % 10 % 2 == 0) {
      result += ' AM';
    } else {
      result += ' PM';
    }
    return result;
  }

  /// Export intermediate state
  void exportState(String path) {
    var content = '';
    // Global setting
    content += 'Setting:\n';
    content += 'Min: ${courseControl.getGlobalMinClassSize()}\n';
    content += 'Max: ${courseControl.getGlobalMaxClassSize()}\n';
    // Course size
    content += '\nCourse size:\n';
    for (var course in courseControl.getCustomSizeClasses()) {
      content +=
          '$course: ${courseControl.getMinClassSize(course)},${courseControl.getMaxClassSize(course)}\n';
    }
    // Dropped
    content += '\nDrop:\n';
    var dropped = courseControl.getDropped();
    for (var course in dropped) {
      content += '$course\n';
    }
    // Limit
    content += '\nLimit:\n';
    for (var course in courseControl.getGo()) {
      if (courseControl.getSplitMode(course) == SplitMode.limit) {
        content += '$course\n';
      }
    }
    // Split
    content += '\nSplit:\n';
    var history = splitControl.getHistory();
    for (var entry in history) {
      content += 'Course: ${entry.item2}\n';
      for (var cluster in entry.item1) {
        content += 'Cluster: ${cluster.join(",")}\n';
      }
    }
    // Schedule
    content += '\nSchedule:\n';
    for (var course in courseControl.getGo()) {
      var timeIndex = scheduleControl.scheduledTimeFor(course);
      if (timeIndex >= 0) {
        content += '$course: $timeIndex\n';
      }
    }
    // Coordinator
    content += '\nCoordinator:\n';
    for (var course in courseControl.getGo()) {
      var coordinator = courseControl.getCoordinators(course);
      if (coordinator != null) {
        content += '$course: ';
        if (coordinator.equal) {
          content += 'equal';
        } else {
          content += 'unequal';
        }
        for (var person in coordinator.coordinators) {
          if (person.isNotEmpty) {
            content += ',$person';
          }
        }
        content += '\n';
      }
    }
    var output = File(path);
    output.writeAsStringSync(content);
  }

  /// Load intermediate state
  void loadState(String path) {
    var input = File(path);
    List<String> lines = input.readAsLinesSync();
    var i = 0;
    // Setting
    while (lines[i].trim() != 'Setting:') {
      i += 1;
    }
    i += 1;
    int minSize = int.parse(lines[i].split(':')[1].trim());
    i += 1;
    int maxSize = int.parse(lines[i].split(':')[1].trim());
    courseControl.setGlobalMinMaxClassSize(minSize, maxSize);

    // Course size
    while (lines[i].trim() != 'Course size:') {
      i += 1;
    }
    i += 1;
    while (true) {
      if (lines[i].isEmpty) {
        i += 1;
        continue;
      }
      if (lines[i].trim() == 'Drop:') {
        i += 1;
        break;
      }
      var course = lines[i].split(':')[0].trim();
      var setting = lines[i].split(':')[1].trim();
      var classMinSize = int.parse(setting.split(',')[0].trim());
      var classMaxSize = int.parse(setting.split(',')[1].trim());
      courseControl.setMinMaxClassSizeForClass(
          course, classMinSize, classMaxSize);
      i += 1;
    }

    // Drop
    while (true) {
      if (lines[i].isEmpty) {
        i += 1;
        continue;
      }
      if (lines[i].trim() == 'Limit:') {
        i += 1;
        break;
      }
      var course = lines[i].trim();
      courseControl.drop(course, noCompute: true);
      i += 1;
    }
    compute(Change.drop);

    // Limit
    while (true) {
      if (lines[i].isEmpty) {
        i += 1;
        continue;
      }
      if (lines[i].trim() == 'Split:') {
        i += 1;
        break;
      }
      var course = lines[i].trim();
      courseControl.setSplitMode(course, SplitMode.limit);
      i += 1;
    }

    // Split
    while (true) {
      if (lines[i].isEmpty) {
        i += 1;
        continue;
      }
      if (lines[i].trim() == 'Schedule:') {
        i += 1;
        break;
      }
      var course = lines[i].split(':')[1].trim();
      i += 1;
      while (lines[i].split(':')[0].trim() == 'Cluster') {
        var clusterStr = lines[i].split(':')[1].trim();
        var cluster = Set<String>.from(
            clusterStr.split(',').map((person) => person.trim()));
        splitControl.addCluster(cluster);
        i += 1;
      }
      splitControl.split(course, noCompute: true);
    }
    compute(Change.course);

    // Schedule
    while (true) {
      if (lines[i].isEmpty) {
        i += 1;
        continue;
      }
      if (lines[i].trim() == 'Coordinator:') {
        i += 1;
        break;
      }

      var data = lines[i].split(':').map((e) => e.trim()).toList();
      var index = int.parse(data[1]);
      if (index >= 0) {
        scheduleControl.schedule(data[0], index, noCompute: true);
      }
      i += 1;
    }
    compute(Change.schedule);

    // Coordinator
    while (i < lines.length) {
      if (lines[i].isEmpty) {
        i += 1;
        continue;
      }

      var course = lines[i].split(':')[0].trim();
      var data = lines[i]
          .split(':')[1]
          .trim()
          .split(',')
          .map((e) => e.trim())
          .toList();
      if (data[0] == 'equal') {
        if (data.length >= 2) {
          courseControl.setEqualCoCoordinator(course, data[1]);
        }
        if (data.length >= 3) {
          courseControl.setEqualCoCoordinator(course, data[2]);
        }
      } else {
        if (data.length >= 2) {
          courseControl.setMainCoCoordinator(course, data[1]);
        }
        if (data.length >= 3) {
          courseControl.setMainCoCoordinator(course, data[2]);
        }
      }
      i += 1;
    }
  }
}
