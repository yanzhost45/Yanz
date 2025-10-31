-- Auto Fishing Rimuru UI v3.5 — Chibi Rimuru Edition (layout fixed)
-- Paste to executor (Synapse/Fluxus/ArceusX...). Replace CHIBI_ASSET_ID with your rimuru chibi asset id, e.g. "rbxassetid://12345678"

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
local camera = workspace.CurrentCamera

-- Theme
local BG_COLOR = Color3.fromRGB(15, 25, 35)
local ACCENT = Color3.fromRGB(123, 232, 255)
local ACCENT2 = Color3.fromRGB(80,200,255)
local TEXT_COLOR = Color3.fromRGB(235, 245, 255)

-- Persistence helpers
if not getgenv then getgenv = function() return _G end end
getgenv().AutoFishingRunning = getgenv().AutoFishingRunning or false
getgenv().AutoFishingStopRequested = getgenv().AutoFishingStopRequested or false
getgenv().AntiLagEnabled = getgenv().AntiLagEnabled or false

local STATE_FILENAME = "autofish_state_v3_5.json"
local function saveStateToFile(stateTable)
    if writefile and HttpService then
        pcall(function() writefile(STATE_FILENAME, HttpService:JSONEncode(stateTable)) end)
    end
end
local function loadStateFromFile()
    if readfile and HttpService then
        local ok, content = pcall(function() return readfile(STATE_FILENAME) end)
        if ok and content then
            local suc, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if suc and type(decoded) == "table" then return decoded end
        end
    end
    return nil
end
local function saveState()
    local state = { running = getgenv().AutoFishingRunning == true, antilag = getgenv().AntiLagEnabled == true }
    pcall(function() getgenv().AutoFishingRunning = state.running end)
    pcall(function() getgenv().AntiLagEnabled = state.antilag end)
    saveStateToFile(state)
end
local function loadState()
    if getgenv().AutoFishingRunning then
        return { running = true, antilag = getgenv().AntiLagEnabled == true }
    end
    local f = loadStateFromFile()
    if f and type(f.running) == "boolean" then
        pcall(function() getgenv().AutoFishingRunning = f.running end)
        pcall(function() getgenv().AntiLagEnabled = f.antilag end)
        return f
    end
    return { running = false, antilag = false }
end

-- Cleanup old GUI
if playerGui:FindFirstChild("AutoFishingRimuruGui_v3_5") then
    playerGui.AutoFishingRimuruGui_v3_5:Destroy()
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFishingRimuruGui_v3_5"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui
ScreenGui.IgnoreGuiInset = true

-- Logo (always present top-right) - replace Image with your chibi asset id
local LogoBtn = Instance.new("ImageButton")
LogoBtn.Name = "RimuruLogo"
LogoBtn.Size = UDim2.new(0, 64, 0, 64)
LogoBtn.Position = UDim2.new(1, -86, 0, 20) -- right top offset
LogoBtn.AnchorPoint = Vector2.new(0,0)
LogoBtn.BackgroundColor3 = Color3.fromRGB(10,18,26)
LogoBtn.BackgroundTransparency = 0
LogoBtn.AutoButtonColor = true
LogoBtn.Parent = ScreenGui
Instance.new("UICorner", LogoBtn).CornerRadius = UDim.new(0, 12)
local logoStroke = Instance.new("UIStroke", LogoBtn); logoStroke.Color = ACCENT2; logoStroke.Transparency = 0.75
-- Replace the string below with your chibi asset id, e.g. "rbxassetid://12345678"
LogoBtn.Image = "rbxassetid://0" -- <<< replace 0 with your chibi rimuru asset id

local LogoGlow = Instance.new("Frame", LogoBtn)
LogoGlow.Size = UDim2.new(1.3, 0, 1.3, 0)
LogoGlow.Position = UDim2.new(-0.15, 0, -0.15, 0)
LogoGlow.BackgroundColor3 = ACCENT
LogoGlow.BackgroundTransparency = 0.9
LogoGlow.ZIndex = 0
Instance.new("UICorner", LogoGlow).CornerRadius = UDim.new(1,0)

-- Main frame (static, not draggable)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 340)
MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.BackgroundTransparency = 0.18
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
MainFrame.ZIndex = 2 -- above aura

-- Soft aura container (subtle particles)
local AuraContainer = Instance.new("Frame", MainFrame)
AuraContainer.Name = "AuraContainer"
AuraContainer.Size = UDim2.new(1, 20, 1, 20)
AuraContainer.Position = UDim2.new(0, -10, 0, -10)
AuraContainer.BackgroundTransparency = 1
AuraContainer.ZIndex = 1

local auraParts = {}
for i=1,5 do
    local p = Instance.new("ImageLabel", AuraContainer)
    p.Name = "AuraMist"..i
    p.Size = UDim2.new(0, 200 + i*40, 0, 120 + i*20)
    p.Position = UDim2.new(0.5, -((200 + i*40)/2), 0.5, -((120 + i*20)/2))
    p.BackgroundTransparency = 1
    p.Image = "" -- blank, uses BackgroundColor with transparency to simulate mist
    p.BackgroundColor3 = ACCENT
    p.ImageTransparency = 1
    p.ZIndex = 1
    p.AnchorPoint = Vector2.new(0,0)
    p.Rotation = i*6
    p.Visible = true
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(1,0)
    local stroke = Instance.new("UIStroke", p); stroke.Color = ACCENT2; stroke.Transparency = 0.95
    table.insert(auraParts, p)
