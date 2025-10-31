-- Auto Fishing Rimuru UI (by bubub) 🎣✨
-- Updated: persistent state save (getgenv + writefile fallback)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Theme (Rimuru)
local BG_COLOR = Color3.fromRGB(15, 25, 35)         -- deep blue
local ACCENT = Color3.fromRGB(123, 232, 255)        -- rimuru cyan
local ACCENT2 = Color3.fromRGB(80,200,255)
local TEXT_COLOR = Color3.fromRGB(235, 245, 255)

-- Persistence helpers (getgenv + file fallback)
if not getgenv then
    getgenv = function() return _G end
end

getgenv().AutoFishingRunning = getgenv().AutoFishingRunning or false
getgenv().AutoFishingStopRequested = getgenv().AutoFishingStopRequested or false

local STATE_FILENAME = "autofish_state.json"

local function saveStateToFile(stateTable)
    if writefile and HttpService then
        pcall(function()
            writefile(STATE_FILENAME, HttpService:JSONEncode(stateTable))
        end)
    end
end

local function loadStateFromFile()
    if readfile and HttpService then
        local ok, content = pcall(function() return readfile(STATE_FILENAME) end)
        if ok and content then
            local suc, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if suc and type(decoded) == "table" then
                return decoded
            end
        end
    end
    return nil
end

local function saveState()
    local state = {
        running = getgenv().AutoFishingRunning == true
    }
    -- set getgenv (already set)
    pcall(function() getgenv().AutoFishingRunning = state.running end)
    saveStateToFile(state)
end

local function loadState()
    -- prefer getgenv (already live), else fallback to file
    if getgenv().AutoFishingRunning then
        return { running = true }
    end
    local f = loadStateFromFile()
    if f and type(f.running) == "boolean" then
        -- restore into getgenv
        pcall(function() getgenv().AutoFishingRunning = f.running end)
        return f
    end
    return { running = false }
end

-- Remove previous GUI if exists
if playerGui:FindFirstChild("AutoFishingRimuruGui") then
    playerGui.AutoFishingRimuruGui:Destroy()
end

--// Root ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFishingRimuruGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui
ScreenGui.IgnoreGuiInset = true

--// Main Frame (center, medium)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 320)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -160)
MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

-- subtle glow behind frame (Frame2)
local Glow = Instance.new("Frame", MainFrame)
Glow.Name = "Glow"
Glow.Size = UDim2.new(1, 14, 1, 14)
Glow.Position = UDim2.new(0, -7, 0, -7)
Glow.BackgroundColor3 = ACCENT
Glow.BackgroundTransparency = 0.9
Glow.ZIndex = 0
Glow.BorderSizePixel = 0
local gcorner = Instance.new("UICorner", Glow)
gcorner.CornerRadius = UDim.new(0, 18)

