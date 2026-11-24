import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvGlobalFocusRoot extends StatelessWidget {
  final Widget child;

  const TvGlobalFocusRoot({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            final currentFocus = FocusManager.instance.primaryFocus;
            if (currentFocus != null && currentFocus != node) {
              final ctx = currentFocus.context;
              if (ctx != null) {
                try {
                  Actions.invoke(ctx, const ActivateIntent());
                  return KeyEventResult.handled;
                } catch (_) {}
              }
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
