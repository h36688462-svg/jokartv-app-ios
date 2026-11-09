import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const TvFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onSelect,
    this.autofocus = false,
    this.focusNode,
    this.margin,
    this.padding,
    this.borderRadius,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  late FocusNode _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _internalFocusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            if (widget.onTap != null) {
              widget.onTap!();
              return KeyEventResult.handled;
            } else if (widget.onSelect != null) {
              widget.onSelect!();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          if (isFocused && widget.onTap != null) {
            // Ensure visible when focused by remote
            Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 50));
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: widget.margin,
            padding: widget.padding,
            transform: isFocused ? Matrix4.diagonal3Values(1.05, 1.05, 1.0) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              border: Border.all(
                color: isFocused ? const Color(0xFF3B82F6) : Colors.transparent,
                width: isFocused ? 2.5 : 0,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: InkWell(
              onTap: widget.onTap ?? widget.onSelect,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