-- Title bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 46)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundTransparency = 1

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(0.6, -20, 1, 0)
TitleLabel.Position = UDim2.new(0, 18, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎣 Auto Fishing — Rimuru UI"
TitleLabel.TextColor3 = TEXT_COLOR
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close / Minimize
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -42, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = TEXT_COLOR
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.Color = ACCENT2
CloseStroke.Transparency = 0.7

local MiniBtn = Instance.new("TextButton", TitleBar)
MiniBtn.Size = UDim2.new(0, 34, 0, 34)
MiniBtn.Position = UDim2.new(1, -82, 0, 6)
MiniBtn.BackgroundColor3 = Color3.fromRGB(22, 32, 44)
MiniBtn.Text = "-"
MiniBtn.TextColor3 = TEXT_COLOR
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 18
MiniBtn.BorderSizePixel = 0
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(0, 8)
local MiniStroke = Instance.new("UIStroke", MiniBtn)
MiniStroke.Color = ACCENT2
MiniStroke.Transparency = 0.7

-- Left sidebar
local SideBar = Instance.new("Frame", MainFrame)
SideBar.Name = "SideBar"
SideBar.Size = UDim2.new(0, 120, 1, -56)
SideBar.Position = UDim2.new(0, 12, 0, 52)
SideBar.BackgroundTransparency = 1

local function makeTabButton(name, y)
    local b = Instance.new("TextButton")
    b.Name = name .. "Tab"
    b.Size = UDim2.new(1, 0, 0, 42)
    b.Position = UDim2.new(0, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(18, 26, 35)
    b.BorderSizePixel = 0
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = TEXT_COLOR
    b.TextSize = 15
    b.Parent = SideBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", b)
    stroke.Color = ACCENT2
    stroke.Transparency = 0.85
    return b
end

local tabNames = {"Main", "Player", "Teleport", "Settings", "Info"}
local tabs = {}
for i, tname in ipairs(tabNames) do
    tabs[tname] = makeTabButton(tname, (i-1)*48)
end

-- Right content area
local Content = Instance.new("Frame", MainFrame)
Content.Name = "Content"
Content.Size = UDim2.new(1, -156, 1, -56)
Content.Position = UDim2.new(0, 140, 0, 52)
Content.BackgroundTransparency = 1

-- helper to clear content children
local function clearContent()
    for _,c in ipairs(Content:GetChildren()) do
        if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then
            c:Destroy()
        end
    end
end

-- Simple tween helper
local function tweenObject(obj, props, t, style, dir)
    tween = TweenService:Create(obj, TweenInfo.new(t or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

-- ===== Build Main Tab Content (Auto Fishing UI) =====
local function buildMain()
    clearContent()
    -- Title small
    local sectionTitle = Instance.new("TextLabel", Content)
    sectionTitle.Size = UDim2.new(1, 0, 0, 26)
    sectionTitle.Position = UDim2.new(0, 0, 0, 0)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = "Auto Fishing"
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextColor3 = ACCENT
    sectionTitle.TextSize = 16
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Container frame
    local container = Instance.new("Frame", Content)
    container.Size = UDim2.new(1, 0, 0, 220)
    container.Position = UDim2.new(0, 0, 0, 34)
    container.BackgroundTransparency = 1

    -- Start/Stop button
    local startBtn = Instance.new("TextButton", container)
    startBtn.Name = "StartBtn"
    startBtn.Size = UDim2.new(0, 220, 0, 44)
    startBtn.Position = UDim2.new(0, 0, 0, 6)
    startBtn.BackgroundColor3 = ACCENT
    startBtn.Text = "▶ Start Auto Fish"
    startBtn.Font = Enum.Font.GothamBold
    startBtn.TextColor3 = Color3.fromRGB(10,10,10)
    startBtn.TextSize = 16
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", startBtn)
    stroke.Color = Color3.fromRGB(220,240,255)
    stroke.Transparency = 0.5

    -- Delay label and input
    local delayLabel = Instance.new("TextLabel", container)
    delayLabel.Size = UDim2.new(0, 160, 0, 20)
    delayLabel.Position = UDim2.new(0, 0, 0, 62)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Minigame Delay (detik):"
    delayLabel.Font = Enum.Font.Gotham
    delayLabel.TextColor3 = TEXT_COLOR
    delayLabel.TextSize = 14
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left

    local delayInput = Instance.new("TextBox", container)
    delayInput.Name = "DelayInput"
    delayInput.Size = UDim2.new(0, 80, 0, 24)
    delayInput.Position = UDim2.new(0, 0, 0, 86)
    delayInput.BackgroundColor3 = Color3.fromRGB(28,36,44)
    delayInput.TextColor3 = TEXT_COLOR
    delayInput.Font = Enum.Font.Code
    delayInput.TextSize = 14
    delayInput.Text = "0.5"
    delayInput.ClearTextOnFocus = false
    Instance.new("UICorner", delayInput).CornerRadius = UDim.new(0,6)

    -- Fish count label
    local fishLabel = Instance.new("TextLabel", container)
    fishLabel.Name = "FishLabel"
    fishLabel.Size = UDim2.new(1, -20, 0, 20)
    fishLabel.Position = UDim2.new(0, 0, 0, 120)
    fishLabel.BackgroundTransparency = 1
    fishLabel.Text = "🐟 Total Ikan: 0"
    fishLabel.Font = Enum.Font.GothamBold
    fishLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    fishLabel.TextSize = 15
    fishLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Timer label
    local timerLabel = Instance.new("TextLabel", container)
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, -20, 0, 20)
    timerLabel.Position = UDim2.new(0, 0, 0, 146)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "🕒 Waktu: 0m 0s"
    timerLabel.Font = Enum.Font.Gotham
    timerLabel.TextColor3 = TEXT_COLOR
    timerLabel.TextSize = 14
    timerLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Notification toggle (optional)
    local notifToggle = Instance.new("TextButton", container)
    notifToggle.Size = UDim2.new(0, 120, 0, 28)
    notifToggle.Position = UDim2.new(0, 0, 0, 176)
    notifToggle.BackgroundColor3 = Color3.fromRGB(30,40,50)
    notifToggle.Text = "Notifications: On"
    notifToggle.Font = Enum.Font.Gotham
    notifToggle.TextSize = 13
    notifToggle.TextColor3 = TEXT_COLOR
    Instance.new("UICorner", notifToggle).CornerRadius = UDim.new(0, 6)
    local notifOn = true

    -- external running indicator
    local externalLabel = Instance.new("TextLabel", container)
    externalLabel.Size = UDim2.new(1, -10, 0, 18)
    externalLabel.Position = UDim2.new(0, 230, 0, 12)
    externalLabel.BackgroundTransparency = 1
    externalLabel.Font = Enum.Font.Gotham
    externalLabel.TextSize = 12
    externalLabel.TextColor3 = Color3.fromRGB(200,200,200)
    externalLabel.TextXAlignment = Enum.TextXAlignment.Left
    externalLabel.Text = ""

    -- Attach functional logic for auto fishing (adapted from original)
    local net
    local ok, nres = pcall(function()
        return ReplicatedStorage
            :WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")
    end)
    if ok and nres then net = nres else
        -- fallback: try common path names
        pcall(function() net = ReplicatedStorage:FindFirstChild("net") end)
    end

    -- fallback guards
    local REFishCaught
    local REObtainedNewFishNotification
    if net then
        REFishCaught = net["RE/FishCaught"]
        REObtainedNewFishNotification = net["RE/ObtainedNewFishNotification"]
    end

    -- disable default notification listeners if available
    if REObtainedNewFishNotification then
        pcall(function()
            for _, conn in pairs(getconnections and getconnections(REObtainedNewFishNotification.OnClientEvent) or {}) do
                if conn and conn.Disable then
                    pcall(function() conn:Disable() end)
                end
            end
        end)
    end

    -- state variables (local view)
    local isFishing = false
    local fishCount = 0
    local startTime = 0

    -- load stored state and reflect
    local loaded = loadState()
    if loaded and loaded.running then
        -- indicate external running state
        externalLabel.Text = "Detected: Auto Fishing is running (from previous session)"
        startBtn.Text = "⏸ Stop Auto Fish (Running)"
    else
        externalLabel.Text = ""
    end

    local function ShowNotification(fishName, weight)
        if not notifOn then return end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "🎣 Ikan Tertangkap!",
                Text = fishName .. " (" .. tostring(weight) .. " kg)",
                Duration = 4
            })
        end)
    end

    -- handle fish event
    if REFishCaught then
        REFishCaught.OnClientEvent:Connect(function(fishName, data)
            local weight = data and data.Weight or "?"
            fishCount = fishCount + 1
            fishLabel.Text = "🐟 Total Ikan: " .. fishCount
            print("🐟 Dapat ikan:", fishName, "| Berat:", weight)
            ShowNotification(fishName, weight)
        end)
    end

    -- timer updater
    spawn(function()
        while true do
            task.wait(1)
            if isFishing then
                local elapsed = math.floor(tick() - startTime)
                local minutes = math.floor(elapsed / 60)
                local seconds = elapsed % 60
                timerLabel.Text = string.format("🕒 Waktu: %dm %ds", minutes, seconds)
            end
        end
    end)

    -- auto fish loop (respects getgenv flags)
    local function AutoFishLoop()
        if not net then
            startBtn.Text = "⚠ Net not found"
            task.wait(1.5)
            startBtn.Text = "▶ Start Auto Fish"
            return
        end

        -- if another execution already running, avoid double spawn
        if getgenv().AutoFishingRunning then
            -- There is already a running loop (external). We'll not spawn a second loop.
            -- Instead we'll switch to "control mode" that requests stop on click.
            externalLabel.Text = "Auto Fishing already running elsewhere. Use Stop to request stop."
            startBtn.Text = "⏸ Stop Auto Fish (Running)"
            return
        end

        -- start local control
        isFishing = true
        startTime = tick()
        fishCount = 0
        fishLabel.Text = "🐟 Total Ikan: 0"
        startBtn.Text = "⏸ Stop Auto Fish"
        print("🎣 Auto Fishing started for " .. player.Name)

        -- set persistent flags
        pcall(function()
            getgenv().AutoFishingRunning = true
            getgenv().AutoFishingStopRequested = false
        end)
        saveState()

