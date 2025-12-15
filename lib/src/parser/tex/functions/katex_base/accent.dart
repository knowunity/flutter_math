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

const _accentEntries = {
  [
    r'\acute',
    r'\grave',
    r'\ddot',
    r'\tilde',
    r'\bar',
    r'\breve',
    r'\check',
    r'\hat',
    r'\vec',
    r'\dot',
    r'\mathring',
    r'\widecheck',
    r'\widehat',
    r'\widetilde',
    r'\overrightarrow',
    r'\overleftarrow',
    r'\Overrightarrow',
    r'\overleftrightarrow',
    // '\\overgroup',
    // '\\overlinesegment',
    r'\overleftharpoon',
    r'\overrightharpoon',

    r'\overline',
  ]: FunctionSpec(
    numArgs: 1,
    handler: _accentHandler,
  ),
  [
    r"\'",
    r'\`',
    r'\^',
    r'\~',
    r'\=',
    r'\u',
    r'\.',
    r'\"',
    r'\r',
    r'\H',
    r'\v',
    // '\\textcircled',
  ]: FunctionSpec(
    numArgs: 1,
    allowedInMath: false,
    allowedInText: true,
    handler: _textAccentHandler,
  ),
};

const nonStretchyAccents = {
  r'\acute',
  r'\grave',
  r'\ddot',
  r'\tilde',
  r'\bar',
  r'\breve',
  r'\check',
  r'\hat',
  r'\vec',
  r'\dot',
  r'\mathring',
};

const shiftyAccents = {r'\widehat', r'\widetilde', r'\widecheck'};

const accentCommandMapping = {
  r'\acute': '\u00B4',
  r'\grave': '\u0060',
  r'\ddot': '\u00A8',
  r'\tilde': '\u007E',
  r'\bar': '\u00AF',
  r'\breve': '\u02D8',
  r'\check': '\u02C7',
  r'\hat': '\u005E',
  r'\vec': '\u2192',
  r'\dot': '\u02D9',
  r'\mathring': '\u02da',
  r'\widecheck': '\u02c7',
  r'\widehat': '\u005e',
  r'\widetilde': '\u007e',
  r'\overrightarrow': '\u2192',
  r'\overleftarrow': '\u2190',
  r'\Overrightarrow': '\u21d2',
  r'\overleftrightarrow': '\u2194',
  // '\\overgroup': '\u',
  // '\\overlinesegment': '\u',
  r'\overleftharpoon': '\u21bc',
  r'\overrightharpoon': '\u21c0',
  r"\'": '\u00b4',
  r'\`': '\u0060',
  r'\^': '\u005e',
  r'\~': '\u007e',
  r'\=': '\u00af',
  r'\u': '\u02d8',
  r'\.': '\u02d9',
  r'\"': '\u00a8',
  r'\r': '\u02da',
  r'\H': '\u02dd',
  r'\v': '\u02c7',

  // '\\textcircled': '\u',
  r'\overline': '\u00AF',
};

GreenNode _accentHandler(TexParser parser, FunctionContext context) {
  final base = parser.parseArgNode(mode: Mode.math, optional: false)!;

  final isStretchy = !nonStretchyAccents.contains(context.funcName);
  final isShifty = !isStretchy || shiftyAccents.contains(context.funcName);

  return AccentNode(
    base: base.wrapWithEquationRow(),
    label: accentCommandMapping[context.funcName]!,
    isStretchy: isStretchy,
    isShifty: isShifty,
  );
}

const textUnicodeAccentMapping = {
  r'\`': '\u0300',
  r'\"': '\u0308',
  r'\~': '\u0303',
  r'\=': '\u0304',
  r"\'": '\u0301',
  r'\u': '\u0306',
  r'\v': '\u030c',
  r'\^': '\u0302',
  r'\.': '\u0307',
  r'\r': '\u030a',
  r'\H': '\u030b',
  // '\\textcircled': '\u',
};
GreenNode _textAccentHandler(TexParser parser, FunctionContext context) {
  final base = parser.parseArgNode(mode: null, optional: false)!;
  if (base is SymbolNode) {
    return base.withSymbol(
      base.symbol + textUnicodeAccentMapping[context.funcName]!,
    );
  }
  if (base is EquationRowNode && base.children.length == 1) {
    final node = base.children[0];
    if (node is SymbolNode) {
      return node.withSymbol(
        node.symbol + textUnicodeAccentMapping[context.funcName]!,
      );
    }
  }
  return AccentNode(
    base: base.wrapWithEquationRow(),
    label: accentCommandMapping[context.funcName]!,
    isStretchy: false,
    isShifty: true,
  );
}
