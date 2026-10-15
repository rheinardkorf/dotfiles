"""panel hud: a full-screen assistant HUD over the panel cache. Purely for show.

    panel hud    (cmd+shift+a: a borderless tmux popup over everything)

Boots ("I.R.I.S. online" and a systems check), then shows an arc reactor, the
time, the Mac's vitals, a radar of agents and a ticker, while the assistant
speaks a briefing. Everything it says comes from the panel cache; only CPU,
memory and battery come from the Mac itself.

Keys: esc / q close, space skips the boot or repeats the briefing, and each
system's letter (shown beside it) jumps to its window in the panel session.

As a window in the panel session (job "mode": "window") it stays open and
silent: space speaks the briefing, the cache is read again every 15 seconds,
and nothing is drawn while the window is off screen. It starts again (without
the boot) when the config or this code changes, so it never runs stale.
Run by panel, with a job file: {"assistant": {...}, "user": "...", "cache": "...",
"units": [{unit, pane, view, title, source, hidden}, ...]}
"""
import concurrent.futures
import json
import math
import os
import random
import re
import select
import shutil
import signal
import subprocess
import sys
import termios
import textwrap
import threading
import time
import tty
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))

# --- colours (Catppuccin Mocha) -------------------------------------------------
C = {
    "text": (205, 214, 244), "sub": (166, 173, 200), "dim": (108, 112, 134), "faint": (69, 71, 90),
    "sky": (137, 220, 235), "sapphire": (116, 199, 236), "blue": (137, 180, 250), "lavender": (180, 190, 254),
    "teal": (148, 226, 213), "green": (166, 227, 161), "yellow": (249, 226, 175), "peach": (250, 179, 135),
    "red": (243, 139, 168), "white": (245, 247, 255), "base": (30, 30, 46),
    "mauve": (203, 166, 247), "pink": (245, 194, 231), "flamingo": (242, 205, 205),
    "rosewater": (245, 224, 220), "maroon": (235, 160, 172),
}

# The HUD draws with roles, not colours: a theme maps each role to a colour.
#   primary    the name, clock, major ticks, the core, keys and cursor
#   secondary  gradients, the inner ring segments, the orbit trails
#   ring       the outer ring segments (and boot noise)
#   accent     the shape inside the reactor
#   radar      the radar sweep and the CPU spark
#   alert      the pulse when an agent waits on you, and rows needing attention
THEMES = {
    "arc": {"primary": "sky", "secondary": "blue", "ring": "sapphire", "accent": "lavender", "radar": "teal", "alert": "peach"},
    "ember": {"primary": "peach", "secondary": "red", "ring": "maroon", "accent": "yellow", "radar": "flamingo", "alert": "sky"},
    "matrix": {"primary": "green", "secondary": "teal", "ring": "green", "accent": "yellow", "radar": "green", "alert": "red"},
    "nebula": {"primary": "pink", "secondary": "mauve", "ring": "lavender", "accent": "flamingo", "radar": "mauve", "alert": "peach"},
}

# The reactor's pattern
REACTOR = {"shape": 3, "segments": 10, "ticks": 60, "orbiters": 3, "speed": 1.0}


