"""panel hud: a full-screen assistant HUD over the panel cache. Purely for show.

    panel hud    (cmd+shift+a: a borderless tmux popup over everything)

Boots ("I.R.I.S. online" and a systems check), then shows an arc reactor, the
time, the Mac's vitals, a radar of agents and a ticker, while the assistant
speaks a briefing. Everything it says comes from the panel cache; only CPU,
memory and battery come from the Mac itself.

Keys: esc / q close, space skips the boot or repeats the briefing.

As a window in the panel session (job "mode": "window") it stays open and
silent: space speaks the briefing, the cache is read again every 15 seconds,
and nothing is drawn while the window is off screen.
Run by panel, with a job file: {"assistant": {...}, "user": "...", "cache": "...",
"units": [{unit, pane, view, title, source, hidden}, ...]}
"""
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
}


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


def load(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return default


def dur(s, spoken=False):
    s = max(0, int(s))
    if s < 3600:
        n, u = max(1, s // 60), "minute"
    elif s < 86400:
        n, u = s // 3600, "hour"
    else:
        n, u = s // 86400, "day"
    if spoken:
        return f"{n} {u}{'' if n == 1 else 's'}"
    return f"{n}{u[0] if u != 'minute' else 'm'}"


WORDS = "no one two three four five six seven eight nine ten eleven twelve".split()


def count_words(n, thing, plural=None):
    word = WORDS[n] if n < len(WORDS) else str(n)
    return f"{word} {thing if n == 1 else (plural or thing + 's')}"


def facts(job):
    cache, now = job["cache"], time.time()
    seen = load(os.path.join(cache, "seen.json"), {})
    units = []
    for u in job["units"]:
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


def clean(title):
    return ANSI.sub("", title or "").split("  ·")[0].strip()


def phrase(f, now):
    """A short summary of one unit for the systems check, or None."""
    src, view, n, bad, nxt = f["source"], f["view"], len(f["items"]), len(f["bad"]), f["next"]
    if src == "agents":
        busy = sum(1 for it in f["items"] if it.get("status") == "busy")
        waiting = sum(1 for it in f["items"] if (it.get("status") or "").startswith("?"))
        return f"{busy} busy" + (f" · {waiting} awaiting you" if waiting else "")
    if src == "calendar":
        return f"next: {clean(nxt['title'])} in {dur(nxt['at'] - now)}" if nxt else "clear"
    if src == "rss":
        return f"{f['unseen']} new in {view or 'feeds'}" if f["unseen"] else f"{n} in {view or 'feeds'}"
    table = {
        ("jira", "assigned"): f"{n} assigned",
        ("jira", "mentioned"): f"{f['unseen']} new mentions" if f["unseen"] else None,
        ("jira", "sla"): f"SLA in {dur(nxt['at'] - now)}" if nxt else (f"{bad} SLA breached" if bad else None),
        ("github", "actions"): f"{bad} failing" if bad else "builds green",
        ("github", "review-requests"): f"{n} reviews waiting" if n else None,
        ("github", "my-prs"): f"{n} open PRs" if n else None,
        ("aws", "alarms"): f"{bad} alarms firing" if bad else f"{n} alarms quiet",
        ("aws", "sqs"): f"{bad} DLQs with messages" if bad else "DLQs empty",
        ("aws", "cloudformation"): None, ("aws", "dynamodb"): None,
    }
    if (src, view) in table:
        return table[(src, view)]
    return f"{n} {view or 'items'}" + (f" · {f['unseen']} new" if f["unseen"] else "")


WORD = {"jira": "linked", "github": "linked", "aws": "nominal", "calendar": "synced", "rss": "synced"}


def systems(units, now):
    """One row per pane: (name, state word, colour, summary)."""
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
        src = fs[0]["source"]
        bits = [p for p in (phrase(f, now) for f in fs if not f["missing"]) if p]
        if any(f["error"] for f in fs):
            state, col = "degraded", "red"
        elif all(f["missing"] for f in fs):
            state, col = "no data", "dim"
        elif src == "agents":
            state, col = f"{len(fs[0]['items'])} online", "green"
            if any((it.get("status") or "").startswith("?") for it in fs[0]["items"]):
                col = "peach"
        elif any(f["bad"] for f in fs if f["view"] not in ("cloudformation", "dynamodb")):
            state, col = "attention", "peach"
        else:
            state, col = WORD.get(src, "online"), "green"
        name = {"aws": "prod"}.get(src, pane)
        out.append((name, state, col, " · ".join(bits)))
    return out


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
    by = {(f["source"], f["view"]): f for f in units if not f["missing"]}
    issues = 0
    agents = next((f for f in units if f["source"] == "agents" and not f["missing"]), None)
    if agents:
        waiting = [it for it in agents["items"] if (it.get("status") or "").startswith("?")]
        if waiting:
            n = len(waiting)
            names = ", ".join(it.get("key") if it.get("key") not in (None, "·") else clean(it["title"]).split()[0] for it in waiting)
            are = "is" if n == 1 else "are"
            lines.append(one(f"{cap(count_words(n, 'agent'))} {are} waiting on you: {names}.",
                             f"{names} {are} waiting for your input.",
                             f"You have {count_words(n, 'agent')} waiting: {names}.",
                             f"{names} would like a word."))
            issues += 1
    # panes whose last fetch failed: say so, and claim nothing about them
    down = []
    for f in units:
        name = {"aws": "Prod"}.get(f["source"], f["title"])
        if f["error"] and not f["hidden"] and name not in down:
            down.append(name)
    if down:
        who, are = " and ".join(down), "is" if len(down) == 1 else "are"
        why = ": the AWS session has expired" if any("expired" in (f["error"] or "") for f in units if f["source"] == "aws") else ""
        lines.append(one(f"{who} {are} not reporting{why}.", f"I've lost contact with {who}{why}.", f"{who} {are} offline{why}."))
        issues += 1
    if ("aws", "alarms") in by and "Prod" not in down:
        bad = len(by[("aws", "alarms")]["bad"])
        if bad:
            alarms, are = count_words(bad, "alarm"), "is" if bad == 1 else "are"
            lines.append(one(f"{cap(count_words(bad, 'prod alarm'))} {are} firing.", f"Prod has {alarms} going off.",
                             f"Heads up: {alarms} firing in prod."))
            issues += 1
        else:
            lines.append(one("Prod is nominal.", "Prod is quiet.", "All quiet in prod.", "Prod is calm. No alarms."))
    if ("aws", "sqs") in by and by[("aws", "sqs")]["bad"]:
        lines.append(one("There are messages in the dead letter queues.", "Something is landing in the dead letter queues.",
                         "The dead letter queues are not empty."))
        issues += 1
    if ("github", "review-requests") in by and by[("github", "review-requests")]["items"]:
        n = len(by[("github", "review-requests")]["items"])
        prs = count_words(n, "pull request")
        lines.append(one(f"{cap(prs)} {'awaits' if n == 1 else 'await'} your review.",
                         f"You have {count_words(n, 'review request')} waiting.",
                         f"{cap(prs)} could use your eyes."))
    sla = by.get(("jira", "sla"))
    if sla and sla["next"] and sla["next"]["at"] - now < 86400:
        d = dur(sla["next"]["at"] - now, True)
        lines.append(one(f"The next SLA breach is in {d}.", f"Your nearest SLA deadline is {d} away.", f"An SLA comes due in {d}."))
    cal = next((f for f in units if f["source"] == "calendar" and f["next"]), None)
    if cal and cal["next"]["at"] - now < 4 * 3600:
        title, d = clean(cal["next"]["title"]), dur(cal["next"]["at"] - now, True)
        lines.append(one(f"{title} starts in {d}.", f"You have {title} in {d}.", f"{title} is coming up in {d}."))
    # new articles, per category (view) of the rss pane
    reads = [(f["view"] or "your feeds", f["unseen"]) for f in units if f["source"] == "rss" and not f["missing"] and not f["hidden"] and f["unseen"]]
    if len(reads) == 1:
        v, n = reads[0]
        lines.append(one(f"{cap(count_words(n, 'new article'))} in {v}.", f"{cap(v)} has {count_words(n, 'new read')}.",
                         f"{cap(count_words(n, 'new story', 'new stories'))} in {v}."))
    elif reads:
        parts = [f"{count_words(n, 'new article') if i == 0 else WORDS[n] if n < len(WORDS) else n} in {v}" for i, (v, n) in enumerate(reads)]
        lines.append(one(f"There are {', '.join(parts[:-1])} and {parts[-1]}.", f"New reading: {', '.join(parts[:-1])} and {parts[-1]}."))
    if not issues and len(lines) <= 2:
        lines.append(one("All systems nominal.", "Nothing needs your attention.", "Everything is running smoothly."))
    lines.append(one("Standing by.", "I'll keep an eye on things.", "At your service.", "Standing by, as always.",
                     "Let me know if you need anything."))
    return lines


def ticker(units, rows, now):
    bits = [f"{name} {state}" + (f": {summary}" if summary else "") for name, state, _, summary in rows]
    for f in units:
        if f["source"] == "calendar":
            for it in [it for it in f["items"] if (it.get("at") or 0) > now][:3]:
                bits.append(f"{clean(it['title'])} in {dur(it['at'] - now)}")
        elif f["source"] == "agents":
            for it in f["items"]:
                bits.append(f"{clean(it['title']).split()[0]} {it.get('status')}")
        elif (f["source"], f["view"]) == ("github", "actions"):
            for it in f["bad"][:3]:
                bits.append(f"✗ {clean(it['title'])}")
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
    speed = 1.6 + busy * 0.8
    pulse = 0.5 + 0.5 * math.sin(t * speed)
    alert = waiting > 0 and int(t * 2) % 2 == 0
    # outer ring: segments turning slowly
    for i in range(10):
        a0 = math.radians(i * 36 + t * 18)
        b.arc(cx, cy, R, a0, a0 + math.radians(28), C["sapphire"], 1)
        b.arc(cx, cy, R - 1.5, a0 + math.radians(4), a0 + math.radians(24), C["blue"], 1)
    # ticks turning the other way, every fifth one longer
    for i in range(60):
        a = math.radians(i * 6 - t * 9)
        r0 = R * (0.74 if i % 5 == 0 else 0.79)
        b.line(cx + r0 * math.cos(a), cy + r0 * math.sin(a), cx + R * 0.85 * math.cos(a), cy + R * 0.85 * math.sin(a),
               C["sky"] if i % 5 == 0 else C["faint"], 2 if i % 5 == 0 else 0)
    # pulsing ring (peach when an agent waits on you)
    ring = mix(C["blue"], C["peach"] if alert else C["sky"], pulse)
    b.arc(cx, cy, R * 0.62, 0, 2 * math.pi, ring, 3)
    b.arc(cx, cy, R * 0.60, 0, 2 * math.pi, ring, 3)
    # orbiting dots
    for k in range(3):
        a = t * 1.9 + k * 2 * math.pi / 3
        for d in range(5):
            b.dot(cx + R * 0.69 * math.cos(a - d * 0.05), cy + R * 0.69 * math.sin(a - d * 0.05),
                  mix(C["white"], C["blue"], d / 5), 4)
    # triangle, turning slowly
    pts = [(cx + R * 0.46 * math.cos(math.radians(90 + 120 * k + t * 6)),
            cy + R * 0.46 * math.sin(math.radians(90 + 120 * k + t * 6))) for k in range(3)]
    for k in range(3):
        b.line(*pts[k], *pts[(k + 1) % 3], C["lavender"], 2)
    # core
    for r in range(int(R * 0.22), 0, -1):
        b.arc(cx, cy, r, 0, 2 * math.pi, mix(C["white"], C["sky"], r / (R * 0.22) * (0.6 + 0.4 * pulse)), 5)
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
        b.line(cx, cy, cx + R * math.cos(a), cy + R * math.sin(a), mix(C["teal"], C["faint"], k / 8), 1)
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
        self.name = self.a.get("name", "A.D.A.")
        self.meaning = self.a.get("meaning", "")
        self.window = job.get("mode") == "window"
        self.read()
        self.t0 = time.time()
        self.boot_end = 2.2 + 0.32 * len(self.rows) + 1.1
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
        self.rows = systems(self.units, self.now)
        self.sentences = briefing(self.job, self.units, self.now)
        self.tick = ticker(self.units, self.rows, self.now)
        self.agents = next((f["items"] for f in self.units if f["source"] == "agents"), [])

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
                scr.put(0, line, "─" * w, C["sky"])
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
                scr.put(x0 + cx, top + cy, "█", mix(C["sky"], C["blue"], cx / max(1, tw)))
            elif t > settle - 0.6:
                scr.put(x0 + cx, top + cy, rnd.choice(NOISE), rnd.choice([C["blue"], C["sapphire"], C["faint"]]))
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
        scr.put(2, 0, f"{self.name}  ", C["sky"])
        scr.put(2 + len(self.name) + 2, 0, self.meaning, C["dim"])
        hint = "space: brief me" if self.window else "space: brief again · esc: dismiss"
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
            big(scr, lx, body_top, now.strftime("%H:%M"), lambda cx, cy, tw: mix(C["sky"], C["blue"], cx / max(1, tw)))
            scr.put(lx + 20, body_top + 4, now.strftime("%S"), C["dim"])
            scr.put(lx, body_top + 6, now.strftime("%A %-d %B"), C["sub"])
            for i, (name, state, col, summary) in enumerate(self.rows):
                yy = body_top + 8 + i * 2
                if yy + 1 >= body_top + body_h:
                    break
                scr.put(lx, yy, "●", C[col])
                scr.put(lx + 2, yy, name.ljust(10), C["text"])
                scr.put(lx + 12, yy, state, C[col])
                scr.put(lx + 2, yy + 1, summary[: max(0, rx - lx - 4)], C["dim"])
            # right: vitals and the agent radar
            vx = rx + rw + 4
            vw = max(10, min(20, w - vx - 14))
            v = self.vitals
            bar(scr, vx, body_top, "CPU", v.cpu, vw)
            spark = "".join("▁▂▃▄▅▆▇█"[min(7, int(c / 12.5))] for c in v.history[-(vw + 9):])
            scr.put(vx + 5, body_top + 1, spark, C["teal"])
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
            scr.put((w - bw) // 2 + len(lines[-1]), by + len(lines) - 1, "▍", C["sky"])
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
        pane, shown, checked = os.environ.get("TMUX_PANE"), True, 0.0
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
