-- ASTRAL.WTF | VOID HIDE ULTIMATE
-- Developed by @opensourcedevv
-- Premium Void Teleport + Anti-Aim + Riot Bypass

local Teleport = loadstring(game:HttpGet("https://raw.githubusercontent.com/opensourcedevv/void/refs/heads/main/omg1.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)
local PANIC_KEY = Enum.KeyCode.P

-- Variables
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local OriginalCFrame = HumanoidRootPart.CFrame
local TeleportCount = 0
local isReturning = false
local returnStartTime = 0
local returnDuration = 0.5
local lastUpdate = 0
local jitterAngle = 0
local spinAngle = 0
local LastVoidPosition = nil
local ThirdPersonCameraState = {Type = nil, Subject = nil, FieldOfView = nil}
local CurrentAimTarget = nil
local AutoExecScheduled = false

-- Settings
local Settings = {
    VoidEnabled = false,
    VoidDistance = 1000000,
    VoidDistancePercent = 100,
    HeightOffset = 0,
    Mode = "None",
    SpinSpeed = 10,
    OrbitSpeed = 1.5,
    OrbitRadius = 25,
    DesyncSpeed = 50,
    
    RiotEnabled = false,
    RiotDistance = 10,
    RiotHeight = 0,
    RiotUpdateRate = 0.5,
    RiotTarget = nil,
    
    AAEnabled = false,
    AAPitch = "None",
    AAYawRange = 45,
    AAMode = "None",
    AASpeed = 15,

    RageEnabled = false,
    RageFOV = 90,
    RageSmooth = 12,
    RageTarget = nil,
    RageLead = 0.15,
    RageHeadPriority = true,
    RageTargetVoided = true,
    RageTargetAttackers = true,
    RageTargetPriority = "Attackers",
    RageVoidedThreshold = 15,

    VoidYMode = "Fixed",
    VoidYLevel = 0,
    VoidYAmplitude = 250,
    VoidYSpeed = 0.5,
    VoidRunEnabled = true,
    VoidMovementControls = true,
    VoidRunSpeed = 35,
    VoidWanderRadius = 45,
    VoidWanderSpeed = 0.35,
    VoidHopRadius = 1000000,
    VoidHopInterval = 1.0,
    VoidUpdateRate = 0.05,
    VoidFollowDistance = 20,
    VoidStrafeDistance = 18,
    VoidAttackEnabled = false,
    VoidAttackRange = 150,
    VoidAttackTargetPriority = "Closest",
    VoidAttackLead = 0.15,
    VoidAttackSmooth = 8,
    VoidAttackHeadPriority = true,
    VoidAttackAutoFire = false,
    VoidAttackAutoFireRate = 10,
    VoidAttackAutoFireRandomness = 0.03,
    UseCameraAim = true,
    AimRandomness = 0.02,
    ThirdPersonEnabled = false,
    ThirdPersonDistance = 16,
    ThirdPersonHeight = 6,
    FlyEnabled = false,
    FlySpeed = 60,
    FlyAscendSpeed = 35,
    AutoExecEnabled = false,
    AutoExecPath = "autoexec.lua",
    AutoExecDelay = 2.0,

    -- Legit bot settings
    LegitEnabled = false,
    LegitFOV = 30,
    LegitSmooth = 6,
    LegitHeadPriority = false,

    SoundId = "rbxassetid://719384308",
    SoundVolume = 0.5,
    EventSoundEnabled = true,
    EventSoundId = "rbxassetid://719384308",
    HitNotify = true,
    KillNotify = true,
    HitSoundEnabled = true,
    KillSoundEnabled = true,
    LowProfile = false,
    EnableKeybinds = false,
}

-- Autosave / Quickslots / ESP settings defaults
Settings.Autosave = false
Settings.AutosaveInterval = 30 -- seconds
Settings.QuickSlots = 3

Settings.ESPEnabled = false
Settings.ESPBoxes = true
Settings.ESPNames = true
Settings.ESPTeamCheck = true
Settings.ESPMaxDistance = 1000
Settings.ESPHealth = false

-- Export/Import helpers
local function exportConfigToClipboard(name)
    if not setclipboard then return false, "clipboard unavailable" end
    if not name or name == "" then return false, "invalid name" end
    if not isfile or not isfile(configPath(name)) then return false, "not found" end
    local ok, content = pcall(readfile, configPath(name))
    if not ok or not content then return false, "read error" end
    pcall(function() setclipboard(content) end)
    return true
end

local function importConfigFromClipboard()
    if not getclipboard then return false, "clipboard unavailable" end
    local ok, content = pcall(getclipboard)
    if not ok or not content then return false, "clipboard read failed" end
    local suc, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not suc or type(data) ~= "table" then return false, "parse error" end
    for k,v in pairs(data) do Settings[k] = v end
    return true
end

-- Quickslots
local function saveQuickSlot(slot)
    if not slot or slot < 1 then return false end
    return saveConfig("slot" .. tostring(slot))
end

local function loadQuickSlot(slot)
    if not slot or slot < 1 then return false end
    return loadConfig("slot" .. tostring(slot))
end

-- Autosave loop
spawn(function()
    while true do
        if Settings.Autosave then
            pcall(function()
                saveConfig("autosave")
            end)
        end
        task.wait(Settings.AutosaveInterval or 30)
    end
end)

-- ESP Implementation (uses Drawing where available)
local DrawingAvailable = (typeof(Drawing) == "table")
local ESPObjects = {}

local function createESPForPlayer(plr)
    if ESPObjects[plr] then return end
    local obj = {}
    if DrawingAvailable then
        obj.box = Drawing.new("Square")
        obj.box.Filled = false
        obj.box.Thickness = 1
        obj.box.Color = Color3.new(1, 0, 0)
        obj.box.Visible = false
        obj.name = Drawing.new("Text")
        obj.name.Size = 16
        obj.name.Color = Color3.new(1, 1, 1)
        obj.name.Center = true
        obj.name.Visible = false
        obj.name.Outline = true
        obj.name.OutlineColor = Color3.new(0, 0, 0)
    else
        -- fallback: create BillboardGui
        local tag = Instance.new("BillboardGui")
        tag.Size = UDim2.new(0, 120, 0, 30)
        tag.AlwaysOnTop = true
        tag.ResetOnSpawn = false
        tag.Adornee = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 1, 1, 1)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.new(1, 1, 1)
        txt.TextScaled = true
        txt.Font = Enum.Font.SourceSansBold
        txt.TextStrokeTransparency = 0.5
        txt.Parent = tag
        obj.gui = tag
        obj.txt = txt
        tag.Parent = game:GetService("CoreGui")
    end
    ESPObjects[plr] = obj
end

local function removeESPForPlayer(plr)
    local obj = ESPObjects[plr]
    if not obj then return end
    if DrawingAvailable then
        pcall(function()
            obj.box:Remove()
            obj.name:Remove()
        end)
    else
        pcall(function()
            if obj.gui then obj.gui:Destroy() end
        end)
    end
    ESPObjects[plr] = nil
end

local function updateESP()
    if not Settings.ESPEnabled then
        for p,_ in pairs(ESPObjects) do removeESPForPlayer(p) end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                if Settings.ESPTeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
                    removeESPForPlayer(plr)
                else
                    local root = plr.Character.HumanoidRootPart
                    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local dist = localRoot and (localRoot.Position - root.Position).Magnitude or 0
                    if dist > Settings.ESPMaxDistance then
                        removeESPForPlayer(plr)
                    else
                        createESPForPlayer(plr)
                        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                        local obj = ESPObjects[plr]
                        local displayText = plr.Name
                        if Settings.ESPHealth then
                            local health = math.floor(hum.Health)
                            displayText = displayText .. " | " .. health .. "hp"
                        end
                        displayText = displayText .. " (" .. math.floor(dist) .. "m)"
                        if DrawingAvailable then
                            if not onScreen or pos.Z < 0 then
                                obj.box.Visible = false
                                obj.name.Visible = false
                            else
                                local size = math.clamp(2000 / pos.Z, 6, 200)
                                obj.box.Visible = Settings.ESPBoxes
                                obj.box.Size = size
                                obj.box.Position = Vector2.new(pos.X - size/2, pos.Y - size/2)
                                obj.name.Visible = Settings.ESPNames
                                obj.name.Position = Vector2.new(pos.X, pos.Y - size/2 - 12)
                                obj.name.Text = displayText
                            end
                        else
                            if obj.gui and obj.txt then
                                obj.gui.Adornee = root
                                obj.txt.Text = displayText
                                obj.gui.Enabled = Settings.ESPBoxes or Settings.ESPNames
                            end
                        end
                    end
                end
            else
                removeESPForPlayer(plr)
            end
        else
            removeESPForPlayer(plr)
        end
    end
end

-- Sound Setup
local SoundService = game:GetService("SoundService")
local TeleportSound = Instance.new("Sound", SoundService)
TeleportSound.SoundId = Settings.SoundId
TeleportSound.Volume = Settings.SoundVolume

local EventSound = Instance.new("Sound", SoundService)
EventSound.SoundId = Settings.EventSoundId
EventSound.Volume = Settings.SoundVolume

local SoundIds = {
    Space = "rbxassetid://719384308",
    Pop = "rbxassetid://140323850218372",
    Bonk = "rbxassetid://18794851884",
    Skeet = "rbxassetid://83717596220569",
    Neverlose = "rbxassetid://97643101798871",
    Slip = "rbxassetid://70557734865364"
}

-- Config persistence
local HttpService = game:GetService("HttpService")
local ConfigFolder = "yesilarp_configs"
local IndexPath = ConfigFolder .. "/index.json"

local function ensureConfigFolder()
    if makefolder and not isfolder(ConfigFolder) then
        pcall(makefolder, ConfigFolder)
    end
end

local function readIndex()
    if isfile and isfile(IndexPath) then
        local ok, content = pcall(readfile, IndexPath)
        if ok and content and #content > 0 then
            local suc, data = pcall(function() return HttpService:JSONDecode(content) end)
            if suc and type(data) == "table" then
                return data
            end
        end
    end
    return {}
end

local function writeIndex(list)
    if writefile then
        pcall(writefile, IndexPath, HttpService:JSONEncode(list or {}))
    end
end

local function configPath(name)
    return ConfigFolder .. "/" .. name .. ".json"
end

local function getSoundNameById(soundId)
    for name,id in pairs(SoundIds) do
        if id == soundId then
            return name
        end
    end
    return "Space"
end

local function updateUIFromSettingsPart1()
    if VoidToggle then VoidToggle:SetValue(Settings.VoidEnabled) end
    if RiotToggle then RiotToggle:SetValue(Settings.RiotEnabled) end
    if AAToggle then AAToggle:SetValue(Settings.AAEnabled) end
    if LowProfileToggle then LowProfileToggle:SetValue(Settings.LowProfile) end
    if MotionModeDropdown then MotionModeDropdown:SetValue(Settings.Mode) end
    if MotionSpeedSlider then MotionSpeedSlider:SetValue(Settings.SpinSpeed) end
    if OrbitRadiusSlider then OrbitRadiusSlider:SetValue(Settings.OrbitRadius) end
    if VoidDistSlider then VoidDistSlider:SetValue(Settings.VoidDistancePercent) end
    if HeightOffsetSlider then HeightOffsetSlider:SetValue(Settings.HeightOffset) end
    if SoundSelectDropdown then SoundSelectDropdown:SetValue(getSoundNameById(Settings.SoundId)) end
    if EventSoundSelectDropdown then EventSoundSelectDropdown:SetValue(getSoundNameById(Settings.EventSoundId)) end
    if SoundVolumeSlider then SoundVolumeSlider:SetValue(Settings.SoundVolume * 100) end
    if EventSound then EventSound.Volume = Settings.SoundVolume end
    if RageToggle then RageToggle:SetValue(Settings.RageEnabled) end
    if RageFOVSlider then RageFOVSlider:SetValue(Settings.RageFOV) end
    if RageSmoothSlider then RageSmoothSlider:SetValue(Settings.RageSmooth) end
    if AAPitchDropdown then AAPitchDropdown:SetValue(Settings.AAPitch) end
    if AAModeDropdown then AAModeDropdown:SetValue(Settings.AAMode) end
    if AASpeedSlider then AASpeedSlider:SetValue(Settings.AASpeed) end
    if AAYawSlider then AAYawSlider:SetValue(Settings.AAYawRange) end
    if VoidMovementToggle then VoidMovementToggle:SetValue(Settings.VoidMovementControls) end
    if VoidRunSpeedSlider then VoidRunSpeedSlider:SetValue(Settings.VoidRunSpeed) end
    if VoidWanderRadiusSlider then VoidWanderRadiusSlider:SetValue(Settings.VoidWanderRadius) end
    if VoidHopRadiusSlider then VoidHopRadiusSlider:SetValue(Settings.VoidHopRadius) end
    if VoidHopIntervalSlider then VoidHopIntervalSlider:SetValue(Settings.VoidHopInterval) end
    if VoidYModeDropdown then VoidYModeDropdown:SetValue(Settings.VoidYMode) end
    if VoidYLevelSlider then VoidYLevelSlider:SetValue(Settings.VoidYLevel) end
    if VoidYAmplitudeSlider then VoidYAmplitudeSlider:SetValue(Settings.VoidYAmplitude) end
    if VoidYSpeedSlider then VoidYSpeedSlider:SetValue(Settings.VoidYSpeed) end
    if VoidAttackToggle then VoidAttackToggle:SetValue(Settings.VoidAttackEnabled) end
    if VoidAttackRangeSlider then VoidAttackRangeSlider:SetValue(Settings.VoidAttackRange) end
    if VoidAttackLeadSlider then VoidAttackLeadSlider:SetValue(Settings.VoidAttackLead) end
    if VoidAttackSmoothSlider then VoidAttackSmoothSlider:SetValue(Settings.VoidAttackSmooth) end
    if VoidAttackHeadToggle then VoidAttackHeadToggle:SetValue(Settings.VoidAttackHeadPriority) end
    if VoidAttackAutoFireToggle then VoidAttackAutoFireToggle:SetValue(Settings.VoidAttackAutoFire) end
    if VoidAttackAutoFireRateSlider then VoidAttackAutoFireRateSlider:SetValue(Settings.VoidAttackAutoFireRate) end
    if VoidAttackAutoFireRandomSlider then VoidAttackAutoFireRandomSlider:SetValue(Settings.VoidAttackAutoFireRandomness) end
end

local function updateUIFromSettingsPart2()
    if ThirdPersonToggle then ThirdPersonToggle:SetValue(Settings.ThirdPersonEnabled) end
    if ThirdPersonDistanceSlider then ThirdPersonDistanceSlider:SetValue(Settings.ThirdPersonDistance) end
    if ThirdPersonHeightSlider then ThirdPersonHeightSlider:SetValue(Settings.ThirdPersonHeight) end
    if FlyToggle then FlyToggle:SetValue(Settings.FlyEnabled) end
    if FlySpeedSlider then FlySpeedSlider:SetValue(Settings.FlySpeed) end
    if FlyAscendSpeedSlider then FlyAscendSpeedSlider:SetValue(Settings.FlyAscendSpeed) end
    if AutoExecToggle then AutoExecToggle:SetValue(Settings.AutoExecEnabled) end
    if AutoExecPathInput then AutoExecPathInput:SetValue(Settings.AutoExecPath) end
    if AutoExecDelaySlider then AutoExecDelaySlider:SetValue(Settings.AutoExecDelay) end
    if HitSoundToggle then HitSoundToggle:SetValue(Settings.HitSoundEnabled) end
    if KillSoundToggle then KillSoundToggle:SetValue(Settings.KillSoundEnabled) end
    if HitNotifyToggle then HitNotifyToggle:SetValue(Settings.HitNotify) end
    if KillNotifyToggle then KillNotifyToggle:SetValue(Settings.KillNotify) end
    if EventSoundToggle then EventSoundToggle:SetValue(Settings.EventSoundEnabled) end
    if ESPEnableToggle then ESPEnableToggle:SetValue(Settings.ESPEnabled) end
    if ESPBoxesToggle then ESPBoxesToggle:SetValue(Settings.ESPBoxes) end
    if ESPNamesToggle then ESPNamesToggle:SetValue(Settings.ESPNames) end
    if ESPTeamCheckToggle then ESPTeamCheckToggle:SetValue(Settings.ESPTeamCheck) end
    if ESPMaxDistanceSlider then ESPMaxDistanceSlider:SetValue(Settings.ESPMaxDistance) end
    if ESPHealthToggle then ESPHealthToggle:SetValue(Settings.ESPHealth) end
end

local function updateUIFromSettings()
    updateUIFromSettingsPart1()
    updateUIFromSettingsPart2()
end

local function saveConfig(name)
    if not name or tostring(name):gsub("%s+","") == "" then return false, "invalid name" end
    ensureConfigFolder()
    local ok, err = pcall(writefile, configPath(name), HttpService:JSONEncode(Settings))
    if ok then
        local idx = readIndex()
        if not table.find(idx, name) then
            table.insert(idx, name)
            writeIndex(idx)
        end
        return true
    end
    return false, err
end

local function loadConfig(name)
    if not name or tostring(name):gsub("%s+","") == "" then return false, "invalid name" end
    if not isfile or not isfile(configPath(name)) then return false, "not found" end
    local ok, content = pcall(readfile, configPath(name))
    if not ok or not content then return false, "read error" end
    local suc, data = pcall(HttpService.JSONDecode, HttpService, content)
    if not suc or type(data) ~= "table" then return false, "parse error" end

    -- apply settings
    for k,v in pairs(data) do
        Settings[k] = v
    end

    -- update some UI controls if present
    pcall(updateUIFromSettings)

    if Settings.AutoExecEnabled then
        scheduleAutoExec()
    end

    return true
end

local function deleteConfig(name)
    if not name or tostring(name):gsub("%s+","") == "" then return false end
    if isfile and isfile(configPath(name)) then
        pcall(function() delfile(configPath(name)) end)
    end
    local idx = readIndex()
    for i,v in ipairs(idx) do if v == name then table.remove(idx,i); break end end
    writeIndex(idx)
    return true
end

local function listConfigs()
    local idx = readIndex()
    return idx or {}
end
-- Helper Functions
local function isAlive()
    return Character and Character.Parent and HumanoidRootPart and HumanoidRootPart.Parent and Humanoid and Humanoid.Health > 0
end

-- Recent attackers tracking
local RecentAttackers = {}
local _lastHealth = Humanoid and Humanoid.Health or nil
local ATTACKER_WINDOW = 2 -- seconds to consider someone an attacker

local function cleanRecentAttackers()
    local now = os.time()
    for plr,t in pairs(RecentAttackers) do
        if (now - t) > ATTACKER_WINDOW then RecentAttackers[plr] = nil end
    end
end

-- Track health drops to guess attackers (best-effort heuristic)
spawn(function()
    while task.wait(0.2) do
        if Humanoid then
            local cur = Humanoid.Health
            if _lastHealth and cur < _lastHealth then
                -- damage detected, guess nearest player as attacker
                local nearest, nd = nil, math.huge
                if HumanoidRootPart then
                    for _,p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                            local r = p.Character.HumanoidRootPart
                            local d = (HumanoidRootPart.Position - r.Position).Magnitude
                            if d < nd then nd = d; nearest = p end
                        end
                    end
                end
                if nearest and nd <= 60 then
                    RecentAttackers[nearest] = os.time()
                end
            end
            _lastHealth = cur
        end
        cleanRecentAttackers()
    end
end)

local function playEventSound()
    if not Settings.EventSoundEnabled or Settings.LowProfile then
        return
    end

    pcall(function()
        EventSound.PlaybackSpeed = math.random(95, 105) / 100
        EventSound:Play()
    end)
end

local function addCombatLog(text)
    if HitLogLabel then
        pcall(function()
            HitLogLabel:SetText(text)
        end)
    end
end

local function handleCombatEvent(kind, plr, damage)
    local displayText = kind .. ": " .. plr.Name
    if damage and damage > 0 then
        displayText = displayText .. " -" .. damage .. "hp"
    end

    if kind == "Hit" and Settings.HitNotify then
        Teleport:Notify(displayText, 1.5)
    elseif kind == "Kill" and Settings.KillNotify then
        Teleport:Notify(displayText, 2)
    end

    if (kind == "Hit" and Settings.HitSoundEnabled) or (kind == "Kill" and Settings.KillSoundEnabled) then
        playEventSound()
    end

    addCombatLog(displayText)
end

local LastPlayerHealth = {}
local PlayerHealthConnections = {}

local function trackPlayerHealth(player, humanoid)
    if not humanoid then return end
    if PlayerHealthConnections[player] then
        PlayerHealthConnections[player]:Disconnect()
    end

    LastPlayerHealth[player] = humanoid.Health
    PlayerHealthConnections[player] = humanoid.HealthChanged:Connect(function(newHealth)
        local oldHealth = LastPlayerHealth[player] or newHealth
        if newHealth < oldHealth then
            local damage = math.floor(oldHealth - newHealth)
            if CurrentAimTarget == player then
                handleCombatEvent("Hit", player, damage)
            end
        end

        if newHealth <= 0 and oldHealth > 0 then
            if CurrentAimTarget == player then
                handleCombatEvent("Kill", player)
            end
        end

        LastPlayerHealth[player] = newHealth
    end)
end

local function connectPlayer(player)
    if player == LocalPlayer then return end

    local function onCharacter(char)
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            trackPlayerHealth(player, humanoid)
        else
            char.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") then
                    trackPlayerHealth(player, child)
                end
            end)
        end
    end

    if player.Character then
        onCharacter(player.Character)
    end

    player.CharacterAdded:Connect(onCharacter)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent and PlayerHealthConnections[player] then
            PlayerHealthConnections[player]:Disconnect()
            PlayerHealthConnections[player] = nil
            LastPlayerHealth[player] = nil
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    connectPlayer(player)
end

