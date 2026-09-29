import 'dart:convert';

import 'package:flet/flet.dart';
import 'package:flutter/material.dart';

class _Rule {
  _Rule({required this.pattern, required this.color, this.before, this.after, this.ignoreIf});
  final RegExp pattern;
  final Color color;
  final String? before;
  final String? after;
  final String? ignoreIf;
}

class _Pair {
  _Pair({required this.open, required this.close, this.color, required this.unmatchedColor});
  final String open;
  final String close;
  final Color? color;
  final Color unmatchedColor;
}

Color _parseColor(String? value, Color fallback) {
  if (value == null || value.isEmpty) return fallback;
  final clean = value.replaceFirst('#', '');
  final hex = clean.length == 6 ? 'FF$clean' : clean;
  final number = int.tryParse(hex, radix: 16);
  return number == null ? fallback : Color(number);
}

List<_Rule> _parseRules(String raw) {
  try {
    final data = jsonDecode(raw) as List<dynamic>;
    final result = <_Rule>[];
    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      final forms = (map['forms'] as List<dynamic>? ?? const []).map((v) => v.toString()).toList();
      if (forms.isEmpty) continue;
      try {
        result.add(_Rule(
          pattern: RegExp(forms.map((form) => '(?:$form)').join('|')),
          color: _parseColor(map['color']?.toString(), Colors.white),
          before: map['before'] as String?,
          after: map['after'] as String?,
          ignoreIf: map['ignore_if'] as String?,
        ));
      } on FormatException {
        
      }
    }
    return result;
  } catch (_) {
    return const [];
  }
}

List<_Pair> _parsePairs(String raw) {
  try {
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return _Pair(
        open: map['open']?.toString() ?? '',
        close: map['close']?.toString() ?? '',
        color: map['color'] == null ? null : _parseColor(map['color'].toString(), Colors.white),
        unmatchedColor: _parseColor(map['unmatched_color']?.toString(), Colors.red),
      );
    }).where((item) => item.open.isNotEmpty && item.close.isNotEmpty).toList();
  } catch (_) {
    return const [];
  }
}

class _EditorController extends TextEditingController {
  _EditorController({
    super.text,
    required this.rules,
    required this.pairs,
    required this.defaultColor,
    required this.strict,
    required this.errorColor,
  });

  List<_Rule> rules;
  List<_Pair> pairs;
  Color defaultColor;
  bool strict;
  Color errorColor;

  bool _validContext(_Rule rule, String source, int start, int end) {
    if (rule.before != null) {
      try {
        if (!RegExp('${rule.before!}\$').hasMatch(source.substring(0, start))) return false;
      } on FormatException {
        return false;
      }
    }
    if (rule.after != null) {
      try {
        if (RegExp(rule.after!).matchAsPrefix(source.substring(end)) == null) return false;
      } on FormatException {
        return false;
      }
    }
    if (rule.ignoreIf != null) {
      try {
        if (RegExp(rule.ignoreIf!).matchAsPrefix(source.substring(start)) != null) return false;
      } on FormatException {
        return false;
      }
    }
    return true;
  }

