# Integrating dotar_flutter_menu into an app

A step-by-step guide for a Dotar Flutter app (or the agent working on it) that wants the company's side menu. The [README](../README.md) is the reference for every parameter; this guide is the order to do things in and the traps on the way.

## 0. Before you start

- **Toolchain:** Dart `^3.11.0`, Flutter `>=3.41.0`. Check with `flutter --version`.
- **Access:** the repository is **private**. Every machine and every CI or Docker build that runs `flutter pub get` needs read access to `github.com/alejandrop1105/dotar_flutter_menu` (see step 5). Ask the owner for access if `git ls-remote https://github.com/alejandrop1105/dotar_flutter_menu.git` fails.
- **Questions:** the package is registered in Nexus as `dotar-flutter-menu`. Send a message there instead of guessing:

  ```sh
  nexuscli msg send dotar-flutter-menu --subject "<your app>: <question>" --body "<what you tried, what you see>"
  ```

## 1. Add the dependency

```yaml
dependencies:
  dotar_flutter_menu:
    git:
      url: https://github.com/alejandrop1105/dotar_flutter_menu.git
      ref: v0.1.0 # always a tag, never a branch
```

Run `flutter pub get` and commit `pubspec.lock`: it pins the exact commit. The package brings only `url_launcher` and its own font; the app declares no font and no asset for it.

## 2. Own a controller

Create one `DotarMenuController` in the `State` that hosts the app's main screen (the home shell, not each page) and dispose it there:

```dart
class _HomeShellState extends State<HomeShell> {
  final _menu = DotarMenuController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }
  // ...
}
```

## 3. Wrap the app's main screen

`DotarMenuShell` goes **around** the screen the menu belongs to, so the whole screen slides aside. Put it above the `Scaffold`, below `MaterialApp`/the router:

```dart
@override
Widget build(BuildContext context) {
  return DotarMenuShell(
    controller: _menu,
    menu: DotarMenu(
      header: Image.asset('assets/logo.png', height: 72),
      user: DotarMenuUser(name: user.fullName, subtitle: user.role),
      onLogout: auth.logout,
      items: [
        DotarMenuItem(icon: Icons.dashboard_rounded, label: 'Inicio', onTap: () => go('/')),
        DotarMenuItem(icon: Icons.receipt_long_rounded, label: 'Pedidos', onTap: () => go('/orders')),
      ],
      bottomItems: [
        DotarMenuItem(icon: Icons.settings_rounded, label: 'Ajustes', onTap: () => go('/settings')),
      ],
      modeSwitch: DotarMenuModeSwitch(isDark: theme.isDark, onChanged: theme.setDark),
      version: appVersion, // e.g. from package_info_plus; null hides it
    ),
    child: Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => DotarMenuController.of(context).toggle(),
          ),
        ),
      ),
      body: page,
    ),
  );
}
```

Rules worth knowing:

- An item's `onTap` runs and then the menu closes by itself: do not call `close()` in it.
- Use `visible: false` to hide an item by permission or setting instead of building the list conditionally.
- `onLogout` runs after the menu closes; leave it null and there is no logout row.
- The brand color defaults to the theme's `primaryColor`; pass `brandColor` only if the app's brand differs from its theme.
- The footer "por Dotar Soluciones SAS" is fixed: it is the company's signature, there is no parameter to change or hide it.

## 4. Remove the old menu and handle back

1. Delete the app's previous menu: `Scaffold.drawer`, `endDrawer`, a custom `Stack` animation, or its own copy of DEAM-Resto's `AnimatedDrawerContent`. Two menus fight over the same gesture.
2. Map every old drawer entry to a `DotarMenuItem` (main list) or a `bottomItems` entry (compact list at the foot).
3. The shell does not catch the back button. Without this, back on Android leaves the page while the menu is open:

   ```dart
   ListenableBuilder(
     listenable: _menu,
     builder: (context, child) => PopScope(
       canPop: !_menu.isOpen,
       onPopInvokedWithResult: (didPop, _) {
         if (!didPop) _menu.close();
       },
       child: child!,
     ),
     child: DotarMenuShell(controller: _menu, menu: ..., child: ...),
   )
   ```

   If the app has its own back dispatcher, check `_menu.isOpen` there and call `_menu.close()` instead.

## 5. Make CI and Docker builds reach the private repo

`flutter pub get` clones the package with the system `git`, so the build needs GitHub credentials.

- **Developer machine:** `gh auth login` and then `gh auth setup-git` once.
- **GitHub Actions:** a fine-grained token with *Contents: read* on this repository, stored as a secret, before `pub get`:

  ```sh
  git config --global url."https://x-access-token:${DOTAR_MENU_TOKEN}@github.com/".insteadOf "https://github.com/"
  ```

- **Docker / Coolify:** pass the token as a BuildKit secret, never as a build `ARG` or `ENV` (both stay in the image history). Setting the rewrite through `GIT_CONFIG_*` variables of that one `RUN` writes nothing to disk:

  ```dockerfile
  RUN --mount=type=secret,id=dotar_menu_token \
      GIT_CONFIG_COUNT=1 \
      GIT_CONFIG_KEY_0="url.https://x-access-token:$(cat /run/secrets/dotar_menu_token)@github.com/.insteadOf" \
      GIT_CONFIG_VALUE_0="https://github.com/" \
      flutter pub get
  ```

## 6. Check it

- `flutter analyze` and `flutter test` pass.
- Run the app: the hamburger opens the menu, the app slides right and tilts, a tap on the app closes it.
- Each item navigates and closes the menu; hidden items do not show.
- Logout closes the menu and then logs out.
- The mode switch changes the theme and the menu follows it.
- Android back with the menu open closes the menu and stays on the page.
- The footer shows the version, and "por Dotar Soluciones SAS" opens the website.

## Updating

New versions are published as tags (`v0.2.0`, ...). Read `CHANGELOG.md`, change `ref`, run `flutter pub upgrade dotar_flutter_menu`, and repeat step 6.
