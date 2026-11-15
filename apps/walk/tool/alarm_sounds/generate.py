#!/usr/bin/env python3
"""walk 앱 내장 알람 벨소리(assets/alarm/*.ogg)를 직접 합성한다.

    # apps/walk 에서
    python3 -m venv .venv && .venv/bin/pip install numpy soundfile
    .venv/bin/python tool/alarm_sounds/generate.py

모두 44.1kHz 모노 OGG Vorbis, 3~6초짜리 한 마디다. 알람은 loopAudio 로 이 파일을 반복하므로
끝 50ms 를 0 으로 감쇠해 이음매에서 딱 소리가 나지 않게 한다. 피크는 -1dBFS 로 맞춘다.
난수는 고정 seed 라 같은 입력이면 같은 파형이 나온다.

- morning.ogg : 아침 차임 — 장3화음을 위로 오르는 맑은 벨 아르페지오, 부드러운 감쇠
- marimba.ogg : 마림바 — 나무 음색(1 · 4 · 10배 배음, 빠른 감쇠)의 짧고 밝은 멜로디
- classic.ogg : 클래식 벨 — 두 금속 벨을 약 20Hz 로 번갈아 두드리는 1초 울림 + 쉼, 두 번
- birds.ogg   : 새소리 — 주파수가 휘는 짧은 지저귐 묶음, 높낮이가 다른 두 마리

기존 wav(default · chime · rising)는 ../generate_alarm_sounds.py 가 만든 것이고 여기서 건드리지 않는다.
"""

from pathlib import Path

import numpy as np
import soundfile as sf

RATE = 44100
PEAK_DBFS = -1.0
TAIL_FADE = 0.05  # 초. 루프 이음매용 끝 감쇠
SEED = 20261116

ASSETS = Path(__file__).resolve().parents[2] / "assets" / "alarm"


def note(name):
    """'A4' · 'C#5' 같은 음 이름 → 주파수(Hz). A4 = 440."""
    steps = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    letter, rest = name[0], name[1:]
    shift = 0
    if rest.startswith("#"):
        shift, rest = 1, rest[1:]
    elif rest.startswith("b"):
        shift, rest = -1, rest[1:]
    semitones = steps[letter] + shift + (int(rest) - 4) * 12
    return 440.0 * 2 ** (semitones / 12)


def timeline(seconds):
    return np.zeros(int(RATE * seconds))


def add_partials(out, start, freq, partials, attack=0.003, gain=1.0, length=None):
    """start(초)부터 감쇠 사인 배음 묶음을 더한다. partials = [(배율, 세기, 감쇠 시간 τ초), …]."""
    begin = max(0, int(start * RATE))
    end = len(out) if length is None else min(len(out), begin + int(length * RATE))
    t = np.arange(end - begin) / RATE
    onset = np.minimum(t / attack, 1.0)  # 짧은 attack 으로 클릭을 막는다
    for ratio, weight, tau in partials:
        f = freq * ratio
        if f >= RATE / 2:
            continue
        out[begin:end] += gain * weight * onset * np.exp(-t / tau) * np.sin(2 * np.pi * f * t)


def finish(signal):
    """처음 2ms 를 0 에서 올리고 끝 50ms 를 0 으로 감쇠한 뒤 피크를 -1dBFS 로 맞춘다."""
    signal = signal - np.mean(signal)  # DC 제거
    head = int(0.002 * RATE)
    signal[:head] *= np.linspace(0, 1, head)
    fade = int(TAIL_FADE * RATE)
    signal[-fade:] *= 0.5 * (1 + np.cos(np.linspace(0, np.pi, fade)))
    signal[-1] = 0.0
    peak = np.max(np.abs(signal))
    return signal * (10 ** (PEAK_DBFS / 20) / peak)


def morning(rng):
    """도-미-솔-도 를 두 번 오른다. 두 번째는 한 옥타브 위 미 까지 올라 마무리. 4.2초."""
    out = timeline(4.2)
    # 맑은 벨: 기음 + 약한 2 · 3배 + 살짝 어긋난 4.2배(쇳소리). 높은 배음일수록 빨리 사라진다.
    bell = [(1.0, 1.0, 0.9), (1.003, 0.35, 0.9), (2.0, 0.28, 0.45), (3.0, 0.1, 0.25), (4.2, 0.06, 0.12)]
    step = 0.17
    phrases = [
        (0.0, ["C5", "E5", "G5", "C6"]),
        (1.6, ["C5", "E5", "G5", "C6", "E6"]),
    ]
    for start, names in phrases:
        for i, name in enumerate(names):
            gain = 0.75 + 0.08 * i + rng.uniform(-0.03, 0.03)  # 위로 갈수록 조금 또렷하게
            add_partials(out, start + i * step, note(name), bell, attack=0.004, gain=gain)
    # 마지막 음 아래에 화음을 깔아 차임이 한 번 '닫히게' 한다.
    for name in ["C5", "G5"]:
        add_partials(out, 1.6 + 4 * step, note(name), bell, attack=0.01, gain=0.3)
    return out


