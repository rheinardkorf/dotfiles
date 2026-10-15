# panel

A tmux control panel of fzf lists over cached data. **Sources** fetch data, a
**cache** holds it, the **engine** (`~/.scripts/panel`) runs everything, and
**tmux** shows it. Data only ever moves in one direction:

```
 Jira / GitHub / AWS / Google        (outside world)     Claude Code hooks
            │  only the fetcher talks to these               │ panel event agents
            ▼
 ┌──────────────────────┐   every N min,    ┌──────────────────────────────┐
 │  fetcher (tmux win)  │──runs──────────▶  │  source scripts              │
 │  panel fetcher work  │  per unit         │  ~/.config/panel/sources/*   │
 └──────────────────────┘                   │  jira · github · aws · calendar
            │                               └──────────────┬───────────────┘
            │ writes                                       │ fetch → JSON items
            ▼                                              ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │  cache  ~/.cache/panel/                                                │
 │   panes/<pane>[/<view>]/items.json, meta.json   ← the list per unit     │
 │   sources/<source>/…                            ← details for previews  │
 │   seen.json                                     ← what you've looked at │
 └────────────────────────────────────────────────────────────────────────┘
            ▲ reads only                           │ "reload" over a socket
            │                                      ▼
 ┌──────────────────────────────────────────────────────────────────────┐
 │  tmux session "panel":  one window per context, one fzf list per pane │
 │  jira · github · aws · calendar · fetch                              │
 └──────────────────────────────────────────────────────────────────────┘
```

## 1. Config: what you want to see

`config.<machine>.json` (committed; the machine name comes from
`~/.config/machine-name`), with `config.local.json` (not committed) merged on
top. JSON, with full-line `//` comments allowed. See `config.example.json`.

- **panes**: a source plus either one `query`, or several `views` (a list of
  names, or `{name: query}`). Each pane also has `every` (one interval, or one
  per view, e.g. `{"*": "5m", "dynamodb": "1h"}`), optional `hidden_views`,
  and `preview` (`"side"`: a narrow list with the preview beside it at any
  width, as rss does; by default the preview sits beside the list only when it
  gets 110 columns, so most windows stack). `"list": "title"` shows rows as just the
  title and its age, and `"count": false` keeps a pane out of its window's ●N
  (rss does both).
- **layouts**: windows mapped to panes. `panel up <layout>` builds them.
- **sources**: settings handed to each source script (profiles, orgs,
  exclusions, field labels, …).
- **global settings**: `seen_after`, `pause_when_idle`, `glow_style`.

The basic unit is a **unit**: a pane, or one view of a pane (`aws/sqs`,
`jira/sla`). Each unit is fetched, cached and listed on its own.

## 2. Sources: the only code that knows a service

Each source is a small zsh script in `sources/` with up to three commands:

| Command | Does | Rule |
|---|---|---|
| `fetch <query>` | prints the list as JSON items, and caches whatever previews will need | the **only** place that calls an API |
| `preview <id>` | prints one item as **Markdown** | reads the **cache only** |
| `search <words>` | prints `id<TAB>snippet` for items whose content matches | cache only (optional) |
| `summary <view>` | the HUD's say on a view: reads its facts (count, unseen, bad, next, error, items) on stdin, prints `{line, state, word, brief, ticker}` | cache only (optional) |
| `event` | records an event pushed to it on stdin (`panel event <source>`); exit 0 when something changed, printing ids to mark seen | optional; writes only to its cache |

Every item has the same basic shape: `id`, `title`, `status`, `updated`
(epoch seconds) and `url`. Optional extras:

- `key`: a short label for the key column
- `at`: a time to count down to (the age column shows `in 2h`)
- `seen`: the key seen state is kept under, when it isn't the id (e.g. a
  recurring meeting series)
- `spark` and `spark_colors`: a short strip of bars, one colour letter per bar
  (`g`reen, `r`ed, `y`ellow, `b`lue, `d`im, `o`range)
