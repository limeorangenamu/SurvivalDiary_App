final RegExp _leadingBulletPattern = RegExp(
  r'^(?:[○●◎◦□■▪▫◆◇▶▷▸▹※•ㆍ][ \t]*|[-*][ \t]+)',
);

final RegExp _inlineBulletPattern = RegExp(
  r'[ \t]+[○●◎◦□■▪▫◆◇▶▷▸▹※•ㆍ][ \t]*',
);

final RegExp _sectionHeadingPattern = RegExp(
  r'^(?:지원\s*(?:내용|혜택)|주요\s*내용|사업\s*내용|정책\s*내용)\s*[:：-]?$',
);

final RegExp _sectionPrefixPattern = RegExp(
  r'^(?:지원\s*(?:내용|혜택)|주요\s*내용|사업\s*내용|정책\s*내용)\s*[:：-]\s*',
);

/// 제공처마다 다른 글머리 기호를 앱의 단일 불릿(`•`)으로 정리한다.
///
/// 원문 자체는 변경하지 않고 화면에 표시할 때만 적용한다.
String normalizePolicyText(String value) {
  final withSeparatedBullets = value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(_inlineBulletPattern, '\n• ');
  final lines = <String>[];
  var previousWasEmpty = false;

  for (final rawLine in withSeparatedBullets.split('\n')) {
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty) {
      if (lines.isNotEmpty && !previousWasEmpty) {
        lines.add('');
      }
      previousWasEmpty = true;
      continue;
    }

    final normalized = trimmed
        .replaceFirst(_leadingBulletPattern, '• ')
        .replaceAll(RegExp(r'[ \t]+'), ' ');
    lines.add(normalized);
    previousWasEmpty = false;
  }

  while (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}

/// 여러 기호가 섞인 원문을 동일한 불릿 목록에 사용할 항목으로 분리한다.
List<String> policyTextItems(String value) {
  return normalizePolicyText(value)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => line.replaceFirst(RegExp(r'^•\s*'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

/// 목록 카드에는 제공처 원문 전체 대신 첫 번째 핵심 문장만 짧게 표시한다.
String compactPolicyText(
  String value, {
  String? fallback,
  int maxLength = 52,
}) {
  final candidates = [value, if (fallback != null) fallback];
  for (final candidate in candidates) {
    final items = policyTextItems(candidate);
    for (final item in items) {
      if (_sectionHeadingPattern.hasMatch(item)) {
        continue;
      }
      final withoutHeading =
          item.replaceFirst(_sectionPrefixPattern, '').trim();
      if (withoutHeading.isEmpty) {
        continue;
      }
      final sentence = _firstSentence(withoutHeading);
      final codePoints = sentence.runes.toList(growable: false);
      if (codePoints.length <= maxLength) {
        return sentence;
      }
      final shortened = String.fromCharCodes(codePoints.take(maxLength));
      return '${shortened.trimRight()}…';
    }
  }
  return '지원 내용 확인';
}

String _firstSentence(String value) {
  var end = value.length;
  for (final marker in ['. ', '。', '; ']) {
    final index = value.indexOf(marker);
    if (index >= 0 && index + 1 < end) {
      end = index + 1;
    }
  }
  return value.substring(0, end).trim();
}
