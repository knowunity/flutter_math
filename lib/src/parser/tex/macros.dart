// The MIT License (MIT)
//
// Copyright (c) 2013-2019 Khan Academy and other contributors
// Copyright (c) 2020 znjameswu <znjameswu@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//ignore_for_file: prefer_single_quotes
//ignore_for_file: lines_longer_than_80_chars

import '../../ast/syntax_tree.dart';
import '../../ast/types.dart';
import '../../font/metrics/font_metrics_data.dart';
import '../../utils/log.dart';

import 'functions.dart';
import 'macro_expander.dart';
import 'parse_error.dart';
import 'symbols.dart';
import 'token.dart';

class MacroDefinition {
  const MacroDefinition(this.expand, {this.unexpandable = false});

  MacroDefinition.fromString(String output)
    : this((context) => MacroExpansion.fromString(output, context));
  MacroDefinition.fromCtxString(String Function(MacroContext) expand)
    : this((context) => MacroExpansion.fromString(expand(context), context));
  MacroDefinition.fromMacroExpansion(MacroExpansion output)
    : this((_) => output, unexpandable: output.unexpandable);
  final MacroExpansion Function(MacroContext context) expand;
  final bool unexpandable;

  bool get expandable => !unexpandable;
}

class MacroExpansion {
  const MacroExpansion({
    required this.tokens,
    required this.numArgs,
    this.unexpandable = false,
  });

  factory MacroExpansion.fromString(String expansion, MacroContext context) {
    var numArgs = 0;
    if (expansion.contains('#')) {
      final stripped = expansion.replaceAll(_strippedRegex, '');
      while (stripped.contains('#${numArgs + 1}')) {
        numArgs += 1;
      }
    }
    final bodyLexer = context.getNewLexer(expansion);
    final tokens = <Token>[];
    var tok = bodyLexer.lex();
    while (tok.text != 'EOF') {
      tokens.add(tok);
      tok = bodyLexer.lex();
    }
    return MacroExpansion(tokens: tokens.reversed.toList(), numArgs: numArgs);
  }

  final List<Token> tokens;
  final int numArgs;

  final bool unexpandable;

  static final _strippedRegex = RegExp('##', multiLine: true);
}

void defineMacro(String name, MacroDefinition body) {
  builtinMacros[name] = body;
}

const digitToNumber = {
  "0": 0,
  "1": 1,
  "2": 2,
  "3": 3,
  "4": 4,
  "5": 5,
  "6": 6,
  "7": 7,
  "8": 8,
  "9": 9,
  "a": 10,
  "A": 10,
  "b": 11,
  "B": 11,
  "c": 12,
  "C": 12,
  "d": 13,
  "D": 13,
  "e": 14,
  "E": 14,
  "f": 15,
  "F": 15,
};

String newcommand(MacroContext context, bool existsOK, bool nonexistsOK) {
  var arg = context.consumeArgs(1)[0];
  if (arg.length != 1) {
    throw ParseException(r"\newcommand's first argument must be a macro name");
  }
  final name = arg[0].text;

  final exists = context.isDefined(name);
  if (exists && !existsOK) {
    throw ParseException(
      '\\newcommand{$name} attempting to redefine '
      '$name; use \\renewcommand',
    );
  }
  if (!exists && !nonexistsOK) {
    throw ParseException(
      '\\renewcommand{$name} when command $name '
      r'does not yet exist; use \newcommand',
    );
  }

  var numArgs = 0;
  arg = context.consumeArgs(1)[0];
  if (arg.length == 1 && arg[0].text == "[") {
    var argText = '';
    var token = context.expandNextToken();
    while (token.text != "]" && token.text != "EOF") {
      // TODO: Should properly expand arg, e.g., ignore {}s
      argText += token.text;
      token = context.expandNextToken();
    }
    if (!RegExp(r'^\s*[0-9]+\s*$').hasMatch(argText)) {
      throw ParseException('Invalid number of arguments: $argText');
    }
    numArgs = int.parse(argText);
    arg = context.consumeArgs(1)[0];
  }

  // Final arg is the expansion of the macro
  context.macros.set(
    name,
    MacroDefinition.fromMacroExpansion(
      MacroExpansion(tokens: arg, numArgs: numArgs),
    ),
  );
  return '';
}

final latexRaiseA =
    '${fontMetricsData['Main-Regular']!["T".codeUnitAt(0)]!.height - 0.7 * fontMetricsData['Main-Regular']!["A".codeUnitAt(0)]!.height}em';

const dotsByToken = {
  ',': r'\dotsc',
  r'\not': r'\dotsb',
  // \keybin@ checks for the following:
  '+': r'\dotsb',
  '=': r'\dotsb',
  '<': r'\dotsb',
  '>': r'\dotsb',
  '-': r'\dotsb',
  '*': r'\dotsb',
  ':': r'\dotsb',
  // Symbols whose definition starts with \DOTSB:
  r'\DOTSB': r'\dotsb',
  r'\coprod': r'\dotsb',
  r'\bigvee': r'\dotsb',
  r'\bigwedge': r'\dotsb',
  r'\biguplus': r'\dotsb',
  r'\bigcap': r'\dotsb',
  r'\bigcup': r'\dotsb',
  r'\prod': r'\dotsb',
  r'\sum': r'\dotsb',
  r'\bigotimes': r'\dotsb',
  r'\bigoplus': r'\dotsb',
  r'\bigodot': r'\dotsb',
  r'\bigsqcup': r'\dotsb',
  r'\And': r'\dotsb',
  r'\longrightarrow': r'\dotsb',
  r'\Longrightarrow': r'\dotsb',
  r'\longleftarrow': r'\dotsb',
  r'\Longleftarrow': r'\dotsb',
  r'\longleftrightarrow': r'\dotsb',
  r'\Longleftrightarrow': r'\dotsb',
  r'\mapsto': r'\dotsb',
  r'\longmapsto': r'\dotsb',
  r'\hookrightarrow': r'\dotsb',
  r'\doteq': r'\dotsb',
  // Symbols whose definition starts with \mathbin:
  r'\mathbin': r'\dotsb',
  // Symbols whose definition starts with \mathrel:
  r'\mathrel': r'\dotsb',
  r'\relbar': r'\dotsb',
  r'\Relbar': r'\dotsb',
  r'\xrightarrow': r'\dotsb',
  r'\xleftarrow': r'\dotsb',
  // Symbols whose definition starts with \DOTSI:
  r'\DOTSI': r'\dotsi',
  r'\int': r'\dotsi',
  r'\oint': r'\dotsi',
  r'\iint': r'\dotsi',
  r'\iiint': r'\dotsi',
  r'\iiiint': r'\dotsi',
  r'\idotsint': r'\dotsi',
  // Symbols whose definition starts with \DOTSX:
  r'\DOTSX': r'\dotsx',
};