while isFishing do
    if getgenv().AutoFishingStopRequested then
        isFishing = false
        break
    end

    pcall(function()
        if net["RF/ChargeFishingRod"] then
            net["RF/ChargeFishingRod"]:InvokeServer(workspace:GetServerTimeNow())
        end
    end)
    if not isFishing or getgenv().AutoFishingStopRequested then break end

    pcall(function()
        if net["RF/RequestFishingMinigameStarted"] then
            net["RF/RequestFishingMinigameStarted"]:InvokeServer(-0.3, 0.2, workspace:GetServerTimeNow())
        end
    end)
    if not isFishing or getgenv().AutoFishingStopRequested then break end

    local delayVal = tonumber(delayInput.Text) or 1.5
    local startTime = tick()
    while tick() - startTime < delayVal do
        if not isFishing or getgenv().AutoFishingStopRequested then
            isFishing = false
            break
        end
        task.wait(0.05)
    end
    if not isFishing then break end

    pcall(function()
        if net["RE/FishingCompleted"] then
            net["RE/FishingCompleted"]:FireServer()
        end
    end)
    if not isFishing or getgenv().AutoFishingStopRequested then break end

    local miniDelay = tick()
    while tick() - miniDelay < 0.3 do
        if not isFishing or getgenv().AutoFishingStopRequested then
            isFishing = false
            break
        end
        task.wait(0.05)
    end
    if not isFishing then break end

    pcall(function()
        if net["RF/CancelFishingInputs"] then
            net["RF/CancelFishingInputs"]:InvokeServer()
        end
    end)
