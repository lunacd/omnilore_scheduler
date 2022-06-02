import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:omnilore_scheduler/main.dart';
import 'package:omnilore_scheduler/model/coordinators.dart';
import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omnilore_scheduler/theme.dart';
import 'package:omnilore_scheduler/widgets/table/main_table.dart';
import 'package:omnilore_scheduler/widgets/overview_data.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';
import 'package:omnilore_scheduler/widgets/table/schedule_row.dart';

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

  /// The current state that the program is in
  StateOfProcessing curState = StateOfProcessing.needCourses;
  bool coursesImported = false;
  bool peopleImported = false;
  int? numCourses;
  int? numPeople;
  Map mainCoordinatorSelected = <String, bool>{};
  Map coCoordinatorSelected = <String, bool>{};
  final minTextField = TextEditingController();
  final maxTextField = TextEditingController();
  String hintMax = 'Max';
  String hintMin = 'Min';
  String minVal = '';
  String maxVal = '';
  String curClass = '';
  String curCell = '';
  String dropDownVal = '';
  String minMaxError = '';
  String mode = 'splitting';
  Iterable<String> curClassRoster = [];
  Map curSelected = <String, bool>{};
  List<List<String>> curClusters = [];
  Map<Set<String>, Color> clustColors = <Set<String>, Color>{};
  bool resultingClass = false;
  bool classCodes = false;
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

  /// Helper function to update all of overviewData
  void _updateOverviewData() {
    courseTakers = schedule.overviewData.getNbrCourseTakers();
    goCourses = schedule.overviewData.getNbrGoCourses();
    placesAsked = schedule.overviewData.getNbrPlacesAsked();
    placesGiven = schedule.overviewData.getNbrPlacesGiven();
    unmetWants = schedule.overviewData.getNbrUnmetWants();
    onLeave = schedule.overviewData.getNbrOnLeave();
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

  /// Helper function to update courses
  void _updateCourses() {
    courses = schedule.getCourseCodes().toList();
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

  /// This class is a private computation function that sets the min and max class
  /// size for each class
  void _setMinMaxClass() {
    if (kDebugMode) {
      print(schedule.courseControl.getSplitMode(dropDownVal).toString());
    }
    setState(() {
      if (kDebugMode) {
        print('Current class selected $dropDownVal $minVal $maxVal');
      }
      if (minVal != '' && maxVal != '' && coursesImported) {
        try {
          int minV = int.parse(minVal);
          int maxV = int.parse(maxVal);
          if (dropDownVal == 'ALL') {
            schedule.courseControl.setGlobalMinMaxClassSize(minV, maxV);

            schedule.courseControl.isMaxSizeMixed()
                ? hintMax = 'Mix'
                : hintMax = schedule.courseControl
                    .getMaxClassSize(dropDownVal)
                    .toString();
            schedule.courseControl.isMinSizeMixed()
                ? hintMin = 'Mix'
                : hintMin = schedule.courseControl
                    .getMinClassSize(dropDownVal)
                    .toString();
          } else {
            schedule.courseControl
                .setMinMaxClassSizeForClass(dropDownVal, minV, maxV);
            hintMax =
                schedule.courseControl.getMaxClassSize(dropDownVal).toString();
            hintMin =
                schedule.courseControl.getMinClassSize(dropDownVal).toString();
          }
          minVal = maxVal = '';
          minTextField.clear();
          maxTextField.clear();

          if (kDebugMode) {
            print('Min and max set with vals $minV $maxV');
          }

          //split and limit toggle goes here!
          SplitMode currmode;

          if (mode == 'splitting') {
            currmode = SplitMode.split;
          } else {
            currmode = SplitMode.limit;
          }

          schedule.courseControl.setSplitMode(dropDownVal, currmode);
        } on Exception {
          // ignore: todo
          //TODO: Add the pop up alert to show the error
          if (kDebugMode) {
            print('Error parsing the int');
          }
          minTextField.clear();
          maxTextField.clear();
        }
      } else {
        if (minVal == '' && maxVal == '') {
          minMaxError = 'Please enter a value for min and max';
        } else if (minVal == '') {
          minMaxError = 'Please enter a value for min';
        } else if (maxVal == '') {
          minMaxError = 'Please enter a value for max';
        } else {
          minMaxError = 'Please import courses';
        }
        popUp();
        minTextField.clear();
        maxTextField.clear();
        minVal = '';
        maxVal = '';
      }
      _updateOverviewData();
    });
  }

  Future<void> customPopUp(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // must be dismissed
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Choice'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// creates an error popup for class sizing
  Future<void> popUp() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // must be dismissed
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error setting class size'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Hint'),
                Text(minMaxError),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreen(
        masterPaneFixedWidth: true,
        detailPaneFlex: 0,
        // ignore: todo
        //TODO: Update the menuList
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
                      dropDownVal = 'ALL';
                      hintMax = schedule.courseControl
                          .getMaxClassSize('ALL')
                          .toString();
                      hintMin = schedule.courseControl
                          .getMinClassSize('ALL')
                          .toString();
                      minVal = '';
                      maxVal = '';
                      minTextField.clear();
                      maxTextField.clear();
                      coursesImported = true;
                      //Setting the boolean map to check if main or coordinator
                      //has been set
                      for (var name in schedule.getCourseCodes()) {
                        mainCoordinatorSelected[name] = false;
                        coCoordinatorSelected[name] = false;
                      }
                      _updateCourses();
                      _updateOverviewMatrix();
                      _updateScheduleMatrix();
                      _updateScheduleData();
                    } catch (e) {
                      _showMyDialog(e.toString(), 'courses');
                    }
                  } else {
                    // ignore: todo
                    //TODO: Add pop up box to show that the user canceled
                    //user canceled
                  }
                }
                setState(() {
                  _updateOverviewData();
                });
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
                      //FormatException s = e.source;
                      _showMyDialog(e.toString(), 'people');
                    }
                  }
                  dropDownVal = 'ALL';
                  hintMax =
                      schedule.courseControl.getMaxClassSize('ALL').toString();
                  hintMin =
                      schedule.courseControl.getMinClassSize('ALL').toString();
                  minVal = '';
                  maxVal = '';
                  minTextField.clear();
                  maxTextField.clear();
                  peopleImported = true;
                } else {
                  // User canceled the picker
                }
                setState(() {
                  _updateOverviewData();
                  _updateOverviewMatrix();
                  _updateScheduleMatrix();
                });
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
                      _showMyDialog(e.toString(), 'save');
                    }
                  }
                } else {
                  //file picker canceled
                }
                setState(() {
                  _updateOverviewData();
                });
              },
            ),
            MenuListItem(
              title: 'Load',
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyD, ctrl: true),
              onPressed: () async {
                if (peopleImported == true) {
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
                          updateDropped();
                          _updateOverviewData();
                        });
                        if (kDebugMode) {
                          print('LOADINGGGGGGGGGGG\n');
                        }
                      } catch (e) {
                        _showMyDialog(e.toString(), 'load');
                      }
                      dropDownVal = 'ALL';
                      hintMax = schedule.courseControl
                          .getMaxClassSize('ALL')
                          .toString();
                      hintMin = schedule.courseControl
                          .getMinClassSize('ALL')
                          .toString();
                      minVal = '';
                      maxVal = '';
                      minTextField.clear();
                      maxTextField.clear();
                      peopleImported = true;
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
                  setState(() {
                    _updateOverviewData();
                  });
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
                        _showMyDialog(e.toString(), 'EarlyRoster');
                      }
                    }
                  } else {
                    //file picker canceled
                  }
                  setState(() {
                    _updateOverviewData();
                  });
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
                        _showMyDialog(e.toString(), 'RosterCC');
                      }
                    }
                  } else {
                    //file picker canceled
                  }
                  setState(() {
                    _updateOverviewData();
                  });
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
                      _showMyDialog(e.toString(), 'MailMerge');
                    }
                  }
                } else {
                  //file picker canceled
                }
                setState(() {
                  _updateOverviewData();
                });
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
        masterPane: masterPane(),
        detailPaneMinWidth: 0,
      ),
    );
  }

  /// This function builds the entire user interface which is split into the main
  /// datatable and screen1
  Builder masterPane() {
    if (kDebugMode) {
      print('BUILD: masterPane');
    }

    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          color: masterBackgroundColor,
          child: SingleChildScrollView(
              child: Column(
            children: [
              screen1(),
              MainTable(
                  state: schedule.getStateOfProcessing(),
                  courses: numCourses == null
                      ? List<String>.filled(14, '')
                      : courses,
                  overviewMatrix: overviewMatrix,
                  scheduleMatrix: scheduleMatrix,
                  droppedList: droppedList,
                  scheduleData: scheduleData,
                  onCellPressed: (String course, int rowIndex) {
                    setState(() {
                      switch (rowIndex) {
                        case 0:
                          curClassRoster = schedule.overviewData
                              .getPeopleForResultingClass(course);
                          resultingClass = false;
                          classCodes = true;
                          break;
                        case 1:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 0);
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 2:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 1);
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 3:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 2);
                          if (kDebugMode) {
                            print(curClassRoster);
                          }
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 4:
                          curClassRoster = schedule.overviewData
                              .getPeopleForClassRank(course, 3);
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 5:
                          curClassRoster = schedule.overviewData
                              .getPeopleAddFromBackup(course);
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 6:
                          curClassRoster =
                              schedule.overviewData.getPeopleDropTime(course);
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 7:
                          curClassRoster = [];
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 8:
                          curClassRoster = [];
                          resultingClass = false;
                          classCodes = false;
                          break;
                        case 9:
                          curClassRoster = schedule.overviewData
                              .getPeopleForResultingClass(course);
                          resultingClass = true;
                          classCodes = false;
                          break;
                      }

                      curClass = course;
                      schedule.splitControl.resetState();
                      curSelected.clear();
                      clustColors.clear();
                      if (rowIndex == 0) {
                        curCell = '';
                      } else {
                        curCell = overviewRows[rowIndex - 1];
                      }
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
                      if (kDebugMode) {
                        print(
                            'dropped list index: $i drop list value: ${droppedList[i]}');
                      }
                      _updateOverviewData();
                      _updateOverviewMatrix();
                      _updateScheduleMatrix();
                    });
                  },
                  onSchedule: (String course, int timeIndex) {
                    setState(() {
                      curClass = course;
                      schedule.splitControl.resetState();
                      schedule.scheduleControl.schedule(curClass, timeIndex);

                      curSelected.clear();
                      clustColors.clear();
                      curCell = scheduleRows[timeIndex];
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
                      _updateOverviewData();
                      _updateScheduleData();
                      _updateOverviewMatrix();
                      _updateScheduleMatrix();
                    });
                  })
            ],
          )),
        );
      },
    );
  }

  /// This is the base widget that holds everything in the UI that is not the datatable
  Widget screen1() {
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
                  child: classNameDisplay(),
                )
              ],
            ),
          ),

          //Class size control widget and Names display mode
          SizedBox(
            width: MediaQuery.of(context).size.width / 4,
            child: Column(
              children: [
                classSizeControl(),
                Expanded(
                  child: namesDisplayMode(),
                )
              ],
            ),
          ),

          //Select process and Aux data
          SizedBox(
            width: MediaQuery.of(context).size.width / 4 - 5,
            child: Column(
              children: [
                selectProcess(),
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
  Widget classNameDisplay() {
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
                onPressed: resultingClass == true
                    ? () {
                        setState(() {
                          for (var item in curSelected.keys.where(
                              (element) => curSelected[element] == true)) {
                            schedule.splitControl.removeCluster(item);
                          }
                          curSelected.forEach((key, value) {
                            curSelected[key] = false;
                          });
                          _updateOverviewData();
                        });
                      }
                    : null,
                child: const Text('Dec Clust')),
            ElevatedButton(
                onPressed: resultingClass == true
                    ? () {
                        setState(() {
                          Set<String> result = <String>{};
                          for (var item in curSelected.keys.where(
                              (element) => curSelected[element] == true)) {
                            result.add(item);
                          }
                          schedule.splitControl.addCluster(result);
                          clustColors[result.toSet()] = randomColor();
                          curSelected.forEach((key, value) {
                            curSelected[key] = false;
                          });
                          if (kDebugMode) {
                            print(result);
                          }
                          _updateOverviewData();
                        });
                      }
                    : null,
                child: const Text('Inc Clust')),
            const ElevatedButton(onPressed: null, child: Text('Back')),
            const ElevatedButton(onPressed: null, child: Text('Forward')),
          ],
        ),
        Row(
          children: (() {
            if (curCell.startsWith('1') ||
                curCell.startsWith('2') ||
                curCell == '' ||
                curClass == '') {
              // print('*********$curCell******');
              return [const Text('')];
            } else if (curCell == '  ') {
              return [
                Text(
                  'Current Class: $curClass',
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold),
                )
              ];
            } else {
              return [
                Text(
                  '$curCell of $curClass',
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold),
                )
              ];
            }
          }()),
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
                        Color r = getColorKey(val);
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
                      if (classCodes) {}
                      _updateOverviewData();
                    });
                  },
                  child: Text(
                    val.toString(),
                    style: (() {
                      if (schedule.splitControl.isClustured(val) == true &&
                          getColorKey(val) == Colors.brown) {
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
  Color randomColor() {
    colorNum++;
    return clusterColors[colorNum % clusterColors.length];
  }

  /// given a person return its given clustering color. If this person is not in
  /// a cluster it will return yellow
  Color getColorKey(String person) {
    Set<String> test =
        schedule.splitControl.getClustByPerson(person) ?? <String>{};
    for (Set<String> item in clustColors.keys) {
      if (item.length == test.length && test.containsAll(item)) {
        return clustColors[item] ?? Colors.grey;
      }
    }
    return Colors.yellow;
  }

  /// Creates widget that allows for viewing and modifying of class sizes
  Widget classSizeControl() {
    return Container(
      color: themeColors['LightBlue'],
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            child: const Text('CLASS SIZE CONTROL',
                style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
          ),
          Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Limit ', style: TextStyle(fontSize: 15)),
                classDropDownMenu(),
                const Text('courses to', style: TextStyle(fontSize: 15))
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                  width: 100,
                  child: TextField(
                      onChanged: (value) => minVal = value,
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(),
                        hintText: hintMin,
                      ),
                      controller: minTextField,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        height: 1.25,
                        color: Colors.black,
                      ))),
              SizedBox(
                  width: 100,
                  child: TextField(
                      onChanged: (value) => maxVal = value,
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(),
                        hintText: hintMax,
                      ),
                      controller: maxTextField,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          height: 1.25,
                          color: Colors.black))),
            ],
          ),
          Row(
            children: const [
              SizedBox(height: 10),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 25.0,
                width: 100.0,
                child: ElevatedButton(
                  onPressed: () {
                    setState((() {
                      if (mode == 'limiting') {
                        mode = 'splitting';
                      } else {
                        mode = 'limiting';
                      }
                      _updateOverviewData();
                    }));
                  },
                  child: Text(mode),
                ),
              ),
              SizedBox(
                height: 25.0,
                width: 100.0,
                child: ElevatedButton(
                    onPressed: _setMinMaxClass, child: const Text('   set   ')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Creates the name display mode set of buttons. This includes show splits,
  /// show BU & CA, Implement splits, Show Coord(s), Set C and CC, Set CC1 and CC2
  Widget namesDisplayMode() {
    return Container(
        // height: double.infinity,
        color: themeColors['KindaBlue'],
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Container(
            alignment: Alignment.center,
            child: const Text('NAMES DISPLAY MODE',
                style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
          ),
          const ElevatedButton(onPressed: null, child: Text('Show BU & CA')),
          const ElevatedButton(onPressed: null, child: Text('Show Splits')),
          ElevatedButton(
              onPressed: resultingClass == true && curClass != ''
                  ? () {
                      setState(() {
                        int splitNum = computeSplitSize(curClass);
                        if (kDebugMode) {
                          print(splitNum);
                        }
                        numCourses = numCourses! + splitNum;
                        Iterable<String> temp =
                            schedule.getCourseCodes(); // get list of courses
                        List<String> res = temp.toList(); // dumb type casting
                        for (var i = 0; i < splitNum; i++) {
                          droppedList.insert(res.indexOf(curClass), false);
                        } // insert "not dropped" value for new class
                        schedule.splitControl.split(
                            curClass); // rest is reseting dynamic variables
                        schedule.splitControl.resetState();
                        curClass = '';
                        schedule.splitControl.resetState();
                        curCell = '';
                        curClassRoster = [];
                        _updateCourses();
                        _updateOverviewData();
                        _updateOverviewMatrix();
                        _updateScheduleMatrix();
                        _updateScheduleData();
                      });
                    }
                  : null,
              child: const Text('Imp. Splits')),
          ElevatedButton(
              onPressed: updateAndShowCO()
                  ? () {
                      setState(() {
                        Coordinators? coordinator =
                            schedule.courseControl.getCoordinators(curClass);
                        if (coordinator != null) {
                          List<String> coordinatorsList =
                              coordinator.coordinators;
                          if (kDebugMode) {
                            print('**********got coordinators*********');
                          }
                          for (int i = 0; i < coordinatorsList.length; i++) {
                            // if (kDebugMode) {
                            if (kDebugMode) {
                              print(coordinatorsList[i]);
                            }
                            if (coordinatorsList[i] != '') {
                              curSelected[coordinatorsList[i]] =
                                  !curSelected[coordinatorsList[i]];
                            }

                            // }
                          }
                        }
                        _updateOverviewData();
                      });
                    }
                  : null, //(() {

              //}),
              child: const Text('Show Coord(s)')),
          ElevatedButton(
              onPressed: classCodes == true &&
                      stateDescriptions[
                              schedule.getStateOfProcessing().index] ==
                          'Coordinator' &&
                      (coCoordinatorSelected.containsKey(curClass)
                          ? !coCoordinatorSelected[curClass]
                          : false)
                  ? () {
                      setState(() {
                        Iterable keysSelected = curSelected.keys
                            .where((element) => curSelected[element] == true);
                        if (keysSelected.length == 1) {
                          // ignore: todo
                          // TODO: Add pop up box to indicate error
                          // ignore: avoid_print
                          for (var item in keysSelected) {
                            try {
                              schedule.courseControl
                                  .setMainCoCoordinator(curClass, item);
                            } on Exception catch (ex) {
                              // ignore: todo
                              //TODO: print out exception
                              // ignore: avoid_print
                              print(ex);
                            }
                          }
                          mainCoordinatorSelected[curClass] = true;
                          curSelected.forEach((key, value) {
                            curSelected[key] = false;
                          });
                        } else {
                          customPopUp('Error: Must select only one name');
                          // if (kDebugMode) {
                          //   print('Error: Must select only one name');
                          // }
                        }
                        _updateOverviewData();
                      });
                    }
                  : null,
              child: const Text('Set C and CC')),
          ElevatedButton(
              onPressed: classCodes == true &&
                      stateDescriptions[
                              schedule.getStateOfProcessing().index] ==
                          'Coordinator' &&
                      (mainCoordinatorSelected.containsKey(curClass)
                          ? !mainCoordinatorSelected[curClass]
                          : false)
                  ? () {
                      setState(() {
                        Iterable keysSelected = curSelected.keys
                            .where((element) => curSelected[element] == true);
                        if (keysSelected.length == 1) {
                          // ignore: todo
                          // TODO: Add pop up box to indicate error
                          // ignore: avoid_print
                          for (var item in keysSelected) {
                            try {
                              schedule.courseControl
                                  .setEqualCoCoordinator(curClass, item);
                            } on Exception catch (ex) {
                              // ignore: todo
                              //TODO: print out exception
                              // ignore: avoid_print
                              print(ex);
                            }
                          }
                          coCoordinatorSelected[curClass] = true;
                          curSelected.forEach((key, value) {
                            curSelected[key] = false;
                          });
                        } else {
                          customPopUp('Error: Must select only one name');
                          // if (kDebugMode) {
                          //   print('Error: Must select only one name');
                          // }
                        }
                        _updateOverviewData();
                      });
                    }
                  : null,
              child: const Text('Set CC1 and CC2')),
        ]));
  }

  bool updateAndShowCO() {
    // print("****************HELLO***********");
    List<String> classes = schedule.getCourseCodes().toList();
    if (stateDescriptions[schedule.getStateOfProcessing().index] ==
        'Schedule') {
      // if (mainCoordinatorSelected.length != classes.length) {
      mainCoordinatorSelected.clear();
      coCoordinatorSelected.clear();
      for (var name in classes) {
        mainCoordinatorSelected[name] = false;
        coCoordinatorSelected[name] = false;
        // }
      }
    }

    return classCodes == true &&
        (stateDescriptions[schedule.getStateOfProcessing().index] ==
                'Coordinator' ||
            stateDescriptions[schedule.getStateOfProcessing().index] ==
                'Output') &&
        (mainCoordinatorSelected[curClass] || coCoordinatorSelected[curClass]);
  }

  Widget selectProcess() {
    return Container(
        color: themeColors['KindaBlue'],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              alignment: Alignment.center,
              child: const Text('SELECT PROCESS',
                  style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
            ),
            const ElevatedButton(
                onPressed: null, child: Text('Enter/Edit Crs')),
            const ElevatedButton(
                onPressed: null, child: Text('Display Courses')),
            const ElevatedButton(
                onPressed: null, child: Text('Enter/Edit Ppl')),
            const ElevatedButton(
                onPressed: null, child: Text('New Curriculum')),
            const ElevatedButton(
                onPressed: null, child: Text('Cont. Old Curriculum')),
          ],
        ));
  }

  /// Widget that creates a drop down menu of courses used to display class size
  /// maximums and minimums
  Widget classDropDownMenu() {
    //String dropDownVal = schedule.getCourseCodes().take(1).toString();
    return DropdownButton(
        hint: Text(dropDownVal),
        items: (schedule.getCourseCodes().isEmpty
                ? schedule.getCourseCodes()
                : <String>['ALL'].followedBy(schedule.getCourseCodes()))
            .map((String value)
                // schedule.getCourseCodes().map((String value)
                {
          return DropdownMenuItem(
            child: Text(value),
            value: value,
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            dropDownVal = newValue!;
            if (dropDownVal == 'ALL') {
              // minVal = maxVal = '';
              schedule.courseControl.isMaxSizeMixed()
                  ? hintMax = 'Mix'
                  : hintMax = schedule.courseControl
                      .getMaxClassSize(dropDownVal)
                      .toString();
              schedule.courseControl.isMinSizeMixed()
                  ? hintMin = 'Mix'
                  : hintMin = schedule.courseControl
                      .getMinClassSize(dropDownVal)
                      .toString();
            } else {
              hintMax = schedule.courseControl
                  .getMaxClassSize(dropDownVal)
                  .toString();
              hintMin = schedule.courseControl
                  .getMinClassSize(dropDownVal)
                  .toString();
            }
            _updateOverviewData();
          });
        });
  }

  /// This is a helper function that will compute the number of new colums needed
  /// in the table if a given course were to be split.
  int computeSplitSize(String course) {
    int courseSize = schedule.overviewData.getResultingClassSize(course).size;
    int maxSize = schedule.courseControl.getMaxClassSize(course);
    int numSplits = (courseSize / maxSize).ceil();

    return numSplits - 1;
  }

  /// This is a helper function ran after a save state is imported. The function
  /// will update the front end to reflect the new information on the back end
  /// regarding which classes are dropped
  void updateDropped() {
    while (droppedList.length != numCourses) {
      droppedList.add(false);
    }
    for (var i = 0; i < droppedList.length; i++) {
      droppedList[i] = false;
    }
    List<String> classes = schedule.getCourseCodes().toList();
    for (var i = 0; i < classes.length; i++) {
      if (schedule.courseControl.isDropped(classes[i])) {
        droppedList[i] = true;
      }
    }
  }

  // /// translation function that will take a time slot and return the correct
  // /// index used by input files. Returns -1 on an unknown timeslot name
  // int getTimeIndex(String c) {
  //   int timeIndex = -1;
  //   if (c == '1st/3rd Mon AM') {
  //     timeIndex = 0;
  //   } else if (c == '1st/3rd Mon PM') {
  //     timeIndex = 1;
  //   } else if (c == '1st/3rd Tue AM') {
  //     timeIndex = 2;
  //     if (kDebugMode) {
  //       print(curClassRoster);
  //     }
  //   } else if (c == '1st/3rd Tue PM') {
  //     timeIndex = 3;
  //   } else if (c == '1st/3rd Wed AM') {
  //     timeIndex = 4;
  //   } else if (c == '1st/3rd Wed PM') {
  //     timeIndex = 5;
  //   } else if (c == '1st/3rd Thu AM') {
  //     timeIndex = 6;
  //   } else if (c == '1st/3rd Thu PM') {
  //     timeIndex = 7;
  //   } else if (c == '1st/3rd Fri AM') {
  //     timeIndex = 8;
  //   } else if (c == '1st/3rd Fri PM') {
  //     timeIndex = 9;
  //   } else if (c == '2nd/4th Mon AM') {
  //     timeIndex = 10;
  //   } else if (c == '2nd/4th Mon PM') {
  //     timeIndex = 11;
  //   } else if (c == '2nd/4th Tue AM') {
  //     timeIndex = 12;
  //   } else if (c == '2nd/4th Tue PM') {
  //     timeIndex = 13;
  //   } else if (c == '2nd/4th Wed AM') {
  //     timeIndex = 14;
  //   } else if (c == '2nd/4th Wed PM') {
  //     timeIndex = 15;
  //   } else if (c == '2nd/4th Thu AM') {
  //     timeIndex = 16;
  //   } else if (c == '2nd/4th Thu PM') {
  //     timeIndex = 17;
  //   } else if (c == '2nd/4th Fri AM') {
  //     timeIndex = 18;
  //   } else if (c == '2nd/4th Fri PM') {
  //     timeIndex = 19;
  //   }
  //   return timeIndex;
  // }

  /// generic error pop up generator. Will produce a popup dialog box
  /// on the screen and show what error has been thrown to the user
  Future<void> _showMyDialog(String error, String loadType) async {
    // found at https://docs.flutter.dev/cookbook/forms/text-input
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('There was a problem loading the $loadType file'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('The following error was encountered: $error'),
                const Text('make sure you have selected the correct file'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

/// checks to see if the current state is set to drop and split

bool validSchedule(Scheduling sched) {
  return stateDescriptions[sched.getStateOfProcessing().index] ==
      'Drop and Split';
}

/// Deprecated function
/// deleting this from source code causes an error  ¯\_(ツ)_/¯
Widget auxData(Scheduling scheduling) {
  return SizedBox(
    height: 200,
    child: DataTable(
      columns: const <DataColumn>[
        DataColumn(
          label: Text(
            'Auxiliary Data',
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            '',
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
      rows: <DataRow>[
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('Course Takers')),
            DataCell(Text('${scheduling.overviewData.getNbrCourseTakers()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('Go Courses')),
            DataCell(Text('${scheduling.overviewData.getNbrGoCourses()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('places asked')),
            DataCell(Text('${scheduling.overviewData.getNbrPlacesAsked()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('places given')),
            DataCell(Text('${scheduling.overviewData.getNbrPlacesGiven()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('un-met wants')),
            DataCell(Text('${scheduling.overviewData.getNbrUnmetWants()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('on leave')),
            DataCell(Text('${scheduling.overviewData.getNbrOnLeave()}')),
          ],
        ),
        const DataRow(
          cells: <DataCell>[
            DataCell(Text('Missing')),
            DataCell(Text('0')),
          ],
        ),
      ],
    ),
  );
}