end

-- animate aura (gentle fade/scale)
spawn(function()
    while true do
        for i,p in ipairs(auraParts) do
            local alpha = 0.9 - (i*0.12)
            p.BackgroundTransparency = 1
            p.UIStroke.Transparency = 0.96
            local t1 = TweenService:Create(p, TweenInfo.new(3 + i*0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = alpha})
            t1:Play()
            local scaleX = 1 + (i*0.02)
            local t2 = TweenService:Create(p, TweenInfo.new(6 + i*0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.new(0, (200 + i*40)*scaleX, 0, (120 + i*20)*scaleX)})
            t2:Play()
        end
        task.wait(1.6)
    end
end)

-- Titlebar inside MainFrame
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1,0,0,48)
TitleBar.BackgroundTransparency = 1
local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 18, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎣 Auto Fishing — Rimuru Tempest UI"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextColor3 = TEXT_COLOR
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Sidebar & content
local SideBar = Instance.new("Frame", MainFrame)
SideBar.Name = "SideBar"
SideBar.Size = UDim2.new(0, 120, 1, -72)
SideBar.Position = UDim2.new(0, 12, 0, 60)
SideBar.BackgroundTransparency = 1

local Content = Instance.new("Frame", MainFrame)
Content.Name = "Content"
Content.Size = UDim2.new(1, -156, 1, -72)
Content.Position = UDim2.new(0, 140, 0, 60)
Content.BackgroundTransparency = 1

local function makeTabButton(name, y)
    local b = Instance.new("TextButton")
    b.Name = name .. "Tab"
    b.Size = UDim2.new(1, 0, 0, 44)
    b.Position = UDim2.new(0, 0, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(18,26,35)
    b.BorderSizePixel = 0
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = TEXT_COLOR
    b.TextSize = 15
    b.Parent = SideBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", b); stroke.Color = ACCENT2; stroke.Transparency = 0.86
    return b
end

local tabNames = {"Main","Player","Teleport","Settings","Info"}
local tabs = {}
for i,tname in ipairs(tabNames) do tabs[tname] = makeTabButton(tname, (i-1)*52) end

local function clearContent()
    for _,c in ipairs(Content:GetChildren()) do
        if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then c:Destroy() end
    end
end
local function tweenObject(obj, props, t, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end

-- backend net
local net = nil
do
    local ok, nres = pcall(function()
        return ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
    end)
    if ok and nres then net = nres else pcall(function() net = ReplicatedStorage:FindFirstChild("net") end)
end
local REFishCaught = net and net["RE/FishCaught"] or nil
local REObtainedNewFishNotification = net and net["RE/ObtainedNewFishNotification"] or nil
if REObtainedNewFishNotification then
    pcall(function() if getconnections then for _,c in pairs(getconnections(REObtainedNewFishNotification.OnClientEvent) or {}) do pcall(function() c:Disable() end) end end end)
end

-- Anti-lag (same safe impl)
local AntiLagState = { enabled = false, modified = {}, terrainOld = nil }
local descendantConnection = nil
local function applyAntiLagToDescendant(v)
    if not v or not v:IsDescendantOf(game) then return end
    if v:IsA("Texture") or v:IsA("Decal") then
        if v.Transparency ~= 1 then table.insert(AntiLagState.modified, {inst=v, prop="Transparency", old=v.Transparency}); pcall(function() v.Transparency = 1 end) end
    elseif v:IsA("SurfaceAppearance") then
        pcall(function() if v.Enabled ~= nil then table.insert(AntiLagState.modified, {inst=v, prop="Enabled", old=v.Enabled}); v.Enabled = false end end)
    end
end
local function enableAntiLag()
    if AntiLagState.enabled then return end
    AntiLagState.enabled = true; AntiLagState.modified = {}
    for _,v in ipairs(workspace:GetDescendants()) do applyAntiLagToDescendant(v) end
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        local old = {WaterReflectance=terrain.WaterReflectance, WaterTransparency=terrain.WaterTransparency, WaterWaveSize=terrain.WaterWaveSize, WaterWaveSpeed=terrain.WaterWaveSpeed}
        AntiLagState.terrainOld = old
        pcall(function() terrain.WaterReflectance=0; terrain.WaterTransparency=1; terrain.WaterWaveSize=0; terrain.WaterWaveSpeed=0 end)
    end
    descendantConnection = workspace.DescendantAdded:Connect(function(v) if AntiLagState.enabled then applyAntiLagToDescendant(v) end end)
    getgenv().AntiLagEnabled = true; saveState()
    print("[AntiLag] Enabled")
end
local function disableAntiLag()
    if not AntiLagState.enabled then return end
    AntiLagState.enabled = false
    for _,rec in ipairs(AntiLagState.modified) do pcall(function() if rec.inst and rec.inst.Parent then if rec.prop=="Transparency" then rec.inst.Transparency=rec.old elseif rec.prop=="Enabled" then rec.inst.Enabled=rec.old end end end) end
    AntiLagState.modified = {}
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and AntiLagState.terrainOld then pcall(function() terrain.WaterReflectance=AntiLagState.terrainOld.WaterReflectance; terrain.WaterTransparency=AntiLagState.terrainOld.WaterTransparency; terrain.WaterWaveSize=AntiLagState.terrainOld.WaterWaveSize; terrain.WaterWaveSpeed=AntiLagState.terrainOld.WaterWaveSpeed end); AntiLagState.terrainOld = nil end
    if descendantConnection then descendantConnection:Disconnect(); descendantConnection = nil end
    getgenv().AntiLagEnabled = false; saveState()
    print("[AntiLag] Disabled and reverted.")
end

-- Player controls (noclip/fly/speed/jump)
local PlayerControls = { speed = 16, jump = 50, noclip = false, fly = false, flySpeed = 60 }
local noclipConnection, flyBV, flyHeartbeatConn = nil, nil, nil
local flyInput = {W=false,A=false,S=false,D=false,Up=false,Down=false}
local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char and char.PrimaryPart then
            for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then pcall(function() part.CanCollide = false end) end end
        end
    end)
    PlayerControls.noclip = true
end
local function disableNoclip()
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    local char = player.Character
    if char then for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end end end
    PlayerControls.noclip = false
end
local function startFly()
    if flyHeartbeatConn then return end
    local char = player.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    pcall(function() if hum then hum.PlatformStand = false end end)
    flyBV = Instance.new("BodyVelocity"); flyBV.Name="RimuruFlyBV"; flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Velocity=Vector3.new(0,0,0); flyBV.Parent=hrp
    flyInput = {W=false,A=false,S=false,D=false,Up=false,Down=false}
    flyHeartbeatConn = RunService.RenderStepped:Connect(function(dt)
        if not player.Character or not player.Character.PrimaryPart then return end
        local camCFrame = workspace.CurrentCamera.CFrame
        local moveVec = Vector3.new(0,0,0)
        local front = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
        local right = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit
        if flyInput.W then moveVec = moveVec + front end
        if flyInput.S then moveVec = moveVec - front end
        if flyInput.A then moveVec = moveVec - right end
        if flyInput.D then moveVec = moveVec + right end
        local vertical = 0
        if flyInput.Up then vertical = vertical + 1 end
        if flyInput.Down then vertical = vertical - 1 end
        local speed = PlayerControls.flySpeed or 60
        local targetVel = Vector3.new(0, vertical * speed, 0)
        if moveVec.Magnitude > 0 then targetVel = (moveVec.Unit * speed) + Vector3.new(0, vertical * speed, 0) end
        flyBV.Velocity = targetVel
    end)
    PlayerControls.fly = true
end
local function stopFly()
    if flyHeartbeatConn then flyHeartbeatConn:Disconnect(); flyHeartbeatConn=nil end
    if flyBV and flyBV.Parent then flyBV:Destroy(); flyBV = nil end
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.PlatformStand=false end) end
    PlayerControls.fly = false
