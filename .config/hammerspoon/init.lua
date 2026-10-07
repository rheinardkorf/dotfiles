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

-- Bind meh + d to launch Calendar (D for date)
hs.hotkey.bind(meh, "d", function()
    hs.application.launchOrFocus("Calendar")
end)

-- Bind hyper + t to launch kitty
hs.hotkey.bind(hyper, "t", function()
    hs.application.launchOrFocus("kitty")
end)

-- Bind hyper + b to launch Brave
hs.hotkey.bind(hyper, "b", function()
    hs.application.launchOrFocus("Brave Browser")
end)

-- Bind hyper + d to launch Cursor
hs.hotkey.bind(hyper, "d", function()
    hs.application.launchOrFocus("Cursor")
end)

-- Bind meh + c to global capture (nvim in panel)
hs.hotkey.bind(meh, "c", function()
    local home = os.getenv("HOME")
    hs.execute(home .. "/.scripts/kitty-panel capture " .. home .. "/.scripts/capture --width=600 --height=300 --edge=center-sized --opacity=1", true)
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
-- Machine name from ~/.config/machine-name (the MDM controls the computer name),
-- falling back to the system name if that file doesn't exist
local function machineName()
    local f = io.open(os.getenv("HOME") .. "/.config/machine-name", "r")
    if f then
        local name = f:read("*l")
        f:close()
        if name and name:match("%S") then return name:match("^%s*(.-)%s*$") end
    end
    return hs.host.localizedName()
end
local mac_hostname = machineName()
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

-- Machines that can't reach the MQTT broker (e.g. mantis, isolated from the home network)
local mqttDisabledOn = { mantis = true }

-- Run this check every 5 seconds (only where MQTT is reachable)
if mqttDisabledOn[mac_hostname] then
    print("MQTT camera/mic publishing disabled on " .. mac_hostname)
else
    cameraAndMicrophoneTimer = hs.timer.doEvery(5, checkCameraAndMicrophoneStatus)
end