end


        -- cleanup on stop
        isFishing = false
        pcall(function() getgenv().AutoFishingRunning = false end)
        pcall(function() getgenv().AutoFishingStopRequested = false end)
        saveState()

        startBtn.Text = "▶ Start Auto Fish"
        externalLabel.Text = ""
        print("🛑 Auto Fishing stopped.")
    end

    -- connect buttons
    startBtn.MouseButton1Click:Connect(function()
        -- If there exists a running external loop, clicking the button will request it to stop
        if getgenv().AutoFishingRunning and not isFishing then
            -- request external loop to stop
            getgenv().AutoFishingStopRequested = true
            externalLabel.Text = "Stop requested... waiting for external loop to end."
            -- poll until external loop clears (with timeout fallback)
            spawn(function()
                local waited = 0
                while getgenv().AutoFishingRunning and waited < 8 do
                    task.wait(0.5)
                    waited = waited + 0.5
                end
                if not getgenv().AutoFishingRunning then
                    externalLabel.Text = "External loop stopped. You can Start again."
                    startBtn.Text = "▶ Start Auto Fish"
                    saveState()
                else
                    externalLabel.Text = "External loop did not stop? You can Force Stop."
                    startBtn.Text = "Force Stop"
                end
            end)
            return
        end

        if isFishing then
            -- local stop
            isFishing = false
            getgenv().AutoFishingStopRequested = true
            getgenv().AutoFishingRunning = false
            saveState()
            startBtn.Text = "▶ Start Auto Fish"
        else
            -- start new local loop
            spawn(AutoFishLoop)
        end
    end)

    notifToggle.MouseButton1Click:Connect(function()
        notifOn = not notifOn
        notifToggle.Text = "Notifications: " .. (notifOn and "On" or "Off")
        tweenObject(notifToggle, {BackgroundColor3 = notifOn and Color3.fromRGB(40,50,60) or Color3.fromRGB(28,34,40)}, 0.18)
    end)
end