end
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then flyInput.W = true end
    if input.KeyCode == Enum.KeyCode.S then flyInput.S = true end
    if input.KeyCode == Enum.KeyCode.A then flyInput.A = true end
    if input.KeyCode == Enum.KeyCode.D then flyInput.D = true end
    if input.KeyCode == Enum.KeyCode.Space then flyInput.Up = true end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then flyInput.Down = true end
end)
UserInputService.InputEnded:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then flyInput.W = false end
    if input.KeyCode == Enum.KeyCode.S then flyInput.S = false end
    if input.KeyCode == Enum.KeyCode.A then flyInput.A = false end
    if input.KeyCode == Enum.KeyCode.D then flyInput.D = false end
    if input.KeyCode == Enum.KeyCode.Space then flyInput.Up = false end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then flyInput.Down = false end
end)

-- safe net helpers
local function safeInvoke(fn, ...)
    pcall(function() if fn then fn(...) end end)
end

-- Build UI: MAIN / PLAYER / TELEPORT / SETTINGS / INFO
-- (functions mostly same as v3 with fixes: no notif toggle, delay input bug fixed)
-- MAIN
local function buildMain()
    clearContent()
    local lbl = Instance.new("TextLabel", Content)
    lbl.Size = UDim2.new(1,0,0,28); lbl.BackgroundTransparency=1; lbl.Text="Auto Fishing"; lbl.Font=Enum.Font.GothamBold; lbl.TextColor3=ACCENT; lbl.TextSize=16; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local container = Instance.new("Frame", Content)
    container.Size = UDim2.new(1,0,0,260); container.Position = UDim2.new(0,0,0,36); container.BackgroundTransparency = 1

    local startBtn = Instance.new("TextButton", container)
    startBtn.Name = "StartBtn"; startBtn.Size = UDim2.new(0,240,0,44); startBtn.Position = UDim2.new(0,0,0,6)
    startBtn.BackgroundColor3 = ACCENT; startBtn.Text="▶ Start Auto Fish"; startBtn.Font=Enum.Font.GothamBold; startBtn.TextColor3=Color3.fromRGB(10,10,10); startBtn.TextSize=16
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,8); Instance.new("UIStroke", startBtn).Color = Color3.fromRGB(220,240,255)

    local delayLabel = Instance.new("TextLabel", container)
    delayLabel.Size = UDim2.new(0,160,0,20); delayLabel.Position = UDim2.new(0,0,0,62); delayLabel.BackgroundTransparency=1; delayLabel.Text="Minigame Delay (detik):"; delayLabel.Font=Enum.Font.Gotham; delayLabel.TextColor3=TEXT_COLOR; delayLabel.TextSize=14; delayLabel.TextXAlignment = Enum.TextXAlignment.Left

    local delayInput = Instance.new("TextBox", container)
    delayInput.Name="DelayInput"; delayInput.Size=UDim2.new(0,84,0,26); delayInput.Position=UDim2.new(0,0,0,86); delayInput.BackgroundColor3=Color3.fromRGB(28,36,44); delayInput.TextColor3=TEXT_COLOR; delayInput.Font=Enum.Font.Code; delayInput.TextSize=14; delayInput.Text="0.5"; delayInput.ClearTextOnFocus=false
    Instance.new("UICorner", delayInput).CornerRadius = UDim.new(0,6)

    local fishLabel = Instance.new("TextLabel", container)
    fishLabel.Name="FishLabel"; fishLabel.Size=UDim2.new(1,-20,0,20); fishLabel.Position = UDim2.new(0,0,0,124); fishLabel.BackgroundTransparency=1; fishLabel.Text="🐟 Total Ikan: 0"; fishLabel.Font=Enum.Font.GothamBold; fishLabel.TextColor3=Color3.fromRGB(0,255,150); fishLabel.TextSize=15; fishLabel.TextXAlignment=Enum.TextXAlignment.Left

    local timerLabel = Instance.new("TextLabel", container)
    timerLabel.Name="TimerLabel"; timerLabel.Size=UDim2.new(1,-20,0,20); timerLabel.Position=UDim2.new(0,0,0,150); timerLabel.BackgroundTransparency=1; timerLabel.Text="🕒 Waktu: 0m 0s"; timerLabel.Font=Enum.Font.Gotham; timerLabel.TextColor3=TEXT_COLOR; timerLabel.TextSize=14; timerLabel.TextXAlignment=Enum.TextXAlignment.Left

    local externalLabel = Instance.new("TextLabel", container)
    externalLabel.Size=UDim2.new(1,-20,0,18); externalLabel.Position=UDim2.new(0,0,0,176); externalLabel.BackgroundTransparency=1; externalLabel.Font=Enum.Font.Gotham; externalLabel.TextSize=12; externalLabel.TextColor3=Color3.fromRGB(200,200,200); externalLabel.TextXAlignment=Enum.TextXAlignment.Left; externalLabel.Text=""

    local isFishing_local=false; local fishCount=0; local startTime=0
    if REFishCaught then
        REFishCaught.OnClientEvent:Connect(function(fishName,data)
            local weight = data and data.Weight or "?"
            fishCount = fishCount + 1
            pcall(function() fishLabel.Text = "🐟 Total Ikan: " .. fishCount end)
            pcall(function() StarterGui:SetCore("SendNotification",{Title="🎣 Ikan Tertangkap!", Text = fishName .. " (" .. tostring(weight) .. " kg)", Duration = 3}) end)
        end)
    end
    spawn(function() while true do task.wait(1) if isFishing_local then local elapsed = math.floor(tick()-startTime); local minutes = math.floor(elapsed/60); local seconds = elapsed % 60; pcall(function() timerLabel.Text = string.format("🕒 Waktu: %dm %ds", minutes, seconds) end) end end end)

    local loaded = loadState()
    if loaded and loaded.running then externalLabel.Text = "Detected: AutoFishing running (external). Click Stop to request."; startBtn.Text = "⏸ Stop Auto Fish (Running)" else externalLabel.Text = "" end

    local function AutoFishLoop()
        if not net then startBtn.Text = "⚠ Net not found"; task.wait(1.6); startBtn.Text = "▶ Start Auto Fish"; return end
        if getgenv().AutoFishingRunning then externalLabel.Text = "AutoFishing already running elsewhere — request stop to control."; startBtn.Text = "⏸ Stop Auto Fish (Running)"; return end
        isFishing_local=true; startTime=tick(); fishCount=0; fishLabel.Text="🐟 Total Ikan: 0"; startBtn.Text="⏸ Stop Auto Fish"
        pcall(function() getgenv().AutoFishingRunning = true; getgenv().AutoFishingStopRequested = false end); saveState()
        while isFishing_local do
            if getgenv().AutoFishingStopRequested then isFishing_local=false; break end
            pcall(function() if net["RF/ChargeFishingRod"] then net["RF/ChargeFishingRod"]:InvokeServer(workspace:GetServerTimeNow()) end end)
            pcall(function() if net["RF/RequestFishingMinigameStarted"] then net["RF/RequestFishingMinigameStarted"]:InvokeServer(-0.3,0.2,workspace:GetServerTimeNow()) end end)
            local delayVal = tonumber(delayInput.Text) or 0.5
            task.wait(delayVal)
            pcall(function() if net["RE/FishingCompleted"] then net["RE/FishingCompleted"]:FireServer() end end)
            task.wait(0.28)
            pcall(function() if net["RF/CancelFishingInputs"] then net["RF/CancelFishingInputs"]:InvokeServer() end end)
        end
        isFishing_local=false; pcall(function() getgenv().AutoFishingRunning=false end); pcall(function() getgenv().AutoFishingStopRequested=false end); saveState()
        startBtn.Text="▶ Start Auto Fish"; externalLabel.Text=""
    end

    startBtn.MouseButton1Click:Connect(function()
        if getgenv().AutoFishingRunning and not isFishing_local then
            getgenv().AutoFishingStopRequested = true
            externalLabel.Text = "Stop requested... waiting for external loop to end."
            spawn(function() local waited=0; while getgenv().AutoFishingRunning and waited < 8 do task.wait(0.5); waited=waited+0.5 end
                if not getgenv().AutoFishingRunning then externalLabel.Text="External loop stopped. You can Start again."; startBtn.Text="▶ Start Auto Fish"; saveState() else externalLabel.Text="External loop did not stop. Use Force Stop in Settings."; startBtn.Text="Force Stop" end
            end)
            return
        end
        if isFishing_local then
            isFishing_local=false; getgenv().AutoFishingStopRequested=true; getgenv().AutoFishingRunning=false; saveState(); startBtn.Text="▶ Start Auto Fish"
        else spawn(AutoFishLoop) end
    end)
