import 'dart:io';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:file_picker/file_picker.dart';

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
  'Drop',
  'Split',
  'Schedule'
];

int colorNum = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
    await DesktopWindow.setMinWindowSize(const Size(1000, 1100));
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
        primarySwatch: Colors.blue,
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

  String minVal = '', maxVal = '';

  String curClass = '';
  String curCell = '';
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
      if (minVal != '' || maxVal != '') {
        try {
          int minV = int.parse(minVal);
          int maxV = int.parse(maxVal);
          schedule.courseControl.setMinMaxClassSize(minV, maxV);
          if (kDebugMode) {
            print('Min and max set with vals $minV $maxV');
          }
        } on Exception {
          // ignore: todo
          //TODO: Add the pop up alert to show the error
          if (kDebugMode) {
            print('Error parsing the int');
          }
        }
      }
    });
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
                    } catch (e) {
                      _showMyDialog(e.toString(), 'courses');
                    }
                  } else {
                    //user canceled
                  }
                }
                // _fileExplorer();
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
                } else {
                  // User canceled the picker
                }
                setState(() {});
              },
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyP, ctrl: true),
            ),
            MenuListItem(
              title: 'Save',
              onPressed: () {},
            ),
            MenuListItem(
              title: 'Delete',
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyD, alt: true),
              onPressed: () {},
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
          child: Column(
            children: [
              screen1(),
              tableData(),
            ],
          ),
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
                      'State of Processing: ${StateProcessing[schedule.overviewData.getStateOfProcessing().index]}',
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
        return clustColors[item] ?? Colors.black;
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
            child: const Text('Limit All courses to',
                style: TextStyle(fontSize: 15)),
          ),
          Row(
            children: [
              SizedBox(height: 10),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                  width: 100,
                  child: TextField(
                      onChanged: (value) => minVal = value,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(),
                        hintText: 'Min',
                      ),
                      style: const TextStyle(
                        fontSize: 15.0,
                        height: 1.25,
                        color: Colors.grey,
                      ))),
              /*const SizedBox(
                width: 50,
                child: Text('min. & '),
              ),*/
              SizedBox(
                  width: 100,
                  child: TextField(
                      onChanged: (value) => maxVal = value,
                      decoration: const InputDecoration(
                        enabledBorder: OutlineInputBorder(),
                        hintText: 'Max',
                      ),
                      style: const TextStyle(
                          fontSize: 15.0, height: 1.25, color: Colors.grey))),
              /*const SizedBox(
                width: 50,
                child: Text('max. '),
              ),*/
            ],
          ),
          Row(
            children: [
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
          Row(
            children: [
              SizedBox(height: 10),
            ],
          )
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
                        numCourses = numCourses! + 1;
                        droppedList.add(false);
                        schedule.splitControl.split(curClass);
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
      constraints: BoxConstraints.expand(),
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

  Widget tableData() {
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
    for (int i = 0; i < droppedList.length; i++) {
      if (droppedList[i] == true) {
        schedule.courseControl.drop(dataList[0][i]);
      } else {
        schedule.courseControl.undrop(dataList[0][i]);
      }
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
      dataList[6][idx] = '0';
      dataList[7][idx] = '0';
      dataList[8][idx] = '0';
      droppedList[idx]
          ? dataList[9][idx] = '0'
          : dataList[9][idx] = resultingSize[idx].toString();
      idx++;
    }
    if (kDebugMode) {
      print(growableList.length);
      print(dataList.length);
    }

    return Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.blue),
          outside: const BorderSide(width: 1)),
      columnWidths: const {0: IntrinsicColumnWidth()},
      children: buildInfo(growableList, dataList),
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
                } else if (growableList[i].toString() == 'second backup') {
                  curClassRoster = schedule.overviewData
                      .getPeopleForClassRank(dataList[0][j].toString(), 2);
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
                  curClassRoster = [];
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
