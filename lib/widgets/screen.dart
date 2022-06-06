import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:omnilore_scheduler/main.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/coordinators.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omnilore_scheduler/theme.dart';
import 'package:omnilore_scheduler/widgets/class_size_control.dart';
import 'package:omnilore_scheduler/widgets/names_display_mode.dart';
import 'package:omnilore_scheduler/widgets/select_process.dart';
import 'package:omnilore_scheduler/widgets/table/main_table.dart';
import 'package:omnilore_scheduler/widgets/overview_data.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';
import 'package:omnilore_scheduler/widgets/table/schedule_row.dart';
import 'package:omnilore_scheduler/widgets/utils.dart';

const stateDescriptions = <String>[
  'Need Courses',
  'Need People',
  'Inconsistent',
  'Drop and Split',
  'Drop and Split',
  'Schedule',
  'Coordinator',
  'Output'
];

class Screen extends StatefulWidget {
  const Screen({Key? key}) : super(key: key);

  @override
  _ScreenState createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  /// this is the main scheduling data structure that holds back end computation
  Scheduling schedule = Scheduling();

  int? numCourses;
  int? numPeople;
  Map mainCoordinatorSelected = <String, bool>{};
  Map coCoordinatorSelected = <String, bool>{};
  Iterable<String> curClassRoster = [];
  Map curSelected = <String, bool>{};
  List<List<String>> curClusters = [];
  Map<Set<String>, Color> clustColors = <Set<String>, Color>{};
  List<bool> droppedList = List<bool>.filled(14, false, growable: true);
  List<int> scheduleData = List<int>.filled(14, -1, growable: false);

  Color masterBackgroundColor = themeColors['WhiteBlue'];
  Color detailBackgroundColor = Colors.blueGrey[300] as Color;

  late int courseTakers = schedule.overviewData.getNbrCourseTakers();
  late int goCourses = schedule.overviewData.getNbrGoCourses();
  late int placesAsked = schedule.overviewData.getNbrPlacesAsked();
  late int placesGiven = schedule.overviewData.getNbrPlacesGiven();
  late int unmetWants = schedule.overviewData.getNbrUnmetWants();
  late int onLeave = schedule.overviewData.getNbrOnLeave();

  List<String> courses = [];
  late var overviewMatrix = List<List<int>>.generate(overviewRows.length,
      (i) => List<int>.filled(numCourses ?? 14, 0, growable: false),
      growable: false);
  late var scheduleMatrix = List<List<int>>.generate(scheduleRows.length,
      (i) => List<int>.filled(numCourses ?? 14, 0, growable: false),
      growable: false);

  String? currentClass;
  RowType currentRow = RowType.none;

  void compute(Change change) {
    setState(() {
      if (change == Change.course) {
        _updateCourses();
      }
      _updateOverviewData();
      _updateOverviewMatrix();
      _updateScheduleMatrix();
      if (change == Change.course || change == Change.schedule) {
        _updateScheduleData();
      }
    });
  }

  /// Helper function to update courses
  void _updateCourses() {
    courses = schedule.getCourseCodes().toList();
  }

  /// Helper function to update all of overviewData
  void _updateOverviewData() {
    courseTakers = schedule.overviewData.getNbrCourseTakers();
    goCourses = schedule.overviewData.getNbrGoCourses();
    placesAsked = schedule.overviewData.getNbrPlacesAsked();
    placesGiven = schedule.overviewData.getNbrPlacesGiven();
    unmetWants = schedule.overviewData.getNbrUnmetWants();
    onLeave = schedule.overviewData.getNbrOnLeave();
  }