-- ===== Build Player Tab (placeholder) =====
local function buildPlayer()
    clearContent()
    local title = Instance.new("TextLabel", Content)
    title.Size = UDim2.new(1,0,0,26)
    title.BackgroundTransparency = 1
    title.Text = "Player"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = ACCENT
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local cont = Instance.new("Frame", Content)
    cont.Size = UDim2.new(1,0,0,220)
    cont.Position = UDim2.new(0,0,0,34)
    cont.BackgroundTransparency = 1

    local hint = Instance.new("TextLabel", cont)
    hint.Size = UDim2.new(1,0,0,60)
    hint.Position = UDim2.new(0,0,0,6)
    hint.BackgroundTransparency = 1
    hint.Text = "Player controls placeholder. (Speed / Jump / other would go here.)"
    hint.Font = Enum.Font.Gotham
    hint.TextColor3 = TEXT_COLOR
    hint.TextSize = 14
    hint.TextWrapped = true
end

-- ===== Build Teleport Tab (placeholder) =====
local function buildTeleport()
    clearContent()
    local title = Instance.new("TextLabel", Content)
    title.Size = UDim2.new(1,0,0,26)
    title.BackgroundTransparency = 1
    title.Text = "Teleport"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = ACCENT
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local cont = Instance.new("Frame", Content)
    cont.Size = UDim2.new(1,0,0,220)
    cont.Position = UDim2.new(0,0,0,34)
    cont.BackgroundTransparency = 1

    local hint = Instance.new("TextLabel", cont)
    hint.Size = UDim2.new(1,0,0,60)
    hint.Position = UDim2.new(0,0,0,6)
    hint.BackgroundTransparency = 1
    hint.Text = "Teleport placeholder. Add favourites coordinates or use server teleports here."
    hint.Font = Enum.Font.Gotham
    hint.TextColor3 = TEXT_COLOR
    hint.TextSize = 14
    hint.TextWrapped = true
end

-- ===== Build Settings Tab (Anti-Lag) =====
local AntiLagState = {
    enabled = false,
    modified = {},
    terrainOld = nil
}
local descendantConnection = nil

local function applyAntiLagToDescendant(v)
    if not v or not v:IsDescendantOf(game) then return end
    if v:IsA("Texture") or v:IsA("Decal") then
        if v.Transparency ~= 1 then
            table.insert(AntiLagState.modified, {inst = v, prop = "Transparency", old = v.Transparency})
            pcall(function() v.Transparency = 1 end)
        end
    elseif v:IsA("SurfaceAppearance") then
        local success, _ = pcall(function()
            if v.Enabled ~= nil then
                table.insert(AntiLagState.modified, {inst = v, prop = "Enabled", old = v.Enabled})
                v.Enabled = false
            end
        end)
    end
end

local function enableAntiLag()
    if AntiLagState.enabled then return end
    AntiLagState.enabled = true
    AntiLagState.modified = {}
    for _,v in ipairs(workspace:GetDescendants()) do
        applyAntiLagToDescendant(v)
    end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local old = {
            WaterReflectance = terrain.WaterReflectance,
            WaterTransparency = terrain.WaterTransparency,
            WaterWaveSize = terrain.WaterWaveSize,
            WaterWaveSpeed = terrain.WaterWaveSpeed
        }
        AntiLagState.terrainOld = old
        pcall(function()
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        end)
    end
    descendantConnection = workspace.DescendantAdded:Connect(function(v)
        if not AntiLagState.enabled then return end
        applyAntiLagToDescendant(v)
    end)
    print("[AntiLag] Enabled. Modified objects:", #AntiLagState.modified)
end

local function disableAntiLag()
    if not AntiLagState.enabled then return end
    AntiLagState.enabled = false
    for _, rec in ipairs(AntiLagState.modified) do
        pcall(function()
            if rec.inst and rec.inst.Parent then
                if rec.prop == "Transparency" then
                    rec.inst.Transparency = rec.old
                elseif rec.prop == "Enabled" then
                    rec.inst.Enabled = rec.old
                end
            end
        end)
    end
    AntiLagState.modified = {}
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and AntiLagState.terrainOld then
        pcall(function()
            terrain.WaterReflectance = AntiLagState.terrainOld.WaterReflectance
            terrain.WaterTransparency = AntiLagState.terrainOld.WaterTransparency
            terrain.WaterWaveSize = AntiLagState.terrainOld.WaterWaveSize
            terrain.WaterWaveSpeed = AntiLagState.terrainOld.WaterWaveSpeed
        end)
        AntiLagState.terrainOld = nil
    end
    if descendantConnection then
        descendantConnection:Disconnect()
        descendantConnection = nil
    end
    print("[AntiLag] Disabled and reverted.")
end

local function buildSettings()
    clearContent()
    local title = Instance.new("TextLabel", Content)
    title.Size = UDim2.new(1,0,0,26)
    title.BackgroundTransparency = 1
    title.Text = "Settings"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = ACCENT
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local cont = Instance.new("Frame", Content)
    cont.Size = UDim2.new(1,0,0,220)
    cont.Position = UDim2.new(0,0,0,34)
    cont.BackgroundTransparency = 1

    local antiLabel = Instance.new("TextLabel", cont)
    antiLabel.Size = UDim2.new(1,0,0,20)
    antiLabel.Position = UDim2.new(0,0,0,6)
    antiLabel.BackgroundTransparency = 1
    antiLabel.Text = "Anti-Lag (disable textures/decals & terrain water)"
    antiLabel.Font = Enum.Font.Gotham
    antiLabel.TextColor3 = TEXT_COLOR
    antiLabel.TextSize = 14
    antiLabel.TextXAlignment = Enum.TextXAlignment.Left

    local antiToggle = Instance.new("TextButton", cont)
    antiToggle.Size = UDim2.new(0, 160, 0, 36)
    antiToggle.Position = UDim2.new(0,0,0,36)
    antiToggle.BackgroundColor3 = Color3.fromRGB(28,36,44)
    antiToggle.Text = "Anti-Lag: OFF"
    antiToggle.Font = Enum.Font.GothamBold
    antiToggle.TextSize = 14
    antiToggle.TextColor3 = TEXT_COLOR
    antiToggle.BorderSizePixel = 0
    Instance.new("UICorner", antiToggle).CornerRadius = UDim.new(0,8)
    local antiStroke = Instance.new("UIStroke", antiToggle)
    antiStroke.Color = ACCENT2
    antiStroke.Transparency = 0.9

    antiToggle.MouseButton1Click:Connect(function()
        if not AntiLagState.enabled then
            antiToggle.Text = "Anti-Lag: ON"
            tweenObject(antiToggle, {BackgroundColor3 = Color3.fromRGB(12,22,30)}, 0.16)
            spawn(enableAntiLag)
        else
            antiToggle.Text = "Anti-Lag: OFF"
            tweenObject(antiToggle, {BackgroundColor3 = Color3.fromRGB(28,36,44)}, 0.16)
            spawn(disableAntiLag)
        end
    end)
end

-- ===== Build Info Tab =====
local function buildInfo()
    clearContent()
    local title = Instance.new("TextLabel", Content)
    title.Size = UDim2.new(1,0,0,26)
    title.BackgroundTransparency = 1
    title.Text = "Info"
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = ACCENT
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local cont = Instance.new("Frame", Content)
    cont.Size = UDim2.new(1,0,0,220)
    cont.Position = UDim2.new(0,0,0,34)
    cont.BackgroundTransparency = 1

    local credit = Instance.new("TextLabel", cont)
    credit.Size = UDim2.new(1,0,0,120)
    credit.Position = UDim2.new(0,0,0,6)
    credit.BackgroundTransparency = 1
    credit.Text = "Auto Fishing (Rimuru UI)\n\nScript by bubub 😎\n\nFeatures:\n• Rimuru-style anime UI\n• Sidebar tabs: Main, Player, Teleport, Settings, Info\n• Anti-Lag (disables textures/decals & terrain water)\n• Auto Fishing: Start/Stop, delay, timer, counter\n• Persistent state: detects running state across GUI open/close\n\nUse responsibly."
    credit.Font = Enum.Font.Gotham
    credit.TextColor3 = TEXT_COLOR
    credit.TextSize = 14
    credit.TextWrapped = true
    credit.TextXAlignment = Enum.TextXAlignment.Left
end

-- ===== Tab switching visuals + connect builders =====
local activeTab = "Main"
local function setActiveTab(name)
    activeTab = name
    for tname, btn in pairs(tabs) do
        if tname == name then
            tweenObject(btn, {BackgroundColor3 = Color3.fromRGB(12,20,28)}, 0.18)
            btn.TextColor3 = ACCENT
        else
            tweenObject(btn, {BackgroundColor3 = Color3.fromRGB(18,26,35)}, 0.18)
            btn.TextColor3 = TEXT_COLOR
        end
    end
    if name == "Main" then buildMain()
    elseif name == "Player" then buildPlayer()
    elseif name == "Teleport" then buildTeleport()
    elseif name == "Settings" then buildSettings()
    elseif name == "Info" then buildInfo() end
end

-- connect tab buttons
for name, btn in pairs(tabs) do
    btn.MouseButton1Click:Connect(function()
        setActiveTab(name)
    end)
end

-- initial build
setActiveTab("Main")

-- Close / Minimize functionality
local minimized = false
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    minimized = true
    -- show small floating button (mini)
    if not ScreenGui:FindFirstChild("RimuruMiniBtn") then
        local mini = Instance.new("ImageButton")
        mini.Name = "RimuruMiniBtn"
        mini.Size = UDim2.new(0, 56, 0, 56)
        mini.Position = UDim2.new(1, -86, 1, -120)
        mini.AnchorPoint = Vector2.new(0,0)
        mini.BackgroundColor3 = Color3.fromRGB(10,18,26)
        mini.AutoButtonColor = true
        mini.Parent = ScreenGui
        Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 12)
        local t = Instance.new("TextLabel", mini)
        t.Size = UDim2.new(1,1,1,1)
        t.BackgroundTransparency = 1
        t.Text = "YH"
        t.Font = Enum.Font.GothamBold
        t.TextSize = 20
        t.TextColor3 = ACCENT
        -- reopen on click
        mini.MouseButton1Click:Connect(function()
            MainFrame.Visible = true
            mini:Destroy()
            minimized = false
        end)
        -- allow dragging
        mini.Active = true
        mini.Draggable = true
    end
