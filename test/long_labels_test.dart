import 'dart:io';

import 'package:dotar_flutter_menu/dotar_flutter_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Labels a little longer than the 240 px column holds on one line, measured
/// in the menu's real font on a typical 360 dp phone (DEAM Preventa: "Buscar
/// actualización" overflowed 17 px, "Modo oscuro" 18 px). Its own file: once
/// Plus Jakarta Sans is loaded, every later test would measure it instead of
/// the test font.
void main() {
  setUpAll(() async {
    final loader = FontLoader('packages/dotar_flutter_menu/PlusJakartaSans');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      final bytes = File('fonts/PlusJakartaSans-$weight.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  Future<void> pumpPhone(WidgetTester tester, Widget menu) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DotarMenuScope(
            controller: DotarMenuController()..open(),
            child: menu,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  DotarMenuItem item(String label) => DotarMenuItem(
    icon: Icons.system_update_rounded,
    label: label,
    onTap: () {},
  );

  /// [label] drawn whole: not cut, not ellipsized, inside the 240 px column.
  void expectWhole(WidgetTester tester, String label) {
    final text = find.text(label);
    expect(text, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(text);
    expect(paragraph.didExceedMaxLines, isFalse, reason: label);
    expect(paragraph.overflow, isNot(TextOverflow.ellipsis), reason: label);
    expect(tester.getRect(text).right, lessThanOrEqualTo(240), reason: label);
  }

  testWidgets('"Buscar actualización", "Modo oscuro" and a long logout label '
      'read whole, with no overflow, on a 360 dp phone', (tester) async {
    await pumpPhone(
      tester,
      DotarMenu(
        onLogout: () {},
        logoutLabel: 'Cerrar sesión en este dispositivo ahora',
        items: [item('Buscar actualización')],
        bottomItems: [
          DotarMenuSection(
            title: 'Sistema',
            items: [item('Sincronización de datos')],
          ),
        ],
        modeSwitch: DotarMenuModeSwitch(
          isDark: false,
          onChanged: (_) {},
          label: 'Modo oscuro',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final label in [
      'Buscar actualización',
      'Sincronización de datos',
      'Modo oscuro',
      'Cerrar sesión en este dispositivo ahora',
    ]) {
      expectWhole(tester, label);
    }
  });

  testWidgets('a label that fits stays on one line, where it was', (
    tester,
  ) async {
    await pumpPhone(tester, DotarMenu(items: [item('Inicio')]));

    final rect = tester.getRect(find.text('Inicio'));
    // 12 px of the item's inset, 12 of its padding, the 28 px icon and the
    // 16 px gap; one line of the 16 px label.
    expect(rect.left, 68);
    expect(rect.height, lessThan(2 * 16));
  });
}
