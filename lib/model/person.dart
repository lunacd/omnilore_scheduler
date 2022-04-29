/// Person holds information of an Omnilore member
class Person {
  const Person(
      {required this.fName,
      required this.lName,
      required this.phone,
      required this.nbrClassWanted,
      required this.availability,
      required this.firstChoices,
      required this.backups,
      required this.submissionOrder});

  /// First name
  final String fName;

  /// Last name
  final String lName;

  /// Phone number
  final String phone;

  /// Number of classes wanted
  final int nbrClassWanted;

  /// Availability for class slots
  final List<bool> availability;

  /// List of classes wanted as first choices
  final List<String> firstChoices;

  /// List of classes wanted as backups
  final List<String> backups;

  /// The order of submission, with smaller being submitted earlier
  final int submissionOrder;

  /// Get full name
  String getName() {
    return '$fName $lName';
  }

  /// Get reversed name
  String getReversedName() {
    return '$lName, $fName';
  }
}
