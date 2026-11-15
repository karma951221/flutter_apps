# 알람 벨소리 합성

[`generate.py`](generate.py) 가 walk 앱 내장 알람 벨소리 4개(`assets/alarm/*.ogg`)를 numpy 로 직접 합성한다.
외부 음원은 쓰지 않는다. 출처 · 라이선스는 [assets/alarm/README.md](../../assets/alarm/README.md).
설계 근거는 [알람 벨소리 스펙 §5](../../../../docs/superpowers/specs/2026-11-16-walk-alarm-ringtone-design.md).

## 실행

`apps/walk` 에서:

```bash
python3 -m venv .venv && .venv/bin/pip install numpy soundfile
.venv/bin/python tool/alarm_sounds/generate.py
```

`.venv/` 는 `apps/walk/.gitignore` 에 있어 커밋되지 않는다. 출력은 `assets/alarm/` 에 덮어쓴다.
ffmpeg · sox · oggenc 없이 `soundfile` 휠에 들어 있는 libsndfile 의 Vorbis 인코더만 쓴다.

마지막으로 만든 환경:

| 도구 | 버전 |
|---|---|
| Python | 3.9.6 (macOS 기본) |
| numpy | 2.0.2 |
| soundfile | 0.13.1 |
| libsndfile | 1.2.2 (soundfile 휠 내장, OGG Vorbis) |

## 공통 규칙

- 44.1kHz 모노 float 로 합성 → OGG Vorbis(기본 품질)로 쓴다.
- 길이 3~6초. 알람이 반복 재생하므로 끝 50ms 를 0 으로, 처음 2ms 를 0 에서 감쇠해 이음매에서 튀지 않게 한다.
- 피크 -1dBFS 로 정규화(Vorbis 손실 압축 뒤에는 피크가 조금 넘칠 수 있다 — 새소리 약 -0.15dBFS).
- 난수 seed 고정(`20261116`). 다시 실행하면 디코딩한 파형은 같다. 다만 Ogg 스트림 일련번호를
  libsndfile 이 무작위로 정하므로 **파일 바이트는 실행마다 달라진다** — 소리를 바꾼 게 아니면 다시 커밋하지 않는다.

## 소리별 설계

| 파일 | 길이 | 설계 |
|---|---|---|
| `morning.ogg` | 4.2초 | 도-미-솔-도 를 맑은 벨(기음 + 2 · 3배 + 살짝 어긋난 4.2배 배음, 높은 배음일수록 빨리 감쇠)로 두 번 오르고, 두 번째는 한 옥타브 위 미 까지 올라 화음으로 닫는다 |
| `marimba.ogg` | 3.4초 | 마림바 막대 모드(1 : 3.93 : 9.9) 의 짧은 감쇠 + 채가 닿는 2ms 잡음으로 솔-도-미-도-솔 … 두 마디 멜로디, 박자마다 낮은 음 |
| `classic.ogg` | 3.0초 | 조금 다른 두 금속 벨(1250 · 1330Hz, 원판 벨 배음 1 · 2.32 · 4.25 · 6.63)을 초당 20번 번갈아 두드리는 1초 울림 + 0.5초 쉼, 두 번 |
| `birds.ogg` | 5.0초 | 높은 새는 아래로 휘는 짧은 지저귐 3~5개 묶음, 낮은 새는 위로 휘는 '휘-익' + 떨림으로 답한다 |
