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

-- Retrieve environment variables from ~/.env
function getEnvVar(var)
    local envFile = os.getenv("HOME") .. "/.env"
    local cmd = "grep '^" .. var .. "=' " .. envFile .. " | cut -d '=' -f2-"
    local result, success, exit_type, rc = hs.execute(cmd, true)

    if rc == 0 and result and result ~= "" then
        return result:gsub("%s+", "") -- Trim spaces
    else
        return "MISSING"
    end
end

-- Load MQTT credentials from ~/.env
local mqtt_host = getEnvVar("MQTT_HOST")
local mqtt_user = getEnvVar("MQTT_USER")
local mqtt_pass = getEnvVar("MQTT_PASS")

-- Get the mosquitto_pub path dynamically
local mosquitto_pub = hs.execute("which mosquitto_pub", true):gsub("%s+", "")

-- Device and topic setup
local mac_hostname = hs.host.localizedName()
-- Camera topic
local mqtt_camera_topic = "office/" .. mac_hostname .. "/camera"
local lastCameraState = "OFF"
local cameraStatusFile = os.getenv("HOME") .. "/.camera_status"
-- Microphone topic
local mqtt_microphone_topic = "office/" .. mac_hostname .. "/microphone"
local lastMicrophoneState = "OFF"
local microphoneStatusFile = os.getenv("HOME") .. "/.mic_status"

-- Function to check camera status and publish MQTT message
function checkCameraAndMicrophoneStatus()
    if mosquitto_pub == "" then
        print("⚠️ ERROR: mosquitto_pub not found!")
        return
    end

    -- Check camera status
    local file = io.open(cameraStatusFile, "r")
    if not file then return end  -- Exit if file doesn't exist
    local cameraStatus = file:read("*all"):gsub("%s+", "")  -- Read and trim whitespace
    file:close()

    if cameraStatus == "ON" and lastCameraState ~= "ON" then
        lastCameraState = "ON"
        hs.execute(mosquitto_pub .. " -h " .. mqtt_host .. " -u " .. mqtt_user .. " -P " .. mqtt_pass .. " -t " .. mqtt_camera_topic .. " -m 'ON'")
    elseif cameraStatus == "OFF" and lastCameraState ~= "OFF" then
        lastCameraState = "OFF"
        hs.execute(mosquitto_pub .. " -h " .. mqtt_host .. " -u " .. mqtt_user .. " -P " .. mqtt_pass .. " -t " .. mqtt_camera_topic .. " -m 'OFF'")
    end

    -- Check microphone status
    local file = io.open(microphoneStatusFile, "r")
    if not file then return end  -- Exit if file doesn't exist
    local microphoneStatus = file:read("*all"):gsub("%s+", "")  -- Read and trim whitespace
    file:close()

    if microphoneStatus == "ON" and lastMicrophoneState ~= "ON" then
        lastMicrophoneState = "ON"
        hs.execute(mosquitto_pub .. " -h " .. mqtt_host .. " -u " .. mqtt_user .. " -P " .. mqtt_pass .. " -t " .. mqtt_microphone_topic .. " -m 'ON'")
    elseif microphoneStatus == "OFF" and lastMicrophoneState ~= "OFF" then
        lastMicrophoneState = "OFF"
        hs.execute(mosquitto_pub .. " -h " .. mqtt_host .. " -u " .. mqtt_user .. " -P " .. mqtt_pass .. " -t " .. mqtt_microphone_topic .. " -m 'OFF'")
    end
end

-- Run this check every 5 seconds
cameraAndMicrophoneTimer = hs.timer.doEvery(5, checkCameraAndMicrophoneStatus)
