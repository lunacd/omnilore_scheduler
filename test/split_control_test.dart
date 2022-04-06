import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

/// This file tests course split functionalities.
void main() {
  test('Split: 2015, 2 splits, without clusters', () async {
    Scheduling scheduling = Scheduling();
    expect(await scheduling.loadCourses('test/resources/2015-split/course.txt'),
        27);
    expect(await scheduling.loadPeople('test/resources/2015-split/people.txt'),
        296);
    scheduling.courseControl.drop('AIN');
    scheduling.courseControl.drop('AUG');
    scheduling.courseControl.drop('DOG');
    scheduling.courseControl.drop('FAK');
    scheduling.courseControl.drop('F2K');
    scheduling.courseControl.drop('GOV');
    scheduling.courseControl.drop('RAP');
    scheduling.courseControl.drop('UKR');
    expect(scheduling.overviewData.getNbrGoCourses(), 19);
    expect(scheduling.overviewData.getResultingClassSize('CRM').size, 16);
    expect(scheduling.overviewData.getResultingClassSize('DIP').size, 11);
    expect(scheduling.overviewData.getResultingClassSize('GFT').size, 13);
    expect(scheduling.overviewData.getResultingClassSize('GHG').size, 14);
    expect(scheduling.overviewData.getResultingClassSize('TED').size, 35);
    var resultingClass =
        scheduling.overviewData.getPeopleForResultingClass('TED');

    scheduling.splitControl.split('TED');

    var people = scheduling
        .getPeople()
        .where((person) =>
            person.backups.indexWhere((course) => course.contains('TED', 0)) !=
                -1 ||
            person.firstChoices
                    .indexWhere((course) => course.contains('TED', 0)) !=
                -1)
        .toList(growable: false);
    var split1 = people
        .where((person) =>
            person.firstChoices.contains('TED1') ||
            person.backups.contains('TED1'))
        .toList(growable: false);
    var split2 = people
        .where((person) =>
            person.firstChoices.contains('TED2') ||
            person.backups.contains('TED2'))
        .toList(growable: false);
    var split1Result = split1
        .map((person) => person.getName())
        .where((person) => resultingClass.contains(person))
        .toList(growable: false);
    var split2Result = split2
        .map((person) => person.getName())
        .where((person) => resultingClass.contains(person))
        .toList(growable: false);
    var split1Backup = split1
        .map((person) => person.getName())
        .where((person) => !resultingClass.contains(person))
        .toList(growable: false);
    var split2Backup = split2
        .map((person) => person.getName())
        .where((person) => !resultingClass.contains(person))
        .toList(growable: false);

    expect(split1Result.length, 18);
    expect(
        split1Result,
        containsAll([
          'Mel Schrier',
          'Zelda Green',
          'Kirk Tuey',
          'John Smith',
          'Carol Wingate',
          'Helen Stockwell',
          'Al Kovalsky',
          'Leslie Criswell',
          'Hank Frankenberg',
          'Susan Egan',
          'Norman Stockwell',
          'Marcia Kovalsky',
          'Jack Carmody',
          'Lynn Schubert',
          'Carmen Svensrud',
          'Merle Culbert',
          'Karol McQueary',
          'Allan Conrad'
        ]));
    expect(split2Result.length, 17);
    expect(
        split2Result,
        containsAll([
          'Susan Fein',
          'Dennis Goodno',
          'Dennis Bosch',
          'Mary Jo Little',
          'Carolyn Pohlner',
          'Joy Jurena',
          'Anne Faass',
          'McNair Maxwell',
          'Frank Reiner',
          'Jake Kamen',
          'Rebecca Hansen',
          'Kate Nelson',
          'Stan Pleatman',
          'Marilou Lieman',
          'Bob Bacinski',
          'Frank Pohlner',
          'Jerry Green'
        ]));
    expect(split1Backup.length, 13);
    expect(
        split1Backup,
        containsAll([
          'Chuck Gray',
          'Maria Ashla',
          'Carlos Lemmi',
          'Andrea Gargaro',
          'Julie Citroen',
          'Carol Johnson',
          'Dennis Eggert',
          'Edith Eddleman',
          'Cathy Gallipeau',
          'Ellen Tarlow',
          'Bill Paul',
          'Muriel Blatt',
          'Jerry Bichlmeier'
        ]));
    expect(split2Backup.length, 13);
    expect(
        split2Backup,
        containsAll([
          'John Vehrencamp',
          'Ronnie Lemmi',
          'Fran Wielin',
          'Gail Ruder',
          'Yvette Reiner',
          'Ruth Belonsky',
          'Carol Kern',
          'Kirsten Loumeau',
          'Leslie Schettler',
          'Faye Schwartz',
          'Frances Roberts',
          'Dayla Sims',
          'Ginny Brown'
        ]));
  });

  test('Split: 2015, 2 split, with clusters', () async {
    Scheduling scheduling = Scheduling();
    expect(await scheduling.loadCourses('test/resources/2015-split/course.txt'),
        27);
    expect(await scheduling.loadPeople('test/resources/2015-split/people.txt'),
        296);
    scheduling.courseControl.drop('AIN');
    scheduling.courseControl.drop('AUG');
    scheduling.courseControl.drop('DOG');
    scheduling.courseControl.drop('FAK');
    scheduling.courseControl.drop('F2K');
    scheduling.courseControl.drop('GOV');
    scheduling.courseControl.drop('RAP');
    scheduling.courseControl.drop('UKR');
    expect(scheduling.overviewData.getNbrGoCourses(), 19);
    expect(scheduling.overviewData.getResultingClassSize('CRM').size, 16);
    expect(scheduling.overviewData.getResultingClassSize('DIP').size, 11);
    expect(scheduling.overviewData.getResultingClassSize('GFT').size, 13);
    expect(scheduling.overviewData.getResultingClassSize('GHG').size, 14);
    expect(scheduling.overviewData.getResultingClassSize('TED').size, 35);
    var resultingClass =
        scheduling.overviewData.getPeopleForResultingClass('TED');

    scheduling.splitControl.addCluster({'Bob Bacinski', 'Leslie Criswell'});
    scheduling.splitControl.addCluster({'Zelda Green', 'Jerry Green'});
    scheduling.splitControl.addCluster({'Al Kovalsky', 'Marcia Kovalsky'});
    scheduling.splitControl.addCluster({'Carolyn Pohlner', 'Frank Pohlner'});
    scheduling.splitControl.addCluster({'Norman Stockwell', 'Helen Stockwell'});

    scheduling.splitControl.split('TED');

    var people = scheduling
        .getPeople()
        .where((person) =>
            person.backups.indexWhere((course) => course.contains('TED', 0)) !=
                -1 ||
            person.firstChoices
                    .indexWhere((course) => course.contains('TED', 0)) !=
                -1)
        .toList(growable: false);
    var split1 = people
        .where((person) =>
            person.firstChoices.contains('TED1') ||
            person.backups.contains('TED1'))
        .toList(growable: false);
    var split2 = people
        .where((person) =>
            person.firstChoices.contains('TED2') ||
            person.backups.contains('TED2'))
        .toList(growable: false);
    var split1Result = split1
        .map((person) => person.getName())
        .where((person) => resultingClass.contains(person))
        .toList(growable: false);
    var split2Result = split2
        .map((person) => person.getName())
        .where((person) => resultingClass.contains(person))
        .toList(growable: false);
    var split1Backup = split1
        .map((person) => person.getName())
        .where((person) => !resultingClass.contains(person))
        .toList(growable: false);
    var split2Backup = split2
        .map((person) => person.getName())
        .where((person) => !resultingClass.contains(person))
        .toList(growable: false);

    expect(split1Result.length, 17);
    expect(
        split1Result,
        containsAll([
          'Mel Schrier',
          'John Smith',
          'Mary Jo Little',
          'Helen Stockwell',
          'Al Kovalsky',
          'Hank Frankenberg',
          'Susan Egan',
          'Frank Reiner',
          'Rebecca Hansen',
          'Norman Stockwell',
          'Kate Nelson',
          'Marcia Kovalsky',
          'Jack Carmody',
          'Carmen Svensrud',
          'Merle Culbert',
          'Karol McQueary',
          'Allan Conrad'
        ]));
    expect(split2Result.length, 18);
    expect(
        split2Result,
        containsAll([
          'Zelda Green',
          'Kirk Tuey',
          'Susan Fein',
          'Dennis Goodno',
          'Dennis Bosch',
          'Carol Wingate',
          'Leslie Criswell',
          'Carolyn Pohlner',
          'Joy Jurena',
          'Anne Faass',
          'McNair Maxwell',
          'Jake Kamen',
          'Stan Pleatman',
          'Lynn Schubert',
          'Marilou Lieman',
          'Bob Bacinski',
          'Frank Pohlner',
          'Jerry Green'
        ]));
    expect(split1Backup.length, 3);
    expect(split1Backup,
        containsAll(['Chuck Gray', 'Edith Eddleman', 'Ginny Brown']));
    expect(split2Backup.length, 23);
    expect(
        split2Backup,
        containsAll([
          'John Vehrencamp',
          'Ronnie Lemmi',
          'Fran Wielin',
          'Gail Ruder',
          'Yvette Reiner',
          'Ruth Belonsky',
          'Carol Kern',
          'Kirsten Loumeau',
          'Leslie Schettler',
          'Faye Schwartz',
          'Frances Roberts',
          'Dayla Sims',
          'Maria Ashla',
          'Carlos Lemmi',
          'Andrea Gargaro',
          'Julie Citroen',
          'Carol Johnson',
          'Dennis Eggert',
          'Cathy Gallipeau',
          'Ellen Tarlow',
          'Bill Paul',
          'Muriel Blatt',
          'Jerry Bichlmeier'
        ]));
  });

  test('Split: 2015, 3 split, with clusters', () async {
    Scheduling scheduling = Scheduling();
    expect(await scheduling.loadCourses('test/resources/2015-split/course.txt'),
        27);
    expect(await scheduling.loadPeople('test/resources/2015-split/people.txt'),
        296);
    scheduling.courseControl.drop('AIN');
    scheduling.courseControl.drop('AUG');
    scheduling.courseControl.drop('DOG');
    scheduling.courseControl.drop('FAK');
    scheduling.courseControl.drop('F2K');
    scheduling.courseControl.drop('GOV');
    scheduling.courseControl.drop('RAP');
    scheduling.courseControl.drop('UKR');
    expect(scheduling.overviewData.getNbrGoCourses(), 19);
    expect(scheduling.overviewData.getResultingClassSize('CRM').size, 16);
    expect(scheduling.overviewData.getResultingClassSize('DIP').size, 11);
    expect(scheduling.overviewData.getResultingClassSize('GFT').size, 13);
    expect(scheduling.overviewData.getResultingClassSize('GHG').size, 14);
    expect(scheduling.overviewData.getResultingClassSize('TED').size, 35);
    var resultingClass =
        scheduling.overviewData.getPeopleForResultingClass('TED');

    scheduling.splitControl.addCluster({'Bob Bacinski', 'Leslie Criswell'});
    scheduling.splitControl.addCluster({'Zelda Green', 'Jerry Green'});
    scheduling.splitControl.addCluster({'Al Kovalsky', 'Marcia Kovalsky'});
    scheduling.splitControl.addCluster({'Carolyn Pohlner', 'Frank Pohlner'});
    scheduling.splitControl.addCluster({'Norman Stockwell', 'Helen Stockwell'});
    scheduling.courseControl.setMinMaxClassSizeForClass('TED', 8, 15);

    scheduling.splitControl.split('TED');

    var people = scheduling
        .getPeople()
        .where((person) =>
            person.backups.indexWhere((course) => course.contains('TED', 0)) !=
                -1 ||
            person.firstChoices
                    .indexWhere((course) => course.contains('TED', 0)) !=
                -1)
        .toList(growable: false);
    var split1 = people
        .where((person) =>
            person.firstChoices.contains('TED1') ||
            person.backups.contains('TED1'))
        .toList(growable: false);
    var split2 = people
        .where((person) =>
            person.firstChoices.contains('TED2') ||
            person.backups.contains('TED2'))
        .toList(growable: false);
    var split3 = people
        .where((person) =>
            person.firstChoices.contains('TED3') ||
            person.backups.contains('TED3'))
        .toList(growable: false);
    var split1Result = split1
        .map((person) => person.getName())
        .where((person) => resultingClass.contains(person))
        .toList(growable: false);
    var split2Result = split2
        .map((person) => person.getName())
        .where((person) => resultingClass.contains(person))
        .toList(growable: false);
    var split3Result = split3
        .map((person) => person.getName())
        .where((person) => resultingClass.contains(person))
        .toList(growable: false);
    // var split1Backup = split1
    //     .map((person) => person.getName())
    //     .where((person) => !resultingClass.contains(person))
    //     .toList(growable: false);
    // var split2Backup = split2
    //     .map((person) => person.getName())
    //     .where((person) => !resultingClass.contains(person))
    //     .toList(growable: false);
    // var split3Backup = split3
    //     .map((person) => person.getName())
    //     .where((person) => !resultingClass.contains(person))
    //     .toList(growable: false);

    expect(split1Result.length, 12);
    expect(
        split1Result,
        containsAll([
          'John Smith',
          'Mary Jo Little',
          'Leslie Criswell',
          'Hank Frankenberg',
          'McNair Maxwell',
          'Frank Reiner',
          'Jake Kamen',
          'Kate Nelson',
          'Jack Carmody',
          'Lynn Schubert',
          'Carmen Svensrud',
          'Bob Bacinski'
        ]));
    expect(split2Result.length, 12);
    expect(
        split2Result,
        containsAll([
          'Mel Schrier',
          'Zelda Green',
          'Kirk Tuey',
          'Susan Fein',
          'Carol Wingate',
          'Helen Stockwell',
          'Joy Jurena',
          'Norman Stockwell',
          'Marilou Lieman',
          'Karol McQueary',
          'Jerry Green',
          'Allan Conrad'
        ]));
    expect(split3Result.length, 11);
    expect(
        split3Result,
        containsAll([
          'Dennis Goodno',
          'Dennis Bosch',
          'Al Kovalsky',
          'Carolyn Pohlner',
          'Susan Egan',
          'Anne Faass',
          'Rebecca Hansen',
          'Marcia Kovalsky',
          'Stan Pleatman',
          'Merle Culbert',
          'Frank Pohlner'
        ]));
    // expect(split1Backup.length, 0);
    // expect(split1Backup, containsAll([]));
    // expect(split2Backup.length, 26);
    // expect(
    //     split2Backup,
    //     containsAll([
    //       'John Vehrencamp',
    //       'Ronnie Lemmi',
    //       'Fran Wielin',
    //       'Gail Ruder',
    //       'Yvette Reiner',
    //       'Ruth Belonsky',
    //       'Carol Kern',
    //       'Kirsten Loumeau',
    //       'Leslie Schettler',
    //       'Faye Schwartz',
    //       'Frances Roberts',
    //       'Dayla Sims',
    //       'Ginny Brown',
    //       'Chuck Gray',
    //       'Maria Ashla',
    //       'Carlos Lemmi',
    //       'Andrea Gargaro',
    //       'Julie Citroen',
    //       'Carol Johnson',
    //       'Dennis Eggert',
    //       'Edith Eddleman',
    //       'Cathy Gallipeau',
    //       'Ellen Tarlow',
    //       'Bill Paul',
    //       'Muriel Blatt',
    //       'Jerry Bichlmeier'
    //     ]));
  });
}
