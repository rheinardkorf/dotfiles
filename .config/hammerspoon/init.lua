hs = hs 

-- Define meh as Alt+Shift+Ctrl
meh = {"ctrl", "shift", "alt"}
-- Define hyper as Alt+Shift+Ctrl+Cmd
hyper = {"cmd", "alt", "shift", "ctrl"}
-- Define ultra as Ctrl+Option+Cmd
ultra = {"ctrl", "alt", "cmd"}

-- Bind hyper + s to launch Slack
hs.hotkey.bind(hyper, "s", function()
    hs.application.launchOrFocus("Slack")
end)

-- Bind hyper + c to launch Outlook
hs.hotkey.bind(hyper, "c", function()
    hs.application.launchOrFocus("Microsoft Outlook")
end)

-- Bind meh + c to launch Calendar    
hs.hotkey.bind(meh, "c", function()
    hs.application.launchOrFocus("Calendar")
end)

-- Bind hyper + t to launch Ghostty
hs.hotkey.bind(hyper, "t", function()
    hs.application.launchOrFocus("Ghostty")
end)

-- Bind hyper + b to launch Brave
hs.hotkey.bind(hyper, "b", function()
    hs.application.launchOrFocus("Brave Browser")
end)

-- Bind hyper + d to launch Cursor
hs.hotkey.bind(hyper, "d", function()
    hs.application.launchOrFocus("Cursor")
end)

-- Bind meh + d to launch Visual Studio Code
hs.hotkey.bind(meh, "d", function()
    hs.application.launchOrFocus("Visual Studio Code")
end)

-- Let Sketchybar know when window states have changed.
hs.window.filter.default:subscribe(hs.window.filter.windowCreated, function(win)
    hs.execute('sketchybar --trigger aerospace_window_change',true)
end)

hs.window.filter.default:subscribe(hs.window.filter.windowDestroyed, function(win)
    hs.execute('sketchybar --trigger aerospace_window_change',true)
end)

