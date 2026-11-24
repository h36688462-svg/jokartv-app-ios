import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVNavigationEngine extends StatefulWidget {
  final Widget child;

  const TVNavigationEngine({
    super.key,
    required this.child,
  });

  @override
  State<TVNavigationEngine> createState() => _TVNavigationEngineState();
}

class _TVNavigationEngineState extends State<TVNavigationEngine> {
  DateTime _lastKeyEventTime = DateTime.now();

  bool _isThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastKeyEventTime).inMilliseconds < 80) {
      return true; // Throttling rapid remote spam clicks (< 80ms) to prevent ANR
    }
    _lastKeyEventTime = now;
    return false;
  }

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
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              if (_isThrottled()) return null;
              final currentFocus = FocusManager.instance.primaryFocus;
              if (currentFocus != null) {
                final ctx = currentFocus.context;
                if (ctx != null) {
                  try {
                    Actions.invoke(ctx, intent);
                  } catch (_) {}
                }
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent || event is KeyRepeatEvent) {
              if (_isThrottled()) {
                return KeyEventResult.handled;
              }
              final logical = event.logicalKey;
              if (logical == LogicalKeyboardKey.escape ||
                  logical == LogicalKeyboardKey.goBack ||
                  logical == LogicalKeyboardKey.browserBack) {
                Future.microtask(() {
                  if (!context.mounted) return;
                  try {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } catch (_) {}
                });
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class BackIntent extends Intent {
  const BackIntent();
}
