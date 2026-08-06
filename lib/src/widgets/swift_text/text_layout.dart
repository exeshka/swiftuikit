part of '../swift_text.dart';

class _TextLayout {
  _TextLayout({required this.painter, required this.glyphs});

  factory _TextLayout.fromPainter(TextPainter painter, TextSpan text) {
    final styles = _StyleMap.fromSpan(text);
    final glyphs = <_Glyph>[];
    final lineIndices = <int, int>{};
    var nextLineIndex = 0;
    var offset = 0;
    for (final grapheme in text.toPlainText().characters) {
      final end = offset + grapheme.length;
      final lineBoundary = painter.getLineBoundary(
        TextPosition(offset: offset),
      );
      final lineIndex = lineIndices.putIfAbsent(
        lineBoundary.start,
        () => nextLineIndex++,
      );
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: end),
        boxHeightStyle: ui.BoxHeightStyle.tight,
        boxWidthStyle: ui.BoxWidthStyle.tight,
      );
      Rect? bounds;
      for (final box in boxes) {
        final rect = box.toRect();
        bounds = bounds == null ? rect : bounds.expandToInclude(rect);
      }
      glyphs.add(
        _Glyph(
          text: grapheme,
          bounds: bounds,
          style: styles.styleAt(offset),
          lineIndex: lineIndex,
        ),
      );
      offset = end;
    }
    return _TextLayout(painter: painter, glyphs: glyphs);
  }

  final TextPainter painter;
  final List<_Glyph> glyphs;

  void dispose() => painter.dispose();
}

class _Glyph {
  const _Glyph({
    required this.text,
    required this.bounds,
    required this.style,
    required this.lineIndex,
  });

  final String text;
  final Rect? bounds;
  final TextStyle style;
  final int lineIndex;
}

class _GlyphPair {
  const _GlyphPair({
    required this.oldGlyph,
    required this.newGlyph,
    required this.unchanged,
    this.waveIndex = -1,
    this.waveCount = 1,
  });

  final _Glyph? oldGlyph;
  final _Glyph? newGlyph;
  final bool unchanged;
  final int waveIndex;
  final int waveCount;
}

List<_GlyphPair> _pairGlyphs(
  List<_Glyph> oldGlyphs,
  List<_Glyph> newGlyphs, {
  bool numericOnly = false,
}) {
  if (numericOnly) return _pairNumericGlyphs(oldGlyphs, newGlyphs);

  final preserveStableNumericTemplate = _hasStableSingleLineNumericTemplate(
    oldGlyphs,
    newGlyphs,
  );

  final oldByLine = <int, List<_Glyph>>{};
  for (final glyph in oldGlyphs) {
    oldByLine.putIfAbsent(glyph.lineIndex, () => <_Glyph>[]).add(glyph);
  }
  final newByLine = <int, List<_Glyph>>{};
  for (final glyph in newGlyphs) {
    newByLine.putIfAbsent(glyph.lineIndex, () => <_Glyph>[]).add(glyph);
  }
  final lines = <int>{...oldByLine.keys, ...newByLine.keys}.toList()..sort();

  final result = <_GlyphPair>[];
  for (final line in lines) {
    _pairLineGlyphs(
      result,
      oldByLine[line] ?? const <_Glyph>[],
      newByLine[line] ?? const <_Glyph>[],
      preserveStableNumericTemplate: preserveStableNumericTemplate,
    );
  }
  return _assignBlockWave(result);
}

void _pairLineGlyphs(
  List<_GlyphPair> result,
  List<_Glyph> oldLine,
  List<_Glyph> newLine, {
  required bool preserveStableNumericTemplate,
}) {
  if (preserveStableNumericTemplate) {
    _pairStableNumericTemplateLine(result, oldLine, newLine);
    return;
  }

  final preservedDigits = _matchingDigits(oldLine, newLine);

  void addPair(_Glyph? oldGlyph, _Glyph? newGlyph, {required bool unchanged}) {
    result.add(
      _GlyphPair(oldGlyph: oldGlyph, newGlyph: newGlyph, unchanged: unchanged),
    );
  }

  var oldCursor = 0;
  var newCursor = 0;
  void addChangedRange(int oldEnd, int newEnd) {
    final oldLength = oldEnd - oldCursor;
    final newLength = newEnd - newCursor;
    final length = math.max(oldLength, newLength);
    for (var i = 0; i < length; i++) {
      addPair(
        i < oldLength ? oldLine[oldCursor + i] : null,
        i < newLength ? newLine[newCursor + i] : null,
        unchanged: false,
      );
    }
    oldCursor = oldEnd;
    newCursor = newEnd;
  }

  for (final match in preservedDigits) {
    addChangedRange(match.$1, match.$2);
    addPair(oldLine[match.$1], newLine[match.$2], unchanged: true);
    oldCursor = match.$1 + 1;
    newCursor = match.$2 + 1;
  }
  addChangedRange(oldLine.length, newLine.length);
}

