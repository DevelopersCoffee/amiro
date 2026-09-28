import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/theme/amiro_card.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAmiroTheme(loadFonts: false),
  home: Scaffold(body: child),
);

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(find.byType(Container).first);
  return container.decoration as BoxDecoration;
}

void main() {
  testWidgets(
    'uses the surface fill, radius 16 and a real offset shadow, never a glow',
    (tester) async {
      await tester.pumpWidget(_host(const AmiroCard(child: Text('x'))));

      final decoration = _decorationOf(tester);
      expect(decoration.color, AmiroColors.surface);
      expect((decoration.borderRadius as BorderRadius?)!.topLeft.x, 16);
      final shadow = decoration.boxShadow!.single;
      expect(
        shadow.offset,
        isNot(Offset.zero),
      ); // an offset shadow, not a centred glow
      expect(
        shadow.spreadRadius,
        lessThan(0),
      ); // matches DESIGN.md's authored shadow
    },
  );

  testWidgets('the neutral hairline border by default', (tester) async {
    await tester.pumpWidget(_host(const AmiroCard(child: Text('x'))));

    final border = _decorationOf(tester).border! as Border;
    expect(border.top.color, AmiroColors.surfaceBorder);
    expect(border.top.width, 1);
  });

  testWidgets(
    'an explicit border overrides the default, e.g. the collector\'s frame',
    (tester) async {
      final frame = Border.all(color: AmiroColors.primary, width: 2);

      await tester.pumpWidget(
        _host(AmiroCard(border: frame, child: const Text('x'))),
      );

      expect(_decorationOf(tester).border, frame);
    },
  );

  testWidgets('padding defaults to 20 and can be overridden', (tester) async {
    Padding paddingIn() => tester.widget<Padding>(
      find.ancestor(of: find.text('x'), matching: find.byType(Padding)).first,
    );

    await tester.pumpWidget(_host(const AmiroCard(child: Text('x'))));
    expect(paddingIn().padding, const EdgeInsets.all(20));

    await tester.pumpWidget(
      _host(const AmiroCard(padding: EdgeInsets.all(8), child: Text('x'))),
    );
    expect(paddingIn().padding, const EdgeInsets.all(8));
  });

  testWidgets(
    'onTap makes it an InkWell so it gets a press state; omitting it stays static',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(AmiroCard(onTap: () => tapped = true, child: const Text('x'))),
      );
      await tester.tap(find.byType(AmiroCard));
      expect(tapped, isTrue);

      await tester.pumpWidget(_host(const AmiroCard(child: Text('x'))));
      expect(find.byType(InkWell), findsNothing);
    },
  );
}