Players.PlayerAdded:Connect(connectPlayer)
Players.PlayerRemoving:Connect(function(player)
    if PlayerHealthConnections[player] then
        PlayerHealthConnections[player]:Disconnect()
        PlayerHealthConnections[player] = nil
    end
    LastPlayerHealth[player] = nil
end)

local function getRoot()
    return isAlive() and HumanoidRootPart or nil
end

local function triggerPanic()
    Settings.VoidEnabled = false
    Settings.VoidAttackEnabled = false
    Settings.RiotEnabled = false
    Settings.RageEnabled = false
    Settings.AAEnabled = false
    Settings.LegitEnabled = false
    Settings.ThirdPersonEnabled = false
    Settings.RageTarget = nil
    Settings.RiotTarget = nil
    CurrentAimTarget = nil

    pcall(function()
        if VoidToggle and VoidToggle.SetValue then VoidToggle:SetValue(false) end
        if VoidAttackToggle and VoidAttackToggle.SetValue then VoidAttackToggle:SetValue(false) end
        if RiotToggle and RiotToggle.SetValue then RiotToggle:SetValue(false) end
        if RageToggle and RageToggle.SetValue then RageToggle:SetValue(false) end
        if AAToggle and AAToggle.SetValue then AAToggle:SetValue(false) end
        if LegitToggle and LegitToggle.SetValue then LegitToggle:SetValue(false) end
        if ThirdPersonToggle and ThirdPersonToggle.SetValue then ThirdPersonToggle:SetValue(false) end
    end)

    restoreCamera()
    if Teleport and Teleport.Notify then Teleport:Notify("PANIC: ALL SYSTEMS OFF", 3) end
