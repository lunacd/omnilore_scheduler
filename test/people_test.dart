import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/exceptions.dart';
import 'package:omnilore_scheduler/store/people.dart';

import 'test_util.dart';

/// This file tests functionalities regarding loading people.
void main() {
  test('Load people: file not found', () {
    var people = People();
    expect(() => people.loadPeople('nonexistent'),
        throwsA(isA<FileSystemException>()));
  });

  test('Load people: Malformed people file', () async {
    var people = People();
    expect(
        () => people.loadPeople('test/resources/malformed_people_columns.txt'),
        throwsA(allOf([
          isA<MalformedPeopleFileException>(),
          hasMessage('The people file is malformed: line 25')
        ])));
  });

  test('Load people: Invalid number of classes', () async {
    var people = People();
    expect(
        () => people
            .loadPeople('test/resources/malformed_people_num_classes.txt'),
        throwsA(allOf([
          isA<InvalidNumClassWantedException>(),
          hasMessage(
              'People file specifies invalid number of classes wanted: 7 at line 55')
        ])));
  });

  test('Load people: Unrecognized availability', () async {
    var people = People();
    expect(
        () => people
            .loadPeople('test/resources/malformed_people_availability.txt'),
        throwsA(allOf([
          isA<UnrecognizedAvailabilityException>(),
          hasMessage(
              'People file specifies unrecognized availability value: 4 at line 34')
        ])));
  });

  test('Load people: Duplicate class selection', () async {
    var people = People();
    expect(
        () =>
            people.loadPeople('test/resources/malformed_people_selection.txt'),
        throwsA(allOf([
          isA<DuplicateClassSelectionException>(),
          hasMessage('A class is chosen more than once: BRX at line 39')
        ])));
  });

  test('Load people: Duplicate record', () async {
    var people = People();
    expect(
        () => people
            .loadPeople('test/resources/malformed_people_duplicate_record.txt'),
        throwsA(allOf([
          isA<DuplicateRecordsException>(),
          hasMessage('Elaine Winer has more than one record')
        ])));
  });

  test('Load people: Listing class when wanting 0', () async {
    var people = People();
    expect(
        () => people.loadPeople(
            'test/resources/malformed_people_listing_when_wanting_zero.txt'),
        throwsA(allOf([
          isA<ListingWhenWantingZeroException>(),
          hasMessage('Fran Wielin still listed classes when wanting 0')
        ])));
  });

  test('Load people: Wanting more than listed', () async {
    var people = People();
    expect(
        () => people.loadPeople(
            'test/resources/malformed_people_wanting_more_than_listed.txt'),
        throwsA(allOf([
          isA<WantingMoreThanListedException>(),
          hasMessage('Elaine Winer wanted more class than they listed')
        ])));
  });

  test('Load people: success', () async {
    var people = People();
    expect(await people.loadPeople('test/resources/people.txt'), 267);
    var person1 = people.people['Carol Johnson']!;
    expect(person1.lName, 'Johnson');
    expect(person1.fName, 'Carol');
    expect(person1.phone, '372-8535');
    expect(person1.nbrClassWanted, 1);
    expect(person1.availability, [
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
    ]);
    expect(person1.firstChoices, ['CHK']);
    expect(person1.backups, ['FAC', 'IMP', 'ILA', 'PRF']);
    expect(person1.submissionOrder, 108);
    var person2 = people.people['Stan Pleatman']!;
    expect(person2.lName, 'Pleatman');
    expect(person2.fName, 'Stan');
    expect(person2.phone, '709-2404');
    expect(person2.nbrClassWanted, 0);
    expect(person2.availability, [
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
    ]);
    expect(person2.firstChoices, []);
    expect(person2.submissionOrder, 259);
    var person3 = people.people['Fran Brown']!;
    expect(person3.lName, 'Brown');
    expect(person3.fName, 'Fran');
    expect(person3.phone, '377-5252');
    expect(person3.nbrClassWanted, 2);
    expect(person3.availability, [
      false,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      true,
      false,
      true
    ]);
    expect(person3.firstChoices, ['IMP', 'BAD']);
    expect(person3.submissionOrder, 9);
  });

  test('Load people: whitespace', () async {
    var people = People();
    expect(
        await people.loadPeople('test/resources/people_whitespace.txt'), 267);
    var person1 = people.people['Carol Johnson']!;
    expect(person1.lName, 'Johnson');
    expect(person1.fName, 'Carol');
    expect(person1.phone, '372-8535');
    expect(person1.nbrClassWanted, 1);
    expect(person1.availability, [
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
      true,
    ]);
    expect(person1.firstChoices, ['CHK']);
    expect(person1.backups, ['FAC', 'IMP', 'ILA', 'PRF']);
    expect(person1.submissionOrder, 108);
    var person2 = people.people['Stan Pleatman']!;
    expect(person2.lName, 'Pleatman');
    expect(person2.fName, 'Stan');
    expect(person2.phone, '709-2404');
    expect(person2.nbrClassWanted, 0);
    expect(person2.availability, [
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
      true,
    ]);
    expect(person2.firstChoices, []);
    expect(person2.submissionOrder, 259);
    var person3 = people.people['Fran Brown']!;
    expect(person3.lName, 'Brown');
    expect(person3.fName, 'Fran');
    expect(person3.phone, '377-5252');
    expect(person3.nbrClassWanted, 2);
    expect(person3.availability, [
      false,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      false,
      true,
      false,
      true,
      false,
      true
    ]);
    expect(person3.firstChoices, ['IMP', 'BAD']);
    expect(person3.submissionOrder, 9);
  });
}
