import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';

class People {
  /// A list of people, ordered as is presented in the input file
  List<Person> people = [];

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
  ///
  /// Asynchronously returns the number of people successfully read.
  ///
  /// ```dart
  /// int numPeople = await people.loadPeople('/path/to/file');
  /// ```
  Future<int> loadPeople(String inputFile) async {
    people.clear();
    var file = File(inputFile);
    var lines =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());
    var numLines = 0;
    await for (var line in lines) {
      if (line.isEmpty) continue;
      // Parse input
      var tokens = line.split('\t').map((e) => e.trim()).toList();
      if (tokens.length != 21) {
        people.clear();
        throw MalformedPeopleFileException(malformedLine: numLines + 1);
      }
      var lName = tokens[0];
      var fName = tokens[1];
      var phone = tokens[2];
      var numClassWanted = int.parse(tokens[3]);
      if (numClassWanted < 0 || numClassWanted > 6) {
        throw InvalidNumClassWantedException(
            malformedLine: numLines + 1, numClassWanted: numClassWanted);
      }
      var availability = Availability();
      List<String> classes = [];
      var submissionOrder = int.parse(tokens[20]);

      // Parse availability
      for (int i = 0; i < 10; i++) {
        var avail = tokens[i + 4];
        if (avail == '1') {
          availability.set(
              WeekOfMonth.firstThird,
              DayOfWeek.values[(i / 2).floor()],
              TimeOfDay.values[i % 2],
              false);
        } else if (avail == '2') {
          availability.set(
              WeekOfMonth.secondFourth,
              DayOfWeek.values[(i / 2).floor()],
              TimeOfDay.values[i % 2],
              false);
        } else if (avail == '3') {
          availability.set(
              WeekOfMonth.firstThird,
              DayOfWeek.values[(i / 2).floor()],
              TimeOfDay.values[i % 2],
              false);
          availability.set(
              WeekOfMonth.secondFourth,
              DayOfWeek.values[(i / 2).floor()],
              TimeOfDay.values[i % 2],
              false);
        } else if (avail != '') {
          people.clear();
          throw UnrecognizedAvailabilityException(
              availability: avail, malformedLine: numLines + 1);
        }
      }

      var chosenClassesSet = HashSet<String>();
      for (int i = 0; i < 6; i++) {
        var chosenClass = tokens[i + 14];
        if (chosenClass.isNotEmpty) {
          if (chosenClassesSet.contains(chosenClass)) {
            people.clear();
            throw DuplicateClassSelectionException(
                malformedLine: numLines + 1, classCode: chosenClass);
          } else {
            classes.add(chosenClass);
            chosenClassesSet.add(chosenClass);
          }
        }
      }

      people.add(Person(
          fName: fName,
          lName: lName,
          phone: phone,
          numClassWanted: numClassWanted,
          availability: availability,
          classes: classes,
          submissionOrder: submissionOrder));

      numLines++;
    }
    return numLines;
  }
}
