import 'dart:convert';

import 'package:dotar_flutter_menu/dotar_flutter_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plus Jakarta Sans ships inside the package, so the menu looks the same in
/// any app and offline: its texts name the package's family, and each weight
/// they draw is a font file the package bundles.
void main() {
  testWidgets('every text of the menu is in the package\'s Plus Jakarta Sans', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.5)),
          child: child!,
        ),
        home: Scaffold(
          body: DotarMenu(
            user: const DotarMenuUser(name: 'Juan Pérez', subtitle: 'Mozo'),
            onLogout: () {},
            items: [
              DotarMenuItem(icon: Icons.circle, label: 'Inicio', onTap: () {}),
            ],
            bottomItems: [
              DotarMenuItem(icon: Icons.circle, label: 'Ayuda', onTap: () {}),
            ],
            modeSwitch: DotarMenuModeSwitch(isDark: false, onChanged: (_) {}),
            version: '1.0.0',
          ),
        ),
      ),
    );

    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    expect(texts, hasLength(9));
    for (final text in texts) {
      expect(
        text.style?.fontFamily,
        'packages/dotar_flutter_menu/PlusJakartaSans',
        reason: '"${text.data}"',
      );
    }
  });

  test('the weights the menu draws are bundled font files that load', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final family =
        manifest.cast<Map<String, dynamic>>().singleWhere(
              (f) => (f['family'] as String).endsWith('PlusJakartaSans'),
            )['fonts']
            as List;
    final weights = {
      for (final font in family.cast<Map<String, dynamic>>())
        font['weight'] as int? ?? 400: font['asset'] as String,
    };
    expect(weights.keys, unorderedEquals([400, 500, 600, 700, 800]));

    final loader = FontLoader('PlusJakartaSansCheck');
    for (final asset in weights.values) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  });
}
