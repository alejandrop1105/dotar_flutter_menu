import 'package:flutter/material.dart';

import 'dotar_menu_controller.dart';

/// The app with the side menu behind it, as DEAM-Resto's `HomeShell` draws
/// it: opening the menu slides the app [slide] px right and [lift] px up,
/// shrinks it to [scale], tilts it [rotation] radians and rounds its corners,
/// over [duration] with [curve]. Closed, the app is drawn as it is, with no
/// transform; open, it takes no input and a tap on it closes the menu.
///
/// [controller] opens and closes it, and the shell hands it down to [menu]
/// and [child] through a [DotarMenuScope].
class DotarMenuShell extends StatefulWidget {
  const DotarMenuShell({
    super.key,
    required this.controller,
    required this.menu,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.slide = 250.0,
    this.lift = 30.0,
    this.scale = 0.85,
    this.rotation = 0.1745,
    this.borderRadius = 30.0,
    this.backgroundColor = const Color(0xFF1E1E2C),
  });

  final DotarMenuController controller;

  /// What the app uncovers, usually a [DotarMenu]. Built only while the menu
  /// is open or moving.
  final Widget menu;

  /// The app, usually a [Scaffold]: it paints its own background.
  final Widget child;

  final Duration duration;
  final Curve curve;

  /// How far right the open app moves.
  final double slide;

  /// How far up the open app moves.
  final double lift;

  /// The open app's size, a fraction of the screen's.
  final double scale;

  /// The open app's tilt in radians, ~10°.
  final double rotation;

  /// The open app's corner radius.
  final double borderRadius;

  /// Behind the menu, and the open app's border.
  final Color backgroundColor;

  @override
  State<DotarMenuShell> createState() => _DotarMenuShellState();
}

class _DotarMenuShellState extends State<DotarMenuShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final CurvedAnimation _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.controller.isOpen ? 1.0 : 0.0,
    )..addStatusListener(_onStatus);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    );
    widget.controller.addListener(_onMenu);
  }

  @override
  void didUpdateWidget(DotarMenuShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animationController.duration = widget.duration;
    _animation.curve = widget.curve;
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onMenu);
      widget.controller.addListener(_onMenu);
      _animate();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onMenu);
    _animation.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onMenu() {
    _animate();
    setState(() {});
  }

  void _animate() {
    if (widget.controller.isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  /// Closed, the menu leaves the tree, and its endless background animation
  /// with it. In DEAM-Resto it stayed built behind the app: its shell decided
  /// the menu's visibility when it built, and nothing rebuilt it when the
  /// closing animation ended.
  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.controller.isOpen;
    return DotarMenuScope(
      controller: widget.controller,
      child: Scaffold(
        backgroundColor: widget.backgroundColor,
        body: Stack(
          children: [
            // The menu behind, hidden while the menu is closed.
            Visibility(
              visible: isOpen || _animationController.isAnimating,
              child: widget.menu,
            ),
            // The app, scaled and moved aside.
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final value = _animation.value;
                if (value == 0.0) return child!;
                final scale = 1.0 - value * (1.0 - widget.scale);
                final radius = value * widget.borderRadius;
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..translateByDouble(
                      widget.slide * value,
                      -widget.lift * value,
                      0.0,
                      1.0,
                    )
                    ..scaleByDouble(scale, scale, scale, 1.0)
                    ..rotateZ(value * widget.rotation),
                  alignment: const Alignment(-1.0, 0.4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: radius > 0
                          ? Border.all(
                              color: widget.backgroundColor,
                              width: 2.5,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4 * value),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(radius),
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: child,
                    ),
                  ),
                );
              },
              child: GestureDetector(
                onTap: isOpen ? widget.controller.close : null,
                child: AbsorbPointer(absorbing: isOpen, child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
