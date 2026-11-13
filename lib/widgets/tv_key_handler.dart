import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVKeyHandler extends StatelessWidget {
  final Widget child;
  final Function(LogicalKeyboardKey key) onKeyPressed;

  const TVKeyHandler({
    super.key,
    required this.child,
    required this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          LogicalKeyboardKey key = event.logicalKey;

          onKeyPressed(key);

          if (
              // Media keys
              key == LogicalKeyboardKey.mediaPlayPause ||
              key == LogicalKeyboardKey.mediaPlay ||
              key == LogicalKeyboardKey.mediaPause ||
              key == LogicalKeyboardKey.mediaFastForward ||
              key == LogicalKeyboardKey.mediaRewind ||
              // D-pad navigation
              key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              // Back
              key == LogicalKeyboardKey.goBack ||
              key == LogicalKeyboardKey.escape) {

            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}
