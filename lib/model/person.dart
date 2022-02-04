import 'package:omnilore_scheduler/model/availability.dart';

/// Person holds information of an Omnilore member
class Person {
  const Person(
      {required this.fName,
      required this.lName,
      required this.phone,
      required this.numClassWanted,
      required this.availability,
      required this.classes,
      required this.submissionOrder});

  /// First name
  final String fName;

  /// Last name
  final String lName;

  /// Phone number
  final String phone;

  /// Number of classes wanted
  final int numClassWanted;

  /// Availability for class slots
  final Availability availability;

  /// List of classes wanted, in order from first-choice to backups
  final List<String> classes;

  /// The order of submission, with smaller being submitted earlier
  final int submissionOrder;
}
