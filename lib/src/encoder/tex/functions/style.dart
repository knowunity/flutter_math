part of '../functions.dart';

EncodeResult _styleEncoder(GreenNode node) {
  final styleNode = node as StyleNode;
  return _optionsDiffEncode(styleNode.optionsDiff, styleNode.children);
}

EncodeResult _optionsDiffEncode(OptionsDiff diff, List<dynamic> children) {
  EncodeResult res = TransparentTexEncodeResult(children);

  if (diff.size != null) {
    final sizeCommand = _sizeCommands[diff.size];
    res = TexModeCommandEncodeResult(
      command: sizeCommand ?? r'\tiny',
      children: <dynamic>[res],
    );
    if (sizeCommand == null) {
      res = NonStrictEncodeResult(
        'imprecise size',
        'Non-strict MethSize encountered during TeX encoding: '
            '${diff.size}',
        res,
      );
    }
  }

  if (diff.style != null) {
    final styleCommand = _styleCommands[diff.style];
    res = TexModeCommandEncodeResult(
      command: styleCommand ?? _styleCommands[diff.style!.uncramp()]!,
      children: <dynamic>[res],
    );
    if (styleCommand == null) {
      NonStrictEncodeResult(
        'imprecise style',
        'Non-strict MathStyle encountered during TeX encoding: '
            '${diff.style}',
        res,
      );
    }
  }

  if (diff.textFontOptions != null) {
    final command = texTextFontOptions.entries
        .firstWhereOrNull((entry) => entry.value == diff.textFontOptions)
        ?.key;
    if (command == null) {
      res = NonStrictEncodeResult(
        'unknown font',
        'Unrecognized text font encountered during TeX encoding: '
            '${diff.textFontOptions}',
        res,
      );
    } else {
      res = TexCommandEncodeResult(command: command, args: <dynamic>[res]);
    }
  }

  if (diff.mathFontOptions != null) {
    final command = texMathFontOptions.entries
        .firstWhereOrNull((entry) => entry.value == diff.mathFontOptions)
        ?.key;
    if (command == null) {
      res = NonStrictEncodeResult(
        'unknown font',
        'Unrecognized math font encountered during TeX encoding: '
            '${diff.mathFontOptions}',
        res,
      );
    } else {
      res = TexCommandEncodeResult(command: command, args: <dynamic>[res]);
    }
  }
  if (diff.color != null) {
    res = TexCommandEncodeResult(
      command: r'\textcolor',
      args: <dynamic>[
        '#${diff.color!.value.toRadixString(16).padLeft(6, '0')}',
        res,
      ],
    );
  }
  return res;
}

const _styleCommands = {
  MathStyle.display: r'\displaystyle',
  MathStyle.text: r'\textstyle',
  MathStyle.script: r'\scriptstyle',
  MathStyle.scriptscript: r'\scriptscriptstyle',
};

const _sizeCommands = {
  MathSize.tiny: r'\tiny',
  MathSize.size2: r'\tiny',
  MathSize.scriptsize: r'\scriptsize',
  MathSize.footnotesize: r'\footnotesize',
  MathSize.small: r'\small',
  MathSize.normalsize: r'\normalsize',
  MathSize.large: r'\large',
  MathSize.Large: r'\Large',
  MathSize.LARGE: r'\LARGE',
  MathSize.huge: r'\huge',
  MathSize.HUGE: r'\HUGE',
};
