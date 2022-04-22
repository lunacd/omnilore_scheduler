import 'dart:io';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tuple/tuple.dart';

const MaterialColor primaryBlack = MaterialColor(
  _blackPrimaryValue,
  <int, Color>{
    50: Color(0xFF000000),
    100: Color(0xFF000000),
    200: Color(0xFF000000),
    300: Color(0xFF000000),
    400: Color(0xFF000000),
    500: Color(_blackPrimaryValue),
    600: Color(0xFF000000),
    700: Color(0xFF000000),
    800: Color(0xFF000000),
    900: Color(0xFF000000),
  },
);
const int _blackPrimaryValue = 0xFF000000;

const Map kColorMap = {
  'DarkBlue': Color.fromARGB(255, 69, 91, 138),
  'MediumBlue': Color.fromARGB(255, 124, 172, 223),
  'LightBlue': Color.fromARGB(255, 189, 209, 247),
  'KindaBlue': Color.fromARGB(255, 204, 219, 242),
  'MoreBlue': Color.fromARGB(255, 217, 223, 248),
  'WhiteBlue': Color.fromARGB(255, 231, 226, 220),
};

const List<Color> clusterColors = [
  Colors.green,
  Colors.purple,
  Colors.yellow,
  Colors.brown,
  Colors.deepOrange,
  Colors.amber,
  Colors.pinkAccent,
  Colors.blue
];

// ignore: constant_identifier_names
const List<String> StateProcessing = [
  'Need Courses',
  'Need People',
  'Inconsistent',
  'Drop and Split',
  'Drop and Split',
  'Schedule'
];

int colorNum = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
    await DesktopWindow.setMinWindowSize(const Size(1200, 1300));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omnilore Demo',
      theme: ThemeData(
        primarySwatch: primaryBlack,
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: MaterialStateProperty.all(
                Colors.blueGrey[600]), // Set Button hover color
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.black),
            backgroundColor: MaterialStateProperty.all(kColorMap['WhiteBlue']),
            overlayColor: MaterialStateProperty.all(
                Colors.blueGrey[600]), // Set Button hover color
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const Screen(),
    );
  }
}

class Screen extends StatefulWidget {
  const Screen({Key? key}) : super(key: key);

  @override
  _ScreenState createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  // final ScrollController scrollController = ScrollController();
  // TextEditingController controller = TextEditingController();
  Scheduling schedule = Scheduling();
  StateOfProcessing curState = StateOfProcessing.needCourses;
  bool coursesImported = false;
  bool peopleImported = false;
  int? numCourses;
  int? numPeople;

  final minTextField = TextEditingController();
  final maxTextField = TextEditingController();
  String hintMax = 'Max', hintMin = 'Min';
  String minVal = '', maxVal = '';
  String curClass = '';
  String curCell = '';
  String dropDownVal = '';
  String minMaxError = '';
  Iterable<String> curClassRoster = [];
  Map curSelected = <String, bool>{};
  List<List<String>> curClusters = [];
  Map<Set<String>, Color> clustColors = <Set<String>, Color>{};
  bool resultingClass = false;
  List<bool> droppedList = List<bool>.filled(14, false,
      growable:
          true); // list that corresponds to each column of the table. will be true when column box is checked, otherwise false

  // String _message = 'Choose a MenuItem.';
  // String _drawerTitle = 'Tap a drawerItem';
  // IconData _drawerIcon = Icons.menu;

  Color masterBackgroundColor = kColorMap['WhiteBlue'];
  Color detailBackgroundColor = Colors.blueGrey[300] as Color;

