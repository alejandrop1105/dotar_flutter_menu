# dotar_flutter_menu

Dotar Soluciones' side menu, the company's signature in its Flutter apps. Opening it slides, shrinks and tilts the app aside to uncover a dark animated menu behind it: a rotating gradient with three drifting orbs under a blur, the signed-in user, the logout, the app's items, a light/dark switch and, at the foot, "por Dotar Soluciones SAS" with the app's version.

DEAM-Resto's menu (`frontendV2`, `HomeShell` and `AnimatedDrawerContent`) is the reference: the package reproduces its look and motion as they are, and leaves everything app-specific to parameters.

## Install

Integrating it into an existing app, step by step (private access in CI and Docker included): [docs/INTEGRATION.md](docs/INTEGRATION.md).

The package is private: add it as a git dependency.

```yaml
dependencies:
  dotar_flutter_menu:
    git:
      url: https://github.com/alejandrop1105/dotar_flutter_menu.git
      ref: v0.1.0
```

It depends only on Flutter and `url_launcher`, and bundles Plus Jakarta Sans (SIL Open Font License, `fonts/OFL.txt`), so the menu looks the same offline and an app declares no font for it.

## Use

The app owns a `DotarMenuController`, passes it to a `DotarMenuShell`, and gives the shell the menu and the app:

```dart
final menu = DotarMenuController(); // dispose it with its State

DotarMenuShell(
  controller: menu,
  menu: DotarMenu(
    header: Image.asset('assets/logo.png', height: 72),
    user: const DotarMenuUser(name: 'Juan Pérez', subtitle: 'Administrador'),
    onLogout: () => auth.logout(),
    items: [
      DotarMenuItem(icon: Icons.dashboard_rounded, label: 'Inicio', onTap: () => go('/')),
      DotarMenuItem(
        icon: Icons.bar_chart_rounded,
        label: 'Estadísticas',
        onTap: () => go('/stats'),
        visible: settings.showStats,
      ),
    ],
    bottomItems: [
      DotarMenuItem(icon: Icons.dns_rounded, label: 'Servidor', onTap: showServer),
    ],
    modeSwitch: DotarMenuModeSwitch(isDark: isDark, onChanged: setDark),
    version: '1.3.0', // shown as "v1.3.0"; null shows nothing
  ),
  child: Scaffold(/* the app */),
)
```

- **Opening and closing.** Anything under the shell reaches the controller with `DotarMenuController.of(context)`: a hamburger button calls `toggle()`. `open()` and `close()` do nothing when the menu already is open or closed, so closing twice never reopens it.
- **Items.** An item runs its `onTap` and then closes the menu; `visible: false` leaves it out. `bottomItems` are drawn compact at the bottom, under the mode switch.
- **Logout.** `onLogout` runs after the menu closes; without it there is no logout. Its label is `logoutLabel`, "Cerrar Sesión" by default.
- **Header.** `header` is drawn centred at the top with 16 px above and below; without it the menu keeps a 50 px gap.
- **User.** The name shows whole, over as many lines as it needs. Without `avatarUrl` the avatar shows the initials of the first and the last word of the name.
- **Mode switch.** Optional. The app owns the mode: `onChanged` gets the mode chosen, true for dark. Its label is "Modo" by default.
- **Colors.** `brandColor` (the avatar's border and the first orb) defaults to the theme's primary color; `brandLightColor` (the third orb) to `brandColor` lightened 20% toward white.
- **Signature.** "por Dotar Soluciones SAS" opens http://dotarsoluciones.com.ar in the browser. It is fixed: it is the company's signature.
- **Motion.** The shell's `duration`, `curve`, `slide`, `lift`, `scale`, `rotation`, `borderRadius` and `backgroundColor` default to DEAM-Resto's values (300 ms easeInOut; 250 px right, 30 px up, 85%, 0.1745 rad, 30 px corners, `0xFF1E1E2C`). While the menu is open the app takes no input and a tap on it closes the menu.

## The back button

The shell does not handle back by itself. Close the open menu instead of leaving the page:

```dart
ListenableBuilder(
  listenable: menu,
  builder: (context, child) => PopScope(
    canPop: !menu.isOpen,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) menu.close();
    },
    child: child!,
  ),
  child: DotarMenuShell(controller: menu, menu: ..., child: ...),
)
```

An app with its own back dispatcher (DEAM-Resto's `NeverExitBackButtonDispatcher`) checks `menu.isOpen` and calls `menu.close()` there instead.

## Example

`example/` is a minimal app with the shell, a hamburger button, a few items, a user, the mode switch and a version. It carries no platform folders: add the ones to run it on with `flutter create --platforms=android .` inside `example/`.

## Develop

```sh
flutter pub get
flutter analyze
flutter test
```
