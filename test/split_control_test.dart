import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

/// This file tests course split functionalities.
void main() {
  test('Split: 2015, 2 clusters', () async {
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
          'Zelda Green',
          'Susan Fein',
          'Dennis Goodno',
          'Mary Jo Little',
          'Carolyn Pohlner',
          'Susan Egan',
          'Joy Jurena',
          'Jake Kamen',
          'Rebecca Hansen',
          'Norman Stockwell',
          'Kate Nelson',
          'Lynn Schubert',
          'Marilou Lieman',
          'Carmen Svensrud',
          'Karol McQueary',
          'Frank Pohlner',
          'Jerry Green',
          'Allan Conrad'
        ]));
    expect(split2Result.length, 17);
    expect(
        split2Result,
        containsAll([
          'Mel Schrier',
          'Kirk Tuey',
          'Dennis Bosch',
          'John Smith',
          'Carol Wingate',
          'Helen Stockwell',
          'Al Kovalsky',
          'Leslie Criswell',
          'Hank Frankenberg',
          'Anne Faass',
          'McNair Maxwell',
          'Frank Reiner',
          'Marcia Kovalsky',
          'Jack Carmody',
          'Stan Pleatman',
          'Bob Bacinski',
          'Merle Culbert'
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
}