end

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
    OriginalCFrame = HumanoidRootPart.CFrame
    
    if Settings.VoidEnabled then
        task.wait(0.5)
        teleportToVoid()
    end
end)

-- Play teleport sound
local function playTeleportSound()
    if Settings.LowProfile then
        return
    end

    pcall(function()
        TeleportSound.PlaybackSpeed = math.random(95, 105) / 100
        TeleportSound:Play()
    end)
end

local function getVoidYOffset()
    local base = Settings.VoidYLevel
    if Settings.VoidYMode == "Sine" then
        return math.sin(tick() * Settings.VoidYSpeed) * Settings.VoidYAmplitude
    elseif Settings.VoidYMode == "Random" then
        return math.random(-Settings.VoidYAmplitude, Settings.VoidYAmplitude)
    end
    return base
end

-- Get void position
local function getVoidPosition()
    local voidY = Settings.VoidDistance + Settings.HeightOffset + getVoidYOffset()
    voidY = math.clamp(voidY, -1000000, 1000000)
    local root = getRoot()
    if not root then 
        return Vector3.new(0, voidY, 0)
    end
    
    if Settings.Mode == "Spin" then
        return Vector3.new(0, voidY, 0)
    elseif Settings.Mode == "Orbit" then
        return Vector3.new(0, voidY, 0)
    elseif Settings.Mode == "Random" then
        local x = math.random(-Settings.OrbitRadius, Settings.OrbitRadius)
        local z = math.random(-Settings.OrbitRadius, Settings.OrbitRadius)
        return Vector3.new(x, voidY, z)
    elseif Settings.Mode == "Hop" then
        if not voidHopTarget or tick() - voidHopTime > Settings.VoidHopInterval or (root.Position - voidHopTarget).Magnitude < 50 then
            local radius = math.max(Settings.VoidHopRadius, 1000)
            voidHopTarget = Vector3.new(
                math.random(-radius, radius),
                voidY,
                math.random(-radius, radius)
            )
            voidHopTime = tick()
        end
        return voidHopTarget
    elseif Settings.Mode == "Desync" then
        return Vector3.new(0, voidY, 0)
    else
        return Vector3.new(0, voidY, 0)
    end
end

-- Teleport to void
local function teleportToVoid()
    if not Settings.VoidEnabled then return end
    if not isAlive() then return end
    
    local root = getRoot()
    if not root then return end
    
    if not OriginalCFrame or OriginalCFrame.Position.Magnitude < 1 then
        OriginalCFrame = root.CFrame
    end
    
    local voidPos = getVoidPosition()
    local targetCFrame = CFrame.new(voidPos, voidPos + root.CFrame.LookVector)

    if not LastVoidPosition or (LastVoidPosition - voidPos).Magnitude > 0.1 then
        TeleportCount = TeleportCount + 1
        playTeleportSound()
        LastVoidPosition = voidPos

        -- Update UI
        if TeleportCounterLabel then
            TeleportCounterLabel:SetText("Teleports: " .. TeleportCount)
        end
        if TotalTeleportsLabel then
            TotalTeleportsLabel:SetText("Total Teleports: " .. TeleportCount)
        end
    end

    root.CFrame = targetCFrame
end

-- Apply motion effects
local wanderTarget = Vector3.new(0, 0, 0)
local voidHopTarget = nil
local voidHopTime = 0

local function applyManualVoidMovement(deltaTime)
    if not Settings.VoidMovementControls or not Settings.VoidEnabled or not Settings.VoidRunEnabled then
        return false
    end

    local root = getRoot()
    local cam = workspace.CurrentCamera
    if not root or not cam then return false end

    local moveDir = Vector3.new()
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end

    if moveDir.Magnitude > 0 then
        moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit * Settings.VoidRunSpeed * deltaTime
        local voidPos = getVoidPosition()
        local newPos = root.Position + moveDir
        newPos = Vector3.new(newPos.X, voidPos.Y + Settings.HeightOffset, newPos.Z)
        root.CFrame = CFrame.new(newPos, newPos + cam.CFrame.LookVector)
        return true
    end

    return false
end

local function applyMotion(deltaTime)
    if not Settings.VoidEnabled then return end
    if not isAlive() then return end
    
    local root = getRoot()
    if not root then return end
    
    spinAngle = spinAngle + (Settings.SpinSpeed * deltaTime)

    if applyManualVoidMovement(deltaTime) then
        return
    end

    local voidPos = getVoidPosition()
    local currentY = voidPos and voidPos.Y or (Settings.VoidDistance + Settings.HeightOffset)
    
    if Settings.Mode == "Spin" then
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, spinAngle, 0)
        
    elseif Settings.Mode == "Orbit" then
        local angle = spinAngle * Settings.OrbitSpeed
        local x = math.cos(angle) * Settings.OrbitRadius
        local z = math.sin(angle) * Settings.OrbitRadius
        root.CFrame = CFrame.new(Vector3.new(voidPos.X + x, currentY, voidPos.Z + z))
        
    elseif Settings.Mode == "Random" then
        if math.random(1, 100) < Settings.SpinSpeed * deltaTime then
            local randomX = math.random(-Settings.OrbitRadius, Settings.OrbitRadius)
            local randomZ = math.random(-Settings.OrbitRadius, Settings.OrbitRadius)
            root.CFrame = CFrame.new(Vector3.new(voidPos.X + randomX, currentY, voidPos.Z + randomZ))
        end
        
    elseif Settings.Mode == "Desync" then
        local desyncX = math.sin(spinAngle * Settings.DesyncSpeed) * 10
        local desyncZ = math.cos(spinAngle * Settings.DesyncSpeed) * 10
        root.CFrame = CFrame.new(Vector3.new(voidPos.X + desyncX, currentY, voidPos.Z + desyncZ))
        root.CFrame = root.CFrame * CFrame.Angles(math.sin(spinAngle) * 0.5, math.cos(spinAngle) * 0.5, 0)

    elseif Settings.Mode == "Wander" then
        if wanderTarget.Magnitude < 1 or (root.Position - (voidPos + wanderTarget)).Magnitude < 4 then
            wanderTarget = Vector3.new(
                math.random(-Settings.VoidWanderRadius, Settings.VoidWanderRadius),
                0,
                math.random(-Settings.VoidWanderRadius, Settings.VoidWanderRadius)
            )
        end
        local targetPos = voidPos + wanderTarget
        root.CFrame = CFrame.new(Vector3.new(targetPos.X, currentY, targetPos.Z))

    elseif Settings.Mode == "Chase" then
        local target = getNearestVoidAttackTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = target.Character.HumanoidRootPart
            local offset = (root.Position - targetRoot.Position).Unit * Settings.VoidFollowDistance
            local chasePos = targetRoot.Position + Vector3.new(offset.X, 0, offset.Z)
            root.CFrame = CFrame.new(Vector3.new(chasePos.X, currentY, chasePos.Z), targetRoot.Position)
        end

    elseif Settings.Mode == "Strafe" then
        local target = getNearestVoidAttackTarget()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = target.Character.HumanoidRootPart
            local angle = spinAngle * Settings.VoidWanderSpeed * 3
            local x = math.cos(angle) * Settings.VoidStrafeDistance
            local z = math.sin(angle) * Settings.VoidStrafeDistance
            local strafePos = targetRoot.Position + Vector3.new(x, 0, z)
            root.CFrame = CFrame.new(Vector3.new(strafePos.X, currentY, strafePos.Z), targetRoot.Position)
        end
    end
end

local function applyFly(deltaTime)
    if not Settings.FlyEnabled then return end
    if not isAlive() then return end

    local root = getRoot()
    local cam = workspace.CurrentCamera
    if not root or not cam then return end

    local horizontal = Vector3.new()
    if UIS:IsKeyDown(Enum.KeyCode.W) then horizontal = horizontal + cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then horizontal = horizontal - cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then horizontal = horizontal - cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then horizontal = horizontal + cam.CFrame.RightVector end

    local vertical = 0
    if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical = vertical + 1 end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = vertical - 1 end

    local direction = Vector3.new(horizontal.X, 0, horizontal.Z)
    if direction.Magnitude > 0 then
        direction = direction.Unit
    end

    if direction.Magnitude > 0 or vertical ~= 0 then
        local newPos = root.Position
        if direction.Magnitude > 0 then
            newPos = newPos + direction * Settings.FlySpeed * deltaTime
        end
        newPos = newPos + Vector3.new(0, vertical * Settings.FlyAscendSpeed * deltaTime, 0)
        root.CFrame = CFrame.new(newPos, newPos + cam.CFrame.LookVector)
    end