  Map<int, Color> _pairOverrides(String source) {
    final result = <int, Color>{};
    for (final pair in pairs) {
      if (pair.open == pair.close) {
        final positions = <int>[];
        for (var i = 0; i <= source.length - pair.open.length;) {
          if (source.startsWith(pair.open, i)) {
            positions.add(i);
            i += pair.open.length;
          } else {
            i++;
          }
        }
        for (var i = 0; i < positions.length; i++) {
          if (positions.length.isOdd && i == positions.length - 1) {
            result[positions[i]] = pair.unmatchedColor;
          } else if (pair.color != null) {
            result[positions[i]] = pair.color!;
          }
        }
        continue;
      }

      final stack = <int>[];
      for (var i = 0; i < source.length;) {
        if (source.startsWith(pair.open, i)) {
          stack.add(i);
          i += pair.open.length;
        } else if (source.startsWith(pair.close, i)) {
          if (stack.isEmpty) {
            result[i] = pair.unmatchedColor;
          } else {
            final open = stack.removeLast();
            if (pair.color != null) {
              result[open] = pair.color!;
              result[i] = pair.color!;
            }
          }
          i += pair.close.length;
        } else {
          i++;
        }
      }
      for (final open in stack) {
        result[open] = pair.unmatchedColor;
      }
    }
    return result;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final source = text;
    if (source.isEmpty) return TextSpan(text: '', style: style);

    final colors = List<Color?>.filled(source.length, null);
    for (final rule in rules) {
      for (final match in rule.pattern.allMatches(source)) {
        if (!_validContext(rule, source, match.start, match.end)) continue;
        for (var i = match.start; i < match.end; i++) {
          colors[i] = rule.color;
        }
      }
    }

    final fallback = strict ? errorColor : defaultColor;
    for (var i = 0; i < colors.length; i++) {
      colors[i] ??= fallback;
    }
    for (final entry in _pairOverrides(source).entries) {
      colors[entry.key] = entry.value;
    }

    final spans = <TextSpan>[];
    var start = 0;
    var current = colors[0]!;
    for (var i = 1; i < source.length; i++) {
      if (colors[i] != current) {
        spans.add(TextSpan(text: source.substring(start, i), style: style?.copyWith(color: current)));
        start = i;
        current = colors[i]!;
      }
    }
    spans.add(TextSpan(text: source.substring(start), style: style?.copyWith(color: current)));
    return TextSpan(style: style, children: spans);
  }
}

class FletCodeEditorControl extends StatefulWidget {
  const FletCodeEditorControl({super.key, required this.control});
  final Control control;

  @override
  State<FletCodeEditorControl> createState() => _FletCodeEditorControlState();
}

class _FletCodeEditorControlState extends State<FletCodeEditorControl> {
  late _EditorController _controller;
  String _lastValue = '';

  void _configure() {
    _controller.rules = _parseRules(widget.control.getString('rules', '[]') ?? '[]');
    _controller.pairs = _parsePairs(widget.control.getString('pairs', '[]') ?? '[]');
    _controller.defaultColor = _parseColor(widget.control.getString('default_color', '#000000'), Colors.black);
    _controller.strict = widget.control.getBool('strict', false) ?? false;
    _controller.errorColor = _parseColor(widget.control.getString('error_color', '#FF0000'), Colors.red);
    _controller.notifyListeners();
  }

  @override
  void initState() {
    super.initState();
    _lastValue = widget.control.getString('value', '') ?? '';
    _controller = _EditorController(
      text: _lastValue,
      rules: _parseRules(widget.control.getString('rules', '[]') ?? '[]'),
      pairs: _parsePairs(widget.control.getString('pairs', '[]') ?? '[]'),
      defaultColor: _parseColor(widget.control.getString('default_color', '#000000'), Colors.black),
      strict: widget.control.getBool('strict', false) ?? false,
      errorColor: _parseColor(widget.control.getString('error_color', '#FF0000'), Colors.red),
    )..addListener(_onLocalChange);
  }

  void _onLocalChange() {
    final value = _controller.text;
    if (value == _lastValue) return;
    _lastValue = value;
    widget.control.triggerEvent('change', value);
  }

  @override
  void didUpdateWidget(covariant FletCodeEditorControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
    final value = widget.control.getString('value', '') ?? '';
    if (value != _lastValue && value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      _lastValue = value;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onLocalChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.control.getDouble('font_size') ?? 14.0;
    final fontFamily = widget.control.getString('font_family', 'monospace') ?? 'monospace';
    final background = widget.control.getColor('background_color', context) ?? const Color(0xFF202124);
    return LayoutControl(
      control: widget.control,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background),
        child: TextField(
          controller: _controller,
          minLines: 12,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textAlignVertical: TextAlignVertical.top,
          style: TextStyle(fontFamily: fontFamily, fontSize: fontSize, height: 1.35),
          cursorColor: Colors.lightBlueAccent,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ),
    );
  }
}
