import 'chat_model.dart';
import 'chat_vendor.dart';

// 벤더별 모델 계열 규칙(키 입력 기획 §6.3 · §6.4 · §10.1 · Q10 · Q11).
//
// 앱 코드에는 모델 id 를 두지 않는다 — 계열 정규식 · 제외 낱말만. 아래 표는
// 구현 전 확인(A2 · A3 · O3 · O4 · O5) 대상이라 이 파일 한 곳에 모은다.

/// 빠른 출력을 지원하는 모델 묶음 하나. 구현 전 확인(A2 · O5) 전에는 표가 비어 있다.
final class FastModeSpec {
  const FastModeSpec({required this.pattern, required this.priceFactor});

  final RegExp pattern;

  /// 요금 배수(안내 문구 "약 ○배"). 정수면 정수로 보인다.
  final double priceFactor;
}

/// 벤더별 빠른 출력 지원 표. 확인 뒤 한 줄씩 더한다.
const Map<ChatVendor, List<FastModeSpec>> fastModeSpecs = {
  ChatVendor.anthropic: [],
  ChatVendor.openai: [],
};

// --- 표(O4 · A3 · O3) -------------------------------------------------------

/// OpenAI 목록에서 채팅용이 아닌 모델을 가르는 낱말. id 에 들어 있으면 뺀다.
const List<String> _openAiExcludedWords = [
  'embedding',
  'tts',
  'whisper',
  'transcribe',
  'audio',
  'realtime',
  'image',
  'dall-e',
  'moderation',
  'search',
  'codex',
  'instruct',
  'babbage',
  'davinci',
];

/// 도구 호출을 받지 않는 OpenAI 모델(확인 전 추정, O4).
const List<String> _openAiNoTools = [r'^o1-mini', r'^o1-preview'];

/// 이미지 입력을 받지 않는 OpenAI 모델(확인 전 추정, O4).
const List<String> _openAiNoImages = [
  r'^gpt-3\.5',
  r'^gpt-4(-\d{4})?$',
  r'^gpt-4-\d{4}-preview$',
  r'^gpt-4-turbo-preview$',
  r'^o1-mini',
  r'^o1-preview',
  r'^o3-mini',
];

/// 이미지 입력을 받지 않는 Anthropic 모델. 지금 목록은 모두 받는다.
const List<String> _anthropicNoImages = [];

/// Anthropic 모델 id 의 계열 · 메이저 · 마이너. `claude-sonnet-4-5-20250929` →
/// (sonnet, 4, 5), `claude-sonnet-4-20250514` → (sonnet, 4, 0) — 날짜는 마이너가 아니다.
/// 옛 이름(`claude-3-5-sonnet-…`)은 맞지 않는다.
final RegExp _anthropicVersion = RegExp(
  r'^claude-([a-z]+)-(\d+)(?:-(\d{1,2}))?(?!\d)',
);
const String _openAiReasoningPattern = r'^o\d';
const String _openAiEffortGptPattern = r'^gpt-(\d+)';
const int _openAiEffortMinMajor = 5;

// --- 계열 ------------------------------------------------------------------

final RegExp _anthropicAllowed = RegExp(r'^claude-');
final RegExp _openAiAllowed = RegExp(r'^(?:gpt-\d|o\d)');
final RegExp _anthropicRecommended = RegExp(r'^claude-sonnet-');
final RegExp _openAiFlagship = RegExp(
  r'^(gpt-\d+(?:\.\d+)?)(-\d{4}-\d{2}-\d{2})?$',
);

bool _matchesAny(List<String> patterns, String id) =>
    patterns.any((p) => RegExp(p).hasMatch(id));

