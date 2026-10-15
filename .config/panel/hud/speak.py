"""panel hud: speak the briefing, sentence by sentence, with a Kokoro voice.

    uv run --no-project --python 3.12 --with kokoro-onnx --with soundfile \
        python -I speak.py <job.json>

job.json: {"sentences": [...], "voice": "bf_isabella" or {"af_jessica": 0.5, ...},
           "lang": "en-gb", "model_dir": "...", "cache": "..."}

Each sentence is cached as a wav (by voice, language and text), so lines heard
before play at once. The next sentence is made while the current one plays.
Prints "start <i> <seconds>" as each one starts, then "done".
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


threading.Thread(target=make, daemon=True).start()
while (item := ready.get()) is not None:
    i, p = item
    say(f"start {i} {sf.info(p).duration:.2f}")
    subprocess.run(["afplay", p])
say("done")