end

-- PLAYER
local function buildPlayer()
    clearContent()
    local title = Instance.new("TextLabel", Content)
    title.Size=UDim2.new(1,0,0,28); title.BackgroundTransparency=1; title.Text="Player"; title.Font=Enum.Font.GothamBold; title.TextColor3=ACCENT; title.TextSize=16; title.TextXAlignment=Enum.TextXAlignment.Left
    local cont = Instance.new("Frame", Content); cont.Size=UDim2.new(1,0,0,300); cont.Position=UDim2.new(0,0,0,36); cont.BackgroundTransparency=1

    -- WalkSpeed slider
    local wsLabel = Instance.new("TextLabel", cont); wsLabel.Size=UDim2.new(1,0,0,18); wsLabel.Position=UDim2.new(0,0,0,6); wsLabel.BackgroundTransparency=1; wsLabel.Text="WalkSpeed: 16"; wsLabel.Font=Enum.Font.Gotham; wsLabel.TextSize=14; wsLabel.TextColor3=TEXT_COLOR; wsLabel.TextXAlignment=Enum.TextXAlignment.Left
    local wsSliderBg = Instance.new("Frame", cont); wsSliderBg.Size=UDim2.new(0.78,0,0,14); wsSliderBg.Position=UDim2.new(0,0,0,30); wsSliderBg.BackgroundColor3=Color3.fromRGB(25,34,42); wsSliderBg.BorderSizePixel=0; Instance.new("UICorner", wsSliderBg).CornerRadius = UDim.new(0,6)
    local wsFill = Instance.new("Frame", wsSliderBg); wsFill.Size=UDim2.new(0.16,0,1,0); wsFill.BackgroundColor3=ACCENT; Instance.new("UICorner", wsFill).CornerRadius=UDim.new(0,6)
    local wsKnob = Instance.new("TextButton", wsSliderBg); wsKnob.Size=UDim2.new(0,14,1,0); wsKnob.Position = UDim2.new(0.16,-7,0,0); wsKnob.Text=""; wsKnob.BackgroundColor3=Color3.fromRGB(240,248,255); Instance.new("UICorner", wsKnob).CornerRadius=UDim.new(0,8)

    -- Jump slider
    local jpLabel = Instance.new("TextLabel", cont); jpLabel.Size=UDim2.new(1,0,0,18); jpLabel.Position=UDim2.new(0,0,0,62); jpLabel.BackgroundTransparency=1; jpLabel.Text="JumpPower: 50"; jpLabel.Font=Enum.Font.Gotham; jpLabel.TextSize=14; jpLabel.TextColor3=TEXT_COLOR; jpLabel.TextXAlignment=Enum.TextXAlignment.Left
    local jpSliderBg = Instance.new("Frame", cont); jpSliderBg.Size=UDim2.new(0.78,0,0,14); jpSliderBg.Position=UDim2.new(0,0,0,86); jpSliderBg.BackgroundColor3=Color3.fromRGB(25,34,42); jpSliderBg.BorderSizePixel=0; Instance.new("UICorner", jpSliderBg).CornerRadius = UDim.new(0,6)
    local jpFill = Instance.new("Frame", jpSliderBg); jpFill.Size=UDim2.new(0.25,0,1,0); jpFill.BackgroundColor3=ACCENT; Instance.new("UICorner", jpFill).CornerRadius=UDim.new(0,6)
    local jpKnob = Instance.new("TextButton", jpSliderBg); jpKnob.Size=UDim2.new(0,14,1,0); jpKnob.Position = UDim2.new(0.25,-7,0,0); jpKnob.Text=""; jpKnob.BackgroundColor3=Color3.fromRGB(240,248,255); Instance.new("UICorner", jpKnob).CornerRadius=UDim.new(0,8)

    -- Noclip & Fly
    local noclipBtn = Instance.new("TextButton", cont); noclipBtn.Size=UDim2.new(0,160,0,36); noclipBtn.Position=UDim2.new(0,0,0,120); noclipBtn.BackgroundColor3=Color3.fromRGB(28,36,44); noclipBtn.Text="Noclip: OFF"; noclipBtn.Font=Enum.Font.GothamBold; noclipBtn.TextSize=14; noclipBtn.TextColor3=TEXT_COLOR; Instance.new("UICorner", noclipBtn).CornerRadius=UDim.new(0,8)
    local flyBtn = Instance.new("TextButton", cont); flyBtn.Size=UDim2.new(0,160,0,36); flyBtn.Position=UDim2.new(0,0,0,166); flyBtn.BackgroundColor3=Color3.fromRGB(28,36,44); flyBtn.Text="Fly: OFF"; flyBtn.Font=Enum.Font.GothamBold; flyBtn.TextSize=14; flyBtn.TextColor3=TEXT_COLOR; Instance.new("UICorner", flyBtn).CornerRadius=UDim.new(0,8)
    local flyLabel = Instance.new("TextLabel", cont); flyLabel.Size=UDim2.new(1,0,0,16); flyLabel.Position=UDim2.new(0,180,0,124); flyLabel.BackgroundTransparency=1; flyLabel.Text="Fly Speed: 60"; flyLabel.Font=Enum.Font.Gotham; flyLabel.TextColor3=TEXT_COLOR; flyLabel.TextSize=13; flyLabel.TextXAlignment=Enum.TextXAlignment.Left
    local flyInputBox = Instance.new("TextBox", cont); flyInputBox.Size=UDim2.new(0,100,0,26); flyInputBox.Position=UDim2.new(0,180,0,146); flyInputBox.BackgroundColor3=Color3.fromRGB(28,36,44); flyInputBox.TextColor3=TEXT_COLOR; flyInputBox.Font=Enum.Font.Code; flyInputBox.TextSize=14; flyInputBox.Text=tostring(PlayerControls.flySpeed); flyInputBox.ClearTextOnFocus=false; Instance.new("UICorner", flyInputBox).CornerRadius=UDim.new(0,6)

    local function setupSlider(bg, fill, knob, minVal, maxVal, initial, onChange)
        local dragging=false
        local function setFromPosition(x)
            local abs = bg.AbsoluteSize.X
            if abs <= 0 then return end
            local rel = math.clamp((x - bg.AbsolutePosition.X) / abs, 0, 1)
            fill.Size = UDim2.new(rel,0,1,0)
            knob.Position = UDim2.new(rel, -7, 0, 0)
            local value = math.floor((minVal + (maxVal-minVal)*rel) * 100) / 100
            if onChange then pcall(onChange, value) end
        end
        knob.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; local mouse = UserInputService:GetMouseLocation(); setFromPosition(mouse.X) end end)
        UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then local mouse = UserInputService:GetMouseLocation(); setFromPosition(mouse.X) end end)
        UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        local ratio = math.clamp((initial - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(ratio,0,1,0); knob.Position = UDim2.new(ratio, -7, 0, 0)
    end

    setupSlider(wsSliderBg, wsFill, wsKnob, 8, 120, PlayerControls.speed, function(val) PlayerControls.speed=val; wsLabel.Text="WalkSpeed: "..tostring(math.floor(val)); local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.WalkSpeed=val end) end end)
    setupSlider(jpSliderBg, jpFill, jpKnob, 30, 200, PlayerControls.jump, function(val) PlayerControls.jump=val; jpLabel.Text="JumpPower: "..tostring(math.floor(val)); local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.JumpPower=val end) end end)

    noclipBtn.MouseButton1Click:Connect(function() if not PlayerControls.noclip then enableNoclip(); noclipBtn.Text="Noclip: ON"; tweenObject(noclipBtn,{BackgroundColor3=Color3.fromRGB(12,20,28)},0.15) else disableNoclip(); noclipBtn.Text="Noclip: OFF"; tweenObject(noclipBtn,{BackgroundColor3=Color3.fromRGB(28,36,44)},0.15) end end)
    flyBtn.MouseButton1Click:Connect(function() if not PlayerControls.fly then local v = tonumber(flyInputBox.Text) or PlayerControls.flySpeed; PlayerControls.flySpeed = math.max(10, math.min(500, v)); flyLabel.Text="Fly Speed: "..tostring(PlayerControls.flySpeed); startFly(); flyBtn.Text="Fly: ON"; tweenObject(flyBtn,{BackgroundColor3=Color3.fromRGB(12,20,28)},0.15) else stopFly(); flyBtn.Text="Fly: OFF"; tweenObject(flyBtn,{BackgroundColor3=Color3.fromRGB(28,36,44)},0.15) end end)
    flyInputBox.FocusLost:Connect(function() local v = tonumber(flyInputBox.Text); if v then PlayerControls.flySpeed = math.max(10, math.min(500, v)); flyLabel.Text = "Fly Speed: "..tostring(PlayerControls.flySpeed) else flyInputBox.Text = tostring(PlayerControls.flySpeed) end end)
