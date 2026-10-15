# Helpers for sources' `summary` commands (jq -L ~/.config/panel/lib, then
# include "summary";). The input is the unit's facts from the HUD:
#   {view, count, unseen, bad, next: {title, at}, error, now, recent, items}
# (recent: the pane's "recent" window in seconds, default 24h)

# 3 -> "three" (up to twelve; digits after)
def words: if . >= 0 and . < 13 then ["no", "one", "two", "three", "four", "five", "six", "seven",
  "eight", "nine", "ten", "eleven", "twelve"][.] else tostring end;
# 3 | count("pull request"; "pull requests") -> "three pull requests"
def count($one; $many): "\(words) \(if . == 1 then $one else $many end)";
def cap: (.[0:1] | ascii_upcase) + .[1:];
# seconds -> "11h" / "40m" / "2d" (for lines)
def span: if . < 3600 then "\([. / 60 | floor, 1] | max)m" elif . < 86400 then "\(. / 3600 | floor)h" else "\(. / 86400 | floor)d" end;
# seconds -> "11 hours" (for spoken sentences)
def spoken: (if . < 3600 then [[. / 60 | floor, 1] | max, "minute"] elif . < 86400 then [. / 3600 | floor, "hour"]
  else [. / 86400 | floor, "day"] end) as [$n, $u] | "\($n) \($u)\(if $n == 1 then "" else "s" end)";
# a title without colour codes or a "  · reply?" style suffix
def clean: gsub("\u001b\\[[0-9;]*m"; "") | split("  ·")[0] | sub("^\\s+"; "") | sub("\\s+$"; "");
# items that changed within the pane's recent window: . as $f | [.items[] | fresh($f)]
def fresh($f): select((.updated // 0) >= $f.now - $f.recent);
