import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/model/person.dart';

class People {
  /// A list of people, ordered as is presented in the input file
  HashMap<String, Person> people = HashMap<String, Person>();

  /// Maximum name length
  int maxLength = 10;

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
  /// Throws a [WantingMoreThanListedException] when a member wants more classes
  /// than they listed.
  /// Throws a [ListingWhenWantingZeroException] when a member still listed
  /// classes when they want 0.
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
      if (lName.length + fName.length + 2 > maxLength) {
        maxLength = lName.length + fName.length + 2;
      }
      var phone = tokens[2];
      var numClassWanted = 0;
      var submissionOrder = 0;
      List<String> firstChoices = [];
      List<String> backups = [];
      List<bool> availability = List<bool>.filled(20, true, growable: false);
      try {
        numClassWanted = int.parse(tokens[3]);
      } catch (e) {
        // Missing people who made no submissions
        people['$fName $lName'] = (Person(
            fName: fName,
            lName: lName,
            phone: phone,
            nbrClassWanted: numClassWanted,
            availability: availability,
            firstChoices: firstChoices,
            backups: backups,
            submissionOrder: submissionOrder));
      }
      if (numClassWanted < 0 || numClassWanted > 6) {
        throw InvalidNumClassWantedException(
            malformedLine: numLines + 1, numClassWanted: numClassWanted);
      }
      submissionOrder = int.parse(tokens[20]);

      // Parse availability
      for (int i = 0; i < 10; i++) {
        var avail = tokens[i + 4];
        if (avail == '1') {
          availability[i] = false;
        } else if (avail == '2') {
          availability[10 + i] = false;
        } else if (avail == '3') {
          availability[i] = false;
          availability[10 + i] = false;
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
            if (firstChoices.length < numClassWanted) {
              firstChoices.add(chosenClass);
            } else {
              backups.add(chosenClass);
            }
            chosenClassesSet.add(chosenClass);
          }
        }
      }
      if (firstChoices.length < numClassWanted) {
        throw WantingMoreThanListedException(fName: fName, lName: lName);
      }
      if (numClassWanted == 0 && backups.isNotEmpty) {
        throw ListingWhenWantingZeroException(fName: fName, lName: lName);
      }

      if (people.containsKey('$fName $lName')) {
        throw DuplicateRecordsException(fName: fName, lName: lName);
      }
      people['$fName $lName'] = (Person(
          fName: fName,
          lName: lName,
          phone: phone,
          nbrClassWanted: numClassWanted,
          availability: availability,
          firstChoices: firstChoices,
          backups: backups,
          submissionOrder: submissionOrder));

      numLines++;
    }
    return numLines;
  }
}
