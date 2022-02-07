/// Course holds information about an Omnilore course
class Course {
  const Course({required this.code, required this.name, required this.reading});

  /// 3-digit course identifier
  final String code;

  /// Full course name
  final String name;

  /// Recommended reading material
  final String reading;

  @override
  bool operator ==(Object other) {
    if (other is Course) {
      return (code == other.code) &&
          (name == other.name) &&
          (reading == other.reading);
    }
    return false;
  }

  @override // coverage:ignore-line
  int get hashCode =>
      code.hashCode ^ name.hashCode ^ reading.hashCode; // coverage:ignore-line
}
