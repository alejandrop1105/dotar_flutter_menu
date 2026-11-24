import 'package:dotar_flutter_menu/dotar_flutter_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell's motion as DEAM-Resto's `HomeShell` draws it, and the rules
/// its drawer tests pin: a tap on the app closes the menu, the app takes no
/// input while the menu is open, and a second close does not reopen it
/// (DEAM-Resto #211).
void main() {
  late DotarMenuController controller;
  late int pressed;

  setUp(() {
    controller = DotarMenuController();
    pressed = 0;
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // The test font draws every glyph 1em wide; halved text measures
        // what the menu's 240 px column holds, not that font.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.5)),
          child: child!,
        ),
        home: DotarMenuShell(
          controller: controller,
          menu: const DotarMenu(),
          // The whole app is one button, so it can be pressed wherever it
          // still shows when the menu pushes it aside.
          child: Scaffold(
            body: InkWell(
              onTap: () => pressed++,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('app'),
                    Builder(
                      builder: (context) => TextButton(
                        onPressed: () =>
                            DotarMenuController.of(context).toggle(),
                        child: const Text('menu'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The menu animates without end, so pumpAndSettle never settles; past the
  /// 300 ms of the shell is enough.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// On the right of the 400 px screen, where the open app still shows: it
  /// starts about 275 px from the left at that height.
  const onTheOpenApp = Offset(370, 400);

  Finder appTransform() =>
      find.ancestor(of: find.text('app'), matching: find.byType(Transform));

  /// DEAM-Resto's transform of the app at [value] of the animation.
  Matrix4 shifted(double value) => Matrix4.identity()
    ..setEntry(3, 2, 0.001)
    ..translateByDouble(250.0 * value, -30.0 * value, 0.0, 1.0)
    ..scaleByDouble(
      1.0 - value * 0.15,
      1.0 - value * 0.15,
      1.0 - value * 0.15,
      1.0,
    )
    ..rotateZ(value * 0.1745);

  testWidgets('opening slides, shrinks and tilts the app aside in 300 ms '
      'easeInOut, and closing returns it untouched', (tester) async {
    await pumpShell(tester);
    expect(appTransform(), findsNothing);
    expect(find.byType(DotarMenu), findsNothing);

    controller.open();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(
      tester.widget<Transform>(appTransform().first).transform,
      matrixMoreOrLessEquals(shifted(Curves.easeInOut.transform(0.25))),
    );

    await tester.pump(const Duration(milliseconds: 225));
    expect(controller.isOpen, isTrue);
    expect(find.byType(DotarMenu), findsOneWidget);
    final transform = tester.widget<Transform>(appTransform().first);
    expect(transform.transform, matrixMoreOrLessEquals(shifted(1)));
    expect(transform.alignment, const Alignment(-1.0, 0.4));
    final frame = tester.widget<Container>(
      find
          .descendant(
            of: appTransform().first,
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      frame.decoration,
      BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF1E1E2C), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
    );

    controller.close();
    await settle(tester);
    expect(appTransform(), findsNothing);
    expect(
      tester.getCenter(find.text('app')).dx,
      moreOrLessEquals(200, epsilon: 1),
    );
    // Closed, the menu leaves the tree, and its endless animation with it.
    expect(find.byType(DotarMenu), findsNothing);
  });

  testWidgets('a tap on the app closes the menu', (tester) async {
    await pumpShell(tester);
    controller.open();
    await settle(tester);
    expect(appTransform(), findsOneWidget);

    await tester.tapAt(onTheOpenApp);
    await settle(tester);

    expect(controller.isOpen, isFalse);
    expect(appTransform(), findsNothing);
  });

  testWidgets('the app takes no input while the menu is open', (tester) async {
    await pumpShell(tester);
    controller.open();
    await settle(tester);

    await tester.tapAt(onTheOpenApp);
    await settle(tester);
    expect(pressed, 0);

    // Closed by that tap, it takes the next one.
    await tester.tapAt(onTheOpenApp);
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('a second close keeps the menu closed (DEAM-Resto #211)', (
    tester,
  ) async {
    await pumpShell(tester);
    controller.open();
    await settle(tester);
    var notified = 0;
    controller.addListener(() => notified++);

    controller.close();
    controller.close();
    await settle(tester);

    expect(controller.isOpen, isFalse);
    expect(notified, 1);
    expect(appTransform(), findsNothing);
  });

  testWidgets('the app reaches the controller through the scope: its button '
      'toggles the menu open and closed', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('menu'));
    await settle(tester);
    expect(controller.isOpen, isTrue);
    expect(appTransform(), findsOneWidget);

    controller.toggle();
    await settle(tester);
    expect(controller.isOpen, isFalse);
    expect(appTransform(), findsNothing);
  });
}
