# Life Log 설정 탭 · 프로필 — 실행 계획

스펙: [2026-11-17-walk-settings-tab-design.md](../specs/2026-11-17-walk-settings-tab-design.md)

각 단계는 실패하는 테스트 → 구현 → 통과 순서다(TDD).

1. **프로필 도메인 · 저장소**
   - `lib/domain/profile/{profile.dart, profile_repository.dart}` — `Profile`(name · bio · photo · shareNameWithAi, `aiName`).
   - `lib/data/profile/prefs_profile_repository.dart` — prefs 키 `profile.*`, 사진은 `<appDocs>/profile/avatar-<millis>.jpg`.
     사진 줄이기(512px · EXIF 없음)는 주입한 인코더(기본 `flutter_image_compress`)가 한다. 교체 · 삭제 시 이전 파일을 지운다.
   - 테스트: `test/data/profile/prefs_profile_repository_test.dart`.
2. **백업 설정 영역** — `SettingsBackupArea` 가 `profile.name` · `profile.bio` · 사진을 담는다. schema `profile: 1`.
   `profile` 이 없는 옛 백업은 지금 프로필을 둔다. 테스트: `settings_backup_area_test.dart` 보강.
3. **물어보기 이름 줄** — `ChatSession` 에 선택 인자 `ProfileRepository? profile`. `aiName` 이 있을 때만
   시스템 프롬프트 날짜 줄 앞에 이름 줄. 테스트: `chat_session_test.dart` 보강.
4. **프로필 cubit · 편집 화면** — `lib/presentation/profile/{cubit,page}`. 사진 시트(갤러리 · 카메라 · 지우기),
   이름 · 소개 · 이름 알려주기 스위치, 저장 · 버리기 확인. `MediaPicker.pickProfilePhoto`.
5. **설정 탭** — `AppSettingsPage` → `SettingsTab`(프로필 머리 · 화면 · 보안 · 데이터 · 연결 · 기록 · 기능별 설정 · 앱 정보).
   셸 넷째 탭, `SettingsTarget.app` 제거, `FeatureMenu` 의 "앱 설정" 제거 · 빈 ⋮ 숨김.
   "API 키 · 연결" 절은 행 목록으로 열어 두어 길찾기(ODsay) 키 행을 나중에 더한다.
6. **마무리** — analyze 0, 전체 테스트, `apps/walk/docs/{plan,status}.md`, 에뮬레이터 스크린샷.
