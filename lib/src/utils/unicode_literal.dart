String fixedHex(int number, int length) {
  return number.toRadixString(16).toUpperCase().padLeft(length, '0');
}

/* Creates a unicode literal based on the string */
String unicodeLiteral(String str, {bool escape = false}) =>
    str.split('').map((e) {
      if (e.codeUnitAt(0) > 126 || e.codeUnitAt(0) < 32) {
        return '\\u${fixedHex(e.codeUnitAt(0), 4)}';
      } else if (escape && (e == "'" || e == r'$')) {
        return '\\$e';
      } else {
        return e;
      }
    }).join();