  /// Helper function to update the overview table data
  void _updateOverviewMatrix() {
    if (courses.length != overviewMatrix[0].length) {
      for (int i = 0; i < overviewMatrix.length; i++) {
        overviewMatrix[i] = List<int>.filled(courses.length, 0);
      }
    }
    for (int i = 0; i < overviewMatrix[0].length; i++) {
      var course = courses[i];
      for (int rank = 0; rank < 4; rank++) {
        overviewMatrix[rank][i] =
            schedule.overviewData.getNbrForClassRank(course, rank).size;
      }
      overviewMatrix[4][i] = schedule.overviewData.getNbrAddFromBackup(course);
      overviewMatrix[5][i] = schedule.overviewData.getNbrDropTime(course);
      overviewMatrix[6][i] = schedule.overviewData.getNbrDropDup(course);
      overviewMatrix[7][i] = schedule.overviewData.getNbrDropFull(course);
      overviewMatrix[8][i] =
          schedule.overviewData.getResultingClassSize(course).size;
    }
  }

  /// Helper function to update schedule data
  void _updateScheduleMatrix() {
    if (courses.length != scheduleMatrix[0].length) {
      for (int i = 0; i < scheduleMatrix.length; i++) {
        scheduleMatrix[i] = List<int>.filled(courses.length, 0);
      }
    }
    for (int i = 0; i < scheduleMatrix[0].length; i++) {
      var course = courses[i];
      for (int time = 0; time < 20; time++) {
        scheduleMatrix[time][i] =
            schedule.scheduleControl.getNbrUnavailable(course, time);
      }
    }
  }

  /// Helper function to update course schedule data
  void _updateScheduleData() {
    if (courses.length != scheduleData.length) {
      scheduleData = List<int>.filled(courses.length, -1, growable: false);
    }
    for (int i = 0; i < courses.length; i++) {
      scheduleData[i] = schedule.scheduleControl.scheduledTimeFor(courses[i]);
    }
  }

  /// Get the description of a row
  String _getRowDescription(RowType row) {
    if (row == RowType.className) {
      return _getRowDescription(RowType.resultingClass);
    }
    return overviewRows[row.index - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreen(
        masterPaneFixedWidth: true,
        detailPaneFlex: 0,
        menuList: [
          MenuItem(title: 'File', menuListItems: [
            MenuListItem(
              icon: Icons.open_in_new,
              title: 'Import Course',
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result != null) {
                  String path = result.files.single.path ?? '';
                  if (path != '') {
                    try {
                      numCourses = await schedule.loadCourses(path);
                      droppedList =
                          List<bool>.filled(numCourses!, false, growable: true);
                      // Setting the boolean map to check if main or coordinator
                      // has been set
                      for (var name in schedule.getCourseCodes()) {
                        mainCoordinatorSelected[name] = false;
                        coCoordinatorSelected[name] = false;
                      }
                      compute(Change.course);
                    } catch (e) {
                      Utils.showPopUp(
                          context, 'Error loading courses', e.toString());
                    }
                  } else {
                    // ignore: todo
                    //TODO: Add pop up box to show that the user canceled
                    //user canceled
                  }
                }
              },
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyO, ctrl: true),
            ),
            MenuListItem(
              title: 'Import People',
              icon: Icons.open_in_new,
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result != null) {
                  String path = result.files.single.path ?? '';
                  if (path != '') {
                    try {
                      numPeople = await schedule.loadPeople(path);
                    } catch (e) {
                      Utils.showPopUp(
                          context, 'Error loading people', e.toString());
                    }
                  }
                } else {
                  // User canceled the picker
                }
                compute(Change.people);
              },
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyP, ctrl: true),
            ),
            MenuListItem(
              title: 'Save',
              onPressed: () async {
                String? path = await FilePicker.platform.saveFile();

                if (path != null) {
                  if (path != '') {
                    try {
                      schedule.exportState(path);
                    } catch (e) {
                      Utils.showPopUp(
                          context, 'Error saving state', e.toString());
                    }
                  }
                } else {
                  //file picker canceled
                }
              },
            ),
            MenuListItem(
              title: 'Load',
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyD, ctrl: true),
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();
                if (kDebugMode) {
                  print('FILE PICKED');
                }

