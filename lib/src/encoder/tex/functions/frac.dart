part of '../functions.dart';

EncodeResult _fracEncoder(GreenNode node) {
  final fracNode = node as FracNode;
  if (fracNode.barSize == null) {
    if (fracNode.continued) {
      return TexCommandEncodeResult(
        command: r'\cfrac',
        args: fracNode.children,
      );
    } else {
      return TexCommandEncodeResult(command: r'\frac', args: fracNode.children);
    }
  } else {
    return TexCommandEncodeResult(
      command: r'\genfrac',
      args: <dynamic>[null, null, fracNode.barSize, null, ...fracNode.children],
    );
  }
}

final _fracOptimizationEntries = [
  // \dfrac \tfrac
  OptimizationEntry(
    matcher: isA<StyleNode>(
      matchSelf: (node) {
        final style = node.optionsDiff.style;
        return style == MathStyle.display || style == MathStyle.text;
      },
      child: isA<FracNode>(
        matchSelf: (node) => node.barSize == null,
        selfSpecificity: 110,
      ),
    ),
    optimize: (node) {
      final style = (node as StyleNode).optionsDiff.style;
      final continued = (node.children.first as FracNode).continued;
      if (style == MathStyle.text && continued) return;

      final res = TexCommandEncodeResult(
        // ignore: avoid-nested-conditional-expressions
        command: style == MathStyle.display
            ? (continued ? r'\cfrac' : r'\dfrac')
            : r'\tfrac',
        args: node.children.first.children,
      );
      final remainingOptions = node.optionsDiff.removeStyle();
      texEncodingCache[node] = remainingOptions.isEmpty
          ? res
          : _optionsDiffEncode(remainingOptions, <dynamic>[res]);
    },
  ),

  // \binom
  OptimizationEntry(
    matcher: isA<LeftRightNode>(
      matchSelf: (node) => node.leftDelim == '(' && node.rightDelim == ')',
      child: isA<EquationRowNode>(
        child: isA<FracNode>(
          matchSelf: (node) => !node.continued && node.barSize?.value == 0,
        ),
      ),
    ),
    optimize: (node) {
      texEncodingCache[node] = TexCommandEncodeResult(
        command: r'\binom',
        args: node.children.first!.children.first!.children,
      );
    },
  ),

  // \tbinom \dbinom

  // \genfrac
  OptimizationEntry(
    matcher: isA<StyleNode>(
      matchSelf: (node) => node.optionsDiff.style != null,
      child: isA<LeftRightNode>(
        child: isA<EquationRowNode>(
          child: isA<FracNode>(matchSelf: (node) => !node.continued),
        ),
      ),
    ),
    optimize: (node) {
      final leftRight = node.children.first! as LeftRightNode;
      final frac = leftRight.children.first.children.first as FracNode;
      final res = TexCommandEncodeResult(
        command: r'\genfrac',
        args: <dynamic>[
          // TODO
          if (leftRight.leftDelim == null)
            null
          else
            SymbolNode(symbol: leftRight.leftDelim!),
          if (leftRight.rightDelim == null)
            null
          else
            SymbolNode(symbol: leftRight.rightDelim!),
          frac.barSize,
          (node as StyleNode).optionsDiff.style?.size,
          ...frac.children,
        ],
      );
      final remainingOptions = node.optionsDiff.removeStyle();
      texEncodingCache[node] = remainingOptions.isEmpty
          ? res
          : _optionsDiffEncode(remainingOptions, <dynamic>[res]);
    },
  ),
  OptimizationEntry(
    matcher: isA<StyleNode>(
      matchSelf: (node) => node.optionsDiff.style != null,
      child: isA<FracNode>(matchSelf: (node) => !node.continued),
    ),
    optimize: (node) {
      final frac = node.children.first! as FracNode;
      final res = TexCommandEncodeResult(
        command: r'\genfrac',
        args: <dynamic>[
          null,
          null,
          frac.barSize,
          (node as StyleNode).optionsDiff.style?.size,
          ...frac.children,
        ],
      );
      final remainingOptions = node.optionsDiff.removeStyle();
      texEncodingCache[node] = remainingOptions.isEmpty
          ? res
          : _optionsDiffEncode(remainingOptions, <dynamic>[res]);
    },
  ),
];
