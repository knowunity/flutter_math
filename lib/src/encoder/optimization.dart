import '../ast/syntax_tree.dart';

import 'matcher.dart';

class OptimizationEntry {
  const OptimizationEntry({
    required this.matcher,
    required this.optimize,
    int? priority,
  }) : _priority = priority;
  final Matcher matcher;
  final void Function(GreenNode node) optimize;

  final int? _priority;
  int get priority => _priority ?? matcher.specificity;
}
