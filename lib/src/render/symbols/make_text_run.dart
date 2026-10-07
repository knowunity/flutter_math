import 'package:flutter/widgets.dart';

import '../../ast/options.dart';
import '../../ast/size.dart';

/// Renders a run of text-mode symbols as one paragraph.
///
/// The symbol renderer draws one character per paragraph, which is fine for Latin but wrong for a
/// script whose letters join to their neighbours or run right to left: the letters neither join nor
/// reorder, because each one is shaped on its own and the line places them left to right. Giving the
/// whole run to a single paragraph lets the text engine shape and order it.
class MakeTextRun extends StatelessWidget {
  const MakeTextRun({
    required this.text,
    required this.font,
    required this.options,
    super.key,
  });

  final String text;
  final FontOptions font;
  final MathOptions options;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'packages/flutter_math_fork/KaTeX_${font.fontFamily}',
          fontWeight: font.fontWeight,
          fontStyle: font.fontShape,
          fontSize: 1.0.cssEm.toLpUnder(options),
          color: options.color,
        ),
      ),
      textDirection: estimateRunDirection(text),
      softWrap: false,
      overflow: TextOverflow.visible,
    );
  }
}

/// The scripts whose letters have to be shaped as a run rather than character by character.
bool requiresTextShaping(int codePoint) =>
    (codePoint >= 0x0590 && codePoint <= 0x08FF) ||
    (codePoint >= 0xFB1D && codePoint <= 0xFDFF) ||
    (codePoint >= 0xFE70 && codePoint <= 0xFEFF) ||
    (codePoint >= 0x0900 && codePoint <= 0x0DFF);

/// True for the code points that may sit inside a run without ending it: joiners, bidi marks and
/// the combining marks that attach to the letter before them.
bool isRunFiller(int codePoint) =>
    (codePoint >= 0x200C && codePoint <= 0x200F) ||
    (codePoint >= 0x202A && codePoint <= 0x202E) ||
    (codePoint >= 0x2066 && codePoint <= 0x2069) ||
    (codePoint >= 0x0610 && codePoint <= 0x061A) ||
    (codePoint >= 0x064B && codePoint <= 0x065F) ||
    codePoint == 0x0670 ||
    (codePoint >= 0x06D6 && codePoint <= 0x06ED);

/// The first strong character decides the run's direction, as the Unicode algorithm does for a
/// paragraph. Forcing left-to-right would misplace a trailing bracket or question mark.
TextDirection estimateRunDirection(String text) {
  for (final codePoint in text.runes) {
    if (_isStrongRtl(codePoint)) return TextDirection.rtl;
    if (_isStrongLtr(codePoint)) return TextDirection.ltr;
  }

  return TextDirection.ltr;
}

bool _isStrongRtl(int codePoint) =>
    (codePoint >= 0x0590 && codePoint <= 0x05FF) ||
    (codePoint >= 0x0600 && codePoint <= 0x07BF) ||
    (codePoint >= 0x08A0 && codePoint <= 0x08FF) ||
    (codePoint >= 0xFB1D && codePoint <= 0xFDFF) ||
    (codePoint >= 0xFE70 && codePoint <= 0xFEFF);

bool _isStrongLtr(int codePoint) =>
    (codePoint >= 0x0041 && codePoint <= 0x005A) ||
    (codePoint >= 0x0061 && codePoint <= 0x007A) ||
    (codePoint >= 0x00C0 && codePoint <= 0x02B8) ||
    (codePoint >= 0x0900 && codePoint <= 0x0DFF);
