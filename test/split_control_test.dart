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
          'Jerry Green',
          'Allan Conrad'
        ]));
    expect(split2Result.length, 17);
    expect(
        split2Result,
        containsAll([
          'Kirk Tuey',
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
          'Frank Pohlner'
        ]));
    expect(split1Backup.length, 11);
    expect(
        split1Backup,
        containsAll([
          'John Vehrencamp',
          'Ronnie Lemmi',
          'Maria Ashla',
          'Carlos Lemmi',
          'Andrea Gargaro',
          'Yvette Reiner',
          'Carol Johnson',
          'Kirsten Loumeau',
          'Leslie Schettler',
          'Dayla Sims',
          'Muriel Blatt'
        ]));
    expect(split2Backup.length, 15);
    expect(
        split2Backup,
        containsAll([
          'Chuck Gray',
          'Fran Wielin',
          'Gail Ruder',
          'Julie Citroen',
          'Ruth Belonsky',
          'Carol Kern',
          'Dennis Eggert',
          'Edith Eddleman',
          'Cathy Gallipeau',
          'Faye Schwartz',
          'Ellen Tarlow',
          'Frances Roberts',
          'Bill Paul',
          'Ginny Brown',
          'Jerry Bichlmeier'
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
    expect(split1Backup.length, 20);
    expect(
        split1Backup,
        containsAll([
          'John Vehrencamp',
          'Chuck Gray',
          'Ronnie Lemmi',
          'Fran Wielin',
          'Carlos Lemmi',
          'Andrea Gargaro',
          'Yvette Reiner',
          'Julie Citroen',
          'Carol Johnson',
          'Dennis Eggert',
          'Kirsten Loumeau',
          'Edith Eddleman',
          'Leslie Schettler',
          'Cathy Gallipeau',
          'Faye Schwartz',
          'Frances Roberts',
          'Bill Paul',
          'Dayla Sims',
          'Muriel Blatt',
          'Ginny Brown'
        ]));
    expect(split2Backup.length, 6);
    expect(
        split2Backup,
        containsAll([
          'Maria Ashla',
          'Gail Ruder',
          'Ruth Belonsky',
          'Carol Kern',
          'Ellen Tarlow',
          'Jerry Bichlmeier'
        ]));
  });

  test('Split: 2015, 2 split, manual', () async {
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

    scheduling.splitControl.addCluster({
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
      'Bob Bacinski',
      'Allan Conrad'
    });
    scheduling.splitControl.addCluster({
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
      'Karol McQueary',
      'Marilou Lieman',
      'Frank Pohlner',
      'Jerry Green'
    });

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
          'Frank Pohlner',
          'Karol McQueary',
          'Jerry Green'
        ]));
    expect(split2Result.length, 17);
    expect(
        split2Result,
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
          'Bob Bacinski',
          'Allan Conrad'
        ]));
    expect(split1Backup.length, 6);
    expect(
        split1Backup,
        containsAll([
          'Maria Ashla',
          'Gail Ruder',
          'Ruth Belonsky',
          'Carol Kern',
          'Ellen Tarlow',
          'Jerry Bichlmeier'
        ]));
    expect(split2Backup.length, 20);
    expect(
        split2Backup,
        containsAll([
          'John Vehrencamp',
          'Chuck Gray',
          'Ronnie Lemmi',
          'Fran Wielin',
          'Carlos Lemmi',
          'Andrea Gargaro',
          'Yvette Reiner',
          'Julie Citroen',
          'Carol Johnson',
          'Dennis Eggert',
          'Kirsten Loumeau',
          'Edith Eddleman',
          'Leslie Schettler',
          'Cathy Gallipeau',
          'Faye Schwartz',
          'Frances Roberts',
          'Bill Paul',
          'Dayla Sims',
          'Muriel Blatt',
          'Ginny Brown'
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
    var split1Backup = split1
        .map((person) => person.getName())
        .where((person) => !resultingClass.contains(person))
        .toList(growable: false);
    var split2Backup = split2
        .map((person) => person.getName())
        .where((person) => !resultingClass.contains(person))
        .toList(growable: false);
    var split3Backup = split3
        .map((person) => person.getName())
        .where((person) => !resultingClass.contains(person))
        .toList(growable: false);

    expect(split1Result.length, 13);
    expect(
        split1Result,
        containsAll([
          'Mel Schrier',
          'John Smith',
          'Mary Jo Little',
          'Helen Stockwell',
          'Hank Frankenberg',
          'McNair Maxwell',
          'Frank Reiner',
          'Jake Kamen',
          'Norman Stockwell',
          'Kate Nelson',
          'Jack Carmody',
          'Lynn Schubert',
          'Carmen Svensrud'
        ]));
    expect(split2Result.length, 11);
    expect(
        split2Result,
        containsAll([
          'Zelda Green',
          'Susan Fein',
          'Carol Wingate',
          'Leslie Criswell',
          'Joy Jurena',
          'Rebecca Hansen',
          'Marilou Lieman',
          'Bob Bacinski',
          'Karol McQueary',
          'Jerry Green',
          'Allan Conrad'
        ]));
    expect(split3Result.length, 11);
    expect(
        split3Result,
        containsAll([
          'Kirk Tuey',
          'Dennis Goodno',
          'Dennis Bosch',
          'Al Kovalsky',
          'Carolyn Pohlner',
          'Susan Egan',
          'Anne Faass',
          'Marcia Kovalsky',
          'Stan Pleatman',
          'Merle Culbert',
          'Frank Pohlner'
        ]));
    expect(split1Backup.length, 20);
    expect(
        split1Backup,
        containsAll([
          'John Vehrencamp',
          'Chuck Gray',
          'Ronnie Lemmi',
          'Maria Ashla',
          'Carlos Lemmi',
          'Gail Ruder',
          'Andrea Gargaro',
          'Yvette Reiner',
          'Julie Citroen',
          'Ruth Belonsky',
          'Carol Johnson',
          'Carol Kern',
          'Dennis Eggert',
          'Kirsten Loumeau',
          'Edith Eddleman',
          'Leslie Schettler',
          'Cathy Gallipeau',
          'Ellen Tarlow',
          'Dayla Sims',
          'Ginny Brown'
        ]));
    expect(split2Backup.length, 3);
    expect(split2Backup,
        containsAll(['Faye Schwartz', 'Muriel Blatt', 'Jerry Bichlmeier']));
    expect(split3Backup.length, 3);
    expect(split3Backup,
        containsAll(['Fran Wielin', 'Frances Roberts', 'Bill Paul']));
  });
}
