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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  final ScrollController scrollController = ScrollController();
  TextEditingController controller = TextEditingController();
  Scheduling schedule = Scheduling();

  int? numCourses;
  int? numPeople;
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

  void _masterSetBackgroundColor(String color) {
    setState(() {
      masterBackgroundColor = kColorMap[color];
    });
  }

  void _detailSetBackgroundColor(String color) {
    setState(() {
      detailBackgroundColor = kColorMap[color];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreen(
        masterContextMenu: ContextMenu(
          width: 150,
          height: 250,
          child: ContextMenuSliver(
            title: 'Master',
            children: [
              masterContextMenuItem(color: 'Red'),
              masterContextMenuItem(color: 'Blue'),
              masterContextMenuItem(color: 'Purple'),
              masterContextMenuItem(color: 'Pink'),
              masterContextMenuItem(color: 'White'),
            ],
          ),
        ),
        detailContextMenu: ContextMenu(
          width: 300,
          height: 150,
          child: ContextMenuSliver(
            title: 'Detail',
            children: [
              detailContextMenuItem(color: 'Yellow'),
              detailContextMenuItem(color: 'Orange'),
              detailContextMenuItem(color: 'Pink'),
              detailContextMenuItem(color: 'Red'),
              detailContextMenuItem(color: 'BlueGrey'),
            ],
          ),
        ),
        menuList: [
          MenuItem(title: 'File', menuListItems: [
            MenuListItem(
              icon: Icons.open_in_new,
              title: 'Import Courses',
              onPressed: () async {
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result != null) {
                  String path = result.files.single.path ?? '';
                  if (path != '') {
                    numCourses = await schedule.loadCourses(path);
                  }
                } else {
                  // User canceled the picker
                }
                setState(() {});
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
                    numCourses = await schedule.loadPeople(path);
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
        detailPane: detailPane(),
        drawer: AppDrawer(
          defaultSmall: false,
          largeDrawerWidth: 200,
          largeDrawer: drawer(small: false),
          smallDrawerWidth: 60,
          smallDrawer: drawer(small: true),
        ),
        onBreakpointChange: () {
          setState(() {
            if (kDebugMode) {
              print('Breakpoint change');
            }
          });
        },
        masterPaneMinWidth: 500,
        detailPaneMinWidth: 500,
      ),
    );
  }

  Widget drawer({required bool small}) {
    return Container(
        color: Colors.amber,
        child: ListView(
          controller: ScrollController(),
          children: [
            drawerButton(
                title: 'User', icon: Icons.account_circle, small: small),
            drawerButton(title: 'Inbox', icon: Icons.inbox, small: small),
            drawerButton(title: 'Files', icon: Icons.save, small: small),
            drawerButton(
              title: 'Clients',
              icon: Icons.supervised_user_circle,
              small: small,
            ),
            drawerButton(
              title: 'Settings',
              icon: Icons.settings,
              small: small,
            ),
          ],
        ));
  }

  Widget drawerButton(
      {required String title, required IconData icon, required bool small}) {
    return small
        ? drawerSmallButton(icon: icon, title: title)
        : drawerLargeButton(icon: icon, title: title);
  }

  Widget drawerLargeButton({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
          elevation: 8,
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            onTap: () {
              // setState(() {
              //   _drawerIcon = icon;
              //   _drawerTitle = title;
              // });
            },
          )),
    );
  }

  Widget auxButton({required String title}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
          elevation: 8,
          child: ListTile(
            title: Text(title),
            onTap: () {
              // setState(() {
              //   _drawerTitle = title;
              // });
            },
          )),
    );
  }

  Widget drawerSmallButton({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
      child: Card(
          elevation: 8,
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                // setState(() {
                //   _drawerIcon = icon;
                //   _drawerTitle = title;
                // });
              },
              child: Center(child: Icon(icon, size: 30, color: Colors.black54)),
            ),
          )),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        ElevatedButton(
                            onPressed: null, child: Text('Enter/Edit Ppl')),
                        ElevatedButton(
                            onPressed: null, child: Text('New Curriculum')),
                        ElevatedButton(
                            onPressed: null, child: Text('Cont. Old Curric')),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        auxData(schedule),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Select Process'),
                        ElevatedButton(
                            onPressed: () async {
                              numCourses = await schedule.loadCourses(
                                  '/Users/harrisonforch/omnilore/omnilore_scheduler/lib/SDGs-1.txt');
                              numPeople = await schedule.loadPeople(
                                  '/Users/harrisonforch/omnilore/omnilore_scheduler/lib/PeopleSelections-1.txt');

                              setState(() {});
                            },
                            child: Text('Enter/Edit Crs')),
                        ElevatedButton(
                            onPressed: null, child: Text('Display Courses')),
                        ElevatedButton(
                            onPressed: null, child: Text('Enter/Edit Ppl')),
                        ElevatedButton(
                            onPressed: null, child: Text('New Curriculum')),
                        ElevatedButton(
                            onPressed: null, child: Text('Cont. Old Curric')),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: const [
                        Text('Names Display Mode'),
                        ElevatedButton(
                            onPressed: null, child: Text('Show BU & CA')),
                        ElevatedButton(
                            onPressed: null, child: Text('Show Splits')),
                        ElevatedButton(
                            onPressed: null, child: Text('Imp. Splits')),
                        ElevatedButton(
                            onPressed: null, child: Text('Show Coord(s)')),
                        ElevatedButton(
                            onPressed: null, child: Text('Set C or CC2')),
                        ElevatedButton(
                            onPressed: null, child: Text('Set CC 1')),
                      ],
                    ),
                    Column(
                      children: [
                        Title(
                            title: 'Auxiliary Data',
                            color: const Color(0xFFFFFFFF),
                            child: auxData(schedule)),
                      ],
                    )
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
            color: masterBackgroundColor,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Text('status: need to import',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold))
                    ],
                  ),
                  data()
                ],
              ),
            ));
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

  Widget masterContextMenuItem({required String color}) {
    return ContextMenuItem(
      onTap: () {
        _masterSetBackgroundColor(color);
      },
      child: Container(
        color: kColorMap[color],
        child: Center(child: Text(color)),
      ),
    );
  }

  Widget detailContextMenuItem({required String color}) {
    return ContextMenuItem(
      onTap: () {
        _detailSetBackgroundColor(color);
      },
      child: Container(
        color: kColorMap[color],
        child: Center(child: Text(color)),
      ),
    );
  }

  Widget data() {
    return DataTable(
      columnSpacing: 0,
      border: TableBorder.all(width: 1.0, color: Colors.blueGrey),
      columns: const <DataColumn>[
        DataColumn(
          label: Center(
              child: Text(
            'Name',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          )),
        ),
        DataColumn(
          label: Center(
              child: Text(
            'First Choices',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          )),
        ),
        DataColumn(
          label: Text(
            'First BU',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Second BU',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Third BU',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Add BU\'s',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Drop, Bad',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Drop, Dupe',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Drop, Full',
            overflow: TextOverflow.clip,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'total',
            overflow: TextOverflow.fade,
            softWrap: true,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
      rows: buildTable(),
    );
  }

  List<DataRow> buildTable() {
    List<DataRow> list = <DataRow>[];

    for (String code in schedule.getCourseCodes()) {
      int first = schedule.overviewData.getNbrForClassRank(code, 0) ?? -1;
      int second = schedule.overviewData.getNbrForClassRank(code, 1) ?? -1;
      int third = schedule.overviewData.getNbrForClassRank(code, 2) ?? -1;
      int fourth = schedule.overviewData.getNbrForClassRank(code, 3) ?? -1;
      int fromBU = schedule.overviewData.getNbrAddFromBackup(code) ?? -1;
      int total = first + second + third + fourth + fromBU;
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
          DataCell(Text(
            '0',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '0',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '0',
            textAlign: TextAlign.center,
          )),
          DataCell(Text(
            '$total',
            textAlign: TextAlign.center,
          )),
        ],
      ));
    }
    return list;
  }

  void updateTable() {}
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
