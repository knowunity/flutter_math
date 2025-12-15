// These symbols are migrated from elsewhere in KaTeX, e.g., macro

import '../../ast/syntax_tree.dart';
import 'symbols.dart';

const extraTexMathSymbolCommandConfigs = {
  // Stacked operator
  // '\u2258': TexSymbolConfig('\u2258'),
  '\u2259': TexSymbolConfig('\u2259'),
  '\u225A': TexSymbolConfig('\u225A'),
  '\u225B': TexSymbolConfig('\u225B'),
  '\u225D': TexSymbolConfig('\u225D'),
  '\u225E': TexSymbolConfig('\u225E'),
  '\u225F': TexSymbolConfig('\u225F'),

  // Circled characters
  // '\\copyright': TexSymbolConfig('\u00A9'), // ©

  // Negated relations
  // '\\not': TexSymbolConfig('\u0338'),
  r'\neq': TexSymbolConfig('\u2260'),
  r'\notin': TexSymbolConfig('\u2209'),
  r'\notni': TexSymbolConfig('\u220C'),
  '\u2260': TexSymbolConfig('\u2260'),
  '\u2209': TexSymbolConfig('\u2209'),
  '\u220C': TexSymbolConfig('\u220C'),

  // colon
  r'\colon': TexSymbolConfig(':', type: AtomType.punct), // From MathJax
  // Composite characters
  r'\dblcolon': TexSymbolConfig('\u2237'),
  r'\coloneqq': TexSymbolConfig('\u2254'),
  r'\eqqcolon': TexSymbolConfig('\u2255'),
  r'\eqcolon': TexSymbolConfig('\u2239'),
  r'\llbracket': TexSymbolConfig('\u27e6'),
  r'\rrbracket': TexSymbolConfig('\u27e7'),
  r'\lBrace': TexSymbolConfig('\u2983'),
  r'\rBrace': TexSymbolConfig('\u2984'),

  // // Private KaTeX code point
  // '\\gvertneqq': TexSymbolConfig('\u2269', type: AtomType.rel),
  // '\\lvertneqq': TexSymbolConfig('\u2268', type: AtomType.rel),
  // '\\ngeqq': TexSymbolConfig('\u2271', type: AtomType.rel),
  // '\\ngeqslant': TexSymbolConfig('\u2271', type: AtomType.rel),
  // '\\nleqq': TexSymbolConfig('\u2270', type: AtomType.rel),
  // '\\nleqslant': TexSymbolConfig('\u2270', type: AtomType.rel),
  // '\\nshortmid': TexSymbolConfig('∤', type: AtomType.rel),
  // '\\nshortparallel': TexSymbolConfig('∦', type: AtomType.rel),
  // '\\nsubseteqq': TexSymbolConfig('\u2288', type: AtomType.rel),
  // '\\nsupseteqq': TexSymbolConfig('\u2289', type: AtomType.rel),
  // '\\varsubsetneq': TexSymbolConfig('⊊', type: AtomType.rel),
  // '\\varsubsetneqq': TexSymbolConfig('⫋', type: AtomType.rel),
  // '\\varsupsetneq': TexSymbolConfig('⊋', type: AtomType.rel),
  // '\\varsupsetneqq': TexSymbolConfig('⫌', type: AtomType.rel),
};

const extraTexTextSymbolCommandConfigs = <String, TexSymbolConfig>{
  // '\\textcopyright': TexSymbolConfig('\u00A9'), // ©
  // '\\textregistered': TexSymbolConfig('\u00AE'), // ®
};
