import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/coordinators.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omnilore_scheduler/theme.dart';
import 'package:omnilore_scheduler/widgets/class_name_display.dart';
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
  State<Screen> createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  /// this is the main scheduling data structure that holds back end computation
  Scheduling schedule = Scheduling();

  final GlobalKey<ClassNameDisplayState> _classNameDisplayKey = GlobalKey();

  int? numCourses;
  int? numPeople;
  List<String> curClassRoster = [];
  List<List<String>> curClusters = [];
  List<bool> droppedList = List<bool>.filled(14, false, growable: true);
  List<int> scheduleData = List<int>.filled(14, -1, growable: false);
  int mainSelected = 0;
  int coSelected = 0;

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
                      compute(Change.course);
                    } catch (e) {
                      if (context.mounted) {
                        Utils.showPopUp(
                            context, 'Error loading courses', e.toString());
                      }
                    }
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
                      if (context.mounted) {
                        Utils.showPopUp(
                            context, 'Error loading people', e.toString());
                      }
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
                      if (context.mounted) {
                        Utils.showPopUp(
                            context, 'Error saving state', e.toString());
                      }
                    }
                  }
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
                    setState(() {
                      try {
                        schedule.loadState(path);
                        courses = schedule.getCourseCodes().toList();
                        numCourses = courses.length;
                        var dropped = schedule.courseControl.getDropped();
                        droppedList = List<bool>.generate(
                            numCourses!, (i) => dropped.contains(courses[i]));
                      } catch (e) {
                        Utils.showPopUp(
                            context, 'Error loading state', e.toString());
                      }
                    });
                    compute(Change.course);
                  }
                }
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
                        if (context.mounted) {
                          Utils.showPopUp(context,
                              'Error exporting early roster', e.toString());
                        }
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
                        if (context.mounted) {
                          Utils.showPopUp(context,
                              'Error exporting roster with CC', e.toString());
                        }
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
                      if (context.mounted) {
                        Utils.showPopUp(
                            context, 'Error exporting MailMerge', e.toString());
                      }
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
                              .getPeopleForResultingClass(course)
                              .toList();
                          // Update coordinator data
                          Coordinators? coordinators =
                              schedule.courseControl.getCoordinators(course);
                          setState(() {
                            if (coordinators == null) {
                              mainSelected = 0;
                              coSelected = 0;
                            } else if (coordinators.equal) {
                              mainSelected = 0;
                              if (coordinators.coordinators[1].isNotEmpty) {
                                coSelected = 2;
                              } else {
                                coSelected = 1;
                              }
                            } else {
                              coSelected = 0;
                              if (coordinators.coordinators[1].isNotEmpty) {
                                mainSelected = 2;
                              } else {
                                mainSelected = 1;
                              }
                            }
                          });
                          break;
                        case RowType.firstChoice:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 0)
                              .toList();
                          break;
                        case RowType.firstBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 1)
                              .toList();
                          break;
                        case RowType.secondBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 2)
                              .toList();
                          break;
                        case RowType.thirdBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 3)
                              .toList();
                          break;
                        case RowType.addFromBackup:
                          curClassRoster = schedule.overviewData
                              .getPeopleAddFromBackup(course)
                              .toList();
                          break;
                        case RowType.dropBadTime:
                          curClassRoster = schedule.overviewData
                              .getPeopleDropTime(course)
                              .toList();
                          break;
                        case RowType.dropDup:
                          curClassRoster = schedule.overviewData
                              .getPeopleDropDup(course)
                              .toList();
                          break;
                        case RowType.dropFull:
                          curClassRoster = schedule.overviewData
                              .getPeopleDropFull(course)
                              .toList();
                          break;
                        case RowType.resultingClass:
                          curClassRoster = schedule.overviewData
                              .getPeopleForResultingClass(course)
                              .toList();
                          schedule.splitControl.resetState();
                          break;
                        default:
                          break;
                      }

                      currentClass = course;
                      schedule.splitControl.resetState();
                      currentRow = row;
                      List<String> tempList = curClassRoster.toList();
                      tempList.sort(
                          (a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                      curClassRoster = tempList;
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

                      List<String> tempList = curClassRoster.toList();
                      tempList.sort(
                          (a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                      curClassRoster = tempList;
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
    return SizedBox(
      height: 400,
      child: Row(
        children: [
          // State of processing widget and class name display widget
          SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: themeColors['MediumBlue'],
                  child: Text(
                      'State of Processing: ${stateDescriptions[schedule.getStateOfProcessing().index]}',
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ClassNameDisplay(
                      key: _classNameDisplayKey,
                      currentClass: currentClass,
                      currentRow: currentRow,
                      people: curClassRoster,
                      schedule: schedule),
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
                    onShowCoords: currentRow == RowType.className &&
                            (schedule.getStateOfProcessing() ==
                                    StateOfProcessing.coordinator ||
                                schedule.getStateOfProcessing() ==
                                    StateOfProcessing.output)
                        ? () {
                            ClassNameDisplayState state =
                                _classNameDisplayKey.currentState!;
                            state.showCoordinators();
                          }
                        : null,
                    onSetC: currentRow == RowType.className &&
                            schedule.getStateOfProcessing() ==
                                StateOfProcessing.coordinator &&
                            coSelected == 0 &&
                            mainSelected < 2
                        ? () {
                            ClassNameDisplayState state =
                                _classNameDisplayKey.currentState!;
                            state.setMainCoordinator();
                            setState(() {
                              mainSelected += 1;
                            });
                          }
                        : null,
                    onSetCC: currentRow == RowType.className &&
                            schedule.getStateOfProcessing() ==
                                StateOfProcessing.coordinator &&
                            mainSelected == 0 &&
                            coSelected < 2
                        ? () {
                            ClassNameDisplayState state =
                                _classNameDisplayKey.currentState!;
                            state.setCoCoordinator();
                            setState(() {
                              coSelected += 1;
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
                            curClassRoster = schedule.overviewData
                                .getPeopleUnmetWants()
                                .toList();
                          });
                        })),
              ],
            ),
          )
        ],
      ),
    );
  }
}
