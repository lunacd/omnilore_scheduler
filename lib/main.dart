import 'dart:io';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_menu/flutter_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'scheduling.dart';
import 'package:filepicker_windows/filepicker_windows.dart';

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
  final ScrollController scrollController = ScrollController();
  TextEditingController controller = TextEditingController();

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

  Future<String> _fileExplorer() async {
    final file = OpenFilePicker()
      ..filterSpecification = {
        'Word Document (*.doc)': '*.doc',
        'Web Page (*.htm; *.html)': '*.htm;*.html',
        'Text Document (*.txt)': '*.txt',
        'All Files': '*.*'
      }
      ..defaultFilterIndex = 0
      ..defaultExtension = 'doc'
      ..title = 'Select a document';

    final result = file.getFile();
    if (result != null) {
      print(result.path);
      return result.path;
    } else {
      return 'error';
    }

    //return Alert(context: context, title: 'Testing').show();
    // else {
    //   //error
    //   return Alert(context: context, title: 'Failed to import file').show();
    //   ;
    // }
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
        // masterContextMenu: ContextMenu(
        //   width: 150,
        //   height: 250,
        //   child: ContextMenuSliver(
        //     title: 'Master',
        //     children: [
        //       masterContextMenuItem(color: 'Red'),
        //       masterContextMenuItem(color: 'Blue'),
        //       masterContextMenuItem(color: 'Purple'),
        //       masterContextMenuItem(color: 'Pink'),
        //       masterContextMenuItem(color: 'White'),
        //     ],
        //   ),
        // ),
        // detailContextMenu: ContextMenu(
        //   width: 300,
        //   height: 150,
        //   child: ContextMenuSliver(
        //     title: 'Detail',
        //     children: [
        //       detailContextMenuItem(color: 'Yellow'),
        //       detailContextMenuItem(color: 'Orange'),
        //       detailContextMenuItem(color: 'Pink'),
        //       detailContextMenuItem(color: 'Red'),
        //       detailContextMenuItem(color: 'BlueGrey'),
        //     ],
        //   ),
        // ),
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
              title: 'Close',
              onPressed: () {
                _showMessage('File.close');
              },
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
        // drawer: AppDrawer(
        //   defaultSmall: false,
        //   largeDrawerWidth: 200,
        //   largeDrawer: drawer(small: false),
        //   smallDrawerWidth: 60,
        //   smallDrawer: drawer(small: true),
        // ),
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
                        auxData(),
                      ],
                    ),
                    Column(
                      children: const [
                        Text('Select Process'),
                        ElevatedButton(
                            onPressed: null, child: Text('Enter/Edit Crs')),
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
                            child: auxData()),
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

  // Builder masterPane() {
  //   if (kDebugMode) {
  //     print('BUILD: masterPane');
  //   }
  //   return Builder(
  //     builder: (BuildContext context) {
  //       return Container(
  //         color: masterBackgroundColor,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.stretch,
  //           children: [
  //             Row(
  //               children: const [
  //                 Text('status: need to import',
  //                     style:
  //                         TextStyle(fontSize: 25, fontWeight: FontWeight.bold))
  //               ],
  //             ),
  //             data()
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Builder masterPane() {
    if (kDebugMode) {
      print('BUILD: masterPane');
    }
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: 1000,
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
  final tempList = List<int>.generate(24, (index) => 1);
  return Container(
    child: Table(
      border: TableBorder.symmetric(
          inside: const BorderSide(width: 1, color: Colors.blue),
          outside: const BorderSide(width: 1)),
      columnWidths: {0: IntrinsicColumnWidth()},
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

Widget data() {
  return DataTable(
    columns: const <DataColumn>[
      DataColumn(
        label: Text(
          'Name',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'First Choices',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'First Backup',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Second Backup',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Third Backup',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Add from BU\'s',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Drop, Bad Time',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Drop, Dupe Class',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'Drop, Class Full',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      DataColumn(
        label: Text(
          'resulting size',
          softWrap: true,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    ],
    rows: const <DataRow>[
      DataRow(
        cells: <DataCell>[
          DataCell(Text('Sarah')),
          DataCell(Text('19')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('Sarah')),
          DataCell(Text('19')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('Sarah')),
          DataCell(Text('19')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('Sarah')),
          DataCell(Text('19')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
          DataCell(Text('Student')),
        ],
      ),
    ],
  );
}

Widget auxData() {
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
    rows: const <DataRow>[
      DataRow(
        cells: <DataCell>[
          DataCell(Text('Course Takers')),
          DataCell(Text('19')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('Go Courses')),
          DataCell(Text('19')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('places asked')),
          DataCell(Text('19')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('places given')),
          DataCell(Text('19')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('un-met wants')),
          DataCell(Text('19')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('on leave')),
          DataCell(Text('19')),
        ],
      ),
      DataRow(
        cells: <DataCell>[
          DataCell(Text('Missing')),
          DataCell(Text('19')),
        ],
      ),
    ],
  );
}