bool _hasStableSingleLineNumericTemplate(
  List<_Glyph> oldGlyphs,
  List<_Glyph> newGlyphs,
) {
  if (oldGlyphs.isEmpty || newGlyphs.isEmpty) return false;
  if (!_isSingleVisualLine(oldGlyphs) || !_isSingleVisualLine(newGlyphs)) {
    return false;
  }
  if (!oldGlyphs.any((glyph) => _isAsciiDigit(glyph.text)) ||
      !newGlyphs.any((glyph) => _isAsciiDigit(glyph.text))) {
    return false;
  }

  final oldTemplate = oldGlyphs
      .where((glyph) => !_isAsciiDigit(glyph.text))
      .toList(growable: false);
  final newTemplate = newGlyphs
      .where((glyph) => !_isAsciiDigit(glyph.text))
      .toList(growable: false);
  if (oldTemplate.length != newTemplate.length) return false;
  for (var index = 0; index < oldTemplate.length; index++) {
    final oldGlyph = oldTemplate[index];
    final newGlyph = newTemplate[index];
    if (oldGlyph.text != newGlyph.text || oldGlyph.style != newGlyph.style) {
      return false;
    }
  }
  return true;
}

bool _isSingleVisualLine(List<_Glyph> glyphs) {
  final line = glyphs.first.lineIndex;
  return glyphs.every((glyph) => glyph.lineIndex == line);
}

void _pairStableNumericTemplateLine(
  List<_GlyphPair> result,
  List<_Glyph> oldLine,
  List<_Glyph> newLine,
) {
  final oldAnchors = <int>[
    for (var index = 0; index < oldLine.length; index++)
      if (!_isAsciiDigit(oldLine[index].text)) index,
  ];
  final newAnchors = <int>[
    for (var index = 0; index < newLine.length; index++)
      if (!_isAsciiDigit(newLine[index].text)) index,
  ];

  var oldCursor = 0;
  var newCursor = 0;
  for (var anchor = 0; anchor < oldAnchors.length; anchor++) {
    final oldAnchor = oldAnchors[anchor];
    final newAnchor = newAnchors[anchor];
    _pairNumericRange(
      result,
      oldLine,
      oldCursor,
      oldAnchor,
      newLine,
      newCursor,
      newAnchor,
    );
    result.add(
      _GlyphPair(
        oldGlyph: oldLine[oldAnchor],
        newGlyph: newLine[newAnchor],
        unchanged: true,
      ),
    );
    oldCursor = oldAnchor + 1;
    newCursor = newAnchor + 1;
  }
  _pairNumericRange(
    result,
    oldLine,
    oldCursor,
    oldLine.length,
    newLine,
    newCursor,
    newLine.length,
  );
}

void _pairNumericRange(
  List<_GlyphPair> result,
  List<_Glyph> oldLine,
  int oldStart,
  int oldEnd,
  List<_Glyph> newLine,
  int newStart,
  int newEnd,
) {
  final oldLength = oldEnd - oldStart;
  final newLength = newEnd - newStart;
  final slotCount = math.max(oldLength, newLength);
  final oldLeadingSlots = slotCount - oldLength;
  final newLeadingSlots = slotCount - newLength;
  for (var slot = 0; slot < slotCount; slot++) {
    final oldOffset = slot - oldLeadingSlots;
    final newOffset = slot - newLeadingSlots;
    final oldGlyph = oldOffset >= 0 ? oldLine[oldStart + oldOffset] : null;
    final newGlyph = newOffset >= 0 ? newLine[newStart + newOffset] : null;
    result.add(
      _GlyphPair(
        oldGlyph: oldGlyph,
        newGlyph: newGlyph,
        unchanged:
            oldGlyph != null &&
            newGlyph != null &&
            oldGlyph.text == newGlyph.text &&
            oldGlyph.style == newGlyph.style,
      ),
    );
  }
}