end

-- TELEPORT
local function buildTeleport()
    clearContent()
    local title = Instance.new("TextLabel", Content); title.Size=UDim2.new(1,0,0,28); title.BackgroundTransparency=1; title.Text="Teleport"; title.Font=Enum.Font.GothamBold; title.TextColor3=ACCENT; title.TextSize=16; title.TextXAlignment=Enum.TextXAlignment.Left
    local cont = Instance.new("Frame", Content); cont.Size=UDim2.new(1,0,0,260); cont.Position=UDim2.new(0,0,0,36); cont.BackgroundTransparency=1
    local copyBtn = Instance.new("TextButton", cont); copyBtn.Size=UDim2.new(0,220,0,40); copyBtn.Position=UDim2.new(0,0,0,6); copyBtn.BackgroundColor3=Color3.fromRGB(30,40,50); copyBtn.Text="📋 Copy Player Position"; copyBtn.Font=Enum.Font.GothamBold; copyBtn.TextSize=14; copyBtn.TextColor3=TEXT_COLOR; Instance.new("UICorner", copyBtn).CornerRadius=UDim.new(0,8)
    local copyStatus = Instance.new("TextLabel", cont); copyStatus.Size=UDim2.new(1,0,0,18); copyStatus.Position=UDim2.new(0,0,0,54); copyStatus.BackgroundTransparency=1; copyStatus.Font=Enum.Font.Gotham; copyStatus.TextSize=13; copyStatus.TextColor3=Color3.fromRGB(200,200,200); copyStatus.TextXAlignment=Enum.TextXAlignment.Left; copyStatus.Text=""
    copyBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if not char or not char.PrimaryPart then copyStatus.Text="Character not found."; return end
        local v3 = char.PrimaryPart.Position
        local formatted = string.format("Vector3.new(%.3f, %.3f, %.3f)", v3.X, v3.Y, v3.Z)
        local ok=false; pcall(function() if setclipboard then setclipboard(formatted); ok=true end end)
        if ok then copyStatus.Text = "Copied to clipboard: "..formatted else copyStatus.Text = "setclipboard() not supported. Position: "..formatted; pcall(function() StarterGui:SetCore("SendNotification",{Title="Copy Position", Text="Executor lacks setclipboard(). Position shown in UI.", Duration=4}) end) end
    end)
    local hint = Instance.new("TextLabel", cont); hint.Size=UDim2.new(1,0,0,80); hint.Position=UDim2.new(0,0,0,86); hint.BackgroundTransparency=1; hint.Text="Teleport favorites placeholder.\nUse Copy Player Position to grab coords."; hint.Font=Enum.Font.Gotham; hint.TextColor3=TEXT_COLOR; hint.TextSize=13; hint.TextWrapped=true
