import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVKeyHandler extends StatefulWidget {
  final Widget child;
  final Function(LogicalKeyboardKey key)? onKeyPressed;

  const TVKeyHandler({
    super.key,
    required this.child,
    this.onKeyPressed,
  });

  @override
  State<TVKeyHandler> createState() => _TVKeyHandlerState();
}

class _TVKeyHandlerState extends State<TVKeyHandler> {
  final FocusScopeNode _rootFocusScopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).setFirstFocus(_rootFocusScopeNode);
      }
    });
  }

  @override
  void dispose() {
    _rootFocusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _rootFocusScopeNode,
      autofocus: true,
      child: Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            final key = event.logicalKey;
            if (widget.onKeyPressed != null) {
              widget.onKeyPressed!(key);
            }

            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.numpadEnter ||
                key == LogicalKeyboardKey.gameButtonA ||
                key == LogicalKeyboardKey.mediaPlayPause ||
                key == LogicalKeyboardKey.mediaPlay ||
                key == LogicalKeyboardKey.mediaPause ||
                key == LogicalKeyboardKey.mediaFastForward ||
                key == LogicalKeyboardKey.mediaRewind) {

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
                key == LogicalKeyboardKey.arrowRight) {
              return KeyEventResult.ignored;
            }
          }
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