List<_GlyphPair> _pairNumericGlyphs(
  List<_Glyph> oldGlyphs,
  List<_Glyph> newGlyphs,
) {
  final slotCount = math.max(oldGlyphs.length, newGlyphs.length);
  final oldLeadingSlots = slotCount - oldGlyphs.length;
  final newLeadingSlots = slotCount - newGlyphs.length;
  final result = <_GlyphPair>[];

  for (var slot = 0; slot < slotCount; slot++) {
    final oldIndex = slot - oldLeadingSlots;
    final newIndex = slot - newLeadingSlots;
    final oldGlyph = oldIndex >= 0 ? oldGlyphs[oldIndex] : null;
    final newGlyph = newIndex >= 0 ? newGlyphs[newIndex] : null;
    final unchanged =
        oldGlyph != null &&
        newGlyph != null &&
        _isAsciiDigit(oldGlyph.text) &&
        oldGlyph.text == newGlyph.text &&
        oldGlyph.style == newGlyph.style &&
        oldGlyph.lineIndex == newGlyph.lineIndex;
    result.add(
      _GlyphPair(oldGlyph: oldGlyph, newGlyph: newGlyph, unchanged: unchanged),
    );
  }
  return _assignBlockWave(result);
}

List<_GlyphPair> _assignBlockWave(List<_GlyphPair> pairs) {
  final changedCount = pairs.where((pair) => !pair.unchanged).length;
  var waveIndex = 0;
  return [
    for (final pair in pairs)
      _GlyphPair(
        oldGlyph: pair.oldGlyph,
        newGlyph: pair.newGlyph,
        unchanged: pair.unchanged,
        waveIndex: pair.unchanged ? -1 : waveIndex++,
        waveCount: changedCount,
      ),
  ];
}

List<(int, int)> _matchingDigits(
  List<_Glyph> oldGlyphs,
  List<_Glyph> newGlyphs,
) {
  bool canPreserve(_Glyph oldGlyph, _Glyph newGlyph) {
    return _isAsciiDigit(oldGlyph.text) &&
        oldGlyph.text == newGlyph.text &&
        oldGlyph.style == newGlyph.style &&
        oldGlyph.lineIndex == newGlyph.lineIndex;
  }

  final result = <(int, int)>[];
  final sharedLength = math.min(oldGlyphs.length, newGlyphs.length);
  for (var index = 0; index < sharedLength; index++) {
    if (canPreserve(oldGlyphs[index], newGlyphs[index])) {
      result.add((index, index));
    }
  }
  return result;
}

bool _isAsciiDigit(String grapheme) {
  if (grapheme.length != 1) return false;
  final codeUnit = grapheme.codeUnitAt(0);
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}

bool? _detectCountsDown(String from, String to) {
  final fromNumbers = _numericValues(from);
  final toNumbers = _numericValues(to);
  if (fromNumbers.isEmpty || toNumbers.isEmpty) return null;
  final sharedLength = math.min(fromNumbers.length, toNumbers.length);
  for (var index = 0; index < sharedLength; index++) {
    final comparison = toNumbers[index].compareTo(fromNumbers[index]);
    if (comparison < 0) return true;
    if (comparison > 0) return false;
  }
  return null;
}

final _numericCandidatePattern = RegExp(
  r"[+\-−]?\d+(?:[.,'’ \u00a0\u202f]\d+)*",
);
final _numericGroupingSeparatorPattern = RegExp(r"['’ \u00a0\u202f]");
final _leadingDigitsPattern = RegExp(r'^\d+');

List<_NumericValue> _numericValues(String text) {
  return <_NumericValue>[
    for (final match in _numericCandidatePattern.allMatches(text))
      ..._parseNumericCandidate(match.group(0)!),
  ];
}

