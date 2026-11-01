import 'chat_vendor.dart';

/// 미리보기 끝에 붙는 점. 길이를 드러내지 않게 늘 4개.
const apiKeyMaskDots = '••••';

/// 키 접두사 표(정규식 원문). 벤더가 null 이면 그 접두사는 어느 벤더 키도 아니다
/// (관리 키 등). 가장 길게 맞는 줄이 이긴다.
const chatKeyPrefixes = <(ChatVendor?, String)>[
  (ChatVendor.anthropic, r'sk-ant-api\d+-'),
  (null, 'sk-ant-'),
  (null, 'sk-admin-'),
  (ChatVendor.openai, 'sk-svcacct-'),
  (ChatVendor.openai, 'sk-proj-'),
  (ChatVendor.openai, 'sk-'),
];

/// [key] 앞에 맞는 가장 긴 접두사 줄. 없으면 null.
(ChatVendor?, String)? _longestPrefix(
  String key, {
  bool Function(ChatVendor? vendor)? where,
}) {
  (ChatVendor?, String)? best;
  for (final (vendor, pattern) in chatKeyPrefixes) {
    if (where != null && !where(vendor)) continue;
    final match = RegExp('^$pattern').matchAsPrefix(key);
    if (match == null) continue;
    final text = match[0]!;
    if (best == null || text.length > best.$2.length) best = (vendor, text);
  }
  return best;
}

/// 벤더 공개 접두사 + 본문 앞 4글자 + `••••`(Q3). 접두사가 안 맞으면 앞 4글자 + `••••`
/// (모르는 키는 4글자 넘게 보이지 않는다),
/// 8글자 미만이면 `••••`. 접두사 뒤 본문이 4글자 미만이면 접두사 + `••••`.
String maskApiKey(ChatVendor vendor, String key) {
  final prefix = _longestPrefix(key, where: (v) => v == vendor)?.$2;
  if (prefix == null) {
    return key.length < 8
        ? apiKeyMaskDots
        : '${key.substring(0, 4)}$apiKeyMaskDots';
  }
  final body = key.substring(prefix.length);
  if (body.length < 4) return '$prefix$apiKeyMaskDots';
  return '$prefix${body.substring(0, 4)}$apiKeyMaskDots';
}

/// 키 모양으로 벤더를 짐작한다. 모르면 null.
/// anthropic: `^sk-ant-api\d+-`(그 밖의 `sk-ant-` 는 null — 관리 키 등).
/// openai: `sk-proj-` · `sk-svcacct-` · `sk-`(옛 형식) — `sk-ant-` · `sk-admin-` 는 아님.
/// 가장 긴 접두사부터 맞춘다.
ChatVendor? vendorOfKey(String key) => _longestPrefix(key)?.$1;

/// 입력 안내에 보일 그 벤더 접두사(anthropic → `sk-ant-`).
String chatKeyPrefixHint(ChatVendor vendor) => switch (vendor) {
  ChatVendor.anthropic => 'sk-ant-',
  ChatVendor.openai => 'sk-',
};
