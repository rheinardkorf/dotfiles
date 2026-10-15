"""panel hud: speak the briefing, sentence by sentence, with a Kokoro voice.

    uv run --no-project --python 3.12 --with kokoro-onnx --with soundfile \
        --with sounddevice python -I speak.py <job.json>

job.json: {"sentences": [...], "voice": "bf_isabella" or {"af_jessica": 0.5, ...},
           "lang": "en-gb", "model_dir": "...", "cache": "..."}

Each sentence is cached as a wav (by voice, language and text), so lines heard
before play at once. The next sentence is made while the current one plays.
Prints "start <i> <seconds>" as each one starts, then "done".

Playback is one continuous output stream for the whole briefing: sentences are
queued into it and silence fills the gaps, so the output device never closes
between sentences (a Bluetooth headset that dozes off between separate players
would lose the start of every sentence). Without sounddevice, it falls back to
afplay per sentence.
"""
import hashlib
import json
import os
import queue
import subprocess
import sys
import threading

job = json.load(open(sys.argv[1]))
sentences, voice, lang = job["sentences"], job["voice"], job.get("lang", "en-us")
cache = job["cache"]
os.makedirs(cache, exist_ok=True)


def path_for(text):
    key = json.dumps([voice, lang, text], sort_keys=True).encode()
    return os.path.join(cache, hashlib.sha1(key).hexdigest() + ".wav")


def say(msg):
    print(msg, flush=True)


import soundfile as sf  # noqa: E402  (after the cheap part: arguments and cache)

ready = queue.Queue()
kokoro = None


def make():
    """Make (or find) each sentence's audio, in order."""
    global kokoro
    for i, text in enumerate(sentences):
        p = path_for(text)
        if not os.path.exists(p):
            if kokoro is None:
                from kokoro_onnx import Kokoro
                d = job["model_dir"]
                kokoro = Kokoro(f"{d}/kokoro-v1.0.onnx", f"{d}/voices-v1.0.bin")
            if isinstance(voice, dict):   # a blend: weighted average of the voices' styles
                style = sum(kokoro.get_voice_style(v) * w for v, w in voice.items()) / sum(voice.values())
            else:
                style = voice
            samples, sr = kokoro.create(text, voice=style, speed=1.0, lang=lang)
            sf.write(p + ".tmp.wav", samples, sr)
            os.replace(p + ".tmp.wav", p)
        ready.put((i, p))
    ready.put(None)


GAP = 0.25   # seconds of silence between sentences: a natural pause


def stream():
    """Everything through one output stream; True when done, False if it can't open one."""
    try:
        import numpy as np
        import sounddevice as sd
    except Exception:
        return False
    chunks, events, finished = queue.Queue(), queue.Queue(), threading.Event()
    state = {"cur": None, "pos": 0, "ending": False}

    def callback(out, frames, _time, _status):
        filled = 0
        while filled < frames:
            if state["cur"] is None:
                try:
                    i, samples = chunks.get_nowait()
                except queue.Empty:   # nothing ready yet: silence keeps the device open
                    out[filled:] = 0
                    if state["ending"]:
                        finished.set()
                    return
                state["cur"], state["pos"] = samples, 0
                if i is not None:
                    events.put((i, len(samples) / rate))
            cur, pos = state["cur"], state["pos"]
            n = min(frames - filled, len(cur) - pos)
            out[filled:filled + n, 0] = cur[pos:pos + n]
            filled += n
            state["pos"] = pos + n
            if state["pos"] >= len(cur):
                state["cur"] = None

    first = ready.get()
    if first is None:
        return True
    rate = sf.info(first[1]).samplerate
    try:
        out = sd.OutputStream(samplerate=rate, channels=1, dtype="float32", callback=callback)
    except Exception:
        ready.queue.appendleft(first)   # no device to open: afplay instead
        return False

    def feed():
        item = first
        while item is not None:
            i, p = item
            samples, _ = sf.read(p, dtype="float32")
            chunks.put((i, samples))
            chunks.put((None, np.zeros(int(rate * GAP), dtype="float32")))
            item = ready.get()
        state["ending"] = True

    threading.Thread(target=feed, daemon=True).start()
    with out:
        while not finished.is_set():
            try:
                i, secs = events.get(timeout=0.05)
                say(f"start {i} {secs:.2f}")
            except queue.Empty:
                pass
        while not events.empty():
            i, secs = events.get()
            say(f"start {i} {secs:.2f}")
    return True


threading.Thread(target=make, daemon=True).start()
if not stream():   # no sounddevice (or no output device to open): one afplay per sentence
    while (item := ready.get()) is not None:
        i, p = item
        say(f"start {i} {sf.info(p).duration:.2f}")
        subprocess.run(["afplay", p])
say("done")