end)

MiniBtn.MouseButton1Click:Connect(function()
    if minimized then return end
    MainFrame.Visible = false
    if not ScreenGui:FindFirstChild("RimuruMiniBtn") then
        local mini = Instance.new("ImageButton")
        mini.Name = "RimuruMiniBtn"
        mini.Size = UDim2.new(0, 56, 0, 56)
        mini.Position = UDim2.new(1, -86, 1, -120)
        mini.AnchorPoint = Vector2.new(0,0)
        mini.BackgroundColor3 = Color3.fromRGB(10,18,26)
        mini.AutoButtonColor = true
        mini.Parent = ScreenGui
        Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 12)
        local t = Instance.new("TextLabel", mini)
        t.Size = UDim2.new(1,1,1,1)
        t.BackgroundTransparency = 1
        t.Text = "YH"
        t.Font = Enum.Font.GothamBold
        t.TextSize = 20
        t.TextColor3 = ACCENT
        mini.MouseButton1Click:Connect(function()
            MainFrame.Visible = true
            mini:Destroy()
        end)
        mini.Active = true
        mini.Draggable = true
    end
end)

-- RightShift toggle for desktop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if MainFrame.Visible then
            MainFrame.Visible = false
        else
            MainFrame.Visible = true
        end
    end
end)

-- Small entrance animation
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -180)
MainFrame.BackgroundTransparency = 1
tweenObject(MainFrame, {BackgroundTransparency = 0.15, Position = UDim2.new(0.5, -250, 0.5, -160)}, 0.45, Enum.EasingStyle.Cubic)

-- Make UI mobile friendly: scale on small screens
local function adjustForScreen()
    local sg = workspace.CurrentCamera.ViewportSize
    if sg.X < 900 then
        MainFrame.Size = UDim2.new(0, 420, 0, 340)
        -- Position tetap UDim2.new(0.5, 0, 0.5, 0) karena AnchorPoint sudah centering
    else
        MainFrame.Size = UDim2.new(0, 500, 0, 360)
        -- Position tetap UDim2.new(0.5, 0, 0.5, 0)
    end
end
adjustForScreen()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustForScreen)

-- Final: ensure cleanup on player leaving
player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        pcall(function()
            if descendantConnection then descendantConnection:Disconnect() end
        end)
    end
end)

-- End of script
print("Auto Fishing Rimuru UI loaded ✅ (persistence enabled)")
