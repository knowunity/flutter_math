import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'load_fonts.dart';

void main() {
  setUpAll(loadKaTeXFonts);

  Future<void> pumpTex(WidgetTester tester, String tex) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Math.tex(tex)),
        ),
      ),
    );
  }

  List<RichText> paragraphsOf(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(of: find.byType(Math), matching: find.byType(RichText)),
      )
      .toList();

  group('text-mode runs', () {
    testWidgets('shapes an Arabic run as one paragraph', (tester) async {
      await pumpTex(tester, r'\text{مرحبا بالعالم}');

      final paragraphs = paragraphsOf(tester);

      expect(
        paragraphs,
        hasLength(1),
        reason: 'Arabic letters only join when one paragraph shapes them.',
      );
      expect(paragraphs.single.text.toPlainText(), contains('مرحبا'));
      expect(paragraphs.single.text.toPlainText(), contains('بالعالم'));
      expect(paragraphs.single.textDirection, TextDirection.rtl);
    });

    testWidgets('leaves a Latin run as one paragraph per character', (
      tester,
    ) async {
      await pumpTex(tester, r'\text{Hello}');

      expect(
        paragraphsOf(tester),
        hasLength(5),
        reason: 'Latin needs no shaping, so it must render as before.',
      );
    });

    testWidgets('keeps a digit and a comma inside an Arabic run', (
      tester,
    ) async {
      await pumpTex(tester, r'\text{مرحبا، 5 عربي}');

      final paragraphs = paragraphsOf(tester);

      expect(
        paragraphs,
        hasLength(1),
        reason: 'Splitting at the digit would reverse the two Arabic halves.',
      );
      expect(paragraphs.single.text.toPlainText(), contains('5'));
    });

    testWidgets('merges only the Arabic part of a mixed run', (tester) async {
      await pumpTex(tester, r'\text{a عربي b}');

      final paragraphs = paragraphsOf(tester);
      final arabicRuns = paragraphs.where(
        (p) => p.text.toPlainText().contains('عربي'),
      );

      expect(arabicRuns, hasLength(1));
      expect(arabicRuns.single.textDirection, TextDirection.rtl);
      expect(
        paragraphs.length,
        greaterThan(1),
        reason: 'The surrounding Latin letters stay their own paragraphs.',
      );
    });

    testWidgets('leaves an equation with no text mode untouched', (
      tester,
    ) async {
      await pumpTex(tester, r'a + b = c');

      expect(paragraphsOf(tester), hasLength(5));
    });
  });
}