  void _setMinMaxClass() {
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
    });
  }

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
                    } catch (e) {
                      _showMyDialog(e.toString(), 'courses');
                    }
                  } else {
                    // ignore: todo
                    //TODO: Add pop up box to show that the user canceled
                    //user canceled
                  }
                }
                setState(() {});
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
                setState(() {});
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
                setState(() {});
              },
            ),
            MenuListItem(
              title: 'Load',
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyD, alt: true),
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
                          updateDropped();
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
                    }
                  } else {
                    //file picker canceled
                  }
                  setState(() {});
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
        masterPane: masterPane(),
        detailPaneMinWidth: 0,
      ),
    );
  }

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
            children: [screen1(), combineTables(tableData(), tableTimeData())],
          )),
        );
      },
    );
  }

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
                  color: kColorMap['MediumBlue'],
                  child: Text(
                      'State of Processing: ${StateProcessing[schedule.getStateOfProcessing().index]}',
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
                Expanded(child: overviewData(schedule)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget classNameDisplay() {
    return Container(
      color: kColorMap['MoreBlue'],
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
                        });
                      }
                    : null,
                child: const Text('Inc Clust')),
            const ElevatedButton(onPressed: null, child: Text('Back')),
            const ElevatedButton(onPressed: null, child: Text('Forward')),
          ],
        ),
        Row(
          children: [Text('$curCell of $curClass')],
          mainAxisAlignment: MainAxisAlignment.start,
        ),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (var val in curClassRoster)
              ElevatedButton(
                  style: (() {
                    if (curSelected[val] == true) {
                      return ElevatedButton.styleFrom(primary: Colors.red);
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
                    });
                  },
                  child: Text(val.toString()))
          ],
        ),
        Container(
          color: Colors.white,
        )
      ]),
    );
  }

  Color randomColor() {
    colorNum++;
    return clusterColors[colorNum % clusterColors.length];
  }

  Color getColorKey(String person) {
    Set<String> test =
        schedule.splitControl.getClustByPerson(person) ?? <String>{};
    for (Set<String> item in clustColors.keys) {
      if (item.length == test.length && test.containsAll(item)) {
        return clustColors[item] ?? Colors.grey;
      }
    }
    return Colors.black;
  }

  Widget classSizeControl() {
    return Container(
      color: kColorMap['LightBlue'],
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
          // Container(alignment: Alignment.center, child: classDropDownMenu()),
          // Row(
          //   children: [
          //     const SizedBox(height: 10),
          //   ],
          // ),
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
              /*const SizedBox(
                width: 50,
                child: Text('max. '),
              ),*/
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
              //const Text('by'),
              const ElevatedButton(
                onPressed: null,
                child: Text('splitting'),
              ),
              ElevatedButton(
                  onPressed: _setMinMaxClass, child: const Text('   set   ')),
            ],
          ),
        ],
      ),
    );
  }

  Widget namesDisplayMode() {
    return Container(
        // height: double.infinity,
        color: kColorMap['KindaBlue'],
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

                        curCell = '';
                        curClassRoster = [];
                      });
                    }
                  : null,
              child: const Text('Imp. Splits')),
          const ElevatedButton(onPressed: null, child: Text('Show Coord(s)')),
          const ElevatedButton(onPressed: null, child: Text('Set C or CC2')),
          const ElevatedButton(onPressed: null, child: Text('Set CC1')),
        ]));
  }

  Widget selectProcess() {
    return Container(
        color: kColorMap['KindaBlue'],
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

  Widget overviewData(Scheduling scheduling) {
    return Container(
      color: kColorMap['LightBlue'],
      constraints: const BoxConstraints.expand(),
      child: DefaultTextStyle(
        child: Column(
          children: [
            Text(
                '\nCourse Takers ${scheduling.overviewData.getNbrCourseTakers()}'),
            Text('Go Courses ${scheduling.overviewData.getNbrGoCourses()}'),
            Text('Places Asked ${scheduling.overviewData.getNbrPlacesAsked()}'),
            Text('Places Given ${scheduling.overviewData.getNbrPlacesGiven()}'),
            Text('Un-met Wants ${scheduling.overviewData.getNbrUnmetWants()}'),
            Text('On Leave ${scheduling.overviewData.getNbrOnLeave()}'),
            const Text('Missing 0'),
          ],
        ),
        style: const TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

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
          });
        });
  }

  int computeSplitSize(String course) {
    int courseSize = schedule.overviewData.getResultingClassSize(course).size;
    int maxSize = schedule.courseControl.getMaxClassSize(course);
    int numSplits = (courseSize / maxSize).ceil();

    return numSplits - 1;
  }

  void updateDropped() {
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

  Tuple2<List<String>, List<List<String>>> tableData() {
    // courseCodes = schedule.getCourseCodes().toList();
    final growableList = <String>[
      '',
      'First Choices',
      'First backup',
      'Second backup',
      'Third backup',
      'Add from BUs',
      'Drop, bad time',
      'Drop, dup class',
      'Drop class full',
      'Resulting Size'
    ];
    if (kDebugMode) {
      print('num of course $numCourses');
    }
    int arrSize = numCourses ?? 14;

    var firstChoiceArr = List<int>.generate(arrSize, (index) => -1);
    var secondChoiceArr = List<int>.generate(arrSize, (index) => -1);
    var thirdChoiceArr = List<int>.generate(arrSize, (index) => -1);
    var fourthChoiceArr = List<int>.generate(arrSize, (index) => -1);
    var fromBU = List<int>.generate(arrSize, (index) => -1);
    var dropBT = List<int>.generate(arrSize, (index) => -1);
    var dropDC = List<int>.generate(arrSize, (index) => -1);
    var dropCF = List<int>.generate(arrSize, (index) => -1);
    var resultingSize = List<int>.generate(arrSize, (index) => -1);
    int idx = 0;
    //creating the 2d array
    var dataList = List<List<String>>.generate(
        10, (i) => List<String>.generate(arrSize, (j) => ''));

    //checking the values of the dropped list and updating the list accordingly
    for (String code in schedule.getCourseCodes()) {
      dataList[0][idx] = code;
      idx++;
    }

    idx = 0;
    for (String code in schedule.getCourseCodes()) {
      firstChoiceArr[idx] =
          schedule.overviewData.getNbrForClassRank(code, 0).size;

      secondChoiceArr[idx] =
          schedule.overviewData.getNbrForClassRank(code, 1).size;
      thirdChoiceArr[idx] =
          schedule.overviewData.getNbrForClassRank(code, 2).size;
      fourthChoiceArr[idx] =
          schedule.overviewData.getNbrForClassRank(code, 3).size;
      fromBU[idx] = schedule.overviewData.getNbrAddFromBackup(code);
      dropBT[idx] = schedule.overviewData.getNbrDropTime(code);
      dropDC[idx] = schedule.overviewData.getNbrDropDup(code);
      dropCF[idx] = schedule.overviewData.getNbrDropFull(code);
      resultingSize[idx] =
          schedule.overviewData.getResultingClassSize(code).size;
      dataList[0][idx] = code;
      droppedList[idx]
          ? dataList[1][idx] = '0'
          : dataList[1][idx] = firstChoiceArr[idx].toString();
      droppedList[idx]
          ? dataList[2][idx] = '0'
          : dataList[2][idx] = secondChoiceArr[idx].toString();
      droppedList[idx]
          ? dataList[3][idx] = '0'
          : dataList[3][idx] = thirdChoiceArr[idx].toString();
      droppedList[idx]
          ? dataList[4][idx] = '0'
          : dataList[4][idx] = fourthChoiceArr[idx].toString();
      droppedList[idx]
          ? dataList[5][idx] = '0'
          : dataList[5][idx] = fromBU[idx].toString();
      droppedList[idx]
          ? dataList[6][idx] = '0'
          : dataList[6][idx] = dropBT[idx].toString();
      droppedList[idx]
          ? dataList[7][idx] = '0'
          : dataList[7][idx] = dropDC[idx].toString();
      droppedList[idx]
          ? dataList[8][idx] = '0'
          : dataList[8][idx] = dropCF[idx].toString();
      droppedList[idx]
          ? dataList[9][idx] = '0'
          : dataList[9][idx] = resultingSize[idx].toString();
      idx++;
    }
    if (kDebugMode) {
      print(growableList.length);
      print(dataList.length);
    }

    /*return Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.black),
          outside: const BorderSide(width: 1)),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: buildInfo(growableList, dataList),
    );*/
    return Tuple2<List<String>, List<List<String>>>(growableList, dataList);
  }

  Widget combineTables(Tuple2<List<String>, List<List<String>>> infoTable,
      Tuple2<List<String>, List<List<String>>> timeTable) {
    return Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.black),
          outside: const BorderSide(width: 1)),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: buildInfo(infoTable.item1, infoTable.item2) +
          buildTimeInfo(timeTable.item1, timeTable.item2),
    );
  }

  List<TableRow> buildInfo(
      // builds the list of table rows. I had to do it in a function because for
      // some reason state doesn't update if its done the other way
      List<String> growableList,
      List<List<String>> dataList) {
    List<TableRow> result = [];
    for (int i = 0; i < growableList.length; i++) {
      result.add(TableRow(children: [
        TableCell(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[Text(growableList[i].toString())])),
        for (int j = 0; j < dataList[i].length; j++)
          TextButton(
            child: Text(dataList[i][j].toString()),
            onPressed: () {
              setState(() {
                if (i == 0) {
                  curClassRoster = schedule.overviewData
                      .getPeopleForResultingClass(dataList[0][j].toString());
                  resultingClass = false;
                } else if (growableList[i].toString() == 'First Choices') {
                  curClassRoster = schedule.overviewData
                      .getPeopleForClassRank(dataList[0][j].toString(), 0);
                  resultingClass = false;
                } else if (growableList[i].toString() == 'First backup') {
                  curClassRoster = schedule.overviewData
                      .getPeopleForClassRank(dataList[0][j].toString(), 1);
                  resultingClass = false;
                } else if (growableList[i].toString() == 'Second backup') {
                  curClassRoster = schedule.overviewData
                      .getPeopleForClassRank(dataList[0][j].toString(), 2);
                  if (kDebugMode) {
                    print(curClassRoster);
                  }
                  resultingClass = false;
                } else if (growableList[i].toString() == 'Third backup') {
                  curClassRoster = schedule.overviewData
                      .getPeopleForClassRank(dataList[0][j].toString(), 3);
                  resultingClass = false;
                } else if (growableList[i].toString() == 'Add from BU\'s') {
                  curClassRoster = schedule.overviewData
                      .getPeopleAddFromBackup(dataList[0][j].toString());
                  resultingClass = false;
                } else if (growableList[i].toString() == 'Drop, bad time') {
                  curClassRoster = schedule.overviewData
                      .getPeopleDropTime(dataList[0][j].toString());
                  resultingClass = false;
                } else if (growableList[i].toString() == 'Drop, dup class') {
                  curClassRoster = [];
                  resultingClass = false;
                } else if (growableList[i].toString() == 'Drop class full') {
                  curClassRoster = [];
                  resultingClass = false;
                } else if (growableList[i].toString() == 'Resulting Size') {
                  curClassRoster = schedule.overviewData
                      .getPeopleForResultingClass(dataList[0][j].toString());
                  resultingClass = true;
                }

                curClass = dataList[0][j].toString();
                curSelected.clear();
                clustColors.clear();
                curCell = growableList[i];
                List<String> tempList = curClassRoster.toList();
                tempList
                    .sort((a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                curClassRoster = tempList;
                for (var name in curClassRoster) {
                  curSelected[name] = false;
                }
                if (kDebugMode) {
                  print(curClassRoster);
                }
              });
            },
          )
      ]));
    }
    result.add(TableRow(children: [
      TableCell(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const <Widget>[Text('class dropped')])),
      for (int i = 0; i < droppedList.length; i++) droppedCheck(i)
    ]));
    return result;
  }

  Widget droppedCheck(int i) {
    // makes a checkmark widget that corresponds to the passed index of dropped
    // list
    return Checkbox(
        checkColor: Colors.white,
        fillColor: null,
        value: droppedList[i],
        onChanged: (bool? value) {
          setState(() {
            droppedList[i] = value!;
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
          });
        });
  }

  List<DataRow> buildTable() {
    List<DataRow> list = <DataRow>[];

    for (String code in schedule.getCourseCodes()) {
      int first = schedule.overviewData.getNbrForClassRank(code, 0).size;
      int second = schedule.overviewData.getNbrForClassRank(code, 1).size;
      int third = schedule.overviewData.getNbrForClassRank(code, 2).size;
      int fourth = schedule.overviewData.getNbrForClassRank(code, 3).size;
      int fromBU = schedule.overviewData.getNbrAddFromBackup(code);
      list.add(DataRow(
        cells: <DataCell>[
          DataCell(Text(code)),
          DataCell(Text(
            '$first',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '$second',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '$third',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '$fourth',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '$fromBU',
            textAlign: TextAlign.center,
          )),
          const DataCell(Text(
            '0',
            textAlign: TextAlign.center,
          )),
          const DataCell(Text(
            '0',
            textAlign: TextAlign.center,
          )),
          const DataCell(Text(
            '0',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '$first',
            textAlign: TextAlign.center,
          )),
        ],
      ));
    }
    return list;
  }

  Tuple2<List<String>, List<List<String>>> tableTimeData() {
    final growableList = <String>[
      '',
      '1st/3rd Mon AM',
      '1st/3rd Mon PM',
      '1st/3rd Tue AM',
      '1st/3rd Tue PM',
      '1st/3rd Wed AM',
      '1st/3rd Wed PM',
      '1st/3rd Thu AM',
      '1st/3rd Thu PM',
      '1st/3rd Fri AM',
      '1st/3rd Fri PM',
      '2nd/4th Mon AM',
      '2nd/4th Mon PM',
      '2nd/4th Tue AM',
      '2nd/4th Tue PM',
      '2nd/4th Wed AM',
      '2nd/4th Wed PM',
      '2nd/4th Thu AM',
      '2nd/4th Thu PM',
      '2nd/4th Fri AM',
      '2nd/4th Fri PM'
    ];
    if (kDebugMode) {
      print('num of course $numCourses');
    }
    int arrSize = numCourses ?? 14;

    var firstMonAM = List<int>.generate(arrSize, (index) => -1);
    var firstMonPM = List<int>.generate(arrSize, (index) => -1);
    var firstTueAM = List<int>.generate(arrSize, (index) => -1);
    var firstTuePM = List<int>.generate(arrSize, (index) => -1);
    var firstWedAM = List<int>.generate(arrSize, (index) => -1);
    var firstWedPM = List<int>.generate(arrSize, (index) => -1);
    var firstThuAM = List<int>.generate(arrSize, (index) => -1);
    var firstThuPM = List<int>.generate(arrSize, (index) => -1);
    var firstFriAM = List<int>.generate(arrSize, (index) => -1);
    var firstFriPM = List<int>.generate(arrSize, (index) => -1);
    var secondMonAM = List<int>.generate(arrSize, (index) => -1);
    var secondMonPM = List<int>.generate(arrSize, (index) => -1);
    var secondTueAM = List<int>.generate(arrSize, (index) => -1);
    var secondTuePM = List<int>.generate(arrSize, (index) => -1);
    var secondWedAM = List<int>.generate(arrSize, (index) => -1);
    var secondWedPM = List<int>.generate(arrSize, (index) => -1);
    var secondThuAM = List<int>.generate(arrSize, (index) => -1);
    var secondThuPM = List<int>.generate(arrSize, (index) => -1);
    var secondFriAM = List<int>.generate(arrSize, (index) => -1);
    var secondFriPM = List<int>.generate(arrSize, (index) => -1);

    int idx = 0;
    //creating the 2d array
    var dataList = List<List<String>>.generate(
        21, (i) => List<String>.generate(arrSize, (j) => ''));

    //checking the values of the dropped list and updating the list accordingly
    for (String code in schedule.getCourseCodes()) {
      dataList[0][idx] = code;
      idx++;
    }

    idx = 0;
    for (String code in schedule.getCourseCodes()) {
      firstMonAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 0);
      firstMonPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 1);
      firstTueAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 2);
      firstTuePM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 3);
      firstWedAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 4);
      firstWedPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 5);
      firstThuAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 6);
      firstThuPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 7);
      firstFriAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 8);
      firstFriPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 9);
      secondMonAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 10);
      secondMonPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 11);
      secondTueAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 12);
      secondTuePM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 13);
      secondWedAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 14);
      secondWedPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 15);
      secondThuAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 16);
      secondThuPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 17);
      secondFriAM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 18);
      secondFriPM[idx] = schedule.scheduleControl.getNbrUnavailable(code, 19);

      dataList[0][idx] = code;
      droppedList[idx]
          ? dataList[1][idx] = '0'
          : dataList[1][idx] = firstMonAM[idx].toString();
      droppedList[idx]
          ? dataList[2][idx] = '0'
          : dataList[2][idx] = firstMonPM[idx].toString();
      droppedList[idx]
          ? dataList[3][idx] = '0'
          : dataList[3][idx] = firstTueAM[idx].toString();
      droppedList[idx]
          ? dataList[4][idx] = '0'
          : dataList[4][idx] = firstTuePM[idx].toString();
      droppedList[idx]
          ? dataList[5][idx] = '0'
          : dataList[5][idx] = firstWedAM[idx].toString();
      droppedList[idx]
          ? dataList[6][idx] = '0'
          : dataList[6][idx] = firstWedPM[idx].toString();
      droppedList[idx]
          ? dataList[7][idx] = '0'
          : dataList[7][idx] = firstThuAM[idx].toString();
      droppedList[idx]
          ? dataList[8][idx] = '0'
          : dataList[8][idx] = firstThuPM[idx].toString();
      droppedList[idx]
          ? dataList[9][idx] = '0'
          : dataList[9][idx] = firstFriAM[idx].toString();
      droppedList[idx]
          ? dataList[10][idx] = '0'
          : dataList[10][idx] = firstFriPM[idx].toString();
      droppedList[idx]
          ? dataList[11][idx] = '0'
          : dataList[11][idx] = secondMonAM[idx].toString();
      droppedList[idx]
          ? dataList[12][idx] = '0'
          : dataList[12][idx] = secondMonPM[idx].toString();
      droppedList[idx]
          ? dataList[13][idx] = '0'
          : dataList[13][idx] = secondTueAM[idx].toString();
      droppedList[idx]
          ? dataList[14][idx] = '0'
          : dataList[14][idx] = secondTuePM[idx].toString();
      droppedList[idx]
          ? dataList[15][idx] = '0'
          : dataList[15][idx] = secondWedAM[idx].toString();
      droppedList[idx]
          ? dataList[16][idx] = '0'
          : dataList[16][idx] = secondWedPM[idx].toString();
      droppedList[idx]
          ? dataList[17][idx] = '0'
          : dataList[17][idx] = secondThuAM[idx].toString();
      droppedList[idx]
          ? dataList[18][idx] = '0'
          : dataList[18][idx] = secondThuPM[idx].toString();
      droppedList[idx]
          ? dataList[19][idx] = '0'
          : dataList[19][idx] = secondFriAM[idx].toString();
      droppedList[idx]
          ? dataList[20][idx] = '0'
          : dataList[20][idx] = secondFriPM[idx].toString();
      idx++;
    }
    if (kDebugMode) {
      print(growableList.length);
      print(dataList.length);
    }

    /*return Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.blue),
          outside: const BorderSide(width: 1)),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: buildTimeInfo(growableList, dataList),
    );*/
    return Tuple2<List<String>, List<List<String>>>(growableList, dataList);
  }

  List<TableRow> buildTimeInfo(
      // builds the list of table rows. I had to do it in a function because for
      // some reason state doesn't update if its done the other way
      List<String> growableList,
      List<List<String>> dataList) {
    List<TableRow> result = [];
    for (int i = 1; i < growableList.length; i++) {
      result.add(TableRow(children: [
        TableCell(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[Text(growableList[i].toString())])),
        for (int j = 0; j < dataList[i].length; j++)
          TextButton(
            child: Text(dataList[i][j].toString()),
            onPressed: () {
              setState(() {
                int timeIndex = getTimeIndex(growableList[i].toString());

                curClass = dataList[0][j].toString();

                schedule.scheduleControl.schedule(curClass, timeIndex);

                curSelected.clear();
                clustColors.clear();
                curCell = growableList[i];
                List<String> tempList = curClassRoster.toList();
                tempList
                    .sort((a, b) => a.split(' ')[1].compareTo(b.split(' ')[1]));
                curClassRoster = tempList;
                for (var name in curClassRoster) {
                  curSelected[name] = false;
                }
                if (kDebugMode) {
                  print(curClassRoster);
                }
              });
            },
            style: (() {
              if (schedule.scheduleControl.isScheduledAt(
                  dataList[0][j].toString(),
                  getTimeIndex(growableList[i].toString()))) {
                if (kDebugMode) {
                  print('got here');
                }
                return ElevatedButton.styleFrom(primary: Colors.red);
              } else {
                return ElevatedButton.styleFrom(primary: Colors.transparent);
              }
            }()),
          )
      ]));
    }
    return result;
  }

  int getTimeIndex(String c) {
    int timeIndex = -1;
    if (c == '1st/3rd Mon AM') {
      timeIndex = 0;
    } else if (c == '1st/3rd Mon PM') {
      timeIndex = 1;
    } else if (c == '1st/3rd Tue AM') {
      timeIndex = 2;
      if (kDebugMode) {
        print(curClassRoster);
      }
    } else if (c == '1st/3rd Tue PM') {
      timeIndex = 3;
    } else if (c == '1st/3rd Wed AM') {
      timeIndex = 4;
    } else if (c == '1st/3rd Wed PM') {
      timeIndex = 5;
    } else if (c == '1st/3rd Thu AM') {
      timeIndex = 6;
    } else if (c == '1st/3rd Thu PM') {
      timeIndex = 7;
    } else if (c == '1st/3rd Fri AM') {
      timeIndex = 8;
    } else if (c == '1st/3rd Fri PM') {
      timeIndex = 9;
    } else if (c == '2nd/4th Mon AM') {
      timeIndex = 10;
    } else if (c == '2nd/4th Mon PM') {
      timeIndex = 11;
    } else if (c == '2nd/4th Tue AM') {
      timeIndex = 12;
    } else if (c == '2nd/4th Tue PM') {
      timeIndex = 13;
    } else if (c == '2nd/4th Wed AM') {
      timeIndex = 14;
    } else if (c == '2nd/4th Wed PM') {
      timeIndex = 15;
    } else if (c == '2nd/4th Thu AM') {
      timeIndex = 16;
    } else if (c == '2nd/4th Thu PM') {
      timeIndex = 17;
    } else if (c == '2nd/4th Fri AM') {
      timeIndex = 18;
    } else if (c == '2nd/4th Fri PM') {
      timeIndex = 19;
    }
    return timeIndex;
  }

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

bool validSchedule(Scheduling sched) {
  return StateProcessing[sched.getStateOfProcessing().index] ==
      'Drop and Split';
}

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
