osascript <<END
tell application "Brave Browser"
      set tabList to every tab of window 1
      set urlList to ""
      repeat with aTab in tabList
        set aTitle to Title of aTab
        set aLink to URL of aTab

        set urlList to urlList & aLink & ASCII character 13
      end repeat
      return urlList
    end tell
END