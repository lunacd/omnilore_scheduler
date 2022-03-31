/// Indicate availability for the 1st/3rd or 2nd/4th week of a month
enum WeekOfMonth { firstThird, secondFourth }

/// Indicate availability for days of the week
enum DayOfWeek { monday, tuesday, wednesday, thursday, friday }

/// Indicate availability for either AM or PM
enum TimeOfDay { morning, afternoon }

/// An availability object an person's availability data
///
/// The constructed availability object defaults to being available for all time
/// slots.
class Availability {
  final List<bool> _availability = List.filled(20, true, growable: false);

  /// Set an availability for week of month, day of week, and time of day
  void set(WeekOfMonth week, DayOfWeek day, TimeOfDay time, bool available) {
    _availability[week.index * 10 + day.index * 2 + time.index] = available;
  }

  /// Get an availability for week of month, day of week, and time of day
  ///
  /// To iterate through all availability slots:
  /// ```dart
  /// for (var week in WeekOfMonth.values) {
  ///   for (var day in DayOfWeek.values) {
  ///     for (var time in TimeOfDay.values) {
  ///       bool available = availability.get(week, day, time);
  ///     }
  ///   }
  /// }
  /// ```
  bool get(WeekOfMonth week, DayOfWeek day, TimeOfDay time) {
    return _availability[week.index * 10 + day.index * 2 + time.index];
  }
}
