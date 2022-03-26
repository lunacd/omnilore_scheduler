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
  'Red': Colors.red,
  'Blue': Colors.blue,
  'Purple': Colors.purple,
  'Black': Colors.black,
  'Pink': Colors.pink,
  'Yellow': Colors.yellow,
  'Orange': Colors.orange,
  'White': Colors.white,
  'BlueGrey': Colors.blueGrey,
};

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

            backgroundColor: MaterialStateProperty.all(Colors.grey),
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
  Iterable<String> curClassRoster = [];
  Map curSelected = {};
  List<bool> droppedList = List<bool>.filled(14, false,
      growable:
          true); // list that corresponds to each column of the table. will be true when column box is checked, otherwise false

  // String _message = 'Choose a MenuItem.';
  // String _drawerTitle = 'Tap a drawerItem';
  // IconData _drawerIcon = Icons.menu;

  Color masterBackgroundColor = Colors.white;
  Color detailBackgroundColor = Colors.blueGrey[300] as Color;

  Future<String?> _fileExplorer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      if (kDebugMode) {
        print(result.files.single.path);
      }
      String path = result.files.single.path ?? '';
      numCourses = await schedule.loadCourses(path);
      droppedList = List<bool>.filled(numCourses!, false, growable: true);
    } else {
      return 'error';
    }
    return null;
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
              onPressed: () {
                _fileExplorer();
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
            width: 700,
            child: Column(
              children: [
                // ignore: todo
                // TODO: Update this to a string that changes based on the state
                Container(
                  width: double.infinity,
                  color: Colors.red,
                  child: const Text('State of Processing: Need to import',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: classNameDisplay(),
                )
              ],
            ),
          ),

          //Class size control widget and Names display mode
          SizedBox(
            width: 300,
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
            width: 200,
            child: Column(
              children: [
                selectProcess(),
                Expanded(child: auxiliaryData(schedule)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget classNameDisplay() {
    return Container(
      color: Colors.blue,
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
                onPressed: () {
                  setState(() {
                    for (var item
                        in curSelected.keys.where((element) => true)) {
                      schedule.splitControl.removeCluster(item);
                    }
                  });
                },
                child: const Text('Dec Clust')),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    Set<String> result = {};
                    for (var item
                        in curSelected.keys.where((element) => true)) {
                      result.add(item);
                    }
                    schedule.splitControl.addCluster(result);
                    if (kDebugMode) {
                      print(result);
                    }
                  });
                },
                child: const Text('Inc Clust')),
            const ElevatedButton(onPressed: null, child: Text('Back')),
            const ElevatedButton(onPressed: null, child: Text('Forward')),
          ],
        ),
        for (var val in curClassRoster)
          TextButton(
              style: curSelected[val] == true
                  ? TextButton.styleFrom(primary: Colors.red)
                  : TextButton.styleFrom(primary: Colors.black),
              onPressed: () {
                setState(() {
                  if (curSelected[val]) {
                    curSelected[val] = false;
                  } else {
                    curSelected[val] = true;
                  }
                });
              },
              child: Text(val.toString())),
        Container(
          color: Colors.white,
        )
      ]),
    );
  }

  Widget classSizeControl() {
    return Container(
      // width: 400,
      color: Colors.green,
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              SizedBox(
                  width: 50,
                  child: TextField(
                      decoration:
                          InputDecoration(enabledBorder: OutlineInputBorder()),
                      style: TextStyle(
                          fontSize: 20.0, height: 0.5, color: Colors.black))),
              SizedBox(
                width: 50,
                child: Text('min. & '),
              ),
              SizedBox(
                  width: 50,
                  child: TextField(
                      decoration:
                          InputDecoration(enabledBorder: OutlineInputBorder()),
                      style: TextStyle(
                          fontSize: 20.0, height: 0.5, color: Colors.grey))),
              SizedBox(
                width: 50,
                child: Text('max. '),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Text('by'),
              ElevatedButton(
                onPressed: null,
                child: Text('splitting.'),
              ),
              ElevatedButton(onPressed: null, child: Text('SET')),
            ],
          )
        ],
      ),
    );
  }

  Widget namesDisplayMode() {
    return Container(
        // height: double.infinity,
        color: Colors.yellow,
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Container(
            alignment: Alignment.center,
            child: const Text('NAMES DISPLAY MODE',
                style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
          ),
          const ElevatedButton(onPressed: null, child: Text('SHow BU & CA')),
          const ElevatedButton(onPressed: null, child: Text('Show Splits')),
          const ElevatedButton(onPressed: null, child: Text('Imp. Splits')),
          const ElevatedButton(onPressed: null, child: Text('Show Coord(s)')),
          const ElevatedButton(onPressed: null, child: Text('Set C or CC2')),
          const ElevatedButton(onPressed: null, child: Text('Set CC1')),
        ]));
  }

  Widget selectProcess() {
    return Container(
        color: Colors.deepOrange,
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

  Widget auxiliaryData(Scheduling scheduling) {
    return Container(
      width: 300,
      color: Colors.green,
      child: DefaultTextStyle(
        child: Column(
          children: [
            Text(
                '\nCourse Takers ${scheduling.auxiliaryData.getNbrCourseTakers()}'),
            Text('Go Courses ${scheduling.auxiliaryData.getNbrGoCourses()}'),
            Text(
                'Places Asked ${scheduling.auxiliaryData.getNbrPlacesAsked()}'),
            Text(
                'Places Given ${scheduling.auxiliaryData.getNbrPlacesGiven()}'),
            Text('Un-met Wants ${scheduling.auxiliaryData.getNbrUnmetWants()}'),
            Text('On Leave ${scheduling.auxiliaryData.getNbrOnLeave()}'),
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
      if (i == 0) {
        result.add(TableRow(children: [
          TableCell(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const <Widget>[Text('Class Codes')])),
          for (var val in dataList[i])
            TextButton(
              child: Text(val.toString()),
              onPressed: () {
                setState(() {
                  curClassRoster = schedule.overviewData
                      .getPeopleForResultingClass(val.toString());
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
      } else {
        result.add(TableRow(children: [
          TableCell(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[Text(growableList[i].toString())])),
          for (var val in dataList[i]) Text(val.toString())
        ]));
      }
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
            DataCell(Text('${scheduling.auxiliaryData.getNbrCourseTakers()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('Go Courses')),
            DataCell(Text('${scheduling.auxiliaryData.getNbrGoCourses()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('places asked')),
            DataCell(Text('${scheduling.auxiliaryData.getNbrPlacesAsked()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('places given')),
            DataCell(Text('${scheduling.auxiliaryData.getNbrPlacesGiven()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('un-met wants')),
            DataCell(Text('${scheduling.auxiliaryData.getNbrUnmetWants()}')),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('on leave')),
            DataCell(Text('${scheduling.auxiliaryData.getNbrOnLeave()}')),
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