def marimba(rng):
    """솔-도-미-도-솔 … 로 뛰노는 두 마디. 아래에 낮은 음을 박자마다 둔다. 3.4초."""
    out = timeline(3.4)
    # 마림바 막대의 진동 모드는 대략 1 : 4 : 10. 높은 모드는 순식간에 사라진다.
    wood = [(1.0, 1.0, 0.32), (3.93, 0.32, 0.06), (9.9, 0.08, 0.02)]
    step = 0.17
    melody = [
        (0, "G5"), (1, "C6"), (2, "E6"), (3, "C6"), (4, "G6"), (6, "E6"), (7, "D6"),
        (8, "C6"), (9, "D6"), (10, "E6"), (11, "G6"), (12, "C7"), (14, "G6"),
    ]
    for beat, name in melody:
        gain = 1.0 + rng.uniform(-0.08, 0.08)  # 손으로 치는 듯한 세기 차이
        add_partials(out, beat * step, note(name), wood, attack=0.002, gain=gain)
        # 채가 막대에 닿는 짧은 '톡' — 아주 짧은 잡음 버스트
        begin = int(beat * step * RATE)
        click = rng.standard_normal(int(0.004 * RATE)) * np.hanning(int(0.004 * RATE)) * 0.06
        out[begin : begin + len(click)] += click
    bass = [(0, "C4"), (4, "G3"), (8, "A3"), (12, "G3")]
    for beat, name in bass:
        add_partials(out, beat * step, note(name), [(1.0, 1.0, 0.5), (3.93, 0.15, 0.08)], gain=0.55)
    return out


def classic(rng):
    """탁상 자명종: 1초 동안 두 벨을 번갈아 약 20Hz 로 두드리고 0.5초 쉰다. 두 번. 3초."""
    out = timeline(3.0)
    # 원판 벨의 어긋난 배음. 서로 조금 다른 두 벨이 맞부딪혀 '따르릉' 하는 맥놀이가 생긴다.
    metal = [(1.0, 1.0, 0.25), (2.32, 0.55, 0.16), (4.25, 0.3, 0.09), (6.63, 0.15, 0.05)]
    bells = [1250.0, 1330.0]
    rate = 20.0  # 초당 타격 수
    for ring_start in (0.0, 1.5):
        strikes = int(1.0 * rate)
        for k in range(strikes):
            t = ring_start + k / rate + rng.uniform(-0.002, 0.002)  # 기계라도 완벽히 고르진 않다
            gain = 0.55 + rng.uniform(-0.08, 0.08)
            add_partials(out, t, bells[k % 2], metal, attack=0.0008, gain=gain)
    return out


def chirp(out, start, duration, f_start, f_end, curve, gain, trill=0.0):
    """start 부터 f_start → f_end 로 휘는 지저귐 한 번. curve > 1 이면 끝에서 급히, < 1 이면 처음에 급히 휜다."""
    n = int(duration * RATE)
    begin = int(start * RATE)
    if begin + n > len(out):
        n = len(out) - begin
    x = np.linspace(0, 1, n)
    freq = f_start + (f_end - f_start) * x**curve
    if trill:
        freq = freq * (1 + trill * np.sin(2 * np.pi * 38 * x * duration))  # 빠른 떨림
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    envelope = np.sin(np.pi * x) ** 1.5
    out[begin : begin + n] += gain * envelope * (np.sin(phase) + 0.12 * np.sin(2 * phase))


def birds(rng):
    """높은 새가 짧게 세 번 묶어 울고, 낮은 새가 길게 답하는 걸 되풀이한다. 5초."""
    out = timeline(5.0)

    def high_bird(at):
        count = int(rng.integers(3, 6))
        t = at
        for _ in range(count):
            d = rng.uniform(0.06, 0.1)
            f0 = rng.uniform(3600, 4200)
            chirp(out, t, d, f0, f0 - rng.uniform(900, 1400), curve=0.6, gain=0.8)
            t += d + rng.uniform(0.03, 0.06)

    def low_bird(at):
        # 아래에서 위로 휘는 '휘-익' 두 번, 두 번째는 떨림을 섞는다.
        chirp(out, at, 0.22, 2100, 3300, curve=2.0, gain=0.7)
        chirp(out, at + 0.3, 0.32, 2500, 2900, curve=1.0, gain=0.6, trill=0.06)

    high_bird(0.05)
    low_bird(0.85)
    high_bird(1.9)
    high_bird(2.6)
    low_bird(3.45)
    return out


SOUNDS = {
    "morning": morning,
    "marimba": marimba,
    "classic": classic,
    "birds": birds,
}


def main():
    rng = np.random.default_rng(SEED)
    ASSETS.mkdir(parents=True, exist_ok=True)
    for name, make in SOUNDS.items():
        data = finish(make(rng)).astype(np.float32)
        path = ASSETS / f"{name}.ogg"
        sf.write(path, data, RATE, format="OGG", subtype="VORBIS")
        info = sf.info(path)
        print(f"{path.name}: {info.duration:.2f}s, {path.stat().st_size / 1024:.1f}KB")


if __name__ == "__main__":
    main()