end

-- SETTINGS
local function buildSettings()
    clearContent()
    local title = Instance.new("TextLabel", Content); title.Size=UDim2.new(1,0,0,28); title.BackgroundTransparency=1; title.Text="Settings"; title.Font=Enum.Font.GothamBold; title.TextColor3=ACCENT; title.TextSize=16; title.TextXAlignment=Enum.TextXAlignment.Left
    local cont = Instance.new("Frame", Content); cont.Size=UDim2.new(1,0,0,260); cont.Position=UDim2.new(0,0,0,36); cont.BackgroundTransparency=1
    local antiLabel = Instance.new("TextLabel", cont); antiLabel.Size=UDim2.new(1,0,0,18); antiLabel.Position=UDim2.new(0,0,0,6); antiLabel.BackgroundTransparency=1; antiLabel.Text="Anti-Lag (disable textures/decals & terrain water)"; antiLabel.Font=Enum.Font.Gotham; antiLabel.TextColor3=TEXT_COLOR; antiLabel.TextSize=14; antiLabel.TextXAlignment=Enum.TextXAlignment.Left
    local antiToggle = Instance.new("TextButton", cont); antiToggle.Size=UDim2.new(0,180,0,36); antiToggle.Position=UDim2.new(0,0,0,30); antiToggle.BackgroundColor3=Color3.fromRGB(28,36,44); antiToggle.Text="Anti-Lag: OFF"; antiToggle.Font=Enum.Font.GothamBold; antiToggle.TextSize=14; antiToggle.TextColor3=TEXT_COLOR; Instance.new("UICorner", antiToggle).CornerRadius=UDim.new(0,8); local antiStroke = Instance.new("UIStroke", antiToggle); antiStroke.Color=ACCENT2; antiStroke.Transparency=0.9
    local forceBtn = Instance.new("TextButton", cont); forceBtn.Size=UDim2.new(0,180,0,36); forceBtn.Position=UDim2.new(0,0,0,86); forceBtn.BackgroundColor3=Color3.fromRGB(80,20,20); forceBtn.Text="Force Stop AutoFishing"; forceBtn.Font=Enum.Font.GothamBold; forceBtn.TextSize=14; forceBtn.TextColor3=TEXT_COLOR; Instance.new("UICorner", forceBtn).CornerRadius=UDim.new(0,8)
    local forceStatus = Instance.new("TextLabel", cont); forceStatus.Size=UDim2.new(1,0,0,28); forceStatus.Position=UDim2.new(0,0,0,132); forceStatus.BackgroundTransparency=1; forceStatus.Font=Enum.Font.Gotham; forceStatus.TextSize=13; forceStatus.TextColor3=Color3.fromRGB(200,200,200); forceStatus.TextXAlignment=Enum.TextXAlignment.Left; forceStatus.Text=""
    if getgenv().AntiLagEnabled then antiToggle.Text="Anti-Lag: ON"; tweenObject(antiToggle, {BackgroundColor3=Color3.fromRGB(12,20,28)},0.12) else antiToggle.Text="Anti-Lag: OFF"; tweenObject(antiToggle, {BackgroundColor3=Color3.fromRGB(28,36,44)},0.12) end
    antiToggle.MouseButton1Click:Connect(function() if not AntiLagState.enabled then antiToggle.Text="Anti-Lag: ON"; tweenObject(antiToggle,{BackgroundColor3=Color3.fromRGB(12,20,28)},0.12); spawn(enableAntiLag) else antiToggle.Text="Anti-Lag: OFF"; tweenObject(antiToggle,{BackgroundColor3=Color3.fromRGB(28,36,44)},0.12); spawn(disableAntiLag) end end)
    forceBtn.MouseButton1Click:Connect(function() pcall(function() getgenv().AutoFishingStopRequested=true end); pcall(function() getgenv().AutoFishingRunning=false end); saveState(); forceStatus.Text="Force stop requested. If loop ignores flags, rejoin the server."; tweenObject(forceBtn,{BackgroundColor3=Color3.fromRGB(40,10,10)},0.12); task.wait(0.6); tweenObject(forceBtn,{BackgroundColor3=Color3.fromRGB(80,20,20)},0.12) end)
