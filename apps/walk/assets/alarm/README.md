# 알람음 에셋

이 폴더의 소리는 모두 이 저장소에서 직접 합성했다. 외부 음원 · 샘플은 쓰지 않았다.
라이선스는 저장소 라이선스를 따른다.

| 파일 | 출처 | 목록 |
|---|---|---|
| `morning.ogg` · `marimba.ogg` · `classic.ogg` · `birds.ogg` | [tool/alarm_sounds/generate.py](../../tool/alarm_sounds/generate.py) 로 생성(설계 · 실행법은 [README](../../tool/alarm_sounds/README.md)) | 앱 소리 목록 |
| `default.wav`(비프) | 첫 알람 구현 때 합성해 넣은 22.05kHz 3초 비프(생성 스크립트는 저장소에 없다). 이미 걸린 회차가 이 경로로 울리므로 이름을 바꾸지 않는다 | 앱 소리 목록 |
| `chime.wav` · `rising.wav` | [tool/generate_alarm_sounds.py](../../tool/generate_alarm_sounds.py)(표준 라이브러리 wave 합성)로 생성 | 목록에서 뺐다. 이미 걸린 회차가 울리도록 파일만 남긴다 |

경로는 `lib/domain/alarm/entity/alarm_sound.dart` 의 `BundledAlarmSounds` 가 가리킨다.
`test/convention/alarm_assets_test.dart` 가 목록의 파일이 있는지 · ogg 가 Ogg 컨테이너인지 · 합계 500KB 미만인지 본다.
