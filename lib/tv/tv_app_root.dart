import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVAppRoot extends StatelessWidget {
  final Widget child;

  const TVAppRoot({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () {},
        const SingleActivator(LogicalKeyboardKey.select): () {},
        const SingleActivator(LogicalKeyboardKey.enter): () {},
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {},
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {},
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {},
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {},
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.numpadEnter ||
                key == LogicalKeyboardKey.gameButtonA ||
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
            }
          }
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    );
  }
}
