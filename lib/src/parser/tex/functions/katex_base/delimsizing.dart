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

part of katex_base;

const _delimSizingEntries = {
  [
    r'\bigl',
    r'\Bigl',
    r'\biggl',
    r'\Biggl',
    r'\bigr',
    r'\Bigr',
    r'\biggr',
    r'\Biggr',
    r'\bigm',
    r'\Bigm',
    r'\biggm',
    r'\Biggm',
    r'\big',
    r'\Big',
    r'\bigg',
    r'\Bigg',
  ]: FunctionSpec(
    numArgs: 1,
    handler: _delimSizeHandler,
  ),
  [r'\right']: FunctionSpec(
    numArgs: 1,
    // greediness: 3,
    handler: _rightHandler,
  ),
  [r'\left']: FunctionSpec(
    numArgs: 1,
    // greediness: 2,
    handler: _leftHandler,
  ),
  [r'\middle']: FunctionSpec(numArgs: 1, handler: _middleHandler),
};

const _delimiterTypes = {
  r'\bigl': AtomType.open,
  r'\Bigl': AtomType.open,
  r'\biggl': AtomType.open,
  r'\Biggl': AtomType.open,
  r'\bigr': AtomType.close,
  r'\Bigr': AtomType.close,
  r'\biggr': AtomType.close,
  r'\Biggr': AtomType.close,
  r'\bigm': AtomType.rel,
  r'\Bigm': AtomType.rel,
  r'\biggm': AtomType.rel,
  r'\Biggm': AtomType.rel,
  r'\big': AtomType.ord,
  r'\Big': AtomType.ord,
  r'\bigg': AtomType.ord,
  r'\Bigg': AtomType.ord,
};

const _delimiterSizes = {
  r'\bigl': 1,
  r'\Bigl': 2,
  r'\biggl': 3,
  r'\Biggl': 4,
  r'\bigr': 1,
  r'\Bigr': 2,
  r'\biggr': 3,
  r'\Biggr': 4,
  r'\bigm': 1,
  r'\Bigm': 2,
  r'\biggm': 3,
  r'\Biggm': 4,
  r'\big': 1,
  r'\Big': 2,
  r'\bigg': 3,
  r'\Bigg': 4,
};

const delimiterCommands = [
  '(',
  r'\lparen',
  ')',
  r'\rparen',
  '[',
  r'\lbrack',
  ']',
  r'\rbrack',
  r'\{',
  r'\lbrace',
  r'\}',
  r'\rbrace',
  r'\lfloor',
  r'\rfloor',
  '\u230a',
  '\u230b',
  r'\lceil',
  r'\rceil',
  '\u2308',
  '\u2309',
  '<',
  '>',
  r'\langle',
  '\u27e8',
  r'\rangle',
  '\u27e9',
  r'\lt',
  r'\gt',
  r'\lvert',
  r'\rvert',
  r'\lVert',
  r'\rVert',
  r'\lgroup',
  r'\rgroup',
  '\u27ee',
  '\u27ef',
  r'\lmoustache',
  r'\rmoustache',
  '\u23b0',
  '\u23b1',
  '/',
  r'\backslash',
  '|',
  r'\vert',
  r'\|',
  r'\Vert',
  r'\uparrow',
  r'\Uparrow',
  r'\downarrow',
  r'\Downarrow',
  r'\updownarrow',
  r'\Updownarrow',
  '.',
];

final _delimiterSymbols = delimiterCommands
    .map((command) => texSymbolCommandConfigs[Mode.math]![command]!)
    .toList(growable: false);

String? _checkDelimiter(GreenNode delim, FunctionContext context) {
  if (delim is SymbolNode) {
    if (_delimiterSymbols.any(
      (symbol) =>
          symbol.symbol == delim.symbol &&
          symbol.variantForm == delim.variantForm,
    )) {
      if (delim.symbol == '<' || delim.symbol == 'lt') {
        return '\u27e8';
      } else if (delim.symbol == '>' || delim.symbol == 'gt') {
        return '\u27e9';
      } else if (delim.symbol == '.') {
        return null;
      } else {
        return delim.symbol;
      }
    } else {
      // TODO: this throw omitted the token location
      throw ParseException(
        "Invalid delimiter '${delim.symbol}' after '${context.funcName}'",
      );
    }
  } else {
    throw ParseException("Invalid delimiter type '${delim.runtimeType}'");
  }
}

GreenNode _delimSizeHandler(TexParser parser, FunctionContext context) {
  final delimArg = parser.parseArgNode(mode: Mode.math, optional: false)!;
  final delim = _checkDelimiter(delimArg, context);
  return delim == null
      ? SpaceNode(
          height: Measurement.zero,
          width: Measurement.zero,
          mode: Mode.math,
        )
      : SymbolNode(
          symbol: delim,
          overrideAtomType: _delimiterTypes[context.funcName],
          overrideFont: FontOptions(
            fontFamily: 'Size${_delimiterSizes[context.funcName]}',
          ),
        );
}

class _LeftRightRightNode extends TemporaryNode {
  _LeftRightRightNode({this.delim});
  final String? delim;
}

/// KaTeX's \color command will affect the right delimiter.
/// MathJax's \color command will not affect the right delimiter.
/// Here we choose to follow MathJax's behavior because it fits out AST design
/// better. KaTeX's solution is messy.
GreenNode _rightHandler(TexParser parser, FunctionContext context) {
  final delimArg = parser.parseArgNode(mode: Mode.math, optional: false)!;
  return _LeftRightRightNode(delim: _checkDelimiter(delimArg, context));
}

GreenNode _leftHandler(TexParser parser, FunctionContext context) {
  final leftArg = parser.parseArgNode(mode: Mode.math, optional: false)!;
  final delim = _checkDelimiter(leftArg, context);
  // Parse out the implicit body
  ++parser.leftrightDepth;
  // parseExpression stops before '\\right'
  final body = parser.parseExpression();
  --parser.leftrightDepth;
  // Check the next token
  parser.expect(r'\right', consume: false);
  // Use parseArgNode instead of parseFunction like KaTeX
  final rightArg = parser.parseFunction(null, null, null);
  final right = assertNodeType<_LeftRightRightNode>(rightArg);

  final splittedBody = [<GreenNode>[]];
  final middles = <String?>[];
  for (final element in body) {
    if (element is _MiddleNode) {
      splittedBody.add([]);
      middles.add(element.delim == '.' ? null : element.delim);
    } else {
      splittedBody.last.add(element);
    }
  }
  return LeftRightNode(
    leftDelim: delim == '.' ? null : delim,
    rightDelim: right.delim == '.' ? null : right.delim,
    body: splittedBody
        .map((part) => part.wrapWithEquationRow())
        .toList(growable: false),
    middle: middles,
  );
}

class _MiddleNode extends TemporaryNode {
  _MiddleNode({this.delim});
  final String? delim;
}

/// Middle can only appear directly between \left and \right. Wrapping \middle
/// will cause error. This is in accordance with MathJax and different from
/// KaTeX, and is more compatible with our AST structure.
GreenNode _middleHandler(TexParser parser, FunctionContext context) {
  final delimArg = parser.parseArgNode(mode: Mode.math, optional: false)!;
  final delim = _checkDelimiter(delimArg, context);
  if (parser.leftrightDepth <= 0) {
    throw ParseException(r'\middle without preceding \left');
  }
  final contexts = parser.argParsingContexts.toList(growable: false);
  final lastContext = contexts[contexts.length - 2];
  if (lastContext.funcName != r'\left') {
    throw ParseException(r'\middle must be within \left and \right');
  }

  return _MiddleNode(delim: delim);
}