//////////////////////////////////////////////////////////////////////
// macro tools

/// Transformed by:
/// /defineMacro\((['"][^'"]*['"]),[\s\r]*(['"][^'"]*['"])/ -> defineMacro($1, MacroDefinition.fromString($2)
/// /defineMacro\((['"][^'"]*['"]), function/ -> defineMacro($1, MacroDefinition(
/// /const ([a-zA-Z]* = context.[a-zA-Z]*[^;]*;)/ -> final $1
/// /let ([^;]*;)$/ -> var $1
/// /==/ -> ==
/// /!=/ -> !=
/// \}\);(([\s\r]*|[\s]//[^\n]*)*defineMacro) -> }));$1
/// `([^']*)` -> '$1'
/// defineMacro\((['"][^'"]*['"]), \(context -> defineMacro($1, MacroDefinition.fromCtxString((context
/// (\([a-zA-Z,:_]*\))[\s]*=>[\s]*\{ -> $1 {
/// charCodeAt -> codeUnitAt
/// ([a-zA-Z.]*) in ([a-zA-Z.]*) -> $2.containsKey($1)
///
/// defineMacro\([\s\n]*"([^"]*)", -> '$1':

final Map<String, MacroDefinition> builtinMacros = {
  r'\noexpand': MacroDefinition((context) {
    // The expansion is the token itself; but that token is interpreted
    // as if its meaning were ‘\relax’ if it is a control sequence that
    // would ordinarily be expanded by TeX’s expansion rules.
    final t = context.popToken();
    if (context.isExpandable(t.text)) {
      t.noexpand = true;
      t.treatAsRelax = true;
    }
    return MacroExpansion(tokens: [t], numArgs: 0);
  }),

  r'\expandafter': MacroDefinition((context) {
    // TeX first reads the token that comes immediately after \expandafter,
    // without expanding it; let’s call this token t. Then TeX reads the
    // token that comes after t (and possibly more tokens, if that token
    // has an argument), replacing it by its expansion. Finally TeX puts
    // t back in front of that expansion.
    final t = context.popToken();
    context.expandOnce(true); // expand only an expandable token
    return MacroExpansion(tokens: [t], numArgs: 0);
  }),

  // LaTeX's \@firstoftwo{#1}{#2} expands to #1, skipping #2
  // TeX source: \long\def\@firstoftwo#1#2{#1}
  r'\@firstoftwo': MacroDefinition((context) {
    final args = context.consumeArgs(2);
    return MacroExpansion(tokens: args[0], numArgs: 0);
  }),

  // LaTeX's \@secondoftwo{#1}{#2} expands to #2, skipping #1
  // TeX source: \long\def\@secondoftwo#1#2{#2}
  r'\@secondoftwo': MacroDefinition((context) {
    final args = context.consumeArgs(2);
    return MacroExpansion(tokens: args[1], numArgs: 0);
  }),

  // LaTeX's \@ifnextchar{#1}{#2}{#3} looks ahead to the next (unexpanded)
  // symbol that isn't a space, consuming any spaces but not consuming the
  // first nonspace character.  If that nonspace character matches #1, then
  // the macro expands to #2; otherwise, it expands to #3.
  r'\@ifnextchar': MacroDefinition((context) {
    final args = context.consumeArgs(3); // symbol, if, else
    context.consumeSpaces();
    final nextToken = context.future();
    if (args[0].length == 1 && args[0][0].text == nextToken.text) {
      return MacroExpansion(tokens: args[1], numArgs: 0);
    } else {
      return MacroExpansion(tokens: args[2], numArgs: 0);
    }
  }),

  // LaTeX's \@ifstar{#1}{#2} looks ahead to the next (unexpanded) symbol.
  // If it is '*', then it consumes the symbol, and the macro expands to #1;
  // otherwise, the macro expands to #2 (without consuming the symbol).
  // TeX source: \def\@ifstar#1{\@ifnextchar *{\@firstoftwo{#1}}}
  r'\@ifstar': MacroDefinition.fromString(r"\@ifnextchar *{\@firstoftwo{#1}}"),

  // LaTeX's \TextOrMath{#1}{#2} expands to #1 in text mode, #2 in math mode
  r'\TextOrMath': MacroDefinition((context) {
    final args = context.consumeArgs(2);
    if (context.mode == Mode.text) {
      return MacroExpansion(tokens: args[0], numArgs: 0);
    } else {
      return MacroExpansion(tokens: args[1], numArgs: 0);
    }
  }),

  // TeX \char makes a literal character (catcode 12) using the following forms:
  // (see The TeXBook, p. 43)
  //   \char123  -- decimal
  //   \char'123 -- octal
  //   \char"123 -- hex
  //   \char`x   -- character that can be written (i.e. isn't active)
  //   \char`\x  -- character that cannot be written (e.g. %)
  // These all refer to characters from the font, so we turn them into special
  // calls to a function \@char dealt with in the Parser.
  r'\char': MacroDefinition.fromCtxString((context) {
    var token = context.popToken();
    int? base;
    int? number;
    if (token.text == "'") {
      base = 8;
      token = context.popToken();
    } else if (token.text == '"') {
      base = 16;
      token = context.popToken();
    } else if (token.text == "`") {
      token = context.popToken();
      if (token.text[0] == r"\") {
        number = token.text.codeUnitAt(1);
      } else if (token.text == "EOF") {
        throw ParseException(r"\char` missing argument");
      } else {
        number = token.text.codeUnitAt(0);
      }
    } else {
      base = 10;
    }
    if (base != null) {
      // Parse a number in the given base, starting with first 'token'.
      number = digitToNumber[token.text];
      if (number == null || number >= base) {
        throw ParseException('Invalid base-$base digit ${token.text}');
      }
      int? digit;
      while ((digit = digitToNumber[context.future().text]) != null &&
          digit! < base) {
        number = number! * base;
        number += digit;
        context.popToken();
      }
    }
    return '\\@char{$number}';
  }),

  // \newcommand{\macro}[args]{definition}
  // \renewcommand{\macro}[args]{definition}
  // TODO: Optional arguments: \newcommand{\macro}[args][default]{definition}
  r'\newcommand': MacroDefinition.fromCtxString(
    (context) => newcommand(context, false, true),
  ),
  r'\renewcommand': MacroDefinition.fromCtxString(
    (context) => newcommand(context, true, false),
  ),
  r'\providecommand': MacroDefinition.fromCtxString(
    (context) => newcommand(context, true, true),
  ),

  // terminal (console) tools
  r'\message': MacroDefinition.fromCtxString((context) {
    final arg = context.consumeArgs(1)[0];
    info(arg.reversed.map((token) => token.text).join());
    return '';
  }),
  r'\errmessage': MacroDefinition.fromCtxString((context) {
    final arg = context.consumeArgs(1)[0];
    error(arg.reversed.map((token) => token.text).join());
    return '';
  }),
  r'\show': MacroDefinition.fromCtxString((context) {
    final tok = context.popToken();
    final name = tok.text;
    info(
      '$tok, ${context.macros.get(name)}, ${functions[name]},'
      '${texSymbolCommandConfigs[Mode.math]![name]}, ${texSymbolCommandConfigs[Mode.text]![name]}',
    );
    return '';
  }),

  //////////////////////////////////////////////////////////////////////
  // Grouping
  // \let\bgroup={ \let\egroup=}
  r'\bgroup': MacroDefinition.fromString("{"),
  r'\egroup': MacroDefinition.fromString("}"),

  // Symbols from latex.ltx:
  // \def\lq{`}
  // \def\rq{'}
  // \def \aa {\r a}
  // \def \AA {\r A}
  r'\lq': MacroDefinition.fromString("`"),
  r'\rq': MacroDefinition.fromString("'"),
  // '\\aa': MacroDefinition.fromString("\\r a"),
  // '\\AA': MacroDefinition.fromString("\\r A"),

  // TODO these should be migrated into renderconfigs
  // Characters omitted from Unicode range 1D400–1D7FF
  '\u212C': MacroDefinition.fromString(r"\mathscr{B}"), // script
  '\u2130': MacroDefinition.fromString(r"\mathscr{E}"),
  '\u2131': MacroDefinition.fromString(r"\mathscr{F}"),
  '\u210B': MacroDefinition.fromString(r"\mathscr{H}"),
  '\u2110': MacroDefinition.fromString(r"\mathscr{I}"),
  '\u2112': MacroDefinition.fromString(r"\mathscr{L}"),
  '\u2133': MacroDefinition.fromString(r"\mathscr{M}"),
  '\u211B': MacroDefinition.fromString(r"\mathscr{R}"),
  '\u212D': MacroDefinition.fromString(r"\mathfrak{C}"), // Fraktur
  '\u210C': MacroDefinition.fromString(r"\mathfrak{H}"),
  '\u2128': MacroDefinition.fromString(r"\mathfrak{Z}"),

  // Define \Bbbk with a macro that works in both HTML and MathML.
  r'\Bbbk': MacroDefinition.fromString(r"\Bbb{k}"),

  // Unicode middle dot
  // The KaTeX fonts do not contain U+00B7. Instead, \cdotp displays
  // the dot at U+22C5 and gives it punct spacing.
  '\u00b7': MacroDefinition.fromString(r"\cdotp"),

  // wont support
  // \llap and \rlap render their contents in text mode
  // '\\llap': MacroDefinition.fromString("\\mathllap{\\textrm{#1}}"),
  // '\\rlap': MacroDefinition.fromString("\\mathrlap{\\textrm{#1}}"),
  // '\\clap': MacroDefinition.fromString("\\mathclap{\\textrm{#1}}"),

  // \not is defined by base/fontmath.ltx via
  // \DeclareMathSymbol{\not}{\mathrel}{symbols}{"36}
  // It's thus treated like a \mathrel, but defined by a symbol that has zero
  // width but extends to the right.  We use \rlap to get that spacing.
  // For MathML we write U+0338 here. buildMathML.js will then do the overlay.
  // TODO fold 'not' with applicable operators
  // defineMacro(
  //     "\\not",
  //     MacroDefinition.fromString(
  //         '\\html@mathml{\\mathrel{\\mathrlap\\@not}}{\\char")338}'));

  // Negated symbols from base/fontmath.ltx:
  // \def\neq{\not=} \let\ne=\neq
  // \DeclareRobustCommand
  //   \notin{\mathrel{\m@th\mathpalette\c@ncel\in}}
  // \def\c@ncel#1#2{\m@th\ooalign{$\hfil#1\mkern1mu/\hfil$\crcr$#1#2$}}
  r'\ne': MacroDefinition.fromString(r"\neq"),
  '\u2260': MacroDefinition.fromString(r"\neq"),
  '\u2209': MacroDefinition.fromString(r"\notin"),

  // Unicode stacked relations are migrated to complex symbols

  // Misc Unicode
  '\u27C2': MacroDefinition.fromString(r"\perp"),
  '\u203C': MacroDefinition.fromString(r"\mathclose{!\mkern-0.8mu!}"),
  '\u220C': MacroDefinition.fromString(r"\notni"),
  '\u231C': MacroDefinition.fromString(r"\ulcorner"),
  '\u231D': MacroDefinition.fromString(r"\urcorner"),
  '\u231E': MacroDefinition.fromString(r"\llcorner"),
  '\u231F': MacroDefinition.fromString(r"\lrcorner"),
  '\u00A9': MacroDefinition.fromString(r"\copyright"),
  '\u00AE': MacroDefinition.fromString(r"\textregistered"),
  '\uFE0F': MacroDefinition.fromString(r"\textregistered"),

  // The KaTeX fonts have corners at codepoints that don't match Unicode.
  // For MathML purposes, use the Unicode code point.
  // TODO strip useless @
  r'\ulcorner': MacroDefinition.fromString(r"\@ulcorner"),
  r'\urcorner': MacroDefinition.fromString(r"\@urcorner"),
  r'\llcorner': MacroDefinition.fromString(r"\@llcorner"),
  r'\lrcorner': MacroDefinition.fromString(r"\@lrcorner"),

  //////////////////////////////////////////////////////////////////////
  // LaTeX_2ε

  // \vdots{\vbox{\baselineskip4\p@  \lineskiplimit\z@
  // \kern6\p@\hbox{.}\hbox{.}\hbox{.}}}
  // We'll call \varvdots, which gets a glyph from symbols.js.
  // The zero-width rule gets us an equivalent to the vertical 6pt kern.
  // TODO should we accept \vdots's kern ?
  r'\vdots': MacroDefinition.fromString(r"\mathord{\varvdots\rule{0pt}{15pt}}"),
  '\u22ee': MacroDefinition.fromString(r"\vdots"),

  //////////////////////////////////////////////////////////////////////
  // amsmath.sty
  // http://mirrors.concertpass.com/tex-archive/macros/latex/required/amsmath/amsmath.pdf

  // Italic Greek capital letters.  AMS defines these with \DeclareMathSymbol,
  // but they are equivalent to \mathit{\Letter}.
  // TODO make them as overrided fonts
  r'\varGamma': MacroDefinition.fromString(r"\mathit{\Gamma}"),
  r'\varDelta': MacroDefinition.fromString(r"\mathit{\Delta}"),
  r'\varTheta': MacroDefinition.fromString(r"\mathit{\Theta}"),
  r'\varLambda': MacroDefinition.fromString(r"\mathit{\Lambda}"),
  r'\varXi': MacroDefinition.fromString(r"\mathit{\Xi}"),
  r'\varPi': MacroDefinition.fromString(r"\mathit{\Pi}"),
  r'\varSigma': MacroDefinition.fromString(r"\mathit{\Sigma}"),
  r'\varUpsilon': MacroDefinition.fromString(r"\mathit{\Upsilon}"),
  r'\varPhi': MacroDefinition.fromString(r"\mathit{\Phi}"),
  r'\varPsi': MacroDefinition.fromString(r"\mathit{\Psi}"),
  r'\varOmega': MacroDefinition.fromString(r"\mathit{\Omega}"),

  //\newcommand{\substack}[1]{\subarray{c}#1\endsubarray}
  r'\substack': MacroDefinition.fromString(
    r"\begin{subarray}{c}#1\end{subarray}",
  ),

  // \renewcommand{\colon}{\nobreak\mskip2mu\mathpunct{}\nonscript
  // \mkern-\thinmuskip{:}\mskip6muplus1mu\relax}

  // \newcommand{\boxed}[1]{\fbox{\m@th$\displaystyle#1$}}
  // TODO fbox
  r'\boxed': MacroDefinition.fromString(r"\fbox{$\displaystyle{#1}$}"),

  // \def\iff{\DOTSB\;\Longleftrightarrow\;}
  // \def\implies{\DOTSB\;\Longrightarrow\;}
  // \def\impliedby{\DOTSB\;\Longleftarrow\;}
  r'\iff': MacroDefinition.fromString(r"\DOTSB\;\Longleftrightarrow\;"),
  r'\implies': MacroDefinition.fromString(r"\DOTSB\;\Longrightarrow\;"),
  r'\impliedby': MacroDefinition.fromString(r"\DOTSB\;\Longleftarrow\;"),

  // AMSMath's automatic \dots, based on \mdots@@ macro.
  r'\dots': MacroDefinition.fromCtxString((context) {
    // TODO: If used in text mode, should expand to \textellipsis.
    // However, in KaTeX, \textellipsis and \ldots behave the same
    // (in text mode), and it's unlikely we'd see any of the math commands
    // that affect the behavior of \dots when in text mode.  So fine for now
    // (until we support \ifmmode ... \else ... \fi).
    var thedots = r'\dotso';
    final next = context.expandAfterFuture().text;
    if (dotsByToken.containsKey(next)) {
      thedots = dotsByToken[next]!;
    } else if (
    // next != null &&
    next.length >= 4 && next.substring(0, 4) == r'\not') {
      thedots = r'\dotsb';
    } else if (texSymbolCommandConfigs[Mode.math]!.containsKey(next)) {
      final command = texSymbolCommandConfigs[Mode.math]![next]!;
      if (command.type == AtomType.bin || command.type == AtomType.rel) {
        thedots = r'\dotsb';
      }
    }
    return thedots;
  }),

  r'\dotso': MacroDefinition.fromString(r"\ldots"),

  r'\dotsc': MacroDefinition.fromString(r"\ldots"),

  r'\cdots': MacroDefinition.fromString(r"\@cdots"),

  r'\dotsb': MacroDefinition.fromString(r"\cdots"),
  r'\dotsm': MacroDefinition.fromString(r"\cdots"),
  r'\dotsi': MacroDefinition.fromString(r"\!\cdots"),
  // amsmath doesn't actually define \dotsx, but \dots followed by a macro
  // starting with \DOTSX implies \dotso, and then \extra@ detects this case
  // and forces the added '\,'.
  r'\dotsx': MacroDefinition.fromString(r"\ldots\,"),

  // \let\DOTSI\relax
  // \let\DOTSB\relax
  // \let\DOTSX\relax
  r'\DOTSI': MacroDefinition.fromString(r"\relax"),
  r'\DOTSB': MacroDefinition.fromString(r"\relax"),
  r'\DOTSX': MacroDefinition.fromString(r"\relax"),

  // Spacing, based on amsmath.sty's override of LaTeX defaults
  // \DeclareRobustCommand{\tmspace}[3]{%
  //   \ifmmode\mskip#1#2\else\kern#1#3\fi\relax}
  r'\tmspace': MacroDefinition.fromString(
    r"\TextOrMath{\kern#1#3}{\mskip#1#2}\relax",
  ),
  // \renewcommand{\,}{\tmspace+\thinmuskip{.1667em}}
  // TODO: math mode should use \thinmuskip
  r'\,': MacroDefinition.fromString(r"\tmspace+{3mu}{.1667em}"),
  // \let\thinspace\,
  r'\thinspace': MacroDefinition.fromString(r"\,"),
  // \def\>{\mskip\medmuskip}
  // \renewcommand{\:}{\tmspace+\medmuskip{.2222em}}
  // TODO: \> and math mode of \: should use \medmuskip = 4mu plus 2mu minus 4mu
  r'\>': MacroDefinition.fromString(r"\mskip{4mu}"),
  r'\:': MacroDefinition.fromString(r"\tmspace+{4mu}{.2222em}"),
  // \let\medspace\:
  r'\medspace': MacroDefinition.fromString(r"\:"),
  // \renewcommand{\;}{\tmspace+\thickmuskip{.2777em}}
  // TODO: math mode should use \thickmuskip = 5mu plus 5mu
  r'\;': MacroDefinition.fromString(r"\tmspace+{5mu}{.2777em}"),
  // \let\thickspace\;
  r'\thickspace': MacroDefinition.fromString(r"\;"),
  // \renewcommand{\!}{\tmspace-\thinmuskip{.1667em}}
  // TODO: math mode should use \thinmuskip
  r'\!': MacroDefinition.fromString(r"\tmspace-{3mu}{.1667em}"),
  // \let\negthinspace\!
  r'\negthinspace': MacroDefinition.fromString(r"\!"),
  // \newcommand{\negmedspace}{\tmspace-\medmuskip{.2222em}}
  // TODO: math mode should use \medmuskip
  r'\negmedspace': MacroDefinition.fromString(r"\tmspace-{4mu}{.2222em}"),
  // \newcommand{\negthickspace}{\tmspace-\thickmuskip{.2777em}}
  // TODO: math mode should use \thickmuskip
  r'\negthickspace': MacroDefinition.fromString(r"\tmspace-{5mu}{.277em}"),
  // \def\enspace{\kern.5em }
  r'\enspace': MacroDefinition.fromString(r"\kern.5em "),
  // \def\enskip{\hskip.5em\relax}
  r'\enskip': MacroDefinition.fromString(r"\hskip.5em\relax"),
  // \def\quad{\hskip1em\relax}
  r'\quad': MacroDefinition.fromString(r"\hskip1em\relax"),
  // \def\qquad{\hskip2em\relax}
  r'\qquad': MacroDefinition.fromString(r"\hskip2em\relax"),

  // \tag@in@display form of \tag
  // TODO tag
  r'\tag': MacroDefinition.fromString(r"\@ifstar\tag@literal\tag@paren"),
  r'\tag@paren': MacroDefinition.fromString(r"\tag@literal{({#1})}"),
  r'\tag@literal': MacroDefinition.fromCtxString((context) {
    if (context.macros.get(r"\df@tag") != null) {
      throw ParseException(r"Multiple \tag");
    }
    return r"\gdef\df@tag{\text{#1}}";
  }),

  // \renewcommand{\bmod}{\nonscript\mskip-\medmuskip\mkern5mu\mathbin
  //   {\operator@font mod}\penalty900
  //   \mkern5mu\nonscript\mskip-\medmuskip}
  // \newcommand{\pod}[1]{\allowbreak
  //   \if@display\mkern18mu\else\mkern8mu\fi(#1)}
  // \renewcommand{\pmod}[1]{\pod{{\operator@font mod}\mkern6mu#1}}
  // \newcommand{\mod}[1]{\allowbreak\if@display\mkern18mu
  //   \else\mkern12mu\fi{\operator@font mod}\,\,#1}
  // TODO: math mode should use \medmuskip = 4mu plus 2mu minus 4mu
  r'\bmod': MacroDefinition.fromString(
    r"\mskip5mu"
    r"\mathbin{\rm mod}"
    r"\mskip5mu",
  ),
  // TODO what should we do about \pod ?
  r'\pod': MacroDefinition.fromString(
    r"\allowbreak"
    r"\mkern8mu(#1)",
  ),
  r'\pmod': MacroDefinition.fromString(r"\pod{{\rm mod}\mkern6mu#1}"),
  r'\mod': MacroDefinition.fromString(
    r"\allowbreak"
    r"\mkern18mu{\rm mod}\,\,#1",
  ),

  //////////////////////////////////////////////////////////////////////
  // LaTeX source2e

  // \\ defaults to \newline, but changes to \cr within array environment
  r'\\': MacroDefinition.fromString(r"\newline"),

  // \def\TeX{T\kern-.1667em\lower.5ex\hbox{E}\kern-.125emX\@}
  // TODO: Doesn't normally work in math mode because \@ fails.  KaTeX doesn't
  // support \@ yet, so that's omitted, and we add \text so that the result
  // doesn't look funny in math mode.
  r'\TeX': MacroDefinition.fromString(
    r"\textrm{"
    r"T\kern-.1667em\raisebox{-.5ex}{E}\kern-.125emX"
    "}",
  ),

  // \DeclareRobustCommand{\LaTeX}{L\kern-.36em%
  //         {\sbox\z@ T%
  //          \vbox to\ht\z@{\hbox{\check@mathfonts
  //                               \fontsize\sf@size\z@
  //                               \math@fontsfalse\selectfont
  //                               A}%
  //                         \vss}%
  //         }%
  //         \kern-.15em%
  //         \TeX}
  // This code aligns the top of the A with the T (from the perspective of TeX's
  // boxes, though visually the A appears to extend above slightly).
  // We compute the corresponding \raisebox when A is rendered in \normalsize
  // \scriptstyle, which has a scale factor of 0.7 (see Options.js).
  r'\LaTeX': MacroDefinition.fromString(
    r"\textrm{"
    'L\\kern-.36em\\raisebox{$latexRaiseA}{\\scriptstyle A}'
    r"\kern-.15em\TeX}",
  ),

  // KaTeX logo based on tweaking LaTeX logo
  r'\KaTeX': MacroDefinition.fromString(
    r"\textrm{"
    'K\\kern-.17em\\raisebox{$latexRaiseA}{\\scriptstyle A}'
    r"\kern-.15em\TeX}",
  ),

  // \DeclareRobustCommand\hspace{\@ifstar\@hspacer\@hspace}
  // \def\@hspace#1{\hskip  #1\relax}
  // \def\@hspacer#1{\vrule \@width\z@\nobreak
  //                 \hskip #1\hskip \z@skip}
  r'\hspace': MacroDefinition.fromString(r"\hskip #1\relax"),

  //////////////////////////////////////////////////////////////////////
  // mathtools.sty migrated to extra_symbols
  // TODO: make as overrided type & font

  //\providecommand\ordinarycolon{:}
  r'\ordinarycolon': MacroDefinition.fromString(":"),
  //\def\vcentcolon{\mathrel{\mathop\ordinarycolon}}
  //TODO(edemaine): Not yet centered. Fix via \raisebox or #726
  r'\vcentcolon': MacroDefinition.fromString(
    r"\mathrel{\mathop\ordinarycolon}",
  ),

  // Some Unicode characters are implemented with macros to mathtools functions.
  '\u2237': MacroDefinition.fromString(r"\dblcolon"), // ::
  '\u2239': MacroDefinition.fromString(r"\eqcolon"), // -:
  '\u2254': MacroDefinition.fromString(r"\coloneqq"), // :=
  '\u2255': MacroDefinition.fromString(r"\eqqcolon"), // =:
  // '\u2A74': MacroDefinition.fromString("\\Coloneqq"), // ::=

  //////////////////////////////////////////////////////////////////////
  // colonequals.sty

  // Alternate names for mathtools's macros:
  r'\ratio': MacroDefinition.fromString(r"\vcentcolon"),
  r'\coloncolon': MacroDefinition.fromString(r"\dblcolon"),
  r'\colonequals': MacroDefinition.fromString(r"\coloneqq"),
  r'\equalscolon': MacroDefinition.fromString(r"\eqqcolon"),
  r'\minuscolon': MacroDefinition.fromString(r"\eqcolon"),

  // Present in newtxmath, pxfonts and txfonts
  r'\limsup': MacroDefinition.fromString(r"\DOTSB\operatorname*{lim\,sup}"),
  r'\liminf': MacroDefinition.fromString(r"\DOTSB\operatorname*{lim\,inf}"),

  //////////////////////////////////////////////////////////////////////
  // MathML alternates for KaTeX glyphs in the Unicode private area

  //////////////////////////////////////////////////////////////////////
  // stmaryrd and semantic migrated to extra symbols

  // The stmaryrd and semantic packages render the next four items by calling a
  // glyph. Those glyphs do not exist in the KaTeX fonts. Hence the macros.

  //////////////////////////////////////////////////////////////////////
  // texvc.sty

  // The texvc package contains macros available in mediawiki pages.
  // We omit the functions deprecated at
  // https://en.wikipedia.org/wiki/Help:Displaying_a_formula#Deprecated_syntax

  // We also omit texvc's \O, which conflicts with \text{\O}
  // TODO: make as override font
  r'\darr': MacroDefinition.fromString(r"\downarrow"),
  r'\dArr': MacroDefinition.fromString(r"\Downarrow"),
  r'\Darr': MacroDefinition.fromString(r"\Downarrow"),
  r'\lang': MacroDefinition.fromString(r"\langle"),
  r'\rang': MacroDefinition.fromString(r"\rangle"),
  r'\uarr': MacroDefinition.fromString(r"\uparrow"),
  r'\uArr': MacroDefinition.fromString(r"\Uparrow"),
  r'\Uarr': MacroDefinition.fromString(r"\Uparrow"),
  r'\N': MacroDefinition.fromString(r"\mathbb{N}"),
  r'\R': MacroDefinition.fromString(r"\mathbb{R}"),
  r'\Z': MacroDefinition.fromString(r"\mathbb{Z}"),
  r'\alef': MacroDefinition.fromString(r"\aleph"),
  r'\alefsym': MacroDefinition.fromString(r"\aleph"),
  r'\Alpha': MacroDefinition.fromString(r"\mathrm{A}"),
  r'\Beta': MacroDefinition.fromString(r"\mathrm{B}"),
  r'\bull': MacroDefinition.fromString(r"\bullet"),
  r'\Chi': MacroDefinition.fromString(r"\mathrm{X}"),
  r'\clubs': MacroDefinition.fromString(r"\clubsuit"),
  r'\cnums': MacroDefinition.fromString(r"\mathbb{C}"),
  r'\Complex': MacroDefinition.fromString(r"\mathbb{C}"),
  r'\Dagger': MacroDefinition.fromString(r"\ddagger"),
  r'\diamonds': MacroDefinition.fromString(r"\diamondsuit"),
  r'\empty': MacroDefinition.fromString(r"\emptyset"),
  r'\Epsilon': MacroDefinition.fromString(r"\mathrm{E}"),
  r'\Eta': MacroDefinition.fromString(r"\mathrm{H}"),
  r'\exist': MacroDefinition.fromString(r"\exists"),
  r'\harr': MacroDefinition.fromString(r"\leftrightarrow"),
  r'\hArr': MacroDefinition.fromString(r"\Leftrightarrow"),
  r'\Harr': MacroDefinition.fromString(r"\Leftrightarrow"),
  r'\hearts': MacroDefinition.fromString(r"\heartsuit"),
  r'\image': MacroDefinition.fromString(r"\Im"),
  r'\infin': MacroDefinition.fromString(r"\infty"),
  r'\Iota': MacroDefinition.fromString(r"\mathrm{I}"),
  r'\isin': MacroDefinition.fromString(r"\in"),
  r'\Kappa': MacroDefinition.fromString(r"\mathrm{K}"),
  r'\larr': MacroDefinition.fromString(r"\leftarrow"),
  r'\lArr': MacroDefinition.fromString(r"\Leftarrow"),
  r'\Larr': MacroDefinition.fromString(r"\Leftarrow"),
  r'\lrarr': MacroDefinition.fromString(r"\leftrightarrow"),
  r'\lrArr': MacroDefinition.fromString(r"\Leftrightarrow"),
  r'\Lrarr': MacroDefinition.fromString(r"\Leftrightarrow"),
  r'\Mu': MacroDefinition.fromString(r"\mathrm{M}"),
  r'\natnums': MacroDefinition.fromString(r"\mathbb{N}"),
  r'\Nu': MacroDefinition.fromString(r"\mathrm{N}"),
  r'\Omicron': MacroDefinition.fromString(r"\mathrm{O}"),
  r'\plusmn': MacroDefinition.fromString(r"\pm"),
  r'\rarr': MacroDefinition.fromString(r"\rightarrow"),
  r'\rArr': MacroDefinition.fromString(r"\Rightarrow"),
  r'\Rarr': MacroDefinition.fromString(r"\Rightarrow"),
  r'\real': MacroDefinition.fromString(r"\Re"),
  r'\reals': MacroDefinition.fromString(r"\mathbb{R}"),
  r'\Reals': MacroDefinition.fromString(r"\mathbb{R}"),
  r'\Rho': MacroDefinition.fromString(r"\mathrm{P}"),
  r'\sdot': MacroDefinition.fromString(r"\cdot"),
  r'\sect': MacroDefinition.fromString(r"\S"),
  r'\spades': MacroDefinition.fromString(r"\spadesuit"),
  r'\sub': MacroDefinition.fromString(r"\subset"),
  r'\sube': MacroDefinition.fromString(r"\subseteq"),
  r'\supe': MacroDefinition.fromString(r"\supseteq"),
  r'\Tau': MacroDefinition.fromString(r"\mathrm{T}"),
  r'\thetasym': MacroDefinition.fromString(r"\vartheta"),
  // TODO: '\\varcoppa': MacroDefinition.fromString("\\\mbox{\\coppa}"),
  r'\weierp': MacroDefinition.fromString(r"\wp"),
  r'\Zeta': MacroDefinition.fromString(r"\mathrm{Z}"),

  //////////////////////////////////////////////////////////////////////
  // statmath.sty
  // https://ctan.math.illinois.edu/macros/latex/contrib/statmath/statmath.pdf
  r'\argmin': MacroDefinition.fromString(r"\DOTSB\operatorname*{arg\,min}"),
  r'\argmax': MacroDefinition.fromString(r"\DOTSB\operatorname*{arg\,max}"),
  r'\plim': MacroDefinition.fromString(r"\DOTSB\operatorname*{plim}\limits"),

  // "\\DOTSB\\mathop{\\operatorname{plim}}\\limits"),

  //////////////////////////////////////////////////////////////////////
  // braket.sty
  // http://ctan.math.washington.edu/tex-archive/macros/latex/contrib/braket/braket.pdf
  r'\bra': MacroDefinition.fromString(r"\mathinner{\langle{#1}|}"),
  r'\ket': MacroDefinition.fromString(r"\mathinner{|{#1}\rangle}"),
  r'\braket': MacroDefinition.fromString(r"\mathinner{\langle{#1}\rangle}"),
  r'\Bra': MacroDefinition.fromString(r"\left\langle#1\right|"),
  r'\Ket': MacroDefinition.fromString(r"\left|#1\right\rangle"),

  // Custom Khan Academy colors, should be moved to an optional package
  r'\blue': MacroDefinition.fromString(r"\textcolor{##6495ed}{#1}"),
  r'\orange': MacroDefinition.fromString(r"\textcolor{##ffa500}{#1}"),
  r'\pink': MacroDefinition.fromString(r"\textcolor{##ff00af}{#1}"),
  r'\red': MacroDefinition.fromString(r"\textcolor{##df0030}{#1}"),
  r'\green': MacroDefinition.fromString(r"\textcolor{##28ae7b}{#1}"),
  r'\gray': MacroDefinition.fromString(r"\textcolor{gray}{#1}"),
  r'\purple': MacroDefinition.fromString(r"\textcolor{##9d38bd}{#1}"),
  r'\blueA': MacroDefinition.fromString(r"\textcolor{##ccfaff}{#1}"),
  r'\blueB': MacroDefinition.fromString(r"\textcolor{##80f6ff}{#1}"),
  r'\blueC': MacroDefinition.fromString(r"\textcolor{##63d9ea}{#1}"),
  r'\blueD': MacroDefinition.fromString(r"\textcolor{##11accd}{#1}"),
  r'\blueE': MacroDefinition.fromString(r"\textcolor{##0c7f99}{#1}"),
  r'\tealA': MacroDefinition.fromString(r"\textcolor{##94fff5}{#1}"),
  r'\tealB': MacroDefinition.fromString(r"\textcolor{##26edd5}{#1}"),
  r'\tealC': MacroDefinition.fromString(r"\textcolor{##01d1c1}{#1}"),
  r'\tealD': MacroDefinition.fromString(r"\textcolor{##01a995}{#1}"),
  r'\tealE': MacroDefinition.fromString(r"\textcolor{##208170}{#1}"),
  r'\greenA': MacroDefinition.fromString(r"\textcolor{##b6ffb0}{#1}"),
  r'\greenB': MacroDefinition.fromString(r"\textcolor{##8af281}{#1}"),
  r'\greenC': MacroDefinition.fromString(r"\textcolor{##74cf70}{#1}"),
  r'\greenD': MacroDefinition.fromString(r"\textcolor{##1fab54}{#1}"),
  r'\greenE': MacroDefinition.fromString(r"\textcolor{##0d923f}{#1}"),
  r'\goldA': MacroDefinition.fromString(r"\textcolor{##ffd0a9}{#1}"),
  r'\goldB': MacroDefinition.fromString(r"\textcolor{##ffbb71}{#1}"),
  r'\goldC': MacroDefinition.fromString(r"\textcolor{##ff9c39}{#1}"),
  r'\goldD': MacroDefinition.fromString(r"\textcolor{##e07d10}{#1}"),
  r'\goldE': MacroDefinition.fromString(r"\textcolor{##a75a05}{#1}"),
  r'\redA': MacroDefinition.fromString(r"\textcolor{##fca9a9}{#1}"),
  r'\redB': MacroDefinition.fromString(r"\textcolor{##ff8482}{#1}"),
  r'\redC': MacroDefinition.fromString(r"\textcolor{##f9685d}{#1}"),
  r'\redD': MacroDefinition.fromString(r"\textcolor{##e84d39}{#1}"),
  r'\redE': MacroDefinition.fromString(r"\textcolor{##bc2612}{#1}"),
  r'\maroonA': MacroDefinition.fromString(r"\textcolor{##ffbde0}{#1}"),
  r'\maroonB': MacroDefinition.fromString(r"\textcolor{##ff92c6}{#1}"),
  r'\maroonC': MacroDefinition.fromString(r"\textcolor{##ed5fa6}{#1}"),
  r'\maroonD': MacroDefinition.fromString(r"\textcolor{##ca337c}{#1}"),
  r'\maroonE': MacroDefinition.fromString(r"\textcolor{##9e034e}{#1}"),
  r'\purpleA': MacroDefinition.fromString(r"\textcolor{##ddd7ff}{#1}"),
  r'\purpleB': MacroDefinition.fromString(r"\textcolor{##c6b9fc}{#1}"),
  r'\purpleC': MacroDefinition.fromString(r"\textcolor{##aa87ff}{#1}"),
  r'\purpleD': MacroDefinition.fromString(r"\textcolor{##7854ab}{#1}"),
  r'\purpleE': MacroDefinition.fromString(r"\textcolor{##543b78}{#1}"),
  r'\mintA': MacroDefinition.fromString(r"\textcolor{##f5f9e8}{#1}"),
  r'\mintB': MacroDefinition.fromString(r"\textcolor{##edf2df}{#1}"),
  r'\mintC': MacroDefinition.fromString(r"\textcolor{##e0e5cc}{#1}"),
  r'\grayA': MacroDefinition.fromString(r"\textcolor{##f6f7f7}{#1}"),
  r'\grayB': MacroDefinition.fromString(r"\textcolor{##f0f1f2}{#1}"),
  r'\grayC': MacroDefinition.fromString(r"\textcolor{##e3e5e6}{#1}"),
  r'\grayD': MacroDefinition.fromString(r"\textcolor{##d6d8da}{#1}"),
  r'\grayE': MacroDefinition.fromString(r"\textcolor{##babec2}{#1}"),
  r'\grayF': MacroDefinition.fromString(r"\textcolor{##888d93}{#1}"),
  r'\grayG': MacroDefinition.fromString(r"\textcolor{##626569}{#1}"),
  r'\grayH': MacroDefinition.fromString(r"\textcolor{##3b3e40}{#1}"),
  r'\grayI': MacroDefinition.fromString(r"\textcolor{##21242c}{#1}"),
  r'\kaBlue': MacroDefinition.fromString(r"\textcolor{##314453}{#1}"),
  r'\kaGreen': MacroDefinition.fromString(r"\textcolor{##71B307}{#1}"),
};
