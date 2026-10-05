# 디자인 시스템 적용 — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [디자인 시스템](../../design.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/presentation/theme
cd apps/pawlog && flutter test            # 전체
```

## `test/presentation/theme/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `pawlog_theme_test.dart` (11) | `PawlogTheme` · `PawlogColors` · `PawlogTextStyles` · `PawlogMotion` | 라이트 바탕 · 주 색 · 오류색 · 다크 바탕 · 다크 주 색 · 연두는 모드 공통 · 연두가 `ColorScheme` 에 없음 · 입력 테두리가 `rule` 이 아니고 바탕 · 시트와 3:1 초과(P4) · 제목 고운돋움 · 본문 Pretendard · 메모 개구 · 숫자 700 + `tabularFigures` · 모서리 4 · 12 · 20 · 알약, 주 버튼 58 · 칩 체크 없음 · 선택 바탕(P2) · 간격 토큰 · 확장이 없을 때 밝기별 기본값 · `disableAnimations` → `off` |
