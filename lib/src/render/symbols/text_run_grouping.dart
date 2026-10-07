import '../../ast/nodes/symbol.dart';
import '../../ast/options.dart';
import '../../ast/syntax_tree.dart';
import '../../ast/types.dart';
import '../layout/line.dart';
import 'make_text_run.dart';

/// Replaces each run of text-mode symbols that needs shaping with a single paragraph.
///
/// Only a run whose characters all resolve to the same font and options is merged, and only when it
/// actually contains a script that has to be shaped as a run — so a Latin `\text{...}` keeps the
/// per-character widgets it has always had and renders identically.
List<LineElement> groupTextRuns({
  required List<GreenNode> nodes,
  required List<MathOptions> childOptions,
  required List<LineElement> lineChildren,
}) {
  final runs = _runsIn(
    nodes: nodes,
    childOptions: childOptions,
    lineChildren: lineChildren,
  );
  if (runs.isEmpty) return lineChildren;

  final grouped = <LineElement>[];
  var index = 0;
  while (index < lineChildren.length) {
    final run = runs[index];
    if (run == null) {
      grouped.add(lineChildren[index]);
      index++;
      continue;
    }

    grouped.add(
      LineElement(
        trailingMargin: lineChildren[run.end].trailingMargin,
        child: MakeTextRun(
          text: [
            for (var i = run.start; i <= run.end; i++)
              (nodes[i] as SymbolNode).symbol,
          ].join(),
          font: const FontOptions(),
          options: childOptions[run.start],
        ),
      ),
    );
    index = run.end + 1;
  }

  return grouped;
}

class _Run {
  const _Run(this.start, this.end);

  final int start;
  final int end;
}

List<_Run?> _runsIn({
  required List<GreenNode> nodes,
  required List<MathOptions> childOptions,
  required List<LineElement> lineChildren,
}) {
  final runs = List<_Run?>.filled(nodes.length, null);
  var found = false;
  var index = 0;

  while (index < nodes.length) {
    if (!_isMergeable(nodes[index])) {
      index++;
      continue;
    }

    var end = index;
    while (end + 1 < nodes.length &&
        _isMergeable(nodes[end + 1]) &&
        childOptions[end + 1] == childOptions[index] &&
        lineChildren[end].trailingMargin == 0) {
      end++;
    }

    final trimmed = _trimToShapedAnchors(nodes, index, end);
    if (trimmed != null) {
      found = true;
      for (var i = trimmed.start; i <= trimmed.end; i++) {
        runs[i] = trimmed;
      }
    }
    index = end + 1;
  }

  return found ? runs : const [];
}

bool _isMergeable(GreenNode node) =>
    node is SymbolNode &&
    node.mode == Mode.text &&
    !node.variantForm &&
    node.overrideFont == null;

/// A run is worth merging only between characters that need shaping. Interior neutrals — a space, a
/// digit, a comma — stay inside it, because splitting there would let the line place the two halves
/// left to right and reverse the reading order.
_Run? _trimToShapedAnchors(List<GreenNode> nodes, int start, int end) {
  var first = -1;
  var last = -1;
  for (var i = start; i <= end; i++) {
    final symbol = (nodes[i] as SymbolNode).symbol;
    if (symbol.runes.any(requiresTextShaping)) {
      if (first < 0) first = i;
      last = i;
    }
  }
  if (first < 0 || first == last) return null;

  return _Run(first, last);
}
