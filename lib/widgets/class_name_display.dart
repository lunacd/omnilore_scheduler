import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/model/coordinators.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/theme.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';
import 'package:omnilore_scheduler/widgets/utils.dart';

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

class ClassNameDisplay extends StatefulWidget {
  const ClassNameDisplay(
      {Key? key,
      required this.currentRow,
      required this.currentClass,
      required this.schedule,
      required this.people})
      : super(key: key);

  final RowType currentRow;
  final String? currentClass;
  final Scheduling schedule;
  final List<String> people;

  @override
  State<StatefulWidget> createState() => ClassNameDisplayState();
}

class ClassNameDisplayState extends State<ClassNameDisplay> {
  late List<bool> _selected =
      List<bool>.filled(widget.people.length, false, growable: false);

  void clearSelection() {
    for (int i = 0; i < _selected.length; i++) {
      _selected[i] = false;
    }
  }

  void _select(String person) {
    for (int i = 0; i < widget.people.length; i++) {
      if (widget.people[i] == person) {
        _selected[i] = true;
      }
    }
  }

  List<String> _getSelected() {
    var result = <String>[];
    for (int i = 0; i < widget.people.length; i++) {
      if (_selected[i]) {
        result.add(widget.people[i]);
      }
    }
    return result;
  }

  /// Display the coordinators for the current course
  void showCoordinators() {
    Coordinators? coordinator =
        widget.schedule.courseControl.getCoordinators(widget.currentClass!);
    if (coordinator != null) {
      setState(() {
        clearSelection();
        for (var person in coordinator.coordinators) {
          if (person.isNotEmpty) {
            _select(person);
          }
        }
      });
    }
  }

  /// Set the selected as the main coordinator or CC
  void setMainCoordinator() {
    var peopleSelected = _getSelected();
    assert(peopleSelected.length < 2);
    if (peopleSelected.isNotEmpty) {
      try {
        widget.schedule.courseControl
            .setMainCoCoordinator(widget.currentClass!, peopleSelected[0]);
      } on Exception catch (e) {
        Utils.showPopUp(context, 'Set C/CC error', e.toString());
      }
    }
    setState(() {
      clearSelection();
    });
  }

  /// Set the selected as CC1 or CC2
  void setCoCoordinator() {
    var peopleSelected = _getSelected();
    assert(peopleSelected.length < 2);
    if (peopleSelected.isNotEmpty) {
      try {
        widget.schedule.courseControl
            .setEqualCoCoordinator(widget.currentClass!, peopleSelected[0]);
      } on Exception catch (e) {
        Utils.showPopUp(context, 'Set CC1/CC2 error', e.toString());
      }
    }
    setState(() {
      clearSelection();
    });
  }

  @override
  void didUpdateWidget(covariant ClassNameDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = List<bool>.filled(widget.people.length, false, growable: false);
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: widget.currentRow == RowType.resultingClass
                    ? () {
                        setState(() {
                          for (int i = 0; i < _selected.length; i++) {
                            if (_selected[i]) {
                              widget.schedule.splitControl
                                  .removeCluster(widget.people[i]);
                              _selected[i] = false;
                            }
                          }
                        });
                      }
                    : null,
                child: const Text('Dec Clust')),
            ElevatedButton(
                onPressed: widget.currentRow == RowType.resultingClass
                    ? () {
                        setState(() {
                          Set<String> result = <String>{};
                          for (int i = 0; i < _selected.length; i++) {
                            if (_selected[i]) {
                              result.add(widget.people[i]);
                            }
                          }
                          widget.schedule.splitControl.addCluster(result);
                          clearSelection();
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
            if (widget.currentRow != RowType.none)
              Text(
                '${_getRowDescription(widget.currentRow)} of ${widget.currentClass}',
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              )
          ],
          mainAxisAlignment: MainAxisAlignment.start,
        ),
        Wrap(
          direction: Axis.horizontal,
          children: [
            for (int i = 0; i < widget.people.length; i++)
              ElevatedButton(
                  style: (() {
                    if (_selected[i] == true) {
                      return ElevatedButton.styleFrom(
                          primary: Colors.red, onPrimary: Colors.white);
                    } else {
                      int clusterIndex = widget.schedule.splitControl
                          .getClusterIndex(widget.people[i]);
                      if (clusterIndex == -1) {
                        return ElevatedButton.styleFrom(primary: Colors.white);
                      } else {
                        return ElevatedButton.styleFrom(
                            primary: clusterColors[
                                clusterIndex % clusterColors.length]);
                      }
                    }
                  }()),
                  onPressed: widget.currentRow == RowType.resultingClass ||
                          widget.currentRow == RowType.className
                      ? () {
                          setState(() {
                            if (widget.currentRow == RowType.resultingClass) {
                              _selected[i] = !_selected[i];
                            } else {
                              clearSelection();
                              _selected[i] = true;
                            }
                          });
                        }
                      : null,
                  child: Text(
                    widget.people[i],
                    style: (() {
                      int clusterIndex = widget.schedule.splitControl
                          .getClusterIndex(widget.people[i]);
                      if (clusterIndex != -1 &&
                          clusterColors[clusterIndex % clusterColors.length] ==
                              Colors.brown) {
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

  /// Get the description of a row
  String _getRowDescription(RowType row) {
    if (row == RowType.className) {
      return _getRowDescription(RowType.resultingClass);
    }
    return overviewRows[row.index - 1];
  }
}
