int estimateInputTokens(String text) {
  var asciiUnits = 0;
  var nonAsciiCharacters = 0;

  for (final rune in text.runes) {
    if (rune <= 0x7f) {
      asciiUnits++;
    } else {
      nonAsciiCharacters++;
    }
  }

  return (asciiUnits + 1) ~/ 2 + (nonAsciiCharacters * 3 + 2) ~/ 3;
}

String limitTextToTokens(
  String text,
  int tokenLimit, {
  bool preserveEnds = false,
}) {
  if (tokenLimit <= 0) return '';
  if (estimateInputTokens(text) <= tokenLimit) return text;

  const marker = '\n[shortened]\n';
  final maxUnits = tokenLimit * 2;
  final markerUnits = marker.length;
  final availableUnits = maxUnits - markerUnits;
  if (availableUnits <= 0) {
    return _takePrefix(text.runes, maxUnits);
  }

  if (!preserveEnds) {
    return '${_takePrefix(text.runes, availableUnits)}$marker';
  }

  final prefixUnits = availableUnits * 2 ~/ 3;
  final suffixUnits = availableUnits - prefixUnits;
  final prefix = _takePrefix(text.runes, prefixUnits);
  final suffix = _takeSuffix(text.runes, suffixUnits);
  return '$prefix$marker$suffix';
}

String _takePrefix(Iterable<int> runes, int maxUnits) {
  final result = StringBuffer();
  var usedUnits = 0;
  for (final rune in runes) {
    final units = rune <= 0x7f ? 1 : 2;
    if (usedUnits + units > maxUnits) break;
    result.writeCharCode(rune);
    usedUnits += units;
  }
  return result.toString();
}

String _takeSuffix(Iterable<int> runes, int maxUnits) {
  final result = <int>[];
  var usedUnits = 0;
  for (final rune in runes.toList().reversed) {
    final units = rune <= 0x7f ? 1 : 2;
    if (usedUnits + units > maxUnits) break;
    result.add(rune);
    usedUnits += units;
  }
  return String.fromCharCodes(result.reversed);
}
