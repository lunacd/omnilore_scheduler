class Change {
  Change(
      {this.course = false,
      this.people = false,
      this.drop = false,
      this.schedule = false});

  /// Denote changes in course data (load course, edit course, split)
  bool course;

  /// Denote changes in people data (load people, edit people)
  bool people;

  /// Denote changes in dropped classes
  bool drop;

  /// Denote changes in course scheduling
  bool schedule;
}