def colour(v):
    """A palette name (\"mauve\") or \"#rrggbb\"."""
    if isinstance(v, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", v):
        return tuple(int(v[i:i + 2], 16) for i in (1, 3, 5))
    return C.get(v)


def configure(a):
    """The assistant's theme (a preset's name, or {"base": preset, role: colour, ...})
    and reactor settings; anything unknown keeps the default."""
    t = a.get("theme") or "arc"
    t = {"base": t} if isinstance(t, str) else dict(t)
    roles = {**THEMES["arc"], **THEMES.get(t.pop("base", "arc"), {}), **t}
    for role, v in roles.items():
        C[role] = colour(v) or colour(THEMES["arc"].get(role)) or C["text"]
    r = a.get("reactor") or {}
    for k, default in REACTOR.items():
        if isinstance(r.get(k), (int, float)) and not isinstance(r.get(k), bool):
            REACTOR[k] = type(default)(r[k])


def mix(a, b, f):
    f = max(0.0, min(1.0, f))
    return tuple(int(a[i] + (b[i] - a[i]) * f) for i in range(3))


# --- block font (5 rows) ---------------------------------------------------------
FONT = {
    "A": ".###.|#...#|#####|#...#|#...#", "B": "####.|#...#|####.|#...#|####.", "C": ".####|#....|#....|#....|.####",
    "D": "####.|#...#|#...#|#...#|####.", "E": "#####|#....|####.|#....|#####", "F": "#####|#....|####.|#....|#....",
    "G": ".####|#....|#..##|#...#|.####", "H": "#...#|#...#|#####|#...#|#...#", "I": "###|.#.|.#.|.#.|###",
    "J": "..###|...#.|...#.|#..#.|.##..", "K": "#...#|#..#.|###..|#..#.|#...#", "L": "#....|#....|#....|#....|#####",
    "M": "#...#|##.##|#.#.#|#...#|#...#", "N": "#...#|##..#|#.#.#|#..##|#...#", "O": ".###.|#...#|#...#|#...#|.###.",
    "P": "####.|#...#|####.|#....|#....", "Q": ".###.|#...#|#.#.#|#..#.|.##.#", "R": "####.|#...#|####.|#..#.|#...#",
    "S": ".####|#....|.###.|....#|####.", "T": "#####|..#..|..#..|..#..|..#..", "U": "#...#|#...#|#...#|#...#|.###.",
    "V": "#...#|#...#|#...#|.#.#.|..#..", "W": "#...#|#...#|#.#.#|##.##|#...#", "X": "#...#|.#.#.|..#..|.#.#.|#...#",
    "Y": "#...#|.#.#.|..#..|..#..|..#..", "Z": "#####|...#.|..#..|.#...|#####", ".": ".|.|.|.|#", " ": "..|..|..|..|..",
    "0": "###|#.#|#.#|#.#|###", "1": ".#.|##.|.#.|.#.|###", "2": "###|..#|###|#..|###", "3": "###|..#|###|..#|###",
    "4": "#.#|#.#|###|..#|..#", "5": "###|#..|###|..#|###", "6": "###|#..|###|#.#|###", "7": "###|..#|..#|..#|..#",
    "8": "###|#.#|###|#.#|###", "9": "###|#.#|###|..#|###", ":": ".|#|.|#|.", "-": "...|...|###|...|...",
}


def glyphs(text):
    """Text -> list of (column offset, row, ...) cells that are on, and the width."""
    cells, x = [], 0
    for ch in text.upper():
        rows = FONT.get(ch, FONT[" "]).split("|")
        for r, row in enumerate(rows):
            for c, v in enumerate(row):
                if v == "#":
                    cells.append((x + c, r))
        x += len(rows[0]) + 1
    return cells, max(0, x - 1)


# --- screen ------------------------------------------------------------------------
class Screen:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.ch = [[" "] * w for _ in range(h)]
        self.co = [[None] * w for _ in range(h)]

    def put(self, x, y, s, color=None):
        if not 0 <= y < self.h:
            return
        for i, c in enumerate(s):
            if 0 <= x + i < self.w:
                self.ch[y][x + i] = c
                self.co[y][x + i] = color

    def center(self, y, s, color=None):
        self.put((self.w - len(s)) // 2, y, s, color)

    def render(self):
        out = []
        for y in range(self.h):
            out.append(f"\x1b[{y + 1};1H")
            last = None
            for x in range(self.w):
                c = self.co[y][x]
                if c != last:
                    out.append(f"\x1b[38;2;{c[0]};{c[1]};{c[2]}m" if c else "\x1b[39m")
                    last = c
                out.append(self.ch[y][x])
        return "".join(out)


BITS = {(0, 0): 0x01, (0, 1): 0x02, (0, 2): 0x04, (1, 0): 0x08, (1, 1): 0x10, (1, 2): 0x20, (0, 3): 0x40, (1, 3): 0x80}


class Braille:
    """A canvas of 2x4 dots per character cell; each cell takes its highest-priority colour."""

    def __init__(self, cw, ch):
        self.cw, self.ch, self.cells = cw, ch, {}

    def dot(self, x, y, color, prio=0):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.cw * 2 and 0 <= y < self.ch * 4:
            key = (x // 2, y // 4)
            m, c, p = self.cells.get(key, (0, color, prio))
            if prio >= p:
                c, p = color, prio
            self.cells[key] = (m | BITS[(x % 2, y % 4)], c, p)

    def arc(self, cx, cy, r, a0, a1, color, prio=0):
        steps = max(4, int(abs(a1 - a0) * r * 1.6))
        for i in range(steps + 1):
            a = a0 + (a1 - a0) * i / steps
            self.dot(cx + r * math.cos(a), cy + r * math.sin(a), color, prio)

    def line(self, x0, y0, x1, y1, color, prio=0):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1):
            self.dot(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, color, prio)

    def draw(self, scr, ox, oy):
        for (cx, cy), (m, c, _) in self.cells.items():
            scr.put(ox + cx, oy + cy, chr(0x2800 + m), c)


# --- facts from the panel cache ----------------------------------------------------
ANSI = re.compile(r"\x1b\[[0-9;]*m")
BAD = re.compile(r"✗|fail|alarm|breach|^\?|dlq: [1-9]", re.I)


def mtime(path):
    try:
        return os.stat(path).st_mtime
    except OSError:
        return None


def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return default


def facts(job):
    cache, now = job["cache"], time.time()
    seen = load(os.path.join(cache, "seen.json"), {})
    units = []
    for u in job["units"]:
        if u.get("hud_only"):   # a HUD-only source: nothing cached, only its summary
            items, meta = [], {}
        else:
            items = load(os.path.join(cache, "panes", u["unit"], "items.json"), None)
            meta = load(os.path.join(cache, "panes", u["unit"], "meta.json"), {})
        f = dict(u, items=items or [], missing=items is None, error=meta.get("error"))
        unseen = 0
        for it in f["items"]:
            s = seen.get(f"{u['source']}:{it.get('seen') or it['id']}", it.get("quiet_before"))
            if s is None or (it.get("updated") or 0) > s:
                unseen += 1
        f["unseen"] = unseen
        f["bad"] = [it for it in f["items"] if BAD.search(it.get("status") or "")]
        upcoming = sorted((it for it in f["items"] if (it.get("at") or 0) > now), key=lambda it: it["at"])
        f["next"] = upcoming[0] if upcoming else None
        units.append(f)
    return units


def seconds(s):
    """30m / 24h / 7d -> seconds (a plain number is seconds)."""
    m = re.fullmatch(r"(\d+)([smhd]?)", str(s).strip())
    return int(m[1]) * {"": 1, "s": 1, "m": 60, "h": 3600, "d": 86400}[m[2]] if m else 86400


def summarize(job, units):
    """Each unit describes itself: its source's `summary <view>` gets the unit's
    facts on stdin and prints {line, state, word, brief, ticker} (all optional).
    The sources run in parallel. f["sum"] is that, {} for a view the config
    leaves out ("summary"), or None when the source has no summary (a plain
    count is shown instead)."""
    now = int(time.time())
    config_dir = job.get("config_dir") or os.path.expanduser("~/.config/panel")

    def facts_of(f):
        nxt = f["next"]
        return {"view": f["view"], "count": len(f["items"]), "unseen": f["unseen"], "bad": len(f["bad"]),
                "recent": seconds(f.get("recent") or "24h"),
                "next": {"title": nxt.get("title"), "at": nxt["at"]} if nxt else None,
                "error": f["error"], "now": now, "items": f["items"]}

    def ask(source, view, facts_in):
        env = dict(os.environ, PANEL_CONFIG_DIR=config_dir,
                   PANEL_SOURCE_CACHE=os.path.join(job["cache"], "sources", source),
                   PANEL_SOURCE_CONFIG=json.dumps((job.get("sources") or {}).get(source) or {}))
        try:
            r = subprocess.run([os.path.join(config_dir, "sources", source), "summary", view or ""],
                               input=json.dumps(facts_in), capture_output=True, text=True, timeout=5, env=env)
            out = json.loads(r.stdout) if r.returncode == 0 and r.stdout.strip() else None
            return out if isinstance(out, dict) else None
        except Exception:
            return None

    # a pane in "pane" mode is asked once, with all its views; the answer goes on its
    # first unit (the others say nothing), so it reads as one line and one sentence
    jobs, panes = [], {}
    for f in units:
        if not f.get("summary", True):
            f["sum"] = {}
        elif f.get("summary_mode") == "pane":
            panes.setdefault(f["pane"], []).append(f)
        elif f["missing"]:
            f["sum"] = None
        else:
            jobs.append((f, lambda f=f: ask(f["source"], f["view"], facts_of(f))))
    for fs in panes.values():
        live = [f for f in fs if not f["missing"]]
        for f in fs:
            f["sum"] = {}
        if live:
            jobs.append((live[0], lambda live=live: ask(live[0]["source"], "", {
                "pane": True, "views": [facts_of(f) for f in live], "now": now,
                "recent": seconds(live[0].get("recent") or "24h")})))
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for (f, _), s in zip(jobs, pool.map(lambda j: j[1](), jobs)):
            f["sum"] = s


def line_of(f):
    """The unit's line: its own, or (no summary command) a plain count."""
    if f["sum"] is None:
        return f"{len(f['items'])} {f['view'] or 'items'}" + (f" · {f['unseen']} new" if f["unseen"] else "")
    return f["sum"].get("line")


def systems(units, now):
    """One row per pane: (name, state word, colour, summary); and the panes, in order."""
    rows, order = {}, []
    for f in units:
        if f["hidden"]:
            continue
        if f["pane"] not in rows:
            rows[f["pane"]] = []
            order.append(f["pane"])
        rows[f["pane"]].append(f)
    out = []
    for pane in order:
        fs = rows[pane]
        bits = [b for b in (line_of(f) for f in fs if not f["missing"]) if b]
        sums = [f["sum"] for f in fs if f["sum"]]
        attention = [s for s in sums if s.get("state") == "attention"]
        if any(f["error"] for f in fs):
            state, col = "degraded", "red"
        elif all(f["missing"] for f in fs):
            state, col = "no data", "dim"
        elif attention:
            state, col = next((s["word"] for s in attention if s.get("word")), "attention"), "alert"
        else:
            state, col = next((s["word"] for s in sums if s.get("word")), "online"), "green"
        name = (fs[0].get("title") or pane).lower()   # the pane's title in the config
        out.append((name, state, col, " · ".join(bits)))
    return out, order


RESERVED = set("q ")   # q closes the popup, space briefs


def letters(names, chosen):
    """A key per name: the one chosen in the config ("key"; case matters, digits
    work), else the name's first free letter, else another from it, else any."""
    used = set(RESERVED) | {k for k in chosen if k}
    keys = []
    for name, k in zip(names, chosen):
        if not k:
            k = next((c for c in name.lower() if c.isalpha() and c not in used), None)
            k = k or next((c for c in "abcdefghijklmnoprstuvwxyz" if c not in used), "")
            used.add(k)
        keys.append(k)
    return keys


def cap(s):
    return s[:1].upper() + s[1:]


def one(*options):
    """One of several ways to say the same thing, so the briefing doesn't sound scripted."""
    return random.choice(options)


def briefing(job, units, now):
    hour, user = datetime.now().hour, job.get("user") or ""
    to = f", {user}" if user else ""
    part = "morning" if hour < 12 else "afternoon" if hour < 18 else "evening"
    greetings = [f"Good {part}{to}.", f"Welcome back{to}.", f"Hello{to}. Good {part}.", f"Good {part}{to}. Here is where things stand."]
    if hour < 12:
        greetings += [f"Morning{to}. Let's see what the day has for us."]
    elif hour >= 22 or hour < 5:
        greetings = [f"Working late{to}?", f"Burning the midnight oil{to}?", f"Still here{to}? Here is the latest."]
    lines = [one(*greetings)]
    # panes whose last fetch failed: say so, and claim nothing about them
    down = []
    for f in units:
        if f["error"] and not f["hidden"] and f["title"] not in down:
            down.append(f["title"])
    if down:
        who, are = " and ".join(down), "is" if len(down) == 1 else "are"
        why = ": its session has expired" if any("expired" in (f["error"] or "") for f in units) and len(down) == 1 else ""
        lines.append(one(f"{who} {are} not reporting{why}.", f"I've lost contact with {who}{why}.", f"{who} {are} offline{why}."))
    # then what each view has to say, the ones needing attention first
    said = [f for f in units if f["sum"] and f["sum"].get("brief") and not f["hidden"] and f["title"] not in down]
    said.sort(key=lambda f: f["sum"].get("state") != "attention")
    for f in said:
        lines.append(one(*f["sum"]["brief"]))
    if not down and not any(f["sum"] and f["sum"].get("state") == "attention" for f in units) and len(lines) <= 2:
        lines.append(one("All systems nominal.", "Nothing needs your attention.", "Everything is running smoothly."))
    lines.append(one("Standing by.", "I'll keep an eye on things.", "At your service.", "Standing by, as always.",
                     "Let me know if you need anything."))
    return lines


def ticker(units, rows, now):
    bits = [f"{name} {state}" + (f": {summary}" if summary else "") for name, state, _, summary in rows]
    for f in units:
        if f["sum"] and not f["hidden"]:
            bits += f["sum"].get("ticker") or []
    return "   ◆   ".join(bits) + "   ◆   "


# --- the Mac's vitals ---------------------------------------------------------------
class Vitals(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True)
        self.cpu, self.mem, self.bat, self.charging, self.history = 0.0, 0.0, None, False, []
        self.active = True   # sample only while someone can see it

    @staticmethod
    def run_cmd(*cmd):
        try:
            return subprocess.run(cmd, capture_output=True, text=True, timeout=3).stdout
        except Exception:
            return ""

    def sample(self):
        ncpu = os.cpu_count() or 1
        total = sum(float(v) for v in self.run_cmd("ps", "-A", "-o", "%cpu=").split() if v.replace(".", "", 1).isdigit())
        self.cpu = min(100.0, total / ncpu)
        self.history = (self.history + [self.cpu])[-40:]
        vm, size = self.run_cmd("vm_stat"), self.run_cmd("sysctl", "-n", "hw.memsize").strip()
        page = int((re.search(r"page size of (\d+)", vm) or [0, 16384])[1])
        pages = {k: int(v) for k, v in re.findall(r"Pages (active|wired down|occupied by compressor):\s+(\d+)", vm)}
        if size.isdigit():
            self.mem = min(100.0, sum(pages.values()) * page * 100 / int(size))
        m = re.search(r"(\d+)%; (\w+)", self.run_cmd("pmset", "-g", "batt"))
        if m:
            self.bat, self.charging = int(m[1]), m[2] in ("charging", "charged", "finishing")

    def run(self):
        while True:
            if self.active:
                self.sample()
            time.sleep(2)


# --- the voice ----------------------------------------------------------------------
class Quiet:
    """No voice (yet): the whole briefing shown, nothing spoken."""

    def __init__(self, sentences):
        self.sentences, self.done = sentences, True

    def shown(self):
        return self.sentences

    def stop(self):
        pass


class Voice(threading.Thread):
    """Speaks the briefing (Kokoro through speak.py, else macOS say); records which
    sentence is playing and since when, so the text can type along."""

    def __init__(self, job, sentences):
        super().__init__(daemon=True)
        self.job, self.sentences = job, sentences
        self.current, self.started, self.length, self.done, self.proc = -1, 0.0, 1.0, False, None

    def run(self):
        a = self.job["assistant"]
        model_dir = os.path.expanduser(a.get("model_dir", "~/.local/share/kokoro"))
        if os.environ.get("PANEL_HUD_QUIET"):   # silent (tests): just the typing
            for i, s in enumerate(self.sentences):
                self.current, self.length, self.started = i, len(s) / 14, time.time()
                time.sleep(self.length)
        elif shutil.which("uv") and os.path.exists(f"{model_dir}/kokoro-v1.0.onnx"):
            spec = os.path.join(self.job["cache"], "hud", "speak.json")
            os.makedirs(os.path.dirname(spec), exist_ok=True)
            with open(spec, "w") as f:
                json.dump({"sentences": self.sentences, "voice": a.get("voice", "bf_isabella"),
                           "lang": a.get("lang", "en-gb"), "model_dir": model_dir,
                           "cache": os.path.join(self.job["cache"], "hud", "voice")}, f)
            self.proc = subprocess.Popen(
                ["uv", "run", "-q", "--no-project", "--python", "3.12", "--with", "kokoro-onnx", "--with", "soundfile",
                 "--with", "sounddevice",
                 "python", "-I", os.path.join(HERE, "speak.py"), spec],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, start_new_session=True)
            for line in self.proc.stdout:
                parts = line.split()
                if parts[:1] == ["start"]:
                    self.current, self.length, self.started = int(parts[1]), float(parts[2]), time.time()
        else:   # no Kokoro: macOS say, with a guess at how long each sentence takes
            for i, s in enumerate(self.sentences):
                self.current, self.length, self.started = i, len(s) / 14, time.time()
                self.proc = subprocess.Popen(["say", s], start_new_session=True)
                self.proc.wait()
        self.done = True

    def stop(self):
        if self.proc and self.proc.poll() is None:
            try:
                os.killpg(self.proc.pid, signal.SIGTERM)
            except Exception:
                pass

    def shown(self):
        """How much of each sentence to show: whole ones spoken, the current one typed along."""
        out = []
        for i, s in enumerate(self.sentences):
            if self.done or i < self.current:
                out.append(s)
            elif i == self.current:
                f = (time.time() - self.started) / max(0.5, self.length * 0.92)
                out.append(s[: int(len(s) * min(1.0, f))])
        return out


# --- drawing ------------------------------------------------------------------------
def reactor(scr, x, y, cw, ch, t, busy, waiting):
    b = Braille(cw, ch)
    cx, cy = cw - 0.5, ch * 2 - 0.5
    R = min(cw, ch * 2) - 1
    alert = waiting > 0 and int(t * 2) % 2 == 0
    t *= REACTOR["speed"]
    speed = 1.6 + busy * 0.8
    pulse = 0.5 + 0.5 * math.sin(t * speed)
    # outer ring: segments turning slowly
    n = max(1, REACTOR["segments"])
    for i in range(n):
        a0 = math.radians(i * 360 / n + t * 18)
        b.arc(cx, cy, R, a0, a0 + math.radians(280 / n), C["ring"], 1)
        b.arc(cx, cy, R - 1.5, a0 + math.radians(40 / n), a0 + math.radians(240 / n), C["secondary"], 1)
    # ticks turning the other way, every fifth one longer
    n = max(0, REACTOR["ticks"])
    for i in range(n):
        a = math.radians(i * 360 / n - t * 9)
        r0 = R * (0.74 if i % 5 == 0 else 0.79)
        b.line(cx + r0 * math.cos(a), cy + r0 * math.sin(a), cx + R * 0.85 * math.cos(a), cy + R * 0.85 * math.sin(a),
               C["primary"] if i % 5 == 0 else C["faint"], 2 if i % 5 == 0 else 0)
    # pulsing ring (the alert colour when an agent waits on you)
    ring = mix(C["secondary"], C["alert"] if alert else C["primary"], pulse)
    b.arc(cx, cy, R * 0.62, 0, 2 * math.pi, ring, 3)
    b.arc(cx, cy, R * 0.60, 0, 2 * math.pi, ring, 3)
    # orbiting dots
    n = max(0, REACTOR["orbiters"])
    for k in range(n):
        a = t * 1.9 + k * 2 * math.pi / n
        for d in range(5):
            b.dot(cx + R * 0.69 * math.cos(a - d * 0.05), cy + R * 0.69 * math.sin(a - d * 0.05),
                  mix(C["white"], C["secondary"], d / 5), 4)
    # a shape (3: triangle, 4: square, ...; 0: none), turning slowly
    n = REACTOR["shape"]
    if n >= 3:
        pts = [(cx + R * 0.46 * math.cos(math.radians(90 + 360 / n * k + t * 6)),
                cy + R * 0.46 * math.sin(math.radians(90 + 360 / n * k + t * 6))) for k in range(n)]
        for k in range(n):
            b.line(*pts[k], *pts[(k + 1) % n], C["accent"], 2)
    # core
    for r in range(int(R * 0.22), 0, -1):
        b.arc(cx, cy, r, 0, 2 * math.pi, mix(C["white"], C["primary"], r / (R * 0.22) * (0.6 + 0.4 * pulse)), 5)
    b.draw(scr, x, y)


def radar(scr, x, y, cw, ch, t, agents):
    b = Braille(cw, ch)
    cx, cy = cw - 0.5, ch * 2 - 0.5
    R = min(cw, ch * 2) - 1
    b.arc(cx, cy, R, 0, 2 * math.pi, C["faint"], 0)
    b.arc(cx, cy, R * 0.5, 0, 2 * math.pi, C["faint"], 0)
    b.line(cx - R, cy, cx + R, cy, C["faint"], 0)
    b.line(cx, cy - R, cx, cy + R, C["faint"], 0)
    sweep = (t * 1.6) % (2 * math.pi)
    for k in range(8):   # the sweep and its fading trail
        a = sweep - k * 0.07
        b.line(cx, cy, cx + R * math.cos(a), cy + R * math.sin(a), mix(C["radar"], C["faint"], k / 8), 1)
    for i, it in enumerate(agents):
        a = 2 * math.pi * i / max(1, len(agents)) - math.pi / 2
        st = it.get("status") or ""
        if st.startswith("?"):
            r, col = 0.72, C["red"]
        elif st in ("busy", "running"):
            r, col = 0.38, C["green"]
        else:
            r, col = 0.88, C["dim"]
        lit = 1 - min(1.0, ((sweep - a) % (2 * math.pi)) / 1.2)   # brightest just after the sweep passes
        col = mix(col, C["white"], lit * 0.6)
        if st in ("busy", "running"):
            col = mix(col, C["white"], 0.25 + 0.25 * math.sin(t * 6 + i))
        px, py = cx + R * r * math.cos(a), cy + R * r * math.sin(a)
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                b.dot(px + dx, py + dy, col, 6)
    b.draw(scr, x, y)


def bar(scr, x, y, label, pct, width, extra=""):
    pct = 0 if pct is None else pct
    n = int(round(pct / 100 * width))
    col = C["green"] if pct < 60 else C["yellow"] if pct < 85 else C["red"]
    scr.put(x, y, label.ljust(5), C["sub"])
    for i in range(width):
        scr.put(x + 5 + i, y, "▰" if i < n else "▱", col if i < n else C["faint"])
    scr.put(x + 6 + width, y, f"{pct:3.0f}%{extra}", C["text"])


def big(scr, x, y, text, color_at):
    cells, w = glyphs(text)
    for cx, cy in cells:
        scr.put(x + cx, y + cy, "█", color_at(cx, cy, w))
    return w


NOISE = "▓▒░#%&@$*+=<>/\\|"


class Hud:
    def __init__(self, job):
        self.job, self.a = job, job["assistant"]
        configure(self.a)
        self.name = self.a.get("name", "A.D.A.")
        self.meaning = self.a.get("meaning", "")
        self.window = job.get("mode") == "window"
        self.read()
        self.t0 = time.time()
        self.boot_end = 2.2 + 0.32 * len(self.rows) + 1.1
        if os.environ.get("PANEL_HUD_NOBOOT"):   # a restart of the window: straight to the HUD
            self.t0 -= self.boot_end + 1
        # what the window was built from: when one changes, it starts again
        self.watched = {f: mtime(f) for f in (job.get("config_files") or []) + [os.path.abspath(__file__)]}
        self.vitals = Vitals()
        self.vitals.start()
        if self.window:   # silent until asked
            self.voice = Quiet(self.sentences)
        else:
            self.voice = Voice(job, self.sentences)
            self.voice.start()

    def read(self):
        """(Re)read the cache: facts, systems, the briefing, the ticker."""
        self.now = self.read_at = time.time()
        self.units = facts(self.job)
        summarize(self.job, self.units)
        self.rows, panes = systems(self.units, self.now)
        # each row's letter and the panel window that holds its pane
        windows = self.job.get("windows") or {}
        chosen = [next((str(f.get("key") or "")[:1] for f in self.units if f["pane"] == pane), "") for pane in panes]
        chosen = ["" if k in RESERVED else k for k in chosen]
        self.keys = letters([r[0] for r in self.rows], chosen)
        self.jumps = {k: next((w for w, ps in windows.items() if pane in ps), None)
                      for k, pane in zip(self.keys, panes) if k}
        # HUD-only sources: their key runs their "open" command instead (e.g. the streak logger)
        opens = {f["pane"]: f.get("open") for f in self.units if f.get("hud_only") and f.get("open")}
        self.opens = {k: opens[pane] for k, pane in zip(self.keys, panes) if k and pane in opens}
        self.sentences = briefing(self.job, self.units, self.now)
        self.tick = ticker(self.units, self.rows, self.now)
        self.agents = next((f["items"] for f in self.units if f["source"] == "agents"), [])

    def jump(self, key):
        """Go to the window of the system with this letter (in the panel session);
        True when it went (the popup then closes)."""
        if key in self.opens:   # run it, detached (it opens its own window)
            subprocess.Popen(["/bin/zsh", "-c", self.opens[key]], start_new_session=True,
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
        win = self.jumps.get(key)
        if not win:
            return False
        out = subprocess.run(["tmux", "list-windows", "-t", "=panel:", "-F", "#{window_id} #{@panel_name}"],
                             capture_output=True, text=True).stdout.split("\n")
        wid = next((line.split()[0] for line in out if line.split()[1:] == [win]), None)
        if not wid:
            return False
        subprocess.run(["tmux", "select-window", "-t", wid], capture_output=True)
        # and show the panel session, when the HUD is a popup over another one
        subprocess.run(["tmux", "switch-client", "-t", "=panel"], capture_output=True)
        return True

    def stale(self):
        """The config or the HUD's code changed since it started."""
        return any(mtime(f) != m for f, m in self.watched.items())

    def refresh(self):
        """In a window: read the cache again every 15 seconds, but not mid-sentence."""
        if self.window and self.voice.done and time.time() - self.read_at > 15:
            self.read()
            self.voice = Quiet(self.sentences)

    def skip(self):
        if time.time() - self.t0 < self.boot_end:
            self.t0 = time.time() - self.boot_end
        elif self.voice.done:   # say it (again), from the latest cache
            if self.window:
                self.read()
            self.voice = Voice(self.job, self.sentences)
            self.voice.start()

    def frame(self, w, h):
        t = time.time() - self.t0
        scr = Screen(w, h)
        if t < self.boot_end:
            self.boot(scr, t)
        else:
            self.hud(scr, t)
            wipe = (t - self.boot_end) / 0.45
            if wipe < 1:   # a scan line uncovering the HUD
                line = int(h * wipe)
                boot = Screen(w, h)
                self.boot(boot, self.boot_end)
                for yy in range(line, h):
                    scr.ch[yy], scr.co[yy] = boot.ch[yy], boot.co[yy]
                scr.put(0, line, "─" * w, C["primary"])
        return scr.render()

    def boot(self, scr, t):
        w, h = scr.w, scr.h
        cells, tw = glyphs(self.name)
        top = max(1, h // 2 - 5 - len(self.rows) // 2 - 2)
        x0 = (w - tw) // 2
        rnd = random.Random(int(t * 20))
        for cx, cy in cells:   # resolve out of noise, left to right
            settle = 0.25 + 1.1 * cx / max(1, tw)
            if t >= settle:
                scr.put(x0 + cx, top + cy, "█", mix(C["primary"], C["secondary"], cx / max(1, tw)))
            elif t > settle - 0.6:
                scr.put(x0 + cx, top + cy, rnd.choice(NOISE), rnd.choice([C["secondary"], C["ring"], C["faint"]]))
        if t > 1.2:
            n = int((t - 1.2) / 0.6 * len(self.meaning))
            scr.center(top + 6, self.meaning[:n], C["sub"])
        if t > 1.7:
            word = "online"
            scr.center(top + 8, word[: int((t - 1.7) * 14)], C["green"])
        y = top + 10
        lw = max(len(r[0]) for r in self.rows) + 12 if self.rows else 20
        bx = max(2, (w - (lw + 14 + 46)) // 2)
        for i, (name, state, col, summary) in enumerate(self.rows):
            st = 2.2 + 0.32 * i
            if t < st:
                break
            branch = "└" if i == len(self.rows) - 1 else "├"
            lead = f" {name} " + "." * (lw - len(name) - 2)
            k = int(min(1.0, (t - st) / 0.22) * len(lead))
            scr.put(bx, y + i, branch, C["faint"])
            scr.put(bx + 1, y + i, lead[:k], C["sub"])
            if t - st > 0.22:
                scr.put(bx + 2 + lw, y + i, state.ljust(12), C[col])
                scr.put(bx + 2 + lw + 13, y + i, summary[: max(0, w - bx - lw - 16)], C["dim"])

    def hud(self, scr, t):
        w, h = scr.w, scr.h
        now = datetime.now()
        # header
        scr.put(2, 0, f"{self.name}  ", C["primary"])
        scr.put(2 + len(self.name) + 2, 0, self.meaning, C["dim"])
        hint = "letter: go there · space: brief me" if self.window else "letter: go there · space: brief again · esc: dismiss"
        scr.put(w - len(hint) - 2, 0, hint, C["faint"])
        scr.put(0, 1, "─" * w, C["faint"])
        busy = sum(1 for it in self.agents if it.get("status") in ("busy", "running"))
        waiting = sum(1 for it in self.agents if (it.get("status") or "").startswith("?"))
        brief_h, foot = 6, 2
        body_top, body_h = 3, h - 3 - brief_h - foot
        side = w >= 110
        # centre: the reactor
        rh = max(6, body_h)
        rw = min(rh * 2, (w - (64 if side else 4)))
        rh = min(rh, rw // 2)
        rx = (w - rw) // 2
        reactor(scr, rx, body_top + (body_h - rh) // 2, rw, rh, t, busy, waiting)
        if side:
            # left: the clock, the date and the systems
            lx = 3
            big(scr, lx, body_top, now.strftime("%H:%M"), lambda cx, cy, tw: mix(C["primary"], C["secondary"], cx / max(1, tw)))
            scr.put(lx + 20, body_top + 4, now.strftime("%S"), C["dim"])
            scr.put(lx, body_top + 6, now.strftime("%A %-d %B"), C["sub"])
            for i, (name, state, col, summary) in enumerate(self.rows):
                yy = body_top + 8 + i * 2
                if yy + 1 >= body_top + body_h:
                    break
                key = self.keys[i] if self.jumps.get(self.keys[i]) or self.keys[i] in self.opens else ""
                scr.put(lx, yy, f"{key or ' '}", C["primary"])   # press it to jump there
                scr.put(lx + 2, yy, "●", C[col])
                scr.put(lx + 4, yy, name.ljust(10), C["text"])
                scr.put(lx + 14, yy, state, C[col])
                scr.put(lx + 4, yy + 1, summary[: max(0, rx - lx - 6)], C["dim"])
            # right: vitals and the agent radar
            vx = rx + rw + 4
            vw = max(10, min(20, w - vx - 14))
            v = self.vitals
            bar(scr, vx, body_top, "CPU", v.cpu, vw)
            spark = "".join("▁▂▃▄▅▆▇█"[min(7, int(c / 12.5))] for c in v.history[-(vw + 9):])
            scr.put(vx + 5, body_top + 1, spark, C["radar"])
            bar(scr, vx, body_top + 3, "MEM", v.mem, vw)
            if v.bat is not None:
                bar(scr, vx, body_top + 5, "BAT", v.bat, vw, " ⚡" if v.charging else "")
            rad_top = body_top + 8
            rad_h = min(9, body_top + body_h - rad_top - 2)
            if rad_h >= 4:
                radar(scr, vx, rad_top, rad_h * 2, rad_h, t, self.agents)
                scr.put(vx, rad_top + rad_h + 1, f"● {busy} busy", C["green"])
                scr.put(vx + 10, rad_top + rad_h + 1, f"? {waiting} waiting", C["red"] if waiting else C["dim"])
                idle = len(self.agents) - busy - waiting
                scr.put(vx + 22, rad_top + rad_h + 1, f"○ {idle} idle", C["dim"])
        # the briefing, typed along with the voice
        bw = min(w - 8, 96)
        text = " ".join(self.voice.shown())
        lines = textwrap.wrap(text, bw)[-(brief_h - 2):]
        by = h - foot - brief_h + 1
        scr.put((w - bw) // 2, by - 1, "─" * bw, C["faint"])
        for i, ln in enumerate(lines):
            scr.put((w - bw) // 2, by + i, ln, C["text"])
        if not self.voice.done and lines and int(t * 3) % 2 == 0:
            scr.put((w - bw) // 2 + len(lines[-1]), by + len(lines) - 1, "▍", C["primary"])
        # ticker
        off = int(t * 9) % len(self.tick)
        scr.put(0, h - 1, (self.tick * 3)[off: off + w], C["dim"])


def main():
    job = load(sys.argv[1], None)
    try:
        os.unlink(sys.argv[1])
    except Exception:
        pass
    if not job:
        sys.exit("panel hud: no job")
    hud = Hud(job)
    signal.signal(signal.SIGHUP, lambda *_: sys.exit(0))   # its terminal closed
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    out = sys.stdout
    try:
        tty.setcbreak(fd)
        out.write("\x1b[?1049h\x1b[?25l\x1b[2J")
        pane, shown, checked, stale_at = os.environ.get("TMUX_PANE"), True, 0.0, time.time()
        while True:
            if hud.window and pane and time.time() - checked > 1:
                # only draw while the window is on screen: the active window of an attached session
                was, checked = shown, time.time()
                shown = subprocess.run(["tmux", "display", "-p", "-t", pane, "#{&&:#{window_active},#{session_attached}}"],
                                       capture_output=True, text=True).stdout.strip() == "1"
                hud.vitals.active = shown
                if shown and not was:
                    out.write("\x1b[2J")
            if not shown:
                r, _, _ = select.select([fd], [], [], 1)
                if r and not os.read(fd, 32):
                    break   # the terminal is gone (end of input): stop, don't spin
                continue
            if hud.window and hud.voice.done and time.time() - stale_at > 5:
                stale_at = time.time()
                if hud.stale():
                    break   # the window loop starts it again, with the new config or code
            hud.refresh()
            try:   # the terminal itself (shutil would trust COLUMNS / LINES from the environment)
                size = os.get_terminal_size(fd)
            except OSError:
                size = os.terminal_size((120, 40))
            out.write(hud.frame(size.columns, size.lines))
            out.flush()
            r, _, _ = select.select([fd], [], [], 1 / 14)
            if r:
                key = os.read(fd, 32)
                if not key:
                    break   # the terminal is gone (end of input): stop, don't spin
                if key[:1] in (b"\x1b", b"q", b"\x03") and not hud.window:
                    break
                if key[:1] == b" ":
                    hud.skip()
                elif len(key) == 1 and hud.jump(key.decode("utf-8", "replace")) and not hud.window:
                    break   # the popup has done its job
    except KeyboardInterrupt:
        pass
    finally:
        hud.voice.stop()
        try:   # the terminal may already be gone
            termios.tcsetattr(fd, termios.TCSADRAIN, old)
            out.write("\x1b[0m\x1b[?25h\x1b[?1049l")
            out.flush()
        except (OSError, ValueError):
            pass


if __name__ == "__main__":
    main()
