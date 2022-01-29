/// Course holds information about an Omnilore course
class Course {
  Course({required this.code, required this.name, required this.reading});

  /// 3-digit course identifier
  String code;

  /// Full course name
  String name;

  /// Recommended reading material
  String reading;
}