List<_NumericValue> _parseNumericCandidate(String candidate) {
  var body = candidate;
  var negative = false;
  if (body.startsWith('-') || body.startsWith('−')) {
    negative = true;
    body = body.substring(1);
  } else if (body.startsWith('+')) {
    body = body.substring(1);
  }

  final groupingChunks = body.split(_numericGroupingSeparatorPattern);
  if (groupingChunks.length > 1) {
    final validGrouping = groupingChunks.skip(1).every((chunk) {
      final digits = _leadingDigitsPattern.firstMatch(chunk)?.group(0);
      return digits?.length == 3;
    });
    if (validGrouping) {
      body = groupingChunks.join();
    } else {
      return <_NumericValue>[
        for (var index = 0; index < groupingChunks.length; index++)
          if (groupingChunks[index].isNotEmpty)
            ..._parseNumericCandidate(
              '${negative && index == 0 ? '-' : ''}${groupingChunks[index]}',
            ),
      ];
    }
  }

  final dots = '.'.allMatches(body).length;
  final commas = ','.allMatches(body).length;
  String? decimalSeparator;
  if (dots > 0 && commas > 0) {
    decimalSeparator = body.lastIndexOf('.') > body.lastIndexOf(',')
        ? '.'
        : ',';
  } else if (dots > 0 || commas > 0) {
    final separator = dots > 0 ? '.' : ',';
    final parts = body.split(separator);
    final isGrouping =
        parts.length > 1 && parts.skip(1).every((part) => part.length == 3);
    if (!isGrouping) decimalSeparator = separator;
  }

  var scale = 0;
  String digits;
  if (decimalSeparator == null) {
    digits = body.replaceAll('.', '').replaceAll(',', '');
  } else {
    final decimalIndex = body.lastIndexOf(decimalSeparator);
    final integer = body
        .substring(0, decimalIndex)
        .replaceAll('.', '')
        .replaceAll(',', '');
    final fraction = body.substring(decimalIndex + 1);
    digits = '$integer$fraction';
    scale = fraction.length;
  }
  if (digits.isEmpty) return const <_NumericValue>[];
  var units = BigInt.parse(digits);
  if (negative) units = -units;
  return <_NumericValue>[_NumericValue(units, scale)];
}

class _NumericValue implements Comparable<_NumericValue> {
  const _NumericValue(this.units, this.scale);

  final BigInt units;
  final int scale;

  @override
  int compareTo(_NumericValue other) {
    final commonScale = math.max(scale, other.scale);
    final left = units * BigInt.from(10).pow(commonScale - scale);
    final right = other.units * BigInt.from(10).pow(commonScale - other.scale);
    return left.compareTo(right);
  }
}

const _numericSeparators = <String>{
  '+',
  '-',
  '−',
  '.',
  ',',
  "'",
  '’',
  ' ',
  '\u00a0',
  '\u202f',
};

bool _isNumericGlyphSequence(List<_Glyph> glyphs) {
  var hasDigit = false;
  for (final glyph in glyphs) {
    if (_isAsciiDigit(glyph.text)) {
      hasDigit = true;
    } else if (!_numericSeparators.contains(glyph.text)) {
      return false;
    }
  }
  return hasDigit;
}

class _StyleRun {
  const _StyleRun(this.start, this.end, this.style);
  final int start;
  final int end;
  final TextStyle style;
}

class _StyleMap {
  const _StyleMap(this.runs, this.fallback);

  factory _StyleMap.fromSpan(TextSpan span) {
    final runs = <_StyleRun>[];
    final fallback = const TextStyle().merge(span.style);
    _collectRuns(span, const TextStyle(), 0, runs);
    return _StyleMap(runs, fallback);
  }

  final List<_StyleRun> runs;
  final TextStyle fallback;

  TextStyle styleAt(int offset) {
    for (final run in runs) {
      if (offset >= run.start && offset < run.end) return run.style;
    }
    return fallback;
  }

  static int _collectRuns(
    TextSpan span,
    TextStyle inherited,
    int offset,
    List<_StyleRun> output,
  ) {
    final style = inherited.merge(span.style);
    final ownText = span.text;
    if (ownText != null && ownText.isNotEmpty) {
      output.add(_StyleRun(offset, offset + ownText.length, style));
      offset += ownText.length;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      if (child is TextSpan) {
        offset = _collectRuns(child, style, offset, output);
      } else {
        offset += child.toPlainText().length;
      }
    }
    return offset;
  }
}
