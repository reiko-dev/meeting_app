import 'package:flutter/material.dart';
import 'package:meeting_app/application_state.dart';
import 'package:meeting_app/src/widgets.dart';

class ConfirmPresence extends StatelessWidget {
  const ConfirmPresence(
      {required this.state, required this.onSelection, Key? key})
      : super(key: key);

  final Attendding state;

  final void Function(Attendding selection) onSelection;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case Attendding.yes:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () => onSelection(Attendding.yes),
                child: const Text('YES'),
              ),
              const SizedBox(width: 8.0),
              TextButton(
                onPressed: () => onSelection(Attendding.no),
                child: const Text('NO'),
              ),
            ],
          ),
        );
      case Attendding.no:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              TextButton(
                onPressed: () => onSelection(Attendding.yes),
                child: const Text('YES'),
              ),
              const SizedBox(width: 8.0),
              ElevatedButton(
                onPressed: () => onSelection(Attendding.no),
                child: const Text('NO'),
              ),
            ],
          ),
        );

      case Attendding.unknown:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              StyledButton(
                onPressed: () => onSelection(Attendding.yes),
                child: const Text('YES'),
              ),
              const SizedBox(width: 8.0),
              StyledButton(
                onPressed: () => onSelection(Attendding.no),
                child: const Text('NO'),
              ),
            ],
          ),
        );
    }
  }
}
