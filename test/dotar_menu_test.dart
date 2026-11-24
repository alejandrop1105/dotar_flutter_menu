import 'package:dotar_flutter_menu/dotar_flutter_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// The menu's content as DEAM-Resto's `AnimatedDrawerContent` draws it, and
/// the rules its drawer tests pin (drawer_mode_test, drawer_navigation_test,
/// drawer_user_test, app_settings_widgets_test), with what was app-specific
/// there passed in here.
void main() {
  late DotarMenuController controller;

  setUp(() => controller = DotarMenuController()..open());

  Future<void> pumpMenu(
    WidgetTester tester,
    Widget menu, {
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        // The test font draws every glyph 1em wide; halved text measures
        // what the menu's 240 px column holds, not that font.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.5)),
          child: child!,
        ),
        home: Scaffold(
          body: DotarMenuScope(controller: controller, child: menu),
        ),
      ),
    );
    await tester.pump();
  }

  DotarMenuItem item(
    String label, {
    bool visible = true,
    VoidCallback? onTap,
  }) => DotarMenuItem(
    icon: Icons.circle,
    label: label,
    onTap: onTap ?? () {},
    visible: visible,
  );

  group('items', () {
    testWidgets('an item runs its action and then closes the menu', (
      tester,
    ) async {
      final openWhenRun = <bool>[];
      await pumpMenu(
        tester,
        DotarMenu(
          items: [
            item('Dashboard', onTap: () => openWhenRun.add(controller.isOpen)),
          ],
        ),
      );

      await tester.tap(find.text('Dashboard'));
      await tester.pump();

      expect(openWhenRun, [true]);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('an item hidden is not in the menu, and hides no other', (
      tester,
    ) async {
      await pumpMenu(
        tester,
        DotarMenu(
          items: [item('Estadísticas', visible: false), item('Sincronizar')],
          bottomItems: [item('Servidor'), item('Logs', visible: false)],
        ),
      );

      expect(find.text('Estadísticas'), findsNothing);
      expect(find.text('Sincronizar'), findsOneWidget);
      expect(find.text('Servidor'), findsOneWidget);
      expect(find.text('Logs'), findsNothing);
    });
  });

  group('logout', () {
    testWidgets('"Cerrar Sesión" closes the menu and calls onLogout', (
      tester,
    ) async {
      var loggedOut = 0;
      await pumpMenu(tester, DotarMenu(onLogout: () => loggedOut++));

      await tester.tap(find.text('Cerrar Sesión'));
      await tester.pump();

      expect(loggedOut, 1);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('without onLogout there is no "Cerrar Sesión"', (tester) async {
      await pumpMenu(tester, const DotarMenu());

      expect(find.text('Cerrar Sesión'), findsNothing);
    });
  });

  group('mode switch', () {
    testWidgets('it says "Modo" and reports the mode chosen', (tester) async {
      final reported = <bool>[];
      var isDark = false;
      await pumpMenu(
        tester,
        StatefulBuilder(
          builder: (context, setState) => DotarMenu(
            modeSwitch: DotarMenuModeSwitch(
              isDark: isDark,
              onChanged: (value) {
                reported.add(value);
                setState(() => isDark = value);
              },
            ),
          ),
        ),
      );

      expect(find.text('Modo'), findsOneWidget);
      expect(find.text('Tema'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 400));
      expect(reported, [true]);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 400));
      expect(reported, [true, false]);
      // The switch changes the mode, not the menu: it stays open.
      expect(controller.isOpen, isTrue);
    });

    testWidgets('without a mode switch there is no "Modo"', (tester) async {
      await pumpMenu(tester, const DotarMenu());

      expect(find.text('Modo'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });
  });

  group('footer', () {
    testWidgets('the version under "por Dotar Soluciones SAS", both centred at '
        'the bottom, below every item', (tester) async {
      await pumpMenu(
        tester,
        DotarMenu(
          items: [item('Dashboard'), item('Sincronizar')],
          bottomItems: [item('Servidor'), item('Logs')],
          version: '1.3.0',
        ),
      );

      final dotar = tester.getRect(find.text('por Dotar Soluciones SAS'));
      final version = tester.getRect(find.text('v1.3.0'));
      expect(version.top, greaterThanOrEqualTo(dotar.bottom));
      expect(version.center.dx, moreOrLessEquals(dotar.center.dx, epsilon: 1));
      // Centred in the menu's 240 px column.
      expect(dotar.center.dx, moreOrLessEquals(120, epsilon: 1));
      for (final label in ['Dashboard', 'Sincronizar', 'Servidor', 'Logs']) {
        expect(
          dotar.top,
          greaterThan(tester.getRect(find.text(label)).bottom),
          reason: 'the footer is below $label',
        );
      }
      expect(2400 - version.bottom, lessThan(80), reason: 'at the bottom');
    });

    testWidgets('no version shown while it is null', (tester) async {
      await pumpMenu(tester, const DotarMenu());

      expect(find.text('por Dotar Soluciones SAS'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^v\d')), findsNothing);
    });

    group('the signature', () {
      late UrlLauncherPlatform original;
      late _FakeLauncher launcher;

      setUp(() {
        original = UrlLauncherPlatform.instance;
        launcher = _FakeLauncher();
        UrlLauncherPlatform.instance = launcher;
      });

      tearDown(() => UrlLauncherPlatform.instance = original);

      testWidgets('opens http://dotarsoluciones.com.ar outside the app', (
        tester,
      ) async {
        await pumpMenu(tester, const DotarMenu());

        await tester.tap(find.text('por Dotar Soluciones SAS'));
        await tester.pump();

        expect(launcher.launched, [
          (
            'http://dotarsoluciones.com.ar',
            PreferredLaunchMode.externalApplication,
          ),
        ]);
      });
    });
  });

  group('user', () {
    const longName = 'Maximiliano Alejandro Fernández de la Cruz';

    testWidgets('a long name shows whole, not cut (DEAM-Resto #233)', (
      tester,
    ) async {
      await pumpMenu(
        tester,
        const DotarMenu(user: DotarMenuUser(name: longName)),
      );

      final name = find.text(longName);
      expect(name, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(name);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('without an avatar, the initials of the first and the last '
        'word of the name, and the subtitle', (tester) async {
      await pumpMenu(
        tester,
        const DotarMenu(
          user: DotarMenuUser(
            name: 'maximiliano alejandro fernández',
            subtitle: 'Usuario / Administrador',
          ),
        ),
      );

      expect(find.text('MF'), findsOneWidget);
      expect(find.text('Usuario / Administrador'), findsOneWidget);
    });
  });

  group('header', () {
    Finder avatar() => find
        .ancestor(of: find.text('JP'), matching: find.byType(Container))
        .first;

    testWidgets('the header shows above the user, 72 px tall', (tester) async {
      await pumpMenu(
        tester,
        const DotarMenu(
          header: SizedBox(key: Key('brand'), width: 120, height: 72),
          user: DotarMenuUser(name: 'Juan Pérez'),
        ),
      );

      expect(find.byKey(const Key('brand')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('brand'))).height, 72);
      // Centred in the 240 px column, 16 px above and below.
      expect(
        tester.getCenter(find.byKey(const Key('brand'))).dx,
        moreOrLessEquals(120, epsilon: 1),
      );
      expect(tester.getTopLeft(avatar()).dy, 16 + 72 + 16);
    });

    testWidgets('without a header the user keeps its 50 px gap', (
      tester,
    ) async {
      await pumpMenu(
        tester,
        const DotarMenu(user: DotarMenuUser(name: 'Juan Pérez')),
      );

      expect(tester.getTopLeft(avatar()).dy, 50);
    });
  });

  group('brand colors', () {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    );

    List<Color> orbColors(WidgetTester tester) => [
      for (final box in tester.widgetList<Container>(find.byType(Container)))
        if (box.decoration case BoxDecoration(
          gradient: RadialGradient(:final colors),
        ))
          colors.first,
    ];

    Color avatarBorder(WidgetTester tester) {
      final circle = tester.widget<Container>(
        find
            .ancestor(of: find.text('JP'), matching: find.byType(Container))
            .first,
      );
      return (circle.decoration! as BoxDecoration).border!.top.color;
    }

    testWidgets('by default the theme\'s primary color, and it lightened 20% '
        'toward white', (tester) async {
      await pumpMenu(
        tester,
        const DotarMenu(user: DotarMenuUser(name: 'Juan Pérez')),
        theme: theme,
      );

      final brand = theme.colorScheme.primary;
      final brandLight = Color.lerp(brand, Colors.white, 0.2)!;
      expect(avatarBorder(tester), brand);
      expect(orbColors(tester), [
        brand.withValues(alpha: 0.6),
        const Color(0xFF6C3BDB).withValues(alpha: 0.45),
        brandLight.withValues(alpha: 0.4),
      ]);
    });

    testWidgets('colors given override the theme\'s', (tester) async {
      await pumpMenu(
        tester,
        const DotarMenu(
          user: DotarMenuUser(name: 'Juan Pérez'),
          brandColor: Color(0xFFF06D42),
          brandLightColor: Color(0xFFFF6B35),
        ),
        theme: theme,
      );

      expect(avatarBorder(tester), const Color(0xFFF06D42));
      expect(orbColors(tester), [
        const Color(0xFFF06D42).withValues(alpha: 0.6),
        const Color(0xFF6C3BDB).withValues(alpha: 0.45),
        const Color(0xFFFF6B35).withValues(alpha: 0.4),
      ]);
    });
  });
}

/// The launcher the signature reaches, recording instead of opening.
class _FakeLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final launched = <(String, PreferredLaunchMode)>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add((url, options.mode));
    return true;
  }
}