end

local function restoreCamera()
    local cam = workspace.CurrentCamera
    if not cam or not ThirdPersonCameraState.Type then return end
    pcall(function()
        cam.CameraType = ThirdPersonCameraState.Type
        cam.CameraSubject = ThirdPersonCameraState.Subject
        cam.FieldOfView = ThirdPersonCameraState.FieldOfView or cam.FieldOfView
    end)
    ThirdPersonCameraState = {Type = nil, Subject = nil, FieldOfView = nil}
end

local function applyThirdPerson()
    if not Settings.ThirdPersonEnabled then return end
    local root = getRoot()
    local cam = workspace.CurrentCamera
    if not root or not cam then return end

    if not ThirdPersonCameraState.Type then
        ThirdPersonCameraState.Type = cam.CameraType
        ThirdPersonCameraState.Subject = cam.CameraSubject
        ThirdPersonCameraState.FieldOfView = cam.FieldOfView
    end

    local distance = math.max(Settings.ThirdPersonDistance, 5)
    local height = Settings.ThirdPersonHeight
    local desiredPosition = root.Position - root.CFrame.LookVector * distance + Vector3.new(0, height, 0)
    local focusPosition = root.Position + Vector3.new(0, math.max(height * 0.35, 2), 0)
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.new(desiredPosition, focusPosition)
end

local function performAutoExec()
    if not Settings.AutoExecEnabled then return false, "disabled" end
    if not readfile or not isfile or not loadstring then return false, "unsupported" end
    local path = tostring(Settings.AutoExecPath or "")
    if path == "" then return false, "path empty" end
    if not isfile(path) then return false, "file not found" end
    local ok, content = pcall(readfile, path)
    if not ok or type(content) ~= "string" then return false, "read failed" end
    local fn, err = loadstring(content)
    if not fn then return false, "compile failed: " .. tostring(err) end
    local success, runErr = pcall(fn)
    if not success then return false, "execution failed: " .. tostring(runErr) end
    return true
end

local function scheduleAutoExec()
    if not Settings.AutoExecEnabled or AutoExecScheduled then return end
    AutoExecScheduled = true
    task.spawn(function()
        task.wait(math.max(Settings.AutoExecDelay, 0.1))
        local ok, err = performAutoExec()
        Teleport:Notify("AutoExec: " .. (ok and "success" or "failed: " .. tostring(err)), 3)
    end)
end

-- Anti-Aim System
local function applyAntiAim(deltaTime)
    if not Settings.AAEnabled then return end
    if not isAlive() then return end
    
    local root = getRoot()
    if not root then return end
    
    local pitch = 0
    local yaw = 0
    
    -- Pitch calculation
    if Settings.AAPitch == "Flip" then
        pitch = math.rad(180)
    elseif Settings.AAPitch == "Up" then
        pitch = math.rad(-90)
    elseif Settings.AAPitch == "Down" then
        pitch = math.rad(90)
    end
    
    -- Yaw calculation based on mode
    if Settings.AAMode == "Jitter" then
        jitterAngle = (jitterAngle + Settings.AASpeed * deltaTime * 10) % (Settings.AAYawRange * 2)
        yaw = math.rad(jitterAngle - Settings.AAYawRange)
        
    elseif Settings.AAMode == "Sway" then
        yaw = math.sin(spinAngle * (Settings.AASpeed / 5)) * math.rad(Settings.AAYawRange)
        
    elseif Settings.AAMode == "Inverter" then
        yaw = (math.floor(spinAngle * 2) % 2 == 0) and 0 or math.rad(180)
        
    elseif Settings.AAMode == "Spin" then
        yaw = spinAngle
    end
    
    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(pitch, yaw, 0)
end

-- Rage Bot Targeting
local function getTargetAngle(position)
    local camera = workspace.CurrentCamera
    if not camera then return math.huge end
    local direction = position - camera.CFrame.Position
    if direction.Magnitude == 0 then return 0 end
    local dot = math.clamp(camera.CFrame.LookVector:Dot(direction.Unit), -1, 1)
    return math.deg(math.acos(dot))
end

local function getNearestRageTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local voidPos = getVoidPosition()

    local function chooseAttackers()
        local best, bestAngle = nil, math.huge
        for plr,t in pairs(RecentAttackers) do
            if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                if (os.time() - t) <= ATTACKER_WINDOW then
                    local root = plr.Character.HumanoidRootPart
                    local angle = getTargetAngle(root.Position)
                    if angle <= Settings.RageFOV and angle < bestAngle then
                        bestAngle = angle
                        best = plr
                    end
                end
            end
        end
        return best
    end

    local function chooseVoided()
        if not Settings.RageTargetVoided then return nil end
        local best, bestDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local root = plr.Character.HumanoidRootPart
                    local d3 = (root.Position - voidPos).Magnitude
                    if d3 <= (Settings.RageVoidedThreshold or 15) then
                        local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                        local d = onScreen and (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).Magnitude or d3
                        if d < bestDist then
                            bestDist = d
                            best = plr
                        end
                    end
                end
            end
        end
        return best
    end

    local function chooseLowestHP()
        local best, bestHP = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local root = plr.Character.HumanoidRootPart
                    local angle = getTargetAngle(root.Position)
                    if angle <= Settings.RageFOV and hum.Health < bestHP then
                        bestHP = hum.Health
                        best = plr
                    end
                end
            end
        end
        return best
    end

    local function chooseClosest()
        local closest = nil
        local closestAngle = math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local root = plr.Character.HumanoidRootPart
                    local angle = getTargetAngle(root.Position)
                    if angle < closestAngle and angle <= Settings.RageFOV then
                        closestAngle = angle
                        closest = plr
                    end
                end
            end
        end
        return closest
    end

    if Settings.RageTargetPriority == "Attackers" then
        local target = chooseAttackers()
        if target then return target end
    elseif Settings.RageTargetPriority == "Voided" then
        local target = chooseVoided()
        if target then return target end
    elseif Settings.RageTargetPriority == "Lowest HP" then
        local target = chooseLowestHP()
        if target then return target end
    elseif Settings.RageTargetPriority == "Closest" then
        local target = chooseClosest()
        if target then return target end
    end

    if Settings.RageTargetAttackers then
        local target = chooseAttackers()
        if target then return target end
    end

    if Settings.RageTargetVoided then
        local target = chooseVoided()
        if target then return target end
    end

    return chooseClosest()
end

local function getRandomAimOffset()
    if not Settings.AimRandomness or Settings.AimRandomness <= 0 then
        return Vector3.new(0, 0, 0)
    end
    local r = Settings.AimRandomness
    return Vector3.new(
        (math.random() * 2 - 1) * r,
        (math.random() * 2 - 1) * r,
        (math.random() * 2 - 1) * r
    )
end

local function aimTarget(targetPosition, deltaTime, smooth)
    local root = getRoot()
    if not root then return end

    local desiredLook = (targetPosition - root.Position).Unit
    desiredLook = (desiredLook + getRandomAimOffset()).Unit

    local alpha = math.clamp((1 / math.max(smooth or 10, 0.001)) * deltaTime * 60, 0, 1)

    if Settings.UseCameraAim then
        local cam = workspace.CurrentCamera
        if cam then
            local currentLook = cam.CFrame.LookVector
            local newLook = currentLook:Lerp(desiredLook, alpha)
            cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + newLook)
        end
    end

    local currentLook = root.CFrame.LookVector
    local newLook = currentLook:Lerp(desiredLook, alpha)
    root.CFrame = CFrame.new(root.Position, root.Position + newLook)
end

local lastAutoFire = 0
local function performAutoFire()
    local now = tick()
    if now < lastAutoFire then return end
    lastAutoFire = now + (1 / math.max(Settings.VoidAttackAutoFireRate, 1))

    pcall(function()
        if mouse1click then
            mouse1click()
            return
        end
        if mouse1press and mouse1release then
            mouse1press()
            task.wait(0.02)
            mouse1release()
            return
        end
        if VirtualInputManager and Mouse then
            local x = Mouse.X + ((math.random() * 2 - 1) * Settings.VoidAttackAutoFireRandomness * 100)
            local y = Mouse.Y + ((math.random() * 2 - 1) * Settings.VoidAttackAutoFireRandomness * 100)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            return
        end
    end)
end

local function applyRageBot(deltaTime)
    if not Settings.RageEnabled then return end
    if not isAlive() then return end

    local target = getNearestRageTarget()
    if not target or not target.Character then
        Settings.RageTarget = nil
        CurrentAimTarget = nil
        return
    end

    CurrentAimTarget = target
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        Settings.RageTarget = nil
        return
    end

    Settings.RageTarget = target
    local root = getRoot()
    if not root then
        return
    end

    local desiredLook = (targetRoot.Position - root.Position).Unit
    -- head priority + simple lead prediction
    local aimPos = targetRoot.Position
    if Settings.RageHeadPriority and target.Character:FindFirstChild("Head") then
        aimPos = target.Character.Head.Position
    end
    local vel = targetRoot.Velocity or Vector3.new(0,0,0)
    aimPos = aimPos + vel * Settings.RageLead
    aimTarget(aimPos, deltaTime, Settings.RageSmooth)
end

local function getNearestVoidAttackTarget()
    local root = getRoot()
    if not root then return nil end

    if Settings.VoidAttackTargetPriority == "Attackers" then
        local best, closestDist = nil, math.huge
        for plr,t in pairs(RecentAttackers) do
            if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                if (os.time() - t) <= ATTACKER_WINDOW then
                    local targetRoot = plr.Character.HumanoidRootPart
                    local dist = (root.Position - targetRoot.Position).Magnitude
                    if dist <= Settings.VoidAttackRange and dist < closestDist then
                        closestDist = dist
                        best = plr
                    end
                end
            end
        end
        if best then return best end
    elseif Settings.VoidAttackTargetPriority == "Lowest HP" then
        local best, bestHP = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local targetRoot = plr.Character.HumanoidRootPart
                    local dist = (root.Position - targetRoot.Position).Magnitude
                    if dist <= Settings.VoidAttackRange and hum.Health < bestHP then
                        bestHP = hum.Health
                        best = plr
                    end
                end
            end
        end
        if best then return best end
    end

    local best, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local targetRoot = plr.Character.HumanoidRootPart
                local dist = (root.Position - targetRoot.Position).Magnitude
                if dist <= Settings.VoidAttackRange and dist < closestDist then
                    closestDist = dist
                    best = plr
                end
            end
        end
    end
    return best
end

local function applyVoidAttack(deltaTime)
    if not Settings.VoidAttackEnabled then return end
    if not Settings.VoidEnabled then return end
    if not isAlive() then return end

    local target = getNearestVoidAttackTarget()
    if not target or not target.Character then
        CurrentAimTarget = nil
        return
    end

    CurrentAimTarget = target
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local root = getRoot()
    if not root then return end

    local aimPos = targetRoot.Position
    if Settings.VoidAttackHeadPriority and target.Character:FindFirstChild("Head") then
        aimPos = target.Character.Head.Position
    end
    local vel = targetRoot.Velocity or Vector3.new(0,0,0)
    aimPos = aimPos + vel * Settings.VoidAttackLead

    aimTarget(aimPos, deltaTime, Settings.VoidAttackSmooth)
    if Settings.VoidAttackAutoFire then
        performAutoFire()
    end
end

-- Legit Bot implementation
local function getNearestLegitTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local closest, closestAngle = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local root = plr.Character.HumanoidRootPart
                local angle = getTargetAngle(root.Position)
                if angle < closestAngle and angle <= Settings.LegitFOV then
                    closestAngle = angle
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function applyLegitBot(deltaTime)
    if not Settings.LegitEnabled then return end
    if not isAlive() then return end

    local target = getNearestLegitTarget()
    if not target or not target.Character then
        Settings.RageTarget = nil
        CurrentAimTarget = nil
        if LegitTargetLabel then LegitTargetLabel:SetText("Target: None") end
        return
    end

    CurrentAimTarget = target

    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        Settings.RageTarget = nil
        return
    end

    Settings.RageTarget = target
    if LegitTargetLabel then LegitTargetLabel:SetText("Target: "..target.Name) end
    local root = getRoot()
    if not root then return end

    local aimPos = targetRoot.Position
    if Settings.LegitHeadPriority and target.Character:FindFirstChild("Head") then
        aimPos = target.Character.Head.Position
    end
    aimTarget(aimPos, deltaTime, Settings.LegitSmooth)
end

-- Riot Bypass - Find nearest player
local function isEnemyPlayer(plr)
    if not plr or plr == LocalPlayer then
        return false
    end
    if LocalPlayer.Team and plr.Team then
        return plr.Team ~= LocalPlayer.Team
    end
    return true
end

local function findNearestPlayer()
    local closest = nil
    local closestDist = math.huge
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemyPlayer(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local root = plr.Character.HumanoidRootPart
                local dist = (HumanoidRootPart.Position - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = plr
                end
            end
        end
    end
    
    return closest
end

local function updateRiotTarget()
    if not Settings.RiotEnabled then return end
    
    local target = findNearestPlayer()
    if target then
        Settings.RiotTarget = target
        if RiotTargetLabel then
            RiotTargetLabel:SetText("Target: " .. target.Name)
        end
    else
        Settings.RiotTarget = nil
        if RiotTargetLabel then
            RiotTargetLabel:SetText("Target: None")
        end
    end
end

local function applyRiotBypass(deltaTime)
    if not Settings.RiotEnabled then return end
    if not isAlive() then return end
    
    if not Settings.RiotTarget or not Settings.RiotTarget.Character then
        updateRiotTarget()
        return
    end
    
    local targetRoot = Settings.RiotTarget.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Get position behind target
    local targetPos = targetRoot.Position
    local targetLook = targetRoot.CFrame.LookVector
    local behindPos = targetPos - targetLook * Settings.RiotDistance
    behindPos = behindPos + Vector3.new(0, Settings.RiotHeight, 0)
    
    -- Smooth movement
    HumanoidRootPart.CFrame = CFrame.new(behindPos, targetPos)
end

-- Main update loop
local lastVoidUpdate = 0
RunService.Heartbeat:Connect(function(deltaTime)
    if not isAlive() then return end
    
    local ok, err = pcall(function()
        -- Return to original position when disabling void
        if isReturning then
            local elapsed = tick() - returnStartTime
            if elapsed < returnDuration then
                local alpha = elapsed / returnDuration
                local newPos = HumanoidRootPart.Position:Lerp(OriginalCFrame.Position, alpha)
                HumanoidRootPart.CFrame = CFrame.new(newPos)
            else
                HumanoidRootPart.CFrame = OriginalCFrame
                isReturning = false
            end
            return
        end

        local now = tick()
        local doVoidUpdate = false
        if Settings.VoidEnabled and now - lastVoidUpdate >= math.max(Settings.VoidUpdateRate, 0.01) then
            doVoidUpdate = true
            lastVoidUpdate = now
        end

        if Settings.ThirdPersonEnabled then
            applyThirdPerson()
        else
            restoreCamera()
        end

        if doVoidUpdate then
            teleportToVoid()
            applyMotion(deltaTime)
        end

        if Settings.FlyEnabled then
            applyFly(deltaTime)
        end

        -- Anti-Aim
        if Settings.AAEnabled then
            applyAntiAim(deltaTime)
        end

        -- Void attack takes precedence when in void
        if Settings.VoidEnabled and Settings.VoidAttackEnabled then
            applyVoidAttack(deltaTime)
        elseif Settings.LegitEnabled then
            applyLegitBot(deltaTime)
        elseif Settings.RageEnabled then
            applyRageBot(deltaTime)
        end

        -- Riot Bypass
        if Settings.RiotEnabled then
            if now - lastUpdate > Settings.RiotUpdateRate then
                updateRiotTarget()
                lastUpdate = now
            end
            applyRiotBypass(deltaTime)
        end

        -- ESP update
        pcall(updateESP)
    end)

    if not ok then
        warn("omg.lua heartbeat error:", err)
    end
end)

-- Create UI Window
local VoidToggle, VoidDistSlider, HeightOffsetSlider, VoidYModeDropdown, VoidYLevelSlider, VoidYAmplitudeSlider, VoidYSpeedSlider, VoidAttackToggle, VoidAttackRangeSlider, VoidAttackLeadSlider, VoidAttackSmoothSlider, VoidAttackHeadToggle, VoidAttackAutoFireToggle, VoidAttackAutoFireRateSlider, VoidAttackAutoFireRandomSlider, TeleportCounterLabel, LowProfileToggle, MotionModeDropdown, VoidMovementToggle, VoidRunSpeedSlider, VoidWanderRadiusSlider, VoidHopRadiusSlider, VoidHopIntervalSlider, MotionSpeedSlider, OrbitRadiusSlider, RiotToggle, RiotTargetLabel, LegitTargetLabel, SoundSelectDropdown, EventSoundSelectDropdown, EventSoundToggle, HitSoundToggle, KillSoundToggle, HitNotifyToggle, KillNotifyToggle, SoundVolumeSlider, TotalTeleportsLabel, HitLogLabel, VoidKeybind, RiotKeybind, AAToggle, AAPitchDropdown, AAYawSlider, AAModeDropdown, AASpeedSlider, RageToggle, RageFOVSlider, RageSmoothSlider, RageTargetLabel, ESPEnableToggle, ESPBoxesToggle, ESPNamesToggle, ESPTeamCheckToggle, ESPMaxDistanceSlider, ESPHealthToggle, ThirdPersonToggle, ThirdPersonDistanceSlider, ThirdPersonHeightSlider, FlyToggle, FlySpeedSlider, FlyAscendSpeedSlider, AutoExecToggle, AutoExecPathInput, AutoExecDelaySlider

local function buildUI()
    Window = Teleport:CreateWindow({
        Title = "ASTRAL.WTF | VOID HIDE",
        Center = true,
        Footer = "Developed by @opensourcedevv | Premium Script",
        ToggleKeybind = Enum.KeyCode.RightShift,
        Size = UDim2.fromOffset(650, 550),
        AutoShow = true
    })

-- ==================== VOID TAB ====================
VoidTab = Window:AddTab("Void")
VoidGroup = VoidTab:AddLeftGroupbox("Void Teleport")

-- Enable Void Toggle with Keybind
VoidToggle = VoidGroup:AddCheckbox("EnableVoid", {
    Text = "Enable Void Hide",
    Default = false,
    Callback = function(value)
        Settings.VoidEnabled = value
        if value then
            OriginalCFrame = HumanoidRootPart.CFrame
            teleportToVoid()
            Teleport:Notify("Void Hide: ACTIVE", 2)
        else
            isReturning = true
            returnStartTime = tick()
            LastVoidPosition = nil
            Teleport:Notify("Void Hide: DEACTIVATED", 2)
        end
    end
})

-- Void Keybind (created only if keybinds enabled)
VoidKeybind = nil

-- Void Distance Slider
VoidDistSlider = VoidGroup:AddSlider("VoidDist", {
    Text = "Void Distance",
    Default = 100,
    Max = 100,
    Min = 1,
    Suffix = "%",
    Rounding = 0,
    Callback = function(value)
        Settings.VoidDistancePercent = value
        Settings.VoidDistance = value * 10000
    end
})

-- Height Offset Slider
HeightOffsetSlider = VoidGroup:AddSlider("HeightOffset", {
    Text = "Height Offset",
    Default = 0,
    Max = 1000,
    Min = -1000,
    Suffix = " studs",
    Rounding = 0,
    Callback = function(value)
        Settings.HeightOffset = value
    end
})

-- Void Y Position and Mode
VoidYModeDropdown = VoidGroup:AddDropdown("VoidYMode", {
    Text = "Void Y Mode",
    Values = {"Fixed", "Sine", "Random"},
    Default = "Fixed",
    Callback = function(value)
        Settings.VoidYMode = value
    end
})

VoidYLevelSlider = VoidGroup:AddSlider("VoidYLevel", {
    Text = "Void Y Offset",
    Default = 0,
    Max = 1000,
    Min = -1000,
    Suffix = " studs",
    Rounding = 0,
    Callback = function(value)
        Settings.VoidYLevel = value
    end
})

VoidYAmplitudeSlider = VoidGroup:AddSlider("VoidYAmplitude", {
    Text = "Void Y Amplitude",
    Default = 250,
    Max = 2000,
    Min = 0,
    Suffix = " studs",
    Rounding = 0,
    Callback = function(value)
        Settings.VoidYAmplitude = value
    end
})

VoidYSpeedSlider = VoidGroup:AddSlider("VoidYSpeed", {
    Text = "Void Y Speed",
    Default = 0.5,
    Max = 5,
    Min = 0.1,
    Suffix = " Hz",
    Rounding = 1,
    Callback = function(value)
        Settings.VoidYSpeed = value
    end
})

-- Void Attack Settings
VoidAttackToggle = VoidGroup:AddCheckbox("VoidAttackEnabled", {
    Text = "Enable Void Attack",
    Default = false,
    Callback = function(value)
        Settings.VoidAttackEnabled = value
        Teleport:Notify("Void Attack: " .. (value and "ACTIVE" or "DEACTIVATED"), 2)
    end
})

VoidAttackRangeSlider = VoidGroup:AddSlider("VoidAttackRange", {
    Text = "Attack Range",
    Default = 150,
    Max = 500,
    Min = 25,
    Suffix = " studs",
    Rounding = 0,
    Callback = function(value)
        Settings.VoidAttackRange = value
    end
})

local VoidAttackTargetPriorityDropdown = VoidGroup:AddDropdown("VoidAttackTargetPriority", {
    Text = "Target Priority",
    Values = {"Closest", "Lowest HP", "Attackers"},
    Default = Settings.VoidAttackTargetPriority,
    Callback = function(value)
        Settings.VoidAttackTargetPriority = value
    end
})

VoidAttackLeadSlider = VoidGroup:AddSlider("VoidAttackLead", {
    Text = "Attack Lead",
    Default = 0.15,
    Max = 1,
    Min = 0,
    Rounding = 2,
    Callback = function(value)
        Settings.VoidAttackLead = value
    end
})

VoidAttackSmoothSlider = VoidGroup:AddSlider("VoidAttackSmooth", {
    Text = "Attack Smoothness",
    Default = 8,
    Max = 30,
    Min = 0,
    Rounding = 1,
    Callback = function(value)
        Settings.VoidAttackSmooth = value
    end
})

VoidAttackHeadToggle = VoidGroup:AddCheckbox("VoidAttackHeadPriority", {
    Text = "Aim Head While Void",
    Default = true,
    Callback = function(value)
        Settings.VoidAttackHeadPriority = value
    end
})

VoidAttackAutoFireToggle = VoidGroup:AddCheckbox("VoidAttackAutoFire", {
    Text = "Auto Fire While Void",
    Default = false,
    Callback = function(value)
        Settings.VoidAttackAutoFire = value
    end
})

VoidAttackAutoFireRateSlider = VoidGroup:AddSlider("VoidAttackAutoFireRate", {
    Text = "Auto Fire Rate",
    Default = 10,
    Max = 30,
    Min = 1,
    Rounding = 0,
    Callback = function(value)
        Settings.VoidAttackAutoFireRate = value
    end
})

VoidAttackAutoFireRandomSlider = VoidGroup:AddSlider("VoidAttackAutoFireRandomness", {
    Text = "Fire Randomness",
    Default = 0.03,
    Max = 0.2,
    Min = 0,
    Rounding = 3,
    Callback = function(value)
        Settings.VoidAttackAutoFireRandomness = value
    end
})

-- Teleport Counter
TeleportCounterLabel = VoidGroup:AddLabel("Teleports: 0")

-- Low Profile Mode Toggle
LowProfileToggle = VoidGroup:AddCheckbox("LowProfile", {
    Text = "Low Profile Mode",
    Default = false,
    Callback = function(value)
        Settings.LowProfile = value
        Teleport:Notify("Low Profile: " .. (value and "ENABLED" or "DISABLED"), 2)
    end
})

-- Motion Settings Group
MotionGroup = VoidTab:AddRightGroupbox("Motion Effects")

-- Current Pattern Label
CurrentPatternLabel = MotionGroup:AddLabel("Current Pattern: None")

-- Motion Mode Dropdown
MotionModeDropdown = MotionGroup:AddDropdown("MotionMode", {
    Text = "Movement Pattern",
    Values = {"None", "Spin", "Orbit", "Random", "Desync", "Wander", "Chase", "Strafe", "Hop"},
    Default = "None",
    Callback = function(value)
        Settings.Mode = value
        CurrentPatternLabel:SetText("Current Pattern: " .. value)
    end
})

VoidMovementToggle = MotionGroup:AddCheckbox("VoidMovementControls", {
    Text = "WASD Void Run",
    Default = true,
    Callback = function(value)
        Settings.VoidMovementControls = value
    end
})

VoidRunSpeedSlider = MotionGroup:AddSlider("VoidRunSpeed", {
    Text = "Void Run Speed",
    Default = 35,
    Max = 120,
    Min = 5,
    Rounding = 0,
    Callback = function(value)
        Settings.VoidRunSpeed = value
    end
})

VoidWanderRadiusSlider = MotionGroup:AddSlider("VoidWanderRadius", {
    Text = "Wander Radius",
    Default = 45,
    Max = 200,
    Min = 5,
    Rounding = 0,
    Callback = function(value)
        Settings.VoidWanderRadius = value
    end
})

VoidHopRadiusSlider = MotionGroup:AddSlider("VoidHopRadius", {
    Text = "Hop Radius",
    Default = 1000000,
    Max = 5000000,
    Min = 100000,
    Suffix = " studs",
    Rounding = 0,
    Callback = function(value)
        Settings.VoidHopRadius = value
    end
})

VoidHopIntervalSlider = MotionGroup:AddSlider("VoidHopInterval", {
    Text = "Hop Interval",
    Default = 1.0,
    Max = 5,
    Min = 0.2,
    Rounding = 2,
    Callback = function(value)
        Settings.VoidHopInterval = value
    end
})

-- Movement Speed Slider
MotionSpeedSlider = MotionGroup:AddSlider("BaseSpeed", {
    Text = "Movement Speed",
    Default = 10,
    Max = 100,
    Min = 0,
    Rounding = 1,
    Callback = function(value)
        Settings.SpinSpeed = value
    end
})

-- Orbit Radius Slider
OrbitRadiusSlider = MotionGroup:AddSlider("Radius", {
    Text = "Effect Radius",
    Default = 25,
    Max = 200,
    Min = 1,
    Rounding = 0,
    Callback = function(value)
        Settings.OrbitRadius = value
    end
})

-- ==================== RIOT BYPASS TAB ====================
RiotTab = Window:AddTab("Riot Bypass")
RiotGroup = RiotTab:AddLeftGroupbox("Riot Bypass Settings")

RiotToggle = RiotGroup:AddCheckbox("EnableRiot", {
    Text = "Enable Riot Bypass",
    Default = false,
    Callback = function(value)
        Settings.RiotEnabled = value
        if value then
            updateRiotTarget()
            Teleport:Notify("Riot Bypass: ACTIVE", 2)
        else
            Teleport:Notify("Riot Bypass: DEACTIVATED", 2)
        end
    end
})

RiotKeybind = nil

RiotDistSlider = RiotGroup:AddSlider("RiotDist", {
    Text = "Distance Behind",
    Default = 10,
    Max = 50,
    Min = 0,
    Suffix = " studs",
    Rounding = 1,
    Callback = function(value)
        Settings.RiotDistance = value
    end
})

RiotHeightSlider = RiotGroup:AddSlider("RiotHeight", {
    Text = "Height Offset",
    Default = 0,
    Max = 20,
    Min = -20,
    Suffix = " studs",
    Rounding = 1,
    Callback = function(value)
        Settings.RiotHeight = value
    end
})
    
RiotUpdateSlider = RiotGroup:AddSlider("RiotUpdateRate", {
    Text = "Target Update Rate",
    Default = 0.5,
    Max = 5,
    Min = 0.1,
    Suffix = "s",
    Rounding = 1,
    Callback = function(value)
        Settings.RiotUpdateRate = value
    end
})

RiotTargetLabel = RiotGroup:AddLabel("Target: None")

    
AntiAimTab = Window:AddTab("Anti Aim")
AAGroup = AntiAimTab:AddLeftGroupbox("Anti-Aim Settings")

AAToggle = AAGroup:AddCheckbox("EnableAA", {
    Text = "Enable Anti-Aim",
    Default = false,
    Callback = function(value)
        Settings.AAEnabled = value
        Teleport:Notify("Anti-Aim: " .. (value and "ACTIVE" or "DEACTIVATED"), 2)
    end
})

AAPitchDropdown = AAGroup:AddDropdown("AAPitch", {
    Text = "Pitch Angle",
    Values = {"Flip", "Up", "Down", "None"},
    Default = "None",
    Callback = function(value)
        Settings.AAPitch = value
    end
})

AAYawSlider = AAGroup:AddSlider("JitterRange", {
    Text = "Rotate Amount",
    Default = 45,
    Max = 360,
    Min = 0,
    Suffix = "°",
    Rounding = 1,
    Callback = function(value)
        Settings.AAYawRange = value
    end
})

AAModeDropdown = AAGroup:AddDropdown("AAMode", {
    Text = "Anti-Aim Type",
    Values = {"Jitter", "Sway", "Inverter", "Spin", "None"},
    Default = "None",
    Callback = function(value)
        Settings.AAMode = value
    end
})

AASpeedSlider = AAGroup:AddSlider("AASpeed", {
    Text = "Anti-Aim Speed",
    Default = 15,
    Max = 30,
    Min = 1,
    Suffix = " Hz",
    Rounding = 0,
    Callback = function(value)
        Settings.AASpeed = value
    end
})

RageTab = Window:AddTab("Rage Bot")
RageGroup = RageTab:AddLeftGroupbox("Rage Bot Settings")

RageToggle = RageGroup:AddCheckbox("EnableRage", {
    Text = "Enable Rage Bot",
    Default = false,
    Callback = function(value)
        Settings.RageEnabled = value
        Teleport:Notify("Rage Bot: " .. (value and "ACTIVE" or "DEACTIVATED"), 2)
    end
})

RageKeybind = nil

RageFOVSlider = RageGroup:AddSlider("RageFOV", {
    Text = "Rage FOV",
    Default = 90,
    Max = 180,
    Min = 10,
    Suffix = "°",
    Rounding = 0,
    Callback = function(value)
        Settings.RageFOV = value
    end
})

RageSmoothSlider = RageGroup:AddSlider("RageSmooth", {
    Text = "Aim Smoothness",
    Default = 12,
    Max = 30,
    Min = 0,
    Suffix = "",
    Rounding = 1,
    Callback = function(value)
        Settings.RageSmooth = value
    end
})

RageTargetLabel = RageGroup:AddLabel("Target: None")

RageTargetVoidedToggle = RageGroup:AddCheckbox("RageTargetVoided", {
    Text = "Target Voided Players",
    Default = Settings.RageTargetVoided,
    Callback = function(v) Settings.RageTargetVoided = v end
})

RageTargetAttackersToggle = RageGroup:AddCheckbox("RageTargetAttackers", {
    Text = "Target Recent Attackers",
    Default = Settings.RageTargetAttackers,
    Callback = function(v) Settings.RageTargetAttackers = v end
})

local RageTargetPriorityDropdown = RageGroup:AddDropdown("RageTargetPriority", {
    Text = "Target Priority",
    Values = {"Attackers", "Voided", "Closest", "Lowest HP"},
    Default = Settings.RageTargetPriority,
    Callback = function(value)
        Settings.RageTargetPriority = value
    end
})

LegitGroup = RageTab:AddRightGroupbox("Legit Bot Settings")

LegitToggle = LegitGroup:AddCheckbox("EnableLegit", {
    Text = "Enable Legit Bot",
    Default = Settings.LegitEnabled,
    Callback = function(v)
        Settings.LegitEnabled = v
        Teleport:Notify("Legit Bot: " .. (v and "ACTIVE" or "DEACTIVATED"), 2)
    end
})

LegitFOVSlider = LegitGroup:AddSlider("LegitFOV", {
    Text = "Legit FOV",
    Default = Settings.LegitFOV,
    Max = 180,
    Min = 5,
    Suffix = "°",
    Rounding = 0,
    Callback = function(value) Settings.LegitFOV = value end
})

LegitSmoothSlider = LegitGroup:AddSlider("LegitSmooth", {
    Text = "Aim Smoothness",
    Default = Settings.LegitSmooth,
    Max = 30,
    Min = 0,
    Rounding = 1,
    Callback = function(value) Settings.LegitSmooth = value end
})

LegitHeadToggle = LegitGroup:AddCheckbox("LegitHead", {
    Text = "Aim Head",
    Default = Settings.LegitHeadPriority,
    Callback = function(v) Settings.LegitHeadPriority = v end
})

LegitTargetLabel = LegitGroup:AddLabel("Target: None")

VisualsTab = Window:AddTab("Visuals")
ESPGroup = VisualsTab:AddLeftGroupbox("ESP Settings")

ESPEnableToggle = ESPGroup:AddCheckbox("ESPEnabled", {
    Text = "Enable ESP",
    Default = Settings.ESPEnabled,
    Callback = function(value)
        Settings.ESPEnabled = value
    end
})

ESPBoxesToggle = ESPGroup:AddCheckbox("ESPBoxes", {
    Text = "Draw Boxes",
    Default = Settings.ESPBoxes,
    Callback = function(value)
        Settings.ESPBoxes = value
    end
})

ESPNamesToggle = ESPGroup:AddCheckbox("ESPNames", {
    Text = "Show Names",
    Default = Settings.ESPNames,
    Callback = function(value)
        Settings.ESPNames = value
    end
})

ESPTeamCheckToggle = ESPGroup:AddCheckbox("ESPTeamCheck", {
    Text = "Ignore Team",
    Default = Settings.ESPTeamCheck,
    Callback = function(value)
        Settings.ESPTeamCheck = value
    end
})

ESPMaxDistanceSlider = ESPGroup:AddSlider("ESPMaxDistance", {
    Text = "ESP Max Distance",
    Default = Settings.ESPMaxDistance,
    Max = 2000,
    Min = 100,
    Suffix = " studs",
    Rounding = 0,
    Callback = function(value)
        Settings.ESPMaxDistance = value
    end
})

ESPHealthToggle = ESPGroup:AddCheckbox("ESPHealth", {
    Text = "Show Health",
    Default = false,
    Callback = function(value) Settings.ESPHealth = value end
})

SettingsTab = Window:AddTab("Settings")
GeneralGroup = SettingsTab:AddLeftGroupbox("General")

function createKeybinds()
    if not Settings.EnableKeybinds then return end
    pcall(function()
        if not VoidKeybind and VoidToggle and VoidToggle.AddKeyPicker then
            VoidKeybind = VoidToggle:AddKeyPicker("VoidBind", {Text = "Toggle Void Mode", Default = "V", SyncToggleState = true, Mode = "Toggle"})
        end
        if not RiotKeybind and RiotToggle and RiotToggle.AddKeyPicker then
            RiotKeybind = RiotToggle:AddKeyPicker("RiotBind", {Text = "Toggle Riot Bypass", Default = "B", SyncToggleState = true, Mode = "Toggle"})
        end
        if not RageKeybind and RageToggle and RageToggle.AddKeyPicker then
            RageKeybind = RageToggle:AddKeyPicker("RageBind", {Text = "Toggle Rage Bot", Default = "R", SyncToggleState = true, Mode = "Toggle"})
        end
    end)
end

function removeKeybinds()
    pcall(function()
        if VoidKeybind then
            if VoidKeybind.Destroy then VoidKeybind:Destroy() end
            if VoidKeybind.SetValue then pcall(function() VoidKeybind:SetValue("") end) end
            VoidKeybind = nil
        end
        if RiotKeybind then
            if RiotKeybind.Destroy then RiotKeybind:Destroy() end
            if RiotKeybind.SetValue then pcall(function() RiotKeybind:SetValue("") end) end
            RiotKeybind = nil
        end
        if RageKeybind then
            if RageKeybind.Destroy then RageKeybind:Destroy() end
            if RageKeybind.SetValue then pcall(function() RageKeybind:SetValue("") end) end
            RageKeybind = nil
        end
    end)
end

KeybindsToggle = GeneralGroup:AddCheckbox("EnableKeybinds", {
    Text = "Enable Keybinds",
    Default = Settings.EnableKeybinds,
    Callback = function(v)
        Settings.EnableKeybinds = v
        if v then createKeybinds() else removeKeybinds() end
    end
})

ThirdPersonToggle = GeneralGroup:AddCheckbox("ThirdPersonEnabled", {
    Text = "Third Person Camera",
    Default = false,
    Callback = function(v)
        Settings.ThirdPersonEnabled = v
        if not v then restoreCamera() end
    end
})

ThirdPersonDistanceSlider = GeneralGroup:AddSlider("ThirdPersonDistance", {
    Text = "Third Person Distance",
    Default = 16,
    Max = 50,
    Min = 5,
    Rounding = 0,
    Callback = function(value)
        Settings.ThirdPersonDistance = value
    end
})

ThirdPersonHeightSlider = GeneralGroup:AddSlider("ThirdPersonHeight", {
    Text = "Third Person Height",
    Default = 6,
    Max = 30,
    Min = 0,
    Rounding = 0,
    Callback = function(value)
        Settings.ThirdPersonHeight = value
    end
})

FlyToggle = GeneralGroup:AddCheckbox("FlyEnabled", {
    Text = "Enable Fly",
    Default = false,
    Callback = function(value)
        Settings.FlyEnabled = value
        if value then
            Teleport:Notify("Fly: ACTIVE", 2)
        else
            Teleport:Notify("Fly: DEACTIVATED", 2)
        end
    end
})

FlySpeedSlider = GeneralGroup:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 60,
    Max = 200,
    Min = 10,
    Rounding = 0,
    Callback = function(value)
        Settings.FlySpeed = value
    end
})

FlyAscendSpeedSlider = GeneralGroup:AddSlider("FlyAscendSpeed", {
    Text = "Ascend/Descend Speed",
    Default = 35,
    Max = 150,
    Min = 10,
    Rounding = 0,
    Callback = function(value)
        Settings.FlyAscendSpeed = value
    end
})

AutoExecToggle = GeneralGroup:AddCheckbox("AutoExecEnabled", {
    Text = "Auto Executor",
    Default = false,
    Callback = function(value)
        Settings.AutoExecEnabled = value
        if value then scheduleAutoExec() end
    end
})

AutoExecPathInput = GeneralGroup:AddInput("AutoExecPath", {
    Text = "AutoExec File",
    Default = "autoexec.lua",
    Placeholder = "autoexec.lua",
    Finished = true,
    Callback = function(value)
        Settings.AutoExecPath = tostring(value or "autoexec.lua")
    end,
})

AutoExecDelaySlider = GeneralGroup:AddSlider("AutoExecDelay", {
    Text = "AutoExec Delay",
    Default = 2,
    Max = 10,
    Min = 0,
    Rounding = 1,
    Suffix = "s",
    Callback = function(value)
        Settings.AutoExecDelay = value
    end,
})

local PanicButton = GeneralGroup:AddButton("PanicButton", {
    Text = "PANIC / Disable All",
    Func = function()
        triggerPanic()
    end,
})

ConfigsTab = Window:AddTab("Configs")
ConfigsGroup = ConfigsTab:AddLeftGroupbox("Config Manager")

ConfigNameInput = ConfigsGroup:AddInput("ConfigName", {
    Text = "Config Name",
    Default = "",
    Placeholder = "Enter config name",
    Finished = true,
    Callback = function(value) end,
})

ConfigSelectDropdown = ConfigsGroup:AddDropdown("ConfigSelect", {
    Text = "Saved Configs",
    Values = listConfigs(),
    Default = "",
    Callback = function(value)
        if value and value ~= "" then
            ConfigNameInput:SetValue(value)
        end
    end,
})

ConfigListLabel = ConfigsGroup:AddLabel("Saved: None")

function refreshConfigs()
    list = listConfigs()
    if not list or #list == 0 then
        ConfigListLabel:SetText("Saved: None")
        pcall(function()
            if ConfigSelectDropdown.SetValue then
                ConfigSelectDropdown:SetValue("")
            end
            if ConfigSelectDropdown.SetValues then
                ConfigSelectDropdown:SetValues({})
            elseif ConfigSelectDropdown.UpdateOptions then
                ConfigSelectDropdown:UpdateOptions({})
            end
        end)
        return
    end
    ConfigListLabel:SetText("Saved: " .. table.concat(list, ", "))
    pcall(function()
        if ConfigSelectDropdown.SetValues then
            ConfigSelectDropdown:SetValues(list)
        elseif ConfigSelectDropdown.UpdateOptions then
            ConfigSelectDropdown:UpdateOptions(list)
        end
        if ConfigSelectDropdown.SetValue and list[1] then
            ConfigSelectDropdown:SetValue(list[1])
        end
    end)
end

SaveCfgBtn = ConfigsGroup:AddButton("CreateCfg", {
    Text = "Create",
    Func = function()
        local name = tostring(ConfigNameInput.Value or ""):gsub("%s+$","")
        if name == "" then
            Teleport:Notify("Enter a config name", 2)
            return
        end
        local ok,err = saveConfig(name)
        if ok then
            Teleport:Notify("Created config: " .. name, 2)
        else
            Teleport:Notify("Create failed: " .. tostring(err), 2)
        end
        refreshConfigs()
    end
})

LoadCfgBtn = ConfigsGroup:AddButton("LoadCfg", {
    Text = "Load",
    Func = function()
        local name = tostring(ConfigNameInput.Value or ""):gsub("%s+$","")
        if name == "" then
            Teleport:Notify("Enter a config name to load", 2)
            return
        end
        local ok, err = loadConfig(name)
        if ok then
            Teleport:Notify("Loaded config: " .. name, 2)
        else
            Teleport:Notify("Load failed: " .. tostring(err), 2)
        end
        refreshConfigs()
    end
})

DelCfgBtn = ConfigsGroup:AddButton("DelCfg", {
    Text = "Delete",
    Func = function()
        local name = tostring(ConfigNameInput.Value or ""):gsub("%s+$","")
        if name == "" then
            Teleport:Notify("Enter a config name to delete", 2)
            return
        end
        local ok = deleteConfig(name)
        if ok then
            Teleport:Notify("Deleted config: " .. name, 2)
        else
            Teleport:Notify("Delete failed", 2)
        end
        refreshConfigs()
    end
})

RefreshCfgBtn = ConfigsGroup:AddButton("RefreshCfg", {
    Text = "Refresh List",
    Func = function()
        refreshConfigs()
        Teleport:Notify("Config list refreshed", 1)
    end
})

refreshConfigs()
if Settings.AutoExecEnabled then
    scheduleAutoExec()
end

ExportCfgBtn = ConfigsGroup:AddButton("ExportCfg", {
    Text = "Export to Clipboard",
    Func = function()
        local name = tostring(ConfigNameInput.Value or ""):gsub("%s+$","")
        if name == "" then
            Teleport:Notify("Enter a config name to export", 2)
            return
        end
        local ok, err = exportConfigToClipboard(name)
        if ok then
            Teleport:Notify("Exported config to clipboard: " .. name, 2)
        else
            Teleport:Notify("Export failed: " .. tostring(err), 2)
        end
    end
})

ImportCfgBtn = ConfigsGroup:AddButton("ImportCfg", {
    Text = "Import from Clipboard",
    Func = function()
        local ok, err = importConfigFromClipboard()
        if ok then
            Teleport:Notify("Imported config from clipboard", 2)
        else
            Teleport:Notify("Import failed: " .. tostring(err), 2)
        end
    end
})

for i=1, Settings.QuickSlots do
    ConfigsGroup:AddButton("QuickSave"..i, {
        Text = "QuickSave "..i,
        Func = function()
            saveQuickSlot(i)
            Teleport:Notify("Saved quickslot "..i, 1)
            refreshConfigs()
        end
    })
    ConfigsGroup:AddButton("QuickLoad"..i, {
        Text = "QuickLoad "..i,
        Func = function()
            local ok,err = loadQuickSlot(i)
            if ok then Teleport:Notify("Loaded quickslot "..i,1) else Teleport:Notify("Load failed",2) end
        end
    })
end

AutosaveToggle = ConfigsGroup:AddCheckbox("Autosave", {
    Text = "Autosave",
    Default = false,
    Callback = function(value)
        Settings.Autosave = value
        Teleport:Notify("Autosave: " .. (value and "ON" or "OFF"), 1)
    end
})

AutosaveIntervalSlider = ConfigsGroup:AddSlider("AutosaveInterval", {
    Text = "Autosave Interval",
    Default = Settings.AutosaveInterval,
    Max = 300,
    Min = 5,
    Suffix = "s",
    Rounding = 0,
    Callback = function(value)
        Settings.AutosaveInterval = value
    end
})

DebugTab = Window:AddTab("Debug")
DebugGroup = DebugTab:AddLeftGroupbox("Remote Debugger")

DebugGroup:AddLabel("Remote debugger disabled due to executor limits.")
DebugGroup:AddLabel("If you want it back, remove the debug tab block.")

SoundTab = Window:AddTab("Sounds")
SoundGroup = SoundTab:AddLeftGroupbox("Sound Effects")

SoundSelectDropdown = SoundGroup:AddDropdown("SoundSelect", {
    Text = "Select Sound",
    Values = {"Space", "Pop", "Bonk", "Skeet", "Neverlose", "Slip"},
    Default = "Space",
    Callback = function(value)
        Settings.SoundId = SoundIds[value]
        TeleportSound.SoundId = Settings.SoundId
    end
})

EventSoundSelectDropdown = SoundGroup:AddDropdown("EventSoundSelect", {
    Text = "Event Sound",
    Values = {"Space", "Pop", "Bonk", "Skeet", "Neverlose", "Slip"},
    Default = "Space",
    Callback = function(value)
        Settings.EventSoundId = SoundIds[value]
        EventSound.SoundId = Settings.EventSoundId
    end
})

EventSoundToggle = SoundGroup:AddCheckbox("EventSoundEnabled", {
    Text = "Enable Hit/Kill Sound",
    Default = true,
    Callback = function(value)
        Settings.EventSoundEnabled = value
    end,
})

HitSoundToggle = SoundGroup:AddCheckbox("HitSoundEnabled", {
    Text = "Play Hit Sound",
    Default = true,
    Callback = function(value)
        Settings.HitSoundEnabled = value
    end,
})

KillSoundToggle = SoundGroup:AddCheckbox("KillSoundEnabled", {
    Text = "Play Kill Sound",
    Default = true,
    Callback = function(value)
        Settings.KillSoundEnabled = value
    end,
})

HitNotifyToggle = SoundGroup:AddCheckbox("HitNotify", {
    Text = "Hit Notifications",
    Default = true,
    Callback = function(value)
        Settings.HitNotify = value
    end,
})

KillNotifyToggle = SoundGroup:AddCheckbox("KillNotify", {
    Text = "Kill Notifications",
    Default = true,
    Callback = function(value)
        Settings.KillNotify = value
    end,
})

SoundVolumeSlider = SoundGroup:AddSlider("SoundVolume", {
    Text = "Sound Volume",
    Default = 50,
    Min = 0,
    Suffix = "%",
    Rounding = 0,
    Callback = function(value)
        Settings.SoundVolume = value / 100
        TeleportSound.Volume = Settings.SoundVolume
        EventSound.Volume = Settings.SoundVolume
    end
})

StatsTab = Window:AddTab("Statistics")
StatsGroup = StatsTab:AddLeftGroupbox("Stats & Info")

TotalTeleportsLabel = StatsGroup:AddLabel("Total Teleports: 0")
VoidStatusLabel = StatsGroup:AddLabel("Void Status: OFF")
RageStatusLabel = StatsGroup:AddLabel("Rage Bot Status: OFF")
RiotStatusLabel = StatsGroup:AddLabel("Riot Status: OFF")
AAStatusLabel = StatsGroup:AddLabel("Anti-Aim Status: OFF")
LowProfileStatusLabel = StatsGroup:AddLabel("Low Profile: OFF")
HitLogLabel = StatsGroup:AddLabel("Last Event: None")
ModeStatusLabel = StatsGroup:AddLabel("Void Mode: None")
ESPStatusLabel = StatsGroup:AddLabel("ESP: OFF")
DevCreditLabel = StatsGroup:AddLabel("Developer: @opensourcedevv")
VersionLabel = StatsGroup:AddLabel("Version: 2.0 | ASTRAL.WTF")

RunService.Heartbeat:Connect(function()
    TotalTeleportsLabel:SetText("Total Teleports: " .. TeleportCount)
    VoidStatusLabel:SetText("Void Status: " .. (Settings.VoidEnabled and "ACTIVE" or "OFF"))
    RageStatusLabel:SetText("Rage Bot Status: " .. (Settings.RageEnabled and "ACTIVE" or "OFF"))
    RiotStatusLabel:SetText("Riot Status: " .. (Settings.RiotEnabled and "ACTIVE" or "OFF"))
    AAStatusLabel:SetText("Anti-Aim Status: " .. (Settings.AAEnabled and "ACTIVE" or "OFF"))
    LowProfileStatusLabel:SetText("Low Profile: " .. (Settings.LowProfile and "ON" or "OFF"))
    ModeStatusLabel:SetText("Void Mode: " .. Settings.Mode)
    ESPStatusLabel:SetText("ESP: " .. (Settings.ESPEnabled and "ON" or "OFF"))
    if RageTargetLabel then
        RageTargetLabel:SetText("Target: " .. (Settings.RageTarget and Settings.RageTarget.Name or "None"))
    end
end)

end
buildUI()

local function isKeybindPressed(bind, input, defaultKey)
    if bind and type(bind.IsPressed) == "function" then
        local ok, result = pcall(function() return bind:IsPressed() end)
        return ok and result
    end
    if input and input.KeyCode then
        return input.KeyCode == defaultKey
    end
    return false
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    pcall(function()

                if isKeybindPressed(VoidKeybind, input, Enum.KeyCode.V) then
            local newState = not Settings.VoidEnabled
            Settings.VoidEnabled = newState
            if newState then
                OriginalCFrame = HumanoidRootPart.CFrame
                teleportToVoid()
                if Teleport and Teleport.Notify then Teleport:Notify("Void Hide: ACTIVE", 2) end
            else
                isReturning = true
                returnStartTime = tick()
                LastVoidPosition = nil
                if Teleport and Teleport.Notify then Teleport:Notify("Void Hide: DEACTIVATED", 2) end
            end
        end

        if isKeybindPressed(RiotKeybind, input, Enum.KeyCode.B) then
            local newState = not Settings.RiotEnabled
            Settings.RiotEnabled = newState
            if RiotToggle and RiotToggle.SetValue then pcall(function() RiotToggle:SetValue(newState) end) end
            if newState then
                updateRiotTarget()
                if Teleport and Teleport.Notify then Teleport:Notify("Riot Bypass: ACTIVE", 2) end
            else
                if Teleport and Teleport.Notify then Teleport:Notify("Riot Bypass: DEACTIVATED", 2) end
            end
        end

        if input.KeyCode == PANIC_KEY then
            triggerPanic()
        end
    end)
end)

Teleport:Notify("ASTRAL.WTF | Void Hide Ultimate Loaded!", 3)
Teleport:Notify("Press RightShift for menu | Click keybinds to change keys", 4)

print("================================================")
print("ASTRAL.WTF | VOID HIDE ULTIMATE")
print("Developed by @opensourcedevv")
print("================================================")
print("FEATURES:")
print("  • Void Teleport - Teleports you to the void")
print("  • Motion Effects - Spin, Orbit, Random, Desync")
print("  • Riot Bypass - Hide behind players")
print("  • Anti-Aim - Break hitboxes with jitter/sway")
print("  • Custom Sound Effects")
print("================================================")
print("CONTROLS:")
print("  • RightShift - Open/Close Menu")
print("  • V - Toggle Void Hide (Click button to change)")
print("  • B - Toggle Riot Bypass (Click button to change)")
print("================================================")
