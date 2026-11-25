import 'package:dotar_flutter_menu/dotar_flutter_menu.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// The app owns the mode; the menu's switch changes it.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF06D42);
    return MaterialApp(
      title: 'Dotar menu',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _mode,
      home: HomePage(
        isDark: _mode == ThemeMode.dark,
        onModeChanged: (dark) =>
            setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.isDark,
    required this.onModeChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onModeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _menu = DotarMenuController();
  var _page = 'Inicio';

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  void _show(String page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    // Back closes the open menu instead of leaving the app.
    return ListenableBuilder(
      listenable: _menu,
      builder: (context, child) => PopScope(
        canPop: !_menu.isOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _menu.close();
        },
        child: child!,
      ),
      child: DotarMenuShell(
        controller: _menu,
        menu: DotarMenu(
          user: const DotarMenuUser(
            name: 'Juan Pérez',
            subtitle: 'Usuario / Administrador',
          ),
          onLogout: () => _show('Sesión cerrada'),
          // The current page's item is selected; loose items and sections mix.
          items: [
            DotarMenuItem(
              icon: Icons.dashboard_rounded,
              label: 'Inicio',
              onTap: () => _show('Inicio'),
              selected: _page == 'Inicio',
            ),
            DotarMenuSection(
              title: 'Operación',
              items: [
                DotarMenuItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Estadísticas',
                  onTap: () => _show('Estadísticas'),
                  selected: _page == 'Estadísticas',
                ),
                DotarMenuItem(
                  icon: Icons.sync_rounded,
                  label: 'Sincronizar',
                  onTap: () => _show('Sincronizar'),
                  selected: _page == 'Sincronizar',
                ),
              ],
            ),
          ],
          bottomItems: [
            DotarMenuItem(
              icon: Icons.dns_rounded,
              label: 'Servidor',
              onTap: () => _show('Servidor'),
            ),
          ],
          modeSwitch: DotarMenuModeSwitch(
            isDark: widget.isDark,
            onChanged: widget.onModeChanged,
          ),
          version: '0.1.0',
        ),
        child: Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => DotarMenuController.of(context).toggle(),
              ),
            ),
            title: Text(_page),
          ),
          body: Center(child: Text(_page)),
        ),
      ),
    );
  }
}