                if (result != null) {
                  String path = result.files.single.path ?? '';
                  if (kDebugMode) {
                    print(path);
                  }
                  if (path != '') {
                    try {
                      if (kDebugMode) {
                        print('its about to load');
                      }
                      setState(() {
                        schedule.loadState(path);

                        numCourses = schedule.getCourseCodes().length;
                      });
                      if (kDebugMode) {
                        print('LOADINGGGGGGGGGGG\n');
                      }
                    } catch (e) {
                      Utils.showPopUp(
                          context, 'Error loading state', e.toString());
                    }
                    //Coordinator code for load state
                    for (var name in schedule.getCourseCodes()) {
                      Coordinators? coordinator =
                          schedule.courseControl.getCoordinators(name);
                      if (coordinator != null) {
                        if (coordinator.equal) {
                          coCoordinatorSelected[name] = true;
                          mainCoordinatorSelected[name] = false;
                        } else {
                          mainCoordinatorSelected[name] = true;
                          coCoordinatorSelected[name] = false;
                        }
                        continue;
                      }
                      mainCoordinatorSelected[name] = false;
                      coCoordinatorSelected[name] = false;
                    }
                  }
                } else {
                  //file picker canceled
                }
                compute(Change.course);
              },
            ),
            MenuListItem(
                title: 'Export Early Roster',
                onPressed: () async {
                  String? path = await FilePicker.platform.saveFile();

                  if (path != null) {
                    if (path != '') {
                      try {
                        schedule.outputRosterPhone(path);
                      } catch (e) {
                        Utils.showPopUp(context, 'Error exporting early roster',
                            e.toString());
                      }
                    }
                  } else {
                    //file picker canceled
                  }
                }),
            MenuListItem(
                title: 'Export Final Roster',
                onPressed: () async {
                  String? path = await FilePicker.platform.saveFile();
                  if (path != null) {
                    if (path != '') {
                      try {
                        if (kDebugMode) {
                          print('name of file $path');
                        }
                        schedule.outputRosterCC(path);
                      } catch (e) {
                        Utils.showPopUp(context,
                            'Error exporting roster with CC', e.toString());
                      }
                    }
                  } else {
                    //file picker canceled
                  }
                }),
            MenuListItem(
              title: 'Export MailMerge',
              onPressed: () async {
                String? path = await FilePicker.platform.saveFile();

                if (path != null) {
                  if (path != '') {
                    try {
                      schedule.outputMM(path);
                    } catch (e) {
                      Utils.showPopUp(
                          context, 'Error exporting MailMerge', e.toString());
                    }
                  }
                } else {
                  //file picker canceled
                }
              },
            ),
          ]),
          MenuItem(title: 'View', isActive: true, menuListItems: [
            MenuListItem(title: 'View all'),
            MenuListItem(title: 'close view'),
            MenuListItem(title: 'jump to'),
            MenuListItem(title: 'go to'),
          ]),
          MenuItem(title: 'Help', isActive: true, menuListItems: [
            MenuListItem(title: 'Help'),
            MenuListItem(title: 'About'),
            MenuListItem(title: 'License'),
            MenuListDivider(),
            MenuListItem(title: 'Goodbye'),
          ]),
        ],
        masterPane: _masterPane(),
        detailPaneMinWidth: 0,
      ),
    );
  }

  /// This function builds the entire user interface which is split into the main
  /// datatable and screen1
  Builder _masterPane() {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          color: masterBackgroundColor,
          child: SingleChildScrollView(
              child: Column(
            children: [
              _screen1(),
              MainTable(
                  state: schedule.getStateOfProcessing(),
                  courses: numCourses == null
                      ? List<String>.filled(14, '')
                      : courses,
                  overviewMatrix: overviewMatrix,
                  scheduleMatrix: scheduleMatrix,
                  droppedList: droppedList,
                  scheduleData: scheduleData,
                  onCellPressed: (String course, RowType row) {
                    setState(() {
                      switch (row) {
                        case RowType.className:
                          curClassRoster = schedule.overviewData
                              .getPeopleForResultingClass(course);
                          break;
                        case RowType.firstChoice:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 0);
                          break;
                        case RowType.firstBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 1);
                          break;
                        case RowType.secondBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 2);
                          break;
                        case RowType.thirdBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 3);
                          break;
                        case RowType.addFromBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleAddFromBackup(course);
                          break;
                        case RowType.dropBadTime:
                          curClassRoster =
                              schedule.overviewData.getPeopleDropTime(course);
                          break;
                        case RowType.dropDup:
                          curClassRoster =
                              schedule.overviewData.getPeopleDropDup(course);
                          break;
                        case RowType.dropFull:
                          curClassRoster =
                              schedule.overviewData.getPeopleDropFull(course);
                          break;
                        case RowType.resultingClass:
                          curClassRoster = schedule.overviewData
                              .getPeopleForResultingClass(course);
                          break;
                        default:
                          break;
                      }

                      currentClass = course;
                      schedule.splitControl.resetState();
                      curSelected.clear();
                      clustColors.clear();
                      currentRow = row;
                      List<String> tempList = curClassRoster.toList();
                      tempList.sort(
                          (a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                      curClassRoster = tempList;
                      for (var name in curClassRoster) {
                        curSelected[name] = false;
                      }
                    });
                  },
                  onDroppedChanged: (int i) {
                    setState(() {
                      droppedList[i] = !droppedList[i];
                      if (droppedList[i] == true) {
                        schedule.courseControl
                            .drop(schedule.getCourseCodes().toList()[i]);
                      } else {
                        schedule.courseControl
                            .undrop(schedule.getCourseCodes().toList()[i]);
                      }
                    });
                    compute(Change.drop);
                  },
                  onSchedule: (String course, int timeIndex) {
                    setState(() {
                      currentClass = course;
                      schedule.splitControl.resetState();
                      schedule.scheduleControl
                          .schedule(currentClass!, timeIndex);

                      curSelected.clear();
                      clustColors.clear();
                      List<String> tempList = curClassRoster.toList();
                      tempList.sort(
                          (a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                      curClassRoster = tempList;
                      for (var name in curClassRoster) {
                        curSelected[name] = false;
                      }
                      if (kDebugMode) {
                        print(curClassRoster);
                      }
                      compute(Change.schedule);
                    });
                  })
            ],
          )),
        );
      },
    );
  }

  /// This is the base widget that holds everything in the UI that is not the datatable
  Widget _screen1() {
    // ignore: sized_box_for_whitespace
    return Container(
      height: 400,
      child: Row(
        children: [
          // State of processing widget and class name display widget
          // ignore: sized_box_for_whitespace
          Container(
            width: MediaQuery.of(context).size.width / 2,
            child: Column(
              children: [
                // ignore: todo
                // TODO: Update this to a string that changes based on the state
                Container(
                  width: double.infinity,
                  color: themeColors['MediumBlue'],
                  child: Text(
                      'State of Processing: ${stateDescriptions[schedule.getStateOfProcessing().index]}',
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: _classNameDisplay(),
                )
              ],
            ),
          ),

          //Class size control widget and Names display mode
          SizedBox(
            width: MediaQuery.of(context).size.width / 4,
            child: Column(
              children: [
                ClassSizeControl(
                    schedule: schedule, courses: courses, onChange: compute),
                Expanded(
                  child: NamesDisplayMode(
                    onImplSplit: currentRow == RowType.resultingClass &&
                            currentClass != null
                        ? () {
                            setState(() {
                              schedule.splitControl.split(currentClass!);
                              var newCourses = schedule.getCourseCodes();
                              droppedList.insertAll(
                                  courses.indexOf(currentClass!),
                                  List<bool>.filled(
                                      newCourses.length - courses.length,
                                      false));
                              currentClass = null;
                              currentRow = RowType.none;
                              curClassRoster = [];
                            });
                            compute(Change.course);
                          }
                        : null,
                    onShowCoords: _updateAndShowCO()
                        ? () {
                            setState(() {
                              Coordinators? coordinator = schedule.courseControl
                                  .getCoordinators(currentClass!);
                              if (coordinator != null) {
                                List<String> coordinatorsList =
                                    coordinator.coordinators;
                                for (int i = 0;
                                    i < coordinatorsList.length;
                                    i++) {
                                  if (coordinatorsList[i] != '') {
                                    curSelected[coordinatorsList[i]] =
                                        !curSelected[coordinatorsList[i]];
                                  }
                                }
                              }
                            });
                          }
                        : null,
                    onSetC: currentRow == RowType.className &&
                            stateDescriptions[
                                    schedule.getStateOfProcessing().index] ==
                                'Coordinator' &&
                            (coCoordinatorSelected.containsKey(currentClass!)
                                ? !coCoordinatorSelected[currentClass!]
                                : false)
                        ? () {
                            setState(() {
                              Iterable keysSelected = curSelected.keys.where(
                                  (element) => curSelected[element] == true);
                              if (keysSelected.length == 1) {
                                for (var item in keysSelected) {
                                  try {
                                    schedule.courseControl.setMainCoCoordinator(
                                        currentClass!, item);
                                  } on Exception catch (e) {
                                    Utils.showPopUp(context, 'Set C/CC error',
                                        e.toString());
                                  }
                                }
                                mainCoordinatorSelected[currentClass!] = true;
                                curSelected.forEach((key, value) {
                                  curSelected[key] = false;
                                });
                              } else {
                                Utils.showPopUp(
                                    context,
                                    'Set coordinator error',
                                    'Must select only one name at a time');
                              }
                            });
                          }
                        : null,
                    onSetCC: currentRow == RowType.className &&
                            stateDescriptions[
                                    schedule.getStateOfProcessing().index] ==
                                'Coordinator' &&
                            (mainCoordinatorSelected.containsKey(currentClass!)
                                ? !mainCoordinatorSelected[currentClass!]
                                : false)
                        ? () {
                            setState(() {
                              Iterable keysSelected = curSelected.keys.where(
                                  (element) => curSelected[element] == true);
                              if (keysSelected.length == 1) {
                                for (var item in keysSelected) {
                                  try {
                                    schedule.courseControl
                                        .setEqualCoCoordinator(
                                            currentClass!, item);
                                  } on Exception catch (ex) {
                                    if (kDebugMode) {
                                      print(ex);
                                    }
                                  }
                                }
                                coCoordinatorSelected[currentClass!] = true;
                                curSelected.forEach((key, value) {
                                  curSelected[key] = false;
                                });
                              } else {
                                Utils.showPopUp(
                                    context,
                                    'Select coordinator error',
                                    'Must select only one name at a time');
                              }
                            });
                          }
                        : null,
                  ),
                )
              ],
            ),
          ),
          //Select process and Aux data
          SizedBox(
            width: MediaQuery.of(context).size.width / 4 - 5,
            child: Column(
              children: [
                const SelectProcess(),
                Expanded(
                    child: OverviewData(
                        placesAsked: placesAsked,
                        placesGiven: placesGiven,
                        goCourses: goCourses,
                        unmetWants: unmetWants,
                        onLeave: onLeave,
                        courseTakers: courseTakers,
                        onUnmetWantsClicked: () {
                          setState(() {
                            curClassRoster =
                                schedule.overviewData.getPeopleUnmetWants();
                            schedule.splitControl.resetState();
                            curSelected.clear();
                            clustColors.clear();
                          });
                        })),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Creates the class name display portion of the User interface. buttons referencing
  /// clustering and current class roster is displayed here
  Widget _classNameDisplay() {
    return Container(
      color: themeColors['MoreBlue'],
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: const Text('CLASS NAMES DISPLAY',
              style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
        ),
        Container(
          alignment: Alignment.center,
          child: const Text('Show constituents by clicking a desired cell.',
              style: TextStyle(fontSize: 15)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: currentRow == RowType.resultingClass
                    ? () {
                        setState(() {
                          for (var item in curSelected.keys.where(
                              (element) => curSelected[element] == true)) {
                            schedule.splitControl.removeCluster(item);
                          }
                          curSelected.forEach((key, value) {
                            curSelected[key] = false;
                          });
                        });
                      }
                    : null,
                child: const Text('Dec Clust')),
            ElevatedButton(
                onPressed: currentRow == RowType.resultingClass
                    ? () {
                        setState(() {
                          Set<String> result = <String>{};
                          for (var item in curSelected.keys.where(
                              (element) => curSelected[element] == true)) {
                            result.add(item);
                          }
                          schedule.splitControl.addCluster(result);
                          clustColors[result.toSet()] = _randomColor();
                          curSelected.forEach((key, value) {
                            curSelected[key] = false;
                          });
                          if (kDebugMode) {
                            print(result);
                          }
                        });
                      }
                    : null,
                child: const Text('Inc Clust')),
            const ElevatedButton(onPressed: null, child: Text('Back')),
            const ElevatedButton(onPressed: null, child: Text('Forward')),
          ],
        ),
        Row(
          children: [
            if (currentRow != RowType.none)
              Text(
                '${_getRowDescription(currentRow)} of $currentClass',
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              )
          ],
          mainAxisAlignment: MainAxisAlignment.start,
        ),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (var val in curClassRoster)
              ElevatedButton(
                  style: (() {
                    if (curSelected[val] == true) {
                      return ElevatedButton.styleFrom(
                          primary: Colors.red, onPrimary: Colors.white);
                    } else {
                      if (schedule.splitControl.isClustured(val.toString()) ==
                          true) {
                        Color r = _getColorKey(val);
                        return ElevatedButton.styleFrom(primary: r);
                      } else {
                        return ElevatedButton.styleFrom(primary: Colors.white);
                      }
                    }
                  }()),
                  onPressed: () {
                    setState(() {
                      if (curSelected[val]) {
                        curSelected[val] = false;
                      } else {
                        curSelected[val] = true;
                      }
                    });
                  },
                  child: Text(
                    val.toString(),
                    style: (() {
                      if (schedule.splitControl.isClustured(val) == true &&
                          _getColorKey(val) == Colors.brown) {
                        return const TextStyle(color: Colors.white);
                      } else {
                        const TextStyle(color: Colors.black);
                      }
                    }()),
                  ))
          ],
        ),
        Container(
          color: Colors.white,
        )
      ]),
    );
  }

  /// Returns a random color from the cluster colors list
  Color _randomColor() {
    colorNum++;
    return clusterColors[colorNum % clusterColors.length];
  }

  /// given a person return its given clustering color. If this person is not in
  /// a cluster it will return yellow
  Color _getColorKey(String person) {
    Set<String> test =
        schedule.splitControl.getClustByPerson(person) ?? <String>{};
    for (Set<String> item in clustColors.keys) {
      if (item.length == test.length && test.containsAll(item)) {
        return clustColors[item] ?? Colors.grey;
      }
    }
    return Colors.yellow;
  }

  bool _updateAndShowCO() {
    List<String> classes = schedule.getCourseCodes().toList();
    if (stateDescriptions[schedule.getStateOfProcessing().index] ==
        'Schedule') {
      mainCoordinatorSelected.clear();
      coCoordinatorSelected.clear();
      for (var name in classes) {
        mainCoordinatorSelected[name] = false;
        coCoordinatorSelected[name] = false;
      }
    }

    return currentRow == RowType.className &&
        (stateDescriptions[schedule.getStateOfProcessing().index] ==
                'Coordinator' ||
            stateDescriptions[schedule.getStateOfProcessing().index] ==
                'Output') &&
        (mainCoordinatorSelected[currentClass!] ||
            coCoordinatorSelected[currentClass!]);
  }
}
