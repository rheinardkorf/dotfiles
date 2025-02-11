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

hs.hotkey.bind(meh, "Right", function()
    hs.spaces.MCwaitTime = 0.3 

    -- Get the current space ID
    local currentSpace = hs.spaces.focusedSpace()
    -- Get the screen containing the focused space
    local screen = hs.spaces.spaceDisplay(currentSpace)
    -- Get all spaces for this screen
    local spaces = hs.spaces.spacesForScreen(screen)
    
    -- Find current space index
    local currentIdx = 0
    for idx, space in ipairs(spaces) do
        if space == currentSpace then
            currentIdx = idx
            break
        end
    end
    
    -- Calculate next space index (with wraparound)
    local nextIdx = currentIdx % #spaces + 1
    -- Exit mission control if it's active
    hs.eventtap.keyStroke({}, "escape")
    -- Go to next space
    hs.spaces.gotoSpace(spaces[nextIdx])
end)

-- Bind ultra + Left Arrow to switch to previous Space
hs.hotkey.bind(meh, "Left", function()
    -- Get the current space ID
    local currentSpace = hs.spaces.focusedSpace()
    -- Get the screen containing the focused space
    local screen = hs.spaces.spaceDisplay(currentSpace)
    -- Get all spaces for this screen
    local spaces = hs.spaces.spacesForScreen(screen)
    
    -- Find current space index
    local currentIdx = 0
    for idx, space in ipairs(spaces) do
        if space == currentSpace then
            currentIdx = idx
            break
        end
    end
    
    -- Calculate previous space index (with wraparound)
    local prevIdx = (currentIdx - 2) % #spaces + 1
    -- Exit mission control if it's active
    hs.eventtap.keyStroke({}, "escape")
    -- Go to previous space
    hs.spaces.gotoSpace(spaces[prevIdx])
end)