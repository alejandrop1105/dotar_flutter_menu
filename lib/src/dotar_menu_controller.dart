import 'package:flutter/widgets.dart';

/// Whether the side menu is open. A [DotarMenuShell] animates to it, and any
/// widget under the shell reaches it with [DotarMenuController.of]: an app's
/// hamburger button toggles it, its back handler closes it.
///
/// The app owns it, as it owns a `TextEditingController`: it creates it,
/// passes it to the shell and disposes it.
class DotarMenuController extends ChangeNotifier {
  DotarMenuController({bool isOpen = false}) : _isOpen = isOpen;

  bool _isOpen;

  bool get isOpen => _isOpen;

  /// Opens the menu, and does nothing when it is open.
  void open() => _set(true);

  /// Closes the menu, and does nothing when it is closed. DEAM-Resto #211:
  /// the menu's items closed it twice, once in each item's action and once in
  /// the builder of every item, and with a toggle the second call opened it
  /// again: "Dashboard" showed the tables behind a menu still open.
  void close() => _set(false);

  void toggle() => _set(!_isOpen);

  void _set(bool isOpen) {
    if (_isOpen == isOpen) return;
    _isOpen = isOpen;
    notifyListeners();
  }

  /// The controller of the closest [DotarMenuScope] (every [DotarMenuShell]
  /// sets one), rebuilding [context] when the menu opens or closes. Asserts
  /// there is one.
  static DotarMenuController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'DotarMenuController.of() called with a context that is not under a '
      'DotarMenuShell or a DotarMenuScope.',
    );
    return controller!;
  }

  /// As [of], null when [context] is not under a shell or a scope.
  static DotarMenuController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DotarMenuScope>()?.notifier;
}

/// Hands a [DotarMenuController] down the tree, for
/// [DotarMenuController.of]. [DotarMenuShell] sets one over the menu and the
/// app; an app needs its own only to reach the controller above the shell.
class DotarMenuScope extends InheritedNotifier<DotarMenuController> {
  const DotarMenuScope({
    super.key,
    required DotarMenuController controller,
    required super.child,
  }) : super(notifier: controller);
}