end

-- INFO
local function buildInfo()
    clearContent()
    local title = Instance.new("TextLabel", Content); title.Size=UDim2.new(1,0,0,28); title.BackgroundTransparency=1; title.Text="Info"; title.Font=Enum.Font.GothamBold; title.TextColor3=ACCENT; title.TextSize=16; title.TextXAlignment=Enum.TextXAlignment.Left
    local cont = Instance.new("Frame", Content); cont.Size=UDim2.new(1,0,0,260); cont.Position=UDim2.new(0,0,0,36); cont.BackgroundTransparency=1
    local credit = Instance.new("TextLabel", cont); credit.Size=UDim2.new(1,0,0,220); credit.Position=UDim2.new(0,0,0,6); credit.BackgroundTransparency=1; credit.Text="Auto Fishing (Rimuru Tempest Edition)\n\nScript by bubub 😎\n\nFeatures: Rimuru UI aura, persistent AutoFishing, Anti-Lag, Player controls, Copy Position (setclipboard)." ; credit.Font=Enum.Font.Gotham; credit.TextColor3=TEXT_COLOR; credit.TextSize=14; credit.TextWrapped=true; credit.TextXAlignment=Enum.TextXAlignment.Left
end

-- Tab handlers
local activeTab = "Main"
local function setActiveTab(name)
    activeTab = name
    for tname, btn in pairs(tabs) do
        if tname == name then tweenObject(btn, {BackgroundColor3=Color3.fromRGB(12,20,28)},0.18); btn.TextColor3 = ACCENT else tweenObject(btn, {BackgroundColor3=Color3.fromRGB(18,26,35)},0.18); btn.TextColor3 = TEXT_COLOR end
    end
    if name == "Main" then buildMain() elseif name == "Player" then buildPlayer() elseif name == "Teleport" then buildTeleport() elseif name == "Settings" then buildSettings() elseif name == "Info" then buildInfo() end
