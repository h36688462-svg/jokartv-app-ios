import 'package:flutter/material.dart';

class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const TvFocusable({
    super.key,
    required this.child,
    required this.onTap,
    this.autofocus = false,
    this.focusNode,
    this.margin,
    this.padding,
    this.borderRadius,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final callback = widget.onTap;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) {
        if (mounted) {
          setState(() => _focused = v);
        }
        if (v) {
          try {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
            );
          } catch (_) {}
        }
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            callback();
            return null;
          },
        ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: widget.margin,
        padding: widget.padding,
        transform: _focused ? Matrix4.diagonal3Values(1.08, 1.08, 1.0) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
          border: Border.all(
            color: _focused ? const Color(0xFF3B82F6) : Colors.transparent,
            width: _focused ? 3.5 : 0,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.8),
                    blurRadius: 16,
                    spreadRadius: 3,
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: callback,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// Backward compatibility alias
class TvFocusWrapper extends TvFocusable {
  const TvFocusWrapper({
    super.key,
    required super.child,
    VoidCallback? onTap,
    VoidCallback? onSelect,
    super.autofocus,
    super.focusNode,
    super.margin,
    super.padding,
    super.borderRadius,
  }) : super(onTap: onTap ?? onSelect ?? _empty);

  static void _empty() {}
}
