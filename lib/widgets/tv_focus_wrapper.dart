import 'package:flutter/material.dart';

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
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final callback = widget.onTap ?? widget.onSelect;

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) {
        setState(() => _focused = v);
        if (v) {
          try {
            Scrollable.ensureVisible(context, alignment: 0.5, duration: const Duration(milliseconds: 150));
          } catch (_) {}
        }
      },
      actions: callback != null
          ? {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  callback();
                  return null;
                },
              ),
            }
          : {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: widget.margin,
        padding: widget.padding,
        transform: _focused ? Matrix4.diagonal3Values(1.06, 1.06, 1.0) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          border: Border.all(
            color: _focused ? const Color(0xFF3B82F6) : Colors.transparent,
            width: _focused ? 3.0 : 0,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: InkWell(
          onTap: callback,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          child: widget.child,
        ),
      ),
    );
  }
}