- `mark` and `mark_color`: the glyph shown instead of `●` / `◆` when unseen
- `status_color`: the status in that colour instead of dim
- `quiet_before`: a time; an item you've never looked at counts as seen then,
  so it's only marked when it changes after that (not just for being new)
- a `url` of `tmux:<target>` (e.g. `tmux:%33`) opens by switching tmux there

The engine knows nothing about any service: it only understands items, so a
new source is just a new script. Each source handles its service's quirks
internally:

- **jira** (acli): a second "updated recently" search, so details are only
  fetched for tickets that changed; `sla:<jql>` lists live SLA timers.
- **github** (gh): PR searches, Actions runs (all pages, one row per workflow
  per branch, a run-history spark), and contributions per person with flow
  stats (lead time, review wait); exclusions are fetched but never shown.
- **aws** (aws CLI): regions queried in parallel; alarms (with a 24h metric
  spark), CloudFormation stacks, DynamoDB tables (a config fingerprint marks
  changes), SQS queues (dead-letter queues with messages first).
- **calendar** (gog, always `--readonly`): today and the next days, with a
  countdown and RSVP state.
- **rss** (Python, standard library): RSS and Atom feeds; each view is a
  category whose query is its list of feeds (`config.local.json`, since a
  feed list is personal). Conditional requests (ETag / Last-Modified), feeds
  in parallel, the last 50 articles per feed; every article is new (●) until
  you've looked at it. Each article's picture is cached at fetch time (media tags or
  enclosure, else the first image in its text, else the page's og:image),
  as a small JPEG, and drawn above the preview with kitty's graphics protocol. Sparse
  articles (feed text under 200 characters: Hacker News, Lobsters, teasers)
  get their page read once at fetch time: its description and the opening of
  the article (readable text via trafilatura, run through uv; 40 pages per
  fetch, the pages themselves not kept), shown instead of the bare links.
- **agents** (local files): every running Claude Code session from
  `~/.claude/sessions/<pid>.json` (name, folder, busy / idle, tmux pane), with
  the title, last prompt and reply from its transcript, and this turn's
  sub-agents as indented rows. Its spark shows activity over the last hour and
  how full the context is (`context_window` in its config). Hooks in `~/.claude/settings.json` (async, all
  calling `panel event agents`) add what the files can't say: `●` finished
  (Stop, SubagentStop), `?` waiting on a permission prompt (also in the status
  column), and prompting the session clears the mark and its sub-agents. The
  last known state of every session is kept (`known/`), for showing or resuming
  ended sessions later. ctrl-o jumps to the session's tmux pane.

## 3. The engine: `~/.scripts/panel`

- **`panel up`** builds the tmux session from a layout: one window per
  context, one pane per entry. The fetcher runs in its own session,
  `panel-fetcher` (`tmux attach -t panel-fetcher` to watch it). Run again, it repairs the
  session: windows the layout has but the session lacks (known by their
  `@panel_name`) come back in the layout's order; nothing else is touched.
  `panel up -d` does the same without switching to it. **hyper+p**
  (Hammerspoon, `~/.scripts/panel-open`) opens the session from anywhere:
  it switches the last-used tmux client to it and brings kitty forward, or opens
  a kitty window attached to it when there is none.
- **The fetcher** (`panel fetcher`) loops every 15 seconds and fetches each
  unit whose interval has passed. Each fetch writes the list and a status file
  (`ok`, or the error, which becomes the pane's header). It pauses after
  `pause_when_idle` without keyboard or mouse input, and restarts itself when
  `panel` changes, so it never runs old code.
- **Locks**: each unit has a lock, so a ctrl-r fetch and the fetcher can't
  overlap ("already fetching").
- **Views**: each pane runs `panel view <pane>`, an fzf list fed by
  `panel _lines`, which turns cached items into lines (marker, key, status,
  countdown or age, spark, title). Columns size themselves to fit.
- **Pushes**: `panel event <source>` hands stdin to the source's `event`; when
  something changed it fetches the source's open panes at once and marks what
  the source says as seen. It never fails or prints, since hooks call it.
- **Live refresh**: each open view has its own socket (`fzf.<pid>.sock`).
  After a fetch, the fetcher sends "reload" to every open view of that pane;
  the list updates without moving the cursor.
- **Images**: a preview starting with `<!-- panel:image <path> -->` gets that
  picture drawn above the text (`kitten icat` with unicode placeholders, which
  pass through tmux and fzf; needs `allow-passthrough on`).
- **Preview**: fzf calls `panel _preview`, which runs the source's `preview`
  and renders the Markdown with glow (glow's own style, e.g. Catppuccin).
  Enter opens the same preview full-screen in glow's pager.
- **Per-view state**: small files keyed by the fzf instance's pid hold which
  view is showing (`view.<pid>`), find mode (`find.<pid>`) and revealed hidden
  views (`reveal.<pid>`). They're removed when the view exits.

## 4. Seen tracking: the quiet part

`seen.json` maps `source:id` (or the item's `seen` key) to the `updated` time
it had when you looked. Comparing that against the cache gives `●` (new),
`◆` (changed since you looked) or nothing. An item is marked seen after the
cursor rests on it for `seen_after`, but only while its pane is actually on
screen. Window names show the count of unseen items, leaving out hidden views,
and each view's tab in the header shows its own (`cloudformation ◆1`), so the
window's count can be traced to a view.

Sources control how noisy this is, through what they put in `updated`:
calendar tracks a recurring series rather than each instance, SQS only changes
when a dead-letter queue gains messages, DynamoDB only when its config
fingerprint changes, and contributions never.

## Actions and tags

A pane's `actions` map keys to tags: `"alt-r": {"tag": "later", "icon": "󰃀"}`.
The key toggles the tag on the item under the cursor (kept in `tags.json`, with
a copy of the item, under a lock), the row shows the icon, and a view whose
query is `tagged:later` lists the pane's tagged items, newest first, built from
the cache (never fetched). The source hears about it (`action <tag> <id>
on|off`): rss keeps a copy of a saved article and its picture in `saved.json`,
so it outlives its feed. The HUD mentions the reading list through rss's
summary of the `later` view.

## 5. Keys (terminal → kitty → fzf)

| Key | Does |
|---|---|
| tab / shift-tab | next / previous view |
| cmd-f (alt-f) | find inside items; esc leaves |
| cmd+shift+h (alt-h) | show / hide the pane's hidden views |
| enter / ctrl-o | full preview / open in the browser (agents: jump to the tmux pane) |
| alt-s / alt-u | mark all seen / mark this one unseen |
| alt-r (rss) | read later: toggle the article on the reading list (a pane's `actions`) |
| ctrl-r | fetch this view now |
| home / end | top / bottom of the list (page up / down: a page) |
| esc | clear the filter (or leave find) |

kitty maps cmd-f and cmd+shift+h to the alt keys: kitty has its own cmd-f
(scrollback search), and AeroSpace holds option-h.

## The HUD: `panel hud`

A full-screen assistant over everything, purely for show: cmd+shift+a (kitty)
sends prefix A, which opens it in a borderless tmux popup; esc closes it, space
skips the boot or repeats the briefing, and each system's key (shown beside
it) jumps to its window in the panel session, from anywhere (the popup then
closes). A pane's `key` in the config picks it (case matters, digits work: aws
is `a`, agents `A` on mantis); without one, a letter of its title. Code in `hud/` (Python, standard
library only).

- **Boot**: the assistant's name resolves out of noise, then a systems check
  (one line per pane: state and a short summary).
- **HUD**: an arc reactor (pulsing faster the busier your agents are, peach when
  one waits on you), the time, the Mac's CPU, memory and battery, a radar of
  agents and a ticker of facts.
- **Briefing**: spoken on open and typed along. `hud/speak.py` uses Kokoro (an
  offline voice model in `~/.local/share/kokoro`, run through `uv`), one
  sentence at a time, each cached by its text; without Kokoro it uses `say`.
- **Sources describe themselves**: the HUD knows no service. For each view it
  runs the source's `summary` (in parallel), which returns its line under the
  system, `state: "attention"` (row in peach, said first), the row's `word`
  (linked, nominal, ...), `brief` (phrasings of one spoken sentence, one picked
  at random) and `ticker` extras. Helpers for jq sources (number words,
  durations) are in `lib/summary.jq`. A pane's `summary` setting picks which
  views are asked (default all; aws asks alarms, sqs and cloudformation;
  `"pane"` asks the source once with all its views, for one line and one
  sentence, as rss does); a
  source without `summary` gets a plain count. A pane's `recent` window
  (default 24h) reaches every summary as `recent`, with the jq helper `fresh`,
  so "attention" can mean new trouble only: a stack that failed within the
  window, not one failed for months (that only shows in the grey line). The HUD itself only adds the greeting, panes
  that aren't reporting, and the sign-off.
- **HUD-only sources** (`assistant.sources`): no pane, window or fetch, just a
  summary when the HUD asks, and a key that runs their `open` command. The
  `streak` source reads `streak json` (the shared streak-log repo): quiet when
  today is logged or paused (with a heads-up before a pause), a gentle mention
  when it isn't, attention and an urgent sentence from 18:00
  (`sources.streak.urgent_from`); `s` opens the streak logger.
- **Per machine** (`assistant` in the config): mando is A.D.A. ("Adaptive
  Daily Attendant", voice `bf_isabella`), mantis is I.R.I.S. ("Intelligent
  Reporting & Insight System", a blend of `af_jessica` and `af_river`).
- **Look** (`assistant.theme` and `assistant.reactor`, both optional): the HUD
  draws with colour roles: `primary` (name, clock, core, keys), `secondary`
  (gradients, inner ring), `ring` (outer ring), `accent` (the shape in the
  reactor), `radar` (sweep, CPU spark) and `alert` (an agent waiting, rows
  needing attention). `theme` is a preset (`arc`, the default; `ember`,
  `matrix`, `nebula`), or `{"base": preset, role: colour, ...}` to change a few
  roles; a colour is a Catppuccin name (`mauve`, `pink`, `peach`, ...) or
  `#rrggbb`. `reactor` sets its pattern: `shape` (sides of the shape inside: 3
  is a triangle, 6 a hexagon, 0 none), `segments` (outer ring), `ticks`,
  `orbiters` and `speed` (1 = as now). The HUD window starts again when the
  config changes, so edits show at once.

As a window (a pane `{"type": "hud"}` in a layout; mantis has `iris` first) it
stays open and silent: space speaks the briefing, it reads the cache again every
15 seconds, and draws nothing while the window is off screen.

Everything it shows comes from the cache, like the panes; CPU, memory and
battery come from the Mac itself.

## Design rules

1. **Panes and previews never call an API.** Everything shown comes from the
   cache: instant, works offline, can't hammer a service.
2. **Sources are separate from the engine,** so adding a service doesn't touch
   `panel`.
3. **Quiet by default:** markers only for real change, an idle pause, hidden
   views, exclusions.
4. **No content history:** the cache holds only the current state. The only
   things kept over time are `seen.json` and numbers (hourly alarm metrics,
   contribution counts over the window).
5. **Public versus local:** the engine, sources and machine config live in
   public dotfiles; work details (profiles, orgs, exclusions, field labels)
   live in `config.local.json`.

## Writing a source

1. Create `sources/<name>` (executable), reading `$PANEL_SOURCE_CACHE` (its own
   cache folder) and `$PANEL_SOURCE_CONFIG` (its `sources.<name>` settings as
   JSON). `$PANEL_SINCE` is the last good fetch of the unit (epoch), if any.
2. `fetch <query>`: print a JSON array of items on stdout; errors on stderr
   (the last lines become the pane's header) and a non-zero exit.
3. `preview <id>`: print Markdown, from the cache only.
4. Optionally `search <words>`: print `id<TAB>snippet` lines, from the cache.
5. Add a pane (and a window in a layout) to the config.
