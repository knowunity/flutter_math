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

const _arrowEntries = {
  [
    r'\xleftarrow', r'\xrightarrow', r'\xLeftarrow', r'\xRightarrow',
    r'\xleftrightarrow', r'\xLeftrightarrow', r'\xhookleftarrow',
    r'\xhookrightarrow', r'\xmapsto', r'\xrightharpoondown',
    r'\xrightharpoonup', r'\xleftharpoondown', r'\xleftharpoonup',
    r'\xrightleftharpoons', r'\xleftrightharpoons', r'\xlongequal',
    r'\xtwoheadrightarrow', r'\xtwoheadleftarrow', r'\xtofrom',
    // The next 3 functions are here to support the mhchem extension.
    // Direct use of these functions is discouraged and may break someday.
    r'\xrightleftarrows', r'\xrightequilibrium', r'\xleftequilibrium',
  ]: FunctionSpec(
    numArgs: 1,
    numOptionalArgs: 1,
    handler: _arrowHandler,
  ),
};

const arrowCommandMapping = {
  r'\xleftarrow': '\u2190',
  r'\xrightarrow': '\u2192',
  r'\xleftrightarrow': '\u2194',

  r'\xLeftarrow': '\u21d0',
  r'\xRightarrow': '\u21d2',
  r'\xLeftrightarrow': '\u21d4',

  r'\xhookleftarrow': '\u21a9',
  r'\xhookrightarrow': '\u21aa',

  r'\xmapsto': '\u21a6',

  r'\xrightharpoondown': '\u21c1',
  r'\xrightharpoonup': '\u21c0',
  r'\xleftharpoondown': '\u21bd',
  r'\xleftharpoonup': '\u21bc',
  r'\xrightleftharpoons': '\u21cc',
  r'\xleftrightharpoons': '\u21cb',

  r'\xlongequal': '=',

  r'\xtwoheadleftarrow': '\u219e',
  r'\xtwoheadrightarrow': '\u21a0',

  r'\xtofrom': '\u21c4',
  r'\xrightleftarrows': '\u21c4',
  r'\xrightequilibrium': '\u21cc', // Not a perfect match.
  r'\xleftequilibrium': '\u21cb', // None better available.
};

GreenNode _arrowHandler(TexParser parser, FunctionContext context) {
  final below = parser.parseArgNode(mode: null, optional: true);
  final above = parser.parseArgNode(mode: null, optional: false)!;
  return StretchyOpNode(
    above: above.wrapWithEquationRow(),
    below: below?.wrapWithEquationRow(),
    symbol: arrowCommandMapping[context.funcName] ?? context.funcName,
  );
}
