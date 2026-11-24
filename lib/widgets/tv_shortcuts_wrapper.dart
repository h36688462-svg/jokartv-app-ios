import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const TVShortcutsWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const BackIntent(),
        const SingleActivator(LogicalKeyboardKey.goBack): const BackIntent(),
        const SingleActivator(LogicalKeyboardKey.browserBack): const BackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          BackIntent: CallbackAction<BackIntent>(
            onInvoke: (BackIntent intent) {
              try {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              } catch (_) {}
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class BackIntent extends Intent {
  const BackIntent();
}
