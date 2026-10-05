#!/usr/bin/env python3
"""walk 앱 내장 알람음(assets/alarm/*.wav)을 합성한다. 표준 라이브러리만 쓴다.

    python3 tool/generate_alarm_sounds.py    # apps/walk 에서

모두 22.05kHz 모노 16bit PCM, 3초다. 알람은 loopAudio 로 이 3초를 반복하므로 끝은
무음으로 맞춰 이음매에서 딱 소리가 나지 않게 한다. 같은 입력이면 같은 바이트가 나온다.

- chime.wav  : 부드러운 2음 차임(감쇠 사인)
- rising.wav : 간격이 점점 짧아지는 비프

기존 비프 assets/alarm/default.wav 는 이미 걸린 회차가 그 경로로 울리므로 만들지도,
이름을 바꾸지도 않는다.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 22050
SECONDS = 3.0
FRAMES = int(RATE * SECONDS)
# 기존 비프와 같은 최대 크기(풀 스케일의 0.8).
PEAK = 0.8

ASSETS = Path(__file__).resolve().parent.parent / "assets" / "alarm"


def _envelope(t, length, attack=0.005, release=0.01):
    """[0, length) 구간의 짧은 attack · release. 클릭을 막는다."""
    if t < 0 or t >= length:
        return 0.0
    if t < attack:
        return t / attack
    if t > length - release:
        return (length - t) / release
    return 1.0


def chime():
    """딩-동. 높은 음 뒤에 낮은 음, 배음을 조금 섞은 감쇠 사인."""
    notes = [(0.0, 659.25), (0.5, 523.25)]  # E5, C5
    decay = 0.45  # 초. 진폭이 1/e 로 주는 시간
    length = 2.4  # 이 뒤로는 무음
    partials = [(1.0, 1.0), (2.0, 0.25), (3.0, 0.08)]
    samples = []
    for i in range(FRAMES):
        t = i / RATE
        value = 0.0
        for start, freq in notes:
            local = t - start
            if local < 0 or local >= length:
                continue
            amp = math.exp(-local / decay) * _envelope(local, length, attack=0.004, release=0.3)
            for ratio, weight in partials:
                value += weight * amp * math.sin(2 * math.pi * freq * ratio * local)
        samples.append(value)
    return samples


def rising():
    """880Hz 비프. 간격이 0.5초에서 0.8배씩 줄어 0.12초에서 멈춘다."""
    freq = 880.0
    beep = 0.07
    end = SECONDS - 0.2  # 반복 이음매 앞에 쉼
    starts = []
    t, gap = 0.0, 0.5
    while t + beep <= end:
        starts.append(t)
        t += gap
        gap = max(0.12, gap * 0.8)
    samples = []
    for i in range(FRAMES):
        now = i / RATE
        value = 0.0
        for start in starts:
            local = now - start
            if 0 <= local < beep:
                value = _envelope(local, beep) * math.sin(2 * math.pi * freq * local)
                break
        samples.append(value)
    return samples


def _write(name, samples):
    top = max(abs(s) for s in samples)
    scale = PEAK * 32767 / top
    frames = b"".join(struct.pack("<h", round(s * scale)) for s in samples)
    path = ASSETS / name
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)
    print(f"wrote {path} ({len(samples) / RATE:.2f}s)")


def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    _write("chime.wav", chime())
    _write("rising.wav", rising())


if __name__ == "__main__":
    main()
