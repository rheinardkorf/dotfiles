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

-- Get the current window app id
hs.hotkey.bind(hyper, "i", function()
    local app = hs.window.focusedWindow():application()
    if app then
        local bundleID = app:bundleID()
        local windowTitle = hs.window.focusedWindow():title()
        local appName = app:name()
        hs.alert.show(appName .. " (" .. bundleID .. ")")
    else
        hs.alert.show("No active window")
    end
end)

local mqtt_host = os.getenv("MQTT_HOST") or "homeassistant.local"
local mqtt_user = os.getenv("MQTT_USER") or "default_user"
local mqtt_pass = os.getenv("MQTT_PASS") or "default_pass"
local mac_hostname = hs.host.localizedName()
local mqtt_topic = "office/" .. mac_hostname .. "/camera"

local lastCameraState = "OFF"
local statusFile = os.getenv("HOME") .. "/.camera_status"

function checkCameraStatus()
    local file = io.open(statusFile, "r")
    if not file then return end
    local status = file:read("*all"):gsub("%s+", "")
    file:close()

    if status == "ON" and lastCameraState ~= "ON" then
        lastCameraState = "ON"
        --hs.execute("mosquitto_pub -h " .. mqtt_host .. " -u " .. mqtt_user .. " -P " .. mqtt_pass .. " -t " .. mqtt_topic .. " -m 'Camera ON'")
        hs.alert.show("Camera is ON (" .. mac_hostname .. ")")
    elseif status == "OFF" and lastCameraState ~= "OFF" then
        lastCameraState = "OFF"
        --hs.execute("mosquitto_pub -h " .. mqtt_host .. " -u " .. mqtt_user .. " -P " .. mqtt_pass .. " -t " .. mqtt_topic .. " -m 'Camera OFF'")
        hs.alert.show("Camera is OFF (" .. mac_hostname .. ")")
    end
end

-- Run this check every 5 seconds
cameraTimer = hs.timer.doEvery(5, checkCameraStatus)


