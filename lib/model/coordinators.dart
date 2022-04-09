class Coordinators {
  Coordinators({required this.equal});

  bool equal;
  List<String> coordinators =
      List<String>.generate(2, (_) => '', growable: false);
}
