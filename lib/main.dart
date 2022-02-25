import 'dart:io';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
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
    await DesktopWindow.setMinWindowSize(const Size(1000, 1000));
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

            backgroundColor: MaterialStateProperty.all(Colors.white),
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

  int? numCourses;
  int? numPeople;
  final int _currentSortColumn = 0;
  final bool _isAscending = true;

  // String _message = 'Choose a MenuItem.';
  // String _drawerTitle = 'Tap a drawerItem';
  // IconData _drawerIcon = Icons.menu;

  Color masterBackgroundColor = Colors.white;
  Color detailBackgroundColor = Colors.blueGrey[300] as Color;

  void _showMessage(String newMessage) {
    // setState(() {
    //   _message = newMessage;
    // });
  }

  Future<String?> _fileExplorer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      print(result.files.single.path);
      return result.files.single.path;
    } else {
      return 'error';
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
              title: 'Open',
              onPressed: () {
                _fileExplorer();
              },
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyO, ctrl: true),
            ),
            MenuListItem(
              title: 'Import People',
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result != null) {
                  String path = result.files.single.path ?? '';
                  if (path != '') {
                    try {
                      numPeople = await schedule.loadPeople(path);
                    } catch (e) {
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
              onPressed: () {
                _showMessage('File.save');
              },
            ),
            MenuListItem(
              title: 'Delete',
              shortcut: MenuShortcut(key: LogicalKeyboardKey.keyD, alt: true),
              onPressed: () {
                _showMessage('File.delete');
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

  Builder detailPane() {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          color: detailBackgroundColor,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Class Name display'),
                const Text(
                    'Show people in a cell by clicking on a desired cell \nshowing: people assigned to DSC'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            ElevatedButton(
                                onPressed: null, child: Text('Enter/Edit Ppl')),
                            ElevatedButton(
                                onPressed: null, child: Text('New Curriculum')),
                            ElevatedButton(
                                onPressed: null,
                                child: Text('Cont. Old Curric')),
                          ],
                        ),
                        const Text('Names Display Mode'),
                        const ElevatedButton(
                            onPressed: null, child: Text('Show BU & CA')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Show Splits')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Imp. Splits')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Show Coord(s)')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Set C or CC2')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Set CC 1')),
                        auxData(schedule),
                        const Text('Select Process'),
                        const ElevatedButton(
                            // onPressed: () async {
                            //   numCourses = await schedule.loadCourses(
                            //       '/Users/harrisonforch/omnilore/omnilore_scheduler/lib/SDGs-1.txt');
                            //   numPeople = await schedule.loadPeople(
                            //       '/Users/harrisonforch/omnilore/omnilore_scheduler/lib/PeopleSelections-1.txt');
                            //   setState(() {});
                            // },
                            onPressed: null,
                            child: Text('Enter/Edit Crs')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Display Courses')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Enter/Edit Ppl')),
                        const ElevatedButton(
                            onPressed: null, child: Text('New Curriculum')),
                        const ElevatedButton(
                            onPressed: null, child: Text('Cont. Old Curric')),
                      ],
                    ),
                  ],
                ),
                if (context.appScreen.isCompact())
                  ElevatedButton(
                    onPressed: () {
                      context.appScreen.showOnlyMaster();
                    },
                    child: const Text('Show master'),
                  ),
              ],
            ),
          ),
        );
      },
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
              Row(
                children: const [
                  Text('status: need to import',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold))
                ],
              ),
              classNameDisplay(),
              tableData()
            ],
          ),
        );
      },
    );
  }

  Builder appContextMenu() {
    if (kDebugMode) {
      print('BUILD: appContextMenu');
    }
    return Builder(
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          width: 400,
          child: Container(
            color: Colors.yellow,
            child: const Text('AppContextMenu'),
          ),
        );
      },
    );
  }

  Widget classNameDisplay() {
    return Container(
      height: 400,
      width: double.infinity,
      color: Colors.blue,
      child: Column(children: [
        Container(
          alignment: Alignment.center,
          child: const Text('Class Names Display',
              style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
        ),
        Container(
          alignment: Alignment.center,
          child: const Text('Show constituents by clicking a desired cell.',
              style: TextStyle(fontSize: 15)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            ElevatedButton(onPressed: null, child: Text('Dec Clust')),
            ElevatedButton(onPressed: null, child: Text('Inc Clust')),
            ElevatedButton(onPressed: null, child: Text('Back')),
            ElevatedButton(onPressed: null, child: Text('Forward')),
          ],
        ),
        Container(
          color: Colors.white,
        )
      ]),
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

    final tempList = List<String>.generate(24, (index) => '');
    return Container(
      child: Table(
        border: TableBorder.symmetric(
            inside: const BorderSide(width: 1, color: Colors.blue),
            outside: const BorderSide(width: 1)),
        columnWidths: const {0: IntrinsicColumnWidth()},
        children: [
          for (var option in growableList)
            TableRow(children: [
              TableCell(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(option.toString()),
                ],
              )),
              for (var val in tempList) Text(val.toString())
            ])
        ],
      ),
    );
  }

// Widget data() {
//   return DataTable(
//     columns: const <DataColumn>[
//       DataColumn(
//         label: Text(
//           'Name',
//           softWrap: true,
//           style: TextStyle(fontStyle: FontStyle.italic),
//         ),
//         DataColumn(
//           label: Center(
//               child: Text(
//             'First Choices',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           )),
//         ),
//         DataColumn(
//           label: Text(
//             'First BU',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Second BU',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Third BU',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Add BU\'s',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Drop, Bad',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Drop, Dupe',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'Drop, Full',
//             overflow: TextOverflow.clip,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//         DataColumn(
//           label: Text(
//             'total',
//             overflow: TextOverflow.fade,
//             softWrap: true,
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ),
//       ],
//       rows: buildTable(),
//     );
//   }

  List<DataRow> buildTable() {
    List<DataRow> list = <DataRow>[];

    for (String code in schedule.getCourseCodes()) {
      int first = schedule.overviewData.getNbrForClassRank(code, 0)?.size ?? -1;
      int second =
          schedule.overviewData.getNbrForClassRank(code, 1)?.size ?? -1;
      int third = schedule.overviewData.getNbrForClassRank(code, 2)?.size ?? -1;
      int fourth =
          schedule.overviewData.getNbrForClassRank(code, 3)?.size ?? -1;
      int fromBU = schedule.overviewData.getNbrAddFromBackup(code) ?? -1;
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
  return DataTable(
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
  );
}