end
for name, btn in pairs(tabs) do btn.MouseButton1Click:Connect(function() setActiveTab(name) end) end

-- Positioning: place MainFrame to the left and slightly below the logo (responsive)
local function positionUI()
    local vw = camera.ViewportSize
    -- calculate offsets depending on screen size
    local logoOffsetX = 86 -- width + margin of logo
    local margin = 18
    local frameWidth = (vw.X < 900) and 420 or 480
    local frameHeight = (vw.X < 900) and 320 or 340
    MainFrame.Size = UDim2.new(0, frameWidth, 0, frameHeight)
    -- place left-below of logo: put MainFrame so its right edge sits some pixels left from logo, y a bit below
    local rightOffset = logoOffsetX + margin
    local posX = vw.X - rightOffset - frameWidth
    local posY = 20 + 64 + 8 -- logo y + logo height + small gap
    -- ensure not offscreen left
    if posX < 12 then posX = 12 end
    MainFrame.Position = UDim2.new(0, posX, 0, posY)
end

-- handle viewport change to reposition
positionUI()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(positionUI)

-- initial load state: if anti-lag was saved, enable it
local loadedState = loadState()
if loadedState.antilag then spawn(enableAntiLag) end

-- Build initial tab
setActiveTab("Main")

-- Logo click toggles main UI visibility (logo always visible)
LogoBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Always keep logo shown (if user tries to hide, re-show)
ScreenGui.DescendantRemoving:Connect(function(desc)
    if desc == LogoBtn then
        -- recreate logo without user prompt (best-effort)
        task.wait(0.1)
        if not ScreenGui:FindFirstChild("RimuruLogo") then
            -- quick recreate with same settings (image left as placeholder)
            local r = Instance.new("ImageButton"); r.Name="RimuruLogo"; r.Size=UDim2.new(0,64,0,64); r.Position=UDim2.new(1,-86,0,20); r.BackgroundColor3=Color3.fromRGB(10,18,26); r.Parent=ScreenGui; Instance.new("UICorner", r).CornerRadius=UDim.new(0,12); r.Image="rbxassetid://0" -- replace if needed
            r.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
        end
    end
end)

-- RightShift toggle
UserInputService.InputBegan:Connect(function(input, gpe) if gpe then return end if input.KeyCode==Enum.KeyCode.RightShift then MainFrame.Visible = not MainFrame.Visible end end)

-- Responsive adjust on load & when content rebuilt
positionUI()

-- Cleanup on leave
player.AncestryChanged:Connect(function(_, parent) if not parent then pcall(function() if descendantConnection then descendantConnection:Disconnect() end end) end end)

print("Auto Fishing Rimuru UI v3.5 — Chibi Edition loaded ✅")
