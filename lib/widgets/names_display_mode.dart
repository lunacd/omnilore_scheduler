import 'package:flutter/material.dart';
import 'package:omnilore_scheduler/theme.dart';

/// Creates the name display mode set of buttons. This includes show splits,
/// show BU & CA, Implement splits, Show Coord(s), Set C and CC, Set CC1 and CC2
class NamesDisplayMode extends StatelessWidget {
  const NamesDisplayMode(
      {Key? key,
      required this.onImplSplit,
      required this.onShowCoords,
      required this.onSetC,
      required this.onSetCC})
      : super(key: key);

  final void Function()? onImplSplit;
  final void Function()? onShowCoords;
  final void Function()? onSetC;
  final void Function()? onSetCC;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: themeColors['KindaBlue'],
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Container(
            alignment: Alignment.center,
            child: const Text('NAMES DISPLAY MODE',
                style: TextStyle(fontStyle: FontStyle.normal, fontSize: 25)),
          ),
          const ElevatedButton(onPressed: null, child: Text('Show Splits')),
          ElevatedButton(
              onPressed: onImplSplit, child: const Text('Imp. Splits')),
          ElevatedButton(
              onPressed: onShowCoords, child: const Text('Show Coord(s)')),
          ElevatedButton(onPressed: onSetC, child: const Text('Set C and CC')),
          ElevatedButton(
              onPressed: onSetCC, child: const Text('Set CC1 and CC2')),
        ]));
  }
}
