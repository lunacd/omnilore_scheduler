import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/compute/course_control.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/model/state_of_processing.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/theme.dart';
import 'package:omnilore_scheduler/widgets/utils.dart';

const modeDescriptions = <String>['splitting', 'limiting'];

class ClassSizeControl extends StatefulWidget {
  const ClassSizeControl(
      {Key? key,
      required this.schedule,
      required this.courses,
      required this.onChange})
      : super(key: key);

  final Scheduling schedule;
  final List<String> courses;
  final void Function(Change) onChange;

  @override
  State<StatefulWidget> createState() => ClassSizeControlState();
}

class ClassSizeControlState extends State<ClassSizeControl> {
  final minController = TextEditingController();
  final maxController = TextEditingController();
  SplitMode mode = SplitMode.split;
  String course = 'ALL';
  late String minValue = widget.schedule.courseControl.isMinSizeMixed()
      ? 'Mix'
      : widget.schedule.courseControl.getGlobalMinClassSize().toString();
  late String maxValue = widget.schedule.courseControl.isMaxSizeMixed()
      ? 'Mix'
      : widget.schedule.courseControl.getGlobalMaxClassSize().toString();

  @override
  Widget build(BuildContext context) {
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
                _classDropDownMenu(),
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
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(),
                        hintText: minValue,
                      ),
                      controller: minController,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        height: 1.25,
                        color: Colors.black,
                      ))),
              SizedBox(
                  width: 100,
                  child: TextField(
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(),
                        hintText: maxValue,
                      ),
                      controller: maxController,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          height: 1.25,
                          color: Colors.black))),
            ],
          ),
          const Row(
            children: [
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
                      if (mode == SplitMode.limit) {
                        mode = SplitMode.split;
                      } else {
                        mode = SplitMode.limit;
                      }
                    }));
                  },
                  child: Text(modeDescriptions[mode.index]),
                ),
              ),
              SizedBox(
                height: 25.0,
                width: 100.0,
                child:
                    ElevatedButton(onPressed: _set, child: const Text('set')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget that creates a drop down menu of courses used to display class size
  /// maximums and minimums
  Widget _classDropDownMenu() {
    return DropdownButton(
        hint: Text(course),
        items: (<String>['ALL'].followedBy(widget.courses)).map((String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          course = newValue!;
          setState(() {
            if (course == 'ALL') {
              widget.schedule.courseControl.isMaxSizeMixed()
                  ? maxValue = 'Mix'
                  : maxValue = widget.schedule.courseControl
                      .getGlobalMaxClassSize()
                      .toString();
              widget.schedule.courseControl.isMinSizeMixed()
                  ? minValue = 'Mix'
                  : minValue = widget.schedule.courseControl
                      .getGlobalMinClassSize()
                      .toString();
              mode = SplitMode.split;
            } else {
              maxValue = widget.schedule.courseControl
                  .getMaxClassSize(course)
                  .toString();
              minValue = widget.schedule.courseControl
                  .getMinClassSize(course)
                  .toString();
              mode = widget.schedule.courseControl.getSplitMode(course);
            }
          });
        });
  }

  /// This class is a private computation function that sets the min and max class
  /// size for each class
  void _set() {
    setState(() {
      minValue = minController.text;
      maxValue = maxController.text;
      if (minValue.isNotEmpty &&
          maxValue.isNotEmpty &&
          widget.schedule.getStateOfProcessing() !=
              StateOfProcessing.needCourses) {
        int min;
        int max;
        try {
          min = int.parse(minValue);
          max = int.parse(maxValue);
        } catch (e) {
          Utils.showPopUp(context, 'Min/Max invalid input', e.toString());
          return;
        }
        if (course == 'ALL') {
          widget.schedule.courseControl.setGlobalMinMaxClassSize(min, max);
        } else {
          widget.schedule.courseControl
              .setMinMaxClassSizeForClass(course, min, max);
          widget.schedule.courseControl.setSplitMode(course, mode);
        }
        minController.clear();
        maxController.clear();
        widget.onChange(Change.schedule);
      } else {
        String error;
        if (minValue == '' || maxValue == '') {
          error = 'Please enter a value for both min and max';
        } else {
          error = 'Please import courses first';
        }
        Utils.showPopUp(context, 'Set class size error', error);
        minController.clear();
        maxController.clear();
      }
    });
  }
}
