import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/availability.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/people.dart';

import 'test_util.dart';

void main() {
  test("Load people: file not found", () {
    var people = People();
    expect(() => people.loadPeople("nonexistent"),
        throwsA(isA<FileSystemException>()));
  });

  test("Load people: Malformed people file", () async {
    var people = People();
    expect(
        () => people.loadPeople("test/resources/malformed_people_columns.txt"),
        throwsA(allOf([
          isA<MalformedPeopleFileException>(),
          hasMessage("The people file is malformed: line 25")
        ])));
  });

  test("Load people: Invalid number of classes", () async {
    var people = People();
    expect(
        () => people
            .loadPeople("test/resources/malformed_people_num_classes.txt"),
        throwsA(allOf([
          isA<InvalidNumClassWantedException>(),
          hasMessage(
              "People file specifies invalid number of classes wanted: 7 at line 56")
        ])));
  });

  test("Load people: Unrecognized availability", () async {
    var people = People();
    expect(
        () => people
            .loadPeople("test/resources/malformed_people_availability.txt"),
        throwsA(allOf([
          isA<UnrecognizedAvailabilityException>(),
          hasMessage(
              "People file specifies unrecognized availability value: 4 at line 34")
        ])));
  });

  test("Load people: Duplicate class selection", () async {
    var people = People();
    expect(
        () =>
            people.loadPeople("test/resources/malformed_people_selection.txt"),
        throwsA(allOf([
          isA<DuplicateClassSelectionException>(),
          hasMessage("A class is chosen more than once: BRX at line 39")
        ])));
  });

  test("Load people", () async {
    var people = People();
    expect(await people.loadPeople("test/resources/people.txt"), 271);
    var person1 = people.people[111];
    expect(person1.lName, "Johnson");
    expect(person1.fName, "Carol");
    expect(person1.phone, "372-8535");
    expect(person1.numClassWanted, 1);
    expect(
        person1.availability
            .get(WeekOfMonth.firstThird, DayOfWeek.friday, TimeOfDay.morning),
        false);
    expect(
        person1.availability.get(
            WeekOfMonth.secondFourth, DayOfWeek.tuesday, TimeOfDay.afternoon),
        true);
    expect(person1.classes, ["CHK", "FAC", "IMP", "ILA", "PRF"]);
    expect(person1.submissionOrder, 108);
    var person2 = people.people[201];
    expect(person2.lName, "Pleatman");
    expect(person2.fName, "Stan");
    expect(person2.phone, "709-2404");
    expect(person2.numClassWanted, 0);
    expect(
        person2.availability
            .get(WeekOfMonth.firstThird, DayOfWeek.friday, TimeOfDay.morning),
        true);
    expect(
        person2.availability.get(
            WeekOfMonth.secondFourth, DayOfWeek.tuesday, TimeOfDay.afternoon),
        true);
    expect(person2.classes, []);
    expect(person2.submissionOrder, 259);
  });

  test("Load people: whitespace", () async {
    var people = People();
    expect(await people.loadPeople("test/resources/people_whitespace.txt"), 271);
    var person1 = people.people[111];
    expect(person1.lName, "Johnson");
    expect(person1.fName, "Carol");
    expect(person1.phone, "372-8535");
    expect(person1.numClassWanted, 1);
    expect(
        person1.availability
            .get(WeekOfMonth.firstThird, DayOfWeek.friday, TimeOfDay.morning),
        false);
    expect(
        person1.availability.get(
            WeekOfMonth.secondFourth, DayOfWeek.tuesday, TimeOfDay.afternoon),
        true);
    expect(person1.classes, ["CHK", "FAC", "IMP", "ILA", "PRF"]);
    expect(person1.submissionOrder, 108);
    var person2 = people.people[201];
    expect(person2.lName, "Pleatman");
    expect(person2.fName, "Stan");
    expect(person2.phone, "709-2404");
    expect(person2.numClassWanted, 0);
    expect(
        person2.availability
            .get(WeekOfMonth.firstThird, DayOfWeek.friday, TimeOfDay.morning),
        true);
    expect(
        person2.availability.get(
            WeekOfMonth.secondFourth, DayOfWeek.tuesday, TimeOfDay.afternoon),
        true);
    expect(person2.classes, []);
    expect(person2.submissionOrder, 259);
  });
}
