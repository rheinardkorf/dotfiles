osascript <<END
tell application "Safari"
    set tabList to every tab of window 1
    set urlList to ""
    repeat with aTab in tabList
      set aTitle to Name of aTab
      set aLink to "[" & aTitle & "](" & URL of aTab & ")" & ASCII character 10
      set urlList to urlList & aLink
    end repeat
  return urlList
  end tell
END