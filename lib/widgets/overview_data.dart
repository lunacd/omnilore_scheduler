import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/theme.dart';

class OverviewData extends StatelessWidget {
  const OverviewData(
      {Key? key,
      required this.courseTakers,
      required this.goCourses,
      required this.placesAsked,
      required this.placesGiven,
      required this.unmetWants,
      required this.onLeave,
      required this.onUnmetWantsClicked})
      : super(key: key);

  final int courseTakers;
  final int goCourses;
  final int placesAsked;
  final int placesGiven;
  final int unmetWants;
  final int onLeave;
  final VoidCallback onUnmetWantsClicked;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: themeColors['LightBlue'],
      constraints: const BoxConstraints.expand(),
      child: DefaultTextStyle(
        child: Column(
          children: [
            Text('\nCourse Takers $courseTakers'),
            Text('Go Courses $goCourses'),
            Text('Places Asked $placesAsked'),
            Text('Places Given $placesGiven'),
            TextButton(
                onPressed: onUnmetWantsClicked,
                child: Text(
                  'Un-met Wants $unmetWants',
                  style: const TextStyle(fontSize: 20, color: Colors.black),
                )),
            Text('On Leave $onLeave'),
            const Text('Missing 0'),
          ],
        ),
        style: const TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }
}