/// 채팅에 쓸 모델만 남기고 최신순으로 정렬한다(§6.3 거르기 1~3).
/// - 벤더가 능력을 줬으면(supportsTools == false) 그걸로 뺀다.
/// - anthropic: `^claude-` 전부. openai: `^gpt-\d` · `^o\d` 만, 제외 낱말 포함 id 와
///   도구 미지원 표에 맞는 id 는 뺀다(벤더가 도구 지원을 알려 줬으면 표는 보지 않는다).
/// - 정렬: createdAt 내림차순, createdAt 이 없으면 입력 순서를 뒤에 그대로(안정 정렬).
List<ModelInfo> chatModelsOf(ChatVendor vendor, List<ModelInfo> raw) {
  bool keep(ModelInfo m) {
    if (m.supportsTools == false) return false;
    final id = m.id;
    return switch (vendor) {
      ChatVendor.anthropic => _anthropicAllowed.hasMatch(id),
      ChatVendor.openai =>
        _openAiAllowed.hasMatch(id) &&
            !_openAiExcludedWords.any(id.contains) &&
            (m.supportsTools == true || !_matchesAny(_openAiNoTools, id)),
    };
  }

  final indexed = [
    for (final (i, m) in raw.indexed)
      if (keep(m)) (i, m),
  ];
  indexed.sort((a, b) {
    final ca = a.$2.createdAt;
    final cb = b.$2.createdAt;
    if (ca != null && cb != null) {
      final byDate = cb.compareTo(ca);
      if (byDate != 0) return byDate;
    } else if (ca != null) {
      return -1;
    } else if (cb != null) {
      return 1;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final (_, m) in indexed) m];
}

/// 추천 계열의 최신(Q11). [models] 는 chatModelsOf 결과(최신순). 계열이 없으면 첫 항목, 비었으면 null.
/// anthropic: `^claude-sonnet-` 첫 항목.
/// openai: 플래그십 `^gpt-\d+(\.\d+)?(-\d{4}-\d{2}-\d{2})?$` 를 날짜 뺀 이름으로 묶어,
///   묶음 안 최대 createdAt 이 가장 늦은 묶음 → 그 안에서 날짜 없는 별칭, 없으면 가장 늦은 스냅샷.
String? recommendedModelOf(ChatVendor vendor, List<ModelInfo> models) {
  if (models.isEmpty) return null;
  final recommended = switch (vendor) {
    ChatVendor.anthropic => _firstWhereOrNull(
      models,
      (m) => _anthropicRecommended.hasMatch(m.id),
    )?.id,
    ChatVendor.openai => _openAiFlagshipOf(models),
  };
  return recommended ?? models.first.id;
}

ModelInfo? _firstWhereOrNull(
  List<ModelInfo> models,
  bool Function(ModelInfo) test,
) {
  for (final m in models) {
    if (test(m)) return m;
  }
  return null;
}

String? _openAiFlagshipOf(List<ModelInfo> models) {
  // 묶음 이름 → 그 묶음의 모델(입력 = 최신순 그대로).
  final groups = <String, List<ModelInfo>>{};
  for (final m in models) {
    final match = _openAiFlagship.firstMatch(m.id);
    if (match == null) continue;
    groups.putIfAbsent(match.group(1)!, () => []).add(m);
  }
  if (groups.isEmpty) return null;

  DateTime? latestOf(List<ModelInfo> group) {
    DateTime? latest;
    for (final m in group) {
      final c = m.createdAt;
      if (c != null && (latest == null || c.isAfter(latest))) latest = c;
    }
    return latest;
  }

  // 최대 createdAt 이 가장 늦은 묶음. 같으면(또는 모두 없으면) 먼저 나온 묶음.
  List<ModelInfo>? best;
  DateTime? bestLatest;
  for (final group in groups.values) {
    final latest = latestOf(group);
    if (best == null ||
        (latest != null &&
            (bestLatest == null || latest.isAfter(bestLatest)))) {
      best = group;
      bestLatest = latest;
    }
  }

  final alias = _firstWhereOrNull(
    best!,
    (m) => _openAiFlagship.firstMatch(m.id)!.group(2) == null,
  );
  if (alias != null) return alias.id;
  // 스냅샷만 — 목록이 최신순이라 첫 항목이 가장 늦은 스냅샷.
  return best.first.id;
}

/// 이미지 입력 가능 여부. ModelInfo.supportsImages 가 있으면 그것, 없으면 이미지 미지원 표, 모르면 true(§6.4).
bool supportsImagesOf(ChatVendor vendor, ModelInfo model) {
  final known = model.supportsImages;
  if (known != null) return known;
  final table = switch (vendor) {
    ChatVendor.anthropic => _anthropicNoImages,
    ChatVendor.openai => _openAiNoImages,
  };
  return !_matchesAny(table, model.id);
}

/// 생각 수준 파라미터를 받는가(A3 · O3). 아니면 어댑터가 필드를 뺀다.
bool supportsEffortOf(ChatVendor vendor, String modelId) {
  int? majorOf(String pattern) {
    final match = RegExp(pattern).firstMatch(modelId);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  switch (vendor) {
    case ChatVendor.anthropic:
      // A3(문서 확인됨): 4.6 이상 · 5.x 이상과 Opus 4.5 만 받는다. Sonnet 4.5 ·
      // Haiku 4.5 와 그 이전은 오류를 낸다.
      final v = _anthropicVersionOf(modelId);
      if (v == null) return false;
      final (family, major, minor) = v;
      return major >= 5 ||
          (major == 4 && minor >= 6) ||
          (major == 4 && minor == 5 && family == 'opus');
    case ChatVendor.openai:
      if (RegExp(_openAiReasoningPattern).hasMatch(modelId)) return true;
      final major = majorOf(_openAiEffortGptPattern);
      return major != null && major >= _openAiEffortMinMajor;
  }
}

/// 서버 쪽 대체(`fallbacks: "default"` + server-side-fallback beta)를 받는가.
/// 문서에 적힌 계열만: Fable 5.1 · Opus 5 / 5.5 · Sonnet 5.5(과 그 뒤 버전). 그 밖은
/// 필드도 beta 헤더도 보내지 않는다. Anthropic 전용.
bool supportsFallbacksOf(String modelId) {
  final v = _anthropicVersionOf(modelId);
  if (v == null) return false;
  final (family, major, minor) = v;
  final (minMajor, minMinor) = switch (family) {
    'fable' => (5, 1),
    'opus' => (5, 0),
    'sonnet' => (5, 5),
    _ => (null, null),
  };
  if (minMajor == null || minMinor == null) return false;
  return major > minMajor || (major == minMajor && minor >= minMinor);
}

(String, int, int)? _anthropicVersionOf(String modelId) {
  final match = _anthropicVersion.firstMatch(modelId);
  if (match == null) return null;
  final major = int.tryParse(match.group(2)!);
  if (major == null) return null;
  final minor = int.tryParse(match.group(3) ?? '0') ?? 0;
  return (match.group(1)!, major, minor);
}

/// 빠른 출력 지원이면 그 spec, 아니면 null. [specs] 는 테스트 주입용.
FastModeSpec? fastModeOf(
  ChatVendor vendor,
  String modelId, {
  Map<ChatVendor, List<FastModeSpec>> specs = fastModeSpecs,
}) {
  for (final spec in specs[vendor] ?? const <FastModeSpec>[]) {
    if (spec.pattern.hasMatch(modelId)) return spec;
  }
  return null;
}
