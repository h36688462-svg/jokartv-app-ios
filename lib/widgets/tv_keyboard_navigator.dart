import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVKeyboardNavigator extends StatelessWidget {
  final Widget child;

  const TVKeyboardNavigator({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final key = event.logicalKey;

          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.mediaPlayPause) {
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
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.mediaFastForward ||
              key == LogicalKeyboardKey.mediaRewind ||
              key == LogicalKeyboardKey.channelUp ||
              key == LogicalKeyboardKey.channelDown ||
              key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.goBack ||
              key == LogicalKeyboardKey.browserBack) {
            return KeyEventResult.ignored;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
