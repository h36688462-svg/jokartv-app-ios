import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TVKeyboardFixWrapper extends StatefulWidget {
  final Widget child;
  const TVKeyboardFixWrapper({super.key, required this.child});

  @override
  State<TVKeyboardFixWrapper> createState() => _TVKeyboardFixWrapperState();
}

class _TVKeyboardFixWrapperState extends State<TVKeyboardFixWrapper> {
  final FocusNode _rootFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_rootFocusNode);
    });
  }

  @override
  void dispose() {
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _rootFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            return KeyEventResult.ignored;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
