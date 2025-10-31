-- Auto Fishing Rimuru UI (Final by bubub) 🎣✨
-- Changes: no notifications, persist only delay + gui pos to yanz-script.json, instant-stop calls CancelFishing, teleport presets added

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- Theme
local BG_COLOR = Color3.fromRGB(15, 25, 35)
local ACCENT = Color3.fromRGB(123, 232, 255)
local ACCENT2 = Color3.fromRGB(80,200,255)
local TEXT_COLOR = Color3.fromRGB(235,245,255)

-- Persistence
if not getgenv then getgenv = function() return _G end end
local STATE_FILE = "yanz-script.json"

local function safeWrite(json)
    if writefile and HttpService then
        pcall(function() writefile(STATE_FILE, HttpService:JSONEncode(json)) end)
    end
end
local function safeRead()
    if isfile and readfile and HttpService and isfile(STATE_FILE) then
        local ok, raw = pcall(function() return readfile(STATE_FILE) end)
        if ok and raw then
            local suc, dec = pcall(function() return HttpService:JSONDecode(raw) end)
            if suc and type(dec) == "table" then return dec end
        end
    end
    return nil
end

-- default persisted state
local persisted = safeRead() or {}
if type(persisted.delay) ~= "number" then persisted.delay = 0.5 end
-- GUI pos persisted in same file if present (keys: pos = {X, Xo, Y, Yo})
local function savePersist()
    safeWrite(persisted)
end

-- Cleanup old GUI
if playerGui:FindFirstChild("AutoFishingRimuruGui") then
    playerGui.AutoFishingRimuruGui:Destroy()
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoFishingRimuruGui"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Logo (top-right chibi; using a default asset)
local LogoBtn = Instance.new("ImageButton")
LogoBtn.Name = "RimuruLogo"
LogoBtn.Size = UDim2.new(0,64,0,64)
LogoBtn.Position = UDim2.new(1,-86,0,20)
LogoBtn.BackgroundColor3 = Color3.fromRGB(10,18,26)
LogoBtn.Parent = ScreenGui
Instance.new("UICorner", LogoBtn).CornerRadius = UDim.new(0,12)
LogoBtn.Image = "rbxassetid://6533429165" -- Using a default fishing rod image

-- MainFrame (center)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5,0.5)
MainFrame.Size = UDim2.new(0,500,0,360)
MainFrame.Position = UDim2.new(0.5,0,0.5,0)
MainFrame.BackgroundColor3 = BG_COLOR
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,14)

-- Drag functionality
local dragging = false
local dragStart = nil
local startPos = nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Title
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1,0,0,48)
TitleBar.BackgroundTransparency = 1
local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(0.6, -20, 1, 0)
TitleLabel.Position = UDim2.new(0, 18, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎣 Auto Fishing — Rimuru UI"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextColor3 = TEXT_COLOR
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Close / Mini
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0,30,0,30); CloseBtn.Position = UDim2.new(1,-42,0,8)
CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextColor3 = TEXT_COLOR
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,8)
local MiniBtn = Instance.new("TextButton", TitleBar)
MiniBtn.Size = UDim2.new(0,34,0,34); MiniBtn.Position = UDim2.new(1,-82,0,6)
MiniBtn.Text = "-"; MiniBtn.Font = Enum.Font.GothamBold; MiniBtn.TextColor3 = TEXT_COLOR
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(0,8)

-- Sidebar
local SideBar = Instance.new("Frame", MainFrame)
SideBar.Size = UDim2.new(0,120,1,-72)
SideBar.Position = UDim2.new(0,12,0,60)
SideBar.BackgroundTransparency = 1

local function makeTabButton(name, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,44); b.Position = UDim2.new(0,0,0,y)
    b.Text = name; b.Font = Enum.Font.GothamBold; b.TextColor3 = TEXT_COLOR; b.TextSize = 14
    b.BackgroundColor3 = Color3.fromRGB(18,26,35); b.BorderSizePixel = 0; b.Parent = SideBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

local tabs = {}
local tabNames = {"Main","Player","Teleport","Settings","Info"}
for i,name in ipairs(tabNames) do tabs[name] = makeTabButton(name,(i-1)*52) end

-- Content
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1,-156,1,-72); Content.Position = UDim2.new(0,140,0,60); Content.BackgroundTransparency = 1

local function clearContent()
    for _,c in ipairs(Content:GetChildren()) do
        if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then pcall(function() c:Destroy() end) end
    end
end

local function tweenObject(obj, props, t, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end

-- Backend net (safe)
local net = nil
pcall(function()
    net = ReplicatedStorage:WaitForChild("Packages",1) and ReplicatedStorage.Packages:WaitForChild("_Index",1) and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0") and ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]:FindFirstChild("net")
end)
if not net then pcall(function() net = ReplicatedStorage:FindFirstChild("net") end) end

local REFishCaught = net and net["RE/FishCaught"] or nil
local CancelFishingRemote = net and net["RF/CancelFishingInputs"] or nil

-- Teleport presets (from your list)
local TELEPORT_PRESETS = {
    ["Hallow Bay"] = CFrame.new(1756.245361328125, 7.867569446563721, 3039.74609375, 0.9994795918464661, 7.515937738844514e-08, -0.032257046550512314, -7.383445677078271e-08, 1, 4.226487959613223e-08, 0.032257046550512314, -3.986120233889778e-08, 0.9994795918464661),
    ["Mount Hallow"] = CFrame.new(2105.3671875, 81.03092956542969, 3295.617919921875, -0.20203767716884613, 6.905739535767452e-09, -0.9793777465820312, 2.1682696527136613e-08, 1, 2.5781858870033147e-09, 0.9793777465820312, -2.071466020936441e-08, -0.20203767716884613),
    ["Crater Islands"] = CFrame.new(1066.1864, 57.2025681, 5045.5542, -0.682534158, 1.00865822e-08, 0.730853677, -5.8900711e-09, 1, -1.93017531e-08, -0.730853677, -1.74788859e-08, -0.682534158),
    ["Tropical Grove"] = CFrame.new(-2165.05469, 2.77070165, 3639.87451, -0.589090407, -3.61497356e-08, -0.808067143, -3.20645626e-08, 1, -2.13606164e-08, 0.808067143, 1.3326984e-08, -0.589090407),
    ["Volcano Island"] = CFrame.new(-701.447937, 48.1446075, 93.1546631, -0.0770962164, 1.34335654e-08, -0.997023642, 9.84464776e-09, 1, 1.27124169e-08, 0.997023642, -8.83526763e-09, -0.0770962164),
    ["Coral Reefs"] = CFrame.new(-3118.39624, 2.42531538, 2135.26392, 0.92336154, -1.0069185e-07, -0.383931547, 8.0607947e-08, 1, -6.84016968e-08, 0.383931547, 3.22115596e-08, 0.92336154),
    ["Winter Tundra"] = CFrame.new(2036.15308, 6.54998732, 3381.88916, 0.943401575, 4.71338666e-08, -0.331652641, -3.28136842e-08, 1, 4.87781051e-08, 0.331652641, -3.51345975e-08, 0.943401575),
    ["Weather Machine"] = CFrame.new(-1459.3772, 14.7103214, 1831.5188, 0.777951121, 2.52131862e-08, -0.628324807, -5.24126378e-08, 1, -2.47663063e-08, 0.628324807, 5.21991339e-08, 0.777951121),
    ["Treasure Room"] = CFrame.new(-3625.0708, -279.074219, -1594.57605, 0.918176472, -3.97606392e-09, -0.396171629, -1.12946204e-08, 1, -3.62128851e-08, 0.396171629, 3.77244298e-08, 0.918176472),
    ["Sisyphus Statue"] = CFrame.new(-3777.43433, -135.074417, -975.198975, -0.284491211, -1.02338751e-08, -0.958678663, 6.38407585e-08, 1, -2.96199456e-08, 0.958678663, -6.96293867e-08, -0.284491211),
    ["Fisherman Island"] = CFrame.new(-75.2439423, 3.24433279, 3103.45093, -0.996514142, -3.14880424e-08, -0.0834242329, -3.84156422e-08, 1, 8.14354024e-08, 0.0834242329, 8.43563228e-08, -0.996514142),
    ["Ancient Jungle"] = CFrame.new(1630.15234, 6.62499952, -724.767212, 0.425332367, 6.19636324e-08, -0.905037224, -6.98903548e-08, 1, 3.56195322e-08, 0.905037224, 4.81032352e-08, 0.425332367),
    ["Sacred Temple"] = CFrame.new(1468.44946, -22.1250019, -651.350342, -0.114698552, -1.09982246e-07, 0.993400335, -1.87054479e-08, 1, 1.08553166e-07, -0.993400335, -6.13110718e-09, -0.114698552),
}

-- UI Builders

-- Build Main tab
local function buildMain()
    clearContent()
    local title = Instance.new("TextLabel", Content)
    title.Size = UDim2.new(1,0,0,26); title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold; title.Text = "Auto Fishing"; title.TextColor3 = ACCENT; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left

    local container = Instance.new("Frame", Content)
    container.Size = UDim2.new(1,0,0,240); container.Position = UDim2.new(0,0,0,38); container.BackgroundTransparency = 1

    -- Start/Stop
    local startBtn = Instance.new("TextButton", container)
    startBtn.Name = "StartBtn"; startBtn.Size = UDim2.new(0,240,0,44); startBtn.Position = UDim2.new(0,0,0,6)
    startBtn.BackgroundColor3 = ACCENT; startBtn.Font = Enum.Font.GothamBold; startBtn.TextColor3 = Color3.fromRGB(10,10,10); startBtn.TextSize = 16
    startBtn.Text = "▶ Start Auto Fish"
    Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,8)

    -- Delay input (persisted)
    local delayLabel = Instance.new("TextLabel", container)
    delayLabel.Size = UDim2.new(0,160,0,20); delayLabel.Position = UDim2.new(0,0,0,62); delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Minigame Delay (detik):"; delayLabel.Font = Enum.Font.Gotham; delayLabel.TextColor3 = TEXT_COLOR; delayLabel.TextSize = 14; delayLabel.TextXAlignment = Enum.TextXAlignment.Left

    local delayInput = Instance.new("TextBox", container)
    delayInput.Name = "DelayInput"; delayInput.Size = UDim2.new(0,80,0,24); delayInput.Position = UDim2.new(0,0,0,86)
    delayInput.BackgroundColor3 = Color3.fromRGB(28,36,44); delayInput.TextColor3 = TEXT_COLOR; delayInput.Font = Enum.Font.Code; delayInput.TextSize = 14
    delayInput.ClearTextOnFocus = false
    delayInput.Text = tostring(persisted.delay or 0.5)
    Instance.new("UICorner", delayInput).CornerRadius = UDim.new(0,6)

    -- fish count & timer
    local fishLabel = Instance.new("TextLabel", container)
    fishLabel.Size = UDim2.new(1,-20,0,20); fishLabel.Position = UDim2.new(0,0,0,118); fishLabel.BackgroundTransparency = 1
    fishLabel.Text = "🐟 Total Ikan: 0"; fishLabel.Font = Enum.Font.GothamBold; fishLabel.TextColor3 = Color3.fromRGB(0,255,150); fishLabel.TextXAlignment = Enum.TextXAlignment.Left

    local timerLabel = Instance.new("TextLabel", container)
    timerLabel.Size = UDim2.new(1,-20,0,20); timerLabel.Position = UDim2.new(0,0,0,146); timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "🕒 Waktu: 0m 0s"; timerLabel.Font = Enum.Font.Gotham; timerLabel.TextColor3 = TEXT_COLOR; timerLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- external indicator
    local externalLabel = Instance.new("TextLabel", container)
    externalLabel.Size = UDim2.new(1,-20,0,20); externalLabel.Position = UDim2.new(0,250,0,12); externalLabel.BackgroundTransparency = 1
    externalLabel.Font = Enum.Font.Gotham; externalLabel.TextColor3 = Color3.fromRGB(200,200,200); externalLabel.TextSize = 12

    -- state
    local isFishing = false
    local fishCount = 0
    local startTime = 0

    -- REFishCaught handling (count)
    if REFishCaught then
        REFishCaught.OnClientEvent:Connect(function(fishName, data)
            local weight = data and data.Weight or "?"
            fishCount = fishCount + 1
            pcall(function() fishLabel.Text = "🐟 Total Ikan: " .. fishCount end)
        end)
    end

    -- timer update
    spawn(function()
        while true do
            task.wait(1)
            if isFishing then
                local elapsed = math.floor(tick() - startTime)
                local m = math.floor(elapsed/60); local s = elapsed % 60
                pcall(function() timerLabel.Text = string.format("🕒 Waktu: %dm %ds", m, s) end)
            end
        end
    end)

    -- AutoFishLoop (instant-stop aware)
    local function AutoFishLoop()
        if not net then
            startBtn.Text = "⚠ Net not found"
            task.wait(1.5)
            startBtn.Text = "▶ Start Auto Fish"
            return
        end

        if getgenv().AutoFishingRunning then
            externalLabel.Text = "Auto Fishing running elsewhere"
            startBtn.Text = "⏸ Stop Auto Fish (Running)"
            return
        end

        -- start
        isFishing = true; startTime = tick(); fishCount = 0
        pcall(function() startBtn.Text = "⏸ Stop Auto Fish" end)
        pcall(function() getgenv().AutoFishingRunning = true; getgenv().AutoFishingStopRequested = false end)

        while isFishing do
            if getgenv().AutoFishingStopRequested then
                isFishing = false; break
            end

            pcall(function()
                if net["RF/ChargeFishingRod"] then net["RF/ChargeFishingRod"]:InvokeServer(workspace:GetServerTimeNow()) end
            end)
            if not isFishing or getgenv().AutoFishingStopRequested then break end

            pcall(function()
                if net["RF/RequestFishingMinigameStarted"] then net["RF/RequestFishingMinigameStarted"]:InvokeServer(-0.3,0.2,workspace:GetServerTimeNow()) end
            end)
            if not isFishing or getgenv().AutoFishingStopRequested then break end

            local delayVal = tonumber(delayInput.Text) or (persisted.delay or 0.5)
            local sT = tick()
            while tick() - sT < delayVal do
                if getgenv().AutoFishingStopRequested then isFishing = false; break end
                task.wait(0.05)
            end
            if not isFishing then break end

            pcall(function() if net["RE/FishingCompleted"] then net["RE/FishingCompleted"]:FireServer() end end)
            if getgenv().AutoFishingStopRequested then break end

            local mini = tick()
            while tick() - mini < 0.3 do
                if getgenv().AutoFishingStopRequested then isFishing = false; break end
                task.wait(0.05)
            end
            if not isFishing then break end

            pcall(function() if net["RF/CancelFishingInputs"] then net["RF/CancelFishingInputs"]:InvokeServer() end end)
        end

        -- ensure server cancel called when stopping
        pcall(function()
            if CancelFishingRemote then
                pcall(function() CancelFishingRemote:InvokeServer() end)
            end
        end)

        -- cleanup
        isFishing = false
        pcall(function() getgenv().AutoFishingRunning = false; getgenv().AutoFishingStopRequested = false end)
        startBtn.Text = "▶ Start Auto Fish"
        externalLabel.Text = ""
    end

    -- Start/Stop button click
    startBtn.MouseButton1Click:Connect(function()
        -- if external running and not local, request stop
        if getgenv().AutoFishingRunning and not isFishing then
            getgenv().AutoFishingStopRequested = true
            externalLabel.Text = "Stop requested... waiting"
            spawn(function()
                local waited = 0
                while getgenv().AutoFishingRunning and waited < 8 do task.wait(0.5); waited = waited + 0.5 end
                if not getgenv().AutoFishingRunning then
                    externalLabel.Text = "External loop stopped"
                    startBtn.Text = "▶ Start Auto Fish"
                else
                    externalLabel.Text = "External loop didn't stop. Use Force Stop."
                    startBtn.Text = "Force Stop"
                end
            end)
            return
        end

        if isFishing then
            -- immediate stop + send CancelFishingRemote if available
            getgenv().AutoFishingStopRequested = true
            isFishing = false
            pcall(function() if CancelFishingRemote then CancelFishingRemote:InvokeServer() end end)
            pcall(function() getgenv().AutoFishingRunning = false end)
            startBtn.Text = "▶ Start Auto Fish"
        else
            spawn(AutoFishLoop)
        end
    end)

    -- persist delay when changed
    delayInput.FocusLost:Connect(function(enter)
        local v = tonumber(delayInput.Text)
        if v and v > 0 then
            persisted.delay = v
            savePersist()
        else
            delayInput.Text = tostring(persisted.delay or 0.5)
        end
    end)
end

-- Build Player tab (speed, jump, noclip, fly) - light implementation
local function buildPlayer()
    clearContent()
    local title = Instance.new("TextLabel", Content)
    title.Size = UDim2.new(1,0,0,26); title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold; title.Text = "Player"; title.TextColor3 = ACCENT; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left

    local cont = Instance.new("Frame", Content); cont.Size = UDim2.new(1,0,0,220); cont.Position = UDim2.new(0,0,0,36); cont.BackgroundTransparency = 1

    -- WalkSpeed slider
    local wsLabel = Instance.new("TextLabel", cont); wsLabel.Size = UDim2.new(1,0,0,18); wsLabel.Position = UDim2.new(0,0,0,6); wsLabel.BackgroundTransparency = 1
    wsLabel.Text = "WalkSpeed: 16"; wsLabel.Font = Enum.Font.Gotham; wsLabel.TextColor3 = TEXT_COLOR; wsLabel.TextSize = 14; wsLabel.TextXAlignment = Enum.TextXAlignment.Left

    local wsInput = Instance.new("TextBox", cont); wsInput.Size = UDim2.new(0,90,0,26); wsInput.Position = UDim2.new(0,0,0,30); wsInput.Text = "16"; wsInput.Font = Enum.Font.Code; wsInput.TextColor3 = TEXT_COLOR; wsInput.ClearTextOnFocus = false
    Instance.new("UICorner", wsInput).CornerRadius = UDim.new(0,6)

    wsInput.FocusLost:Connect(function()
        local v = tonumber(wsInput.Text)
        if v then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.WalkSpeed = v end) end
            wsLabel.Text = "WalkSpeed: "..tostring(v)
        else wsInput.Text = "16" end
    end)

    -- JumpPower input
    local jpLabel = Instance.new("TextLabel", cont); jpLabel.Size = UDim2.new(1,0,0,18); jpLabel.Position = UDim2.new(0,120,0,6); jpLabel.BackgroundTransparency = 1
    jpLabel.Text = "JumpPower: 50"; jpLabel.Font = Enum.Font.Gotham; jpLabel.TextColor3 = TEXT_COLOR; jpLabel.TextSize = 14; jpLabel.TextXAlignment = Enum.TextXAlignment.Left

    local jpInput = Instance.new("TextBox", cont); jpInput.Size = UDim2.new(0,90,0,26); jpInput.Position = UDim2.new(0,120,0,30); jpInput.Text = "50"; jpInput.Font = Enum.Font.Code; jpInput.TextColor3 = TEXT_COLOR; jpInput.ClearTextOnFocus = false
    Instance.new("UICorner", jpInput).CornerRadius = UDim.new(0,6)

    jpInput.FocusLost:Connect(function()
        local v = tonumber(jpInput.Text)
        if v then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.JumpPower = v end) end
            jpLabel.Text = "JumpPower: "..tostring(v)
        else jpInput.Text = "50" end
    end)

    -- Noclip toggle
    local noclipBtn = Instance.new("TextButton", cont); noclipBtn.Size = UDim2.new(0,160,0,36); noclipBtn.Position = UDim2.new(0,0,0,74); noclipBtn.Text = "Noclip: OFF"; noclipBtn.Font = Enum.Font.GothamBold; noclipBtn.TextColor3 = TEXT_COLOR
    Instance.new("UICorner", noclipBtn).CornerRadius = UDim.new(0,8)
    local noclipConn = nil
    noclipBtn.MouseButton1Click:Connect(function()
        if not noclipConn then
            noclipBtn.Text = "Noclip: ON"
            noclipConn = RunService.Stepped:Connect(function()
                local char = player.Character
                if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
            end)
        else
            noclipBtn.Text = "Noclip: OFF"
            noclipConn:Disconnect(); noclipConn = nil
            local char = player.Character
            if char then for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        end
    end)
end

-- Build Teleport tab (using the new scrolling implementation)
local function buildTeleport()
    clearContent()
    
    -- 🧭 TELEPORT TAB (scrollable & mobile friendly)
    local TeleportTab = Instance.new("Frame")
    TeleportTab.Name = "TeleportTab"
    TeleportTab.BackgroundTransparency = 1
    TeleportTab.Size = UDim2.new(1, 0, 1, -40)
    TeleportTab.Position = UDim2.new(0, 0, 0, 40)
    TeleportTab.Visible = true
    TeleportTab.Parent = Content

    -- ScrollingFrame buat konten
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = "TeleportScroll"
    Scroll.Size = UDim2.new(1, -10, 1, -50)
    Scroll.Position = UDim2.new(0, 5, 0, 10)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 5
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    Scroll.MidImage = "rbxassetid://6883017081" -- transparan halus
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(90, 200, 255)
    Scroll.Active = true
    Scroll.ClipsDescendants = true
    Scroll.ScrollingEnabled = true
    Scroll.Parent = TeleportTab

    -- Layout biar rapi vertikal
    local list = Instance.new("UIListLayout", Scroll)
    list.Padding = UDim.new(0, 5)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder

    -- Fungsi tambah tombol teleport
    local function addTeleportButton(name, pos)
        local btn = Instance.new("TextButton")
        btn.Text = name
        btn.Size = UDim2.new(0.9, 0, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
        btn.TextColor3 = Color3.fromRGB(200, 230, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = true
        btn.Parent = Scroll
        btn.BackgroundTransparency = 0.15
        btn.BorderSizePixel = 0
        btn.TextStrokeTransparency = 0.6
        btn.TextStrokeColor3 = Color3.fromRGB(100, 150, 255)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.MouseButton1Click:Connect(function()
            local plr = game.Players.LocalPlayer
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character:MoveTo(pos)
            end
        end)
    end

    -- Tombol "Copy Position"
    local copyBtn = Instance.new("TextButton")
    copyBtn.Text = "📋 Salin Posisi Sekarang"
    copyBtn.Size = UDim2.new(0.9, 0, 0, 35)
    copyBtn.BackgroundColor3 = Color3.fromRGB(70, 110, 160)
    copyBtn.TextColor3 = Color3.fromRGB(220, 250, 255)
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 14
    copyBtn.AutoButtonColor = true
    copyBtn.Parent = Scroll
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
    copyBtn.MouseButton1Click:Connect(function()
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and setclipboard then
            setclipboard(string.format("Vector3.new(%.2f, %.2f, %.2f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
        end
    end)

    -- Add preset locations from TELEPORT_PRESETS
    for name, cf in pairs(TELEPORT_PRESETS) do
        addTeleportButton(name, cf.Position)
    end
    
    -- Contoh preset tambahan
    addTeleportButton("Spawn", Vector3.new(0, 10, 0))
    addTeleportButton("Fishing Spot", Vector3.new(120, 12, -80))
    addTeleportButton("Shop", Vector3.new(-50, 10, 30))
    addTeleportButton("Mountain Top", Vector3.new(250, 200, 150))
    addTeleportButton("Hidden Cave", Vector3.new(-200, -20, 75))
    addTeleportButton("Secret Room", Vector3.new(300, 40, 120))
    addTeleportButton("Harbor", Vector3.new(75, 9, -220))
    addTeleportButton("Boss Area", Vector3.new(-100, 50, 300))
    addTeleportButton("Treasure", Vector3.new(150, -5, -400))
end

-- Settings (anti-lag)
local AntiLagState = { enabled = false, modified = {}, terrainOld = nil }
local descendantConnection = nil
local function applyAntiLagToDescendant(v)
    if not v then return end
    if v:IsA("Texture") or v:IsA("Decal") then
        if v.Transparency ~= 1 then table.insert(AntiLagState.modified, {inst=v, prop="Transparency", old=v.Transparency}); pcall(function() v.Transparency = 1 end) end
    elseif v:IsA("SurfaceAppearance") then pcall(function() if v.Enabled ~= nil then table.insert(AntiLagState.modified, {inst=v, prop="Enabled", old=v.Enabled}); v.Enabled = false end end) end
end
local function enableAntiLag()
    if AntiLagState.enabled then return end
    AntiLagState.enabled = true; AntiLagState.modified = {}
    for _,v in ipairs(Workspace:GetDescendants()) do applyAntiLagToDescendant(v) end
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then AntiLagState.terrainOld = {WaterReflectance=terrain.WaterReflectance, WaterTransparency=terrain.WaterTransparency, WaterWaveSize=terrain.WaterWaveSize, WaterWaveSpeed=terrain.WaterWaveSpeed}; pcall(function() terrain.WaterReflectance=0; terrain.WaterTransparency=1; terrain.WaterWaveSize=0; terrain.WaterWaveSpeed=0 end) end
    descendantConnection = Workspace.DescendantAdded:Connect(function(v) if AntiLagState.enabled then applyAntiLagToDescendant(v) end end)
end
local function disableAntiLag()
    if not AntiLagState.enabled then return end
    AntiLagState.enabled = false
    for _,rec in ipairs(AntiLagState.modified) do pcall(function() if rec.inst and rec.inst.Parent then if rec.prop=="Transparency" then rec.inst.Transparency=rec.old elseif rec.prop=="Enabled" then rec.inst.Enabled=rec.old end end end) end
    AntiLagState.modified = {}
    if AntiLagState.terrainOld then local terrain = Workspace:FindFirstChildOfClass("Terrain"); if terrain then pcall(function() terrain.WaterReflectance=AntiLagState.terrainOld.WaterReflectance; terrain.WaterTransparency=AntiLagState.terrainOld.WaterTransparency; terrain.WaterWaveSize=AntiLagState.terrainOld.WaterWaveSize; terrain.WaterWaveSpeed=AntiLagState.terrainOld.WaterWaveSpeed end) end; AntiLagState.terrainOld = nil end
    if descendantConnection then descendantConnection:Disconnect(); descendantConnection = nil end
end

local function buildSettings()
    clearContent()
    local title = Instance.new("TextLabel", Content); title.Size = UDim2.new(1,0,0,26); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.Text = "Settings"; title.TextColor3 = ACCENT; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left
    local cont = Instance.new("Frame", Content); cont.Size = UDim2.new(1,0,0,220); cont.Position = UDim2.new(0,0,0,36); cont.BackgroundTransparency = 1

    local antiToggle = Instance.new("TextButton", cont); antiToggle.Size = UDim2.new(0,200,0,36); antiToggle.Position = UDim2.new(0,0,0,8); antiToggle.Text = "Anti-Lag: OFF"; antiToggle.Font = Enum.Font.GothamBold; antiToggle.TextColor3 = TEXT_COLOR; Instance.new("UICorner", antiToggle).CornerRadius = UDim.new(0,8)
    antiToggle.MouseButton1Click:Connect(function()
        if not AntiLagState.enabled then antiToggle.Text = "Anti-Lag: ON"; spawn(enableAntiLag) else antiToggle.Text = "Anti-Lag: OFF"; spawn(disableAntiLag) end
    end)

    local forceBtn = Instance.new("TextButton", cont); forceBtn.Size = UDim2.new(0,200,0,36); forceBtn.Position = UDim2.new(0,0,0,56); forceBtn.Text = "Force Stop AutoFishing"; forceBtn.Font = Enum.Font.GothamBold; forceBtn.TextColor3 = TEXT_COLOR; Instance.new("UICorner", forceBtn).CornerRadius = UDim.new(0,8)
    forceBtn.MouseButton1Click:Connect(function()
        -- hard-stop: set flags + invoke cancel
        pcall(function() getgenv().AutoFishingStopRequested = true; getgenv().AutoFishingRunning = false end)
        if CancelFishingRemote then pcall(function() CancelFishingRemote:InvokeServer() end) end
    end)
end

-- Info
local function buildInfo()
    clearContent()
    local title = Instance.new("TextLabel", Content); title.Size = UDim2.new(1,0,0,26); title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBold; title.Text = "Info"; title.TextColor3 = ACCENT; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left
    local cont = Instance.new("Frame", Content); cont.Size = UDim2.new(1,0,0,220); cont.Position = UDim2.new(0,0,0,36); cont.BackgroundTransparency = 1
    local credit = Instance.new("TextLabel", cont); credit.Size = UDim2.new(1,0,0,220); credit.Position = UDim2.new(0,0,0,6); credit.BackgroundTransparency = 1
    credit.Text = "Auto Fishing (Rimuru UI)\n\nScript by bubub 😎\n\nFeatures: Rimuru UI, AutoFishing, Anti-Lag, Player controls, Teleport presets, persistent delay+gui pos in yanz-script.json"
    credit.Font = Enum.Font.Gotham; credit.TextColor3 = TEXT_COLOR; credit.TextSize = 14; credit.TextWrapped = true; credit.TextXAlignment = Enum.TextXAlignment.Left
end

-- Tab handlers
local function setActiveTab(name)
    for tname, btn in pairs(tabs) do
        if tname == name then tweenObject(btn, {BackgroundColor3 = Color3.fromRGB(12,20,28)}, 0.18); btn.TextColor3 = ACCENT
        else tweenObject(btn, {BackgroundColor3 = Color3.fromRGB(18,26,35)}, 0.18); btn.TextColor3 = TEXT_COLOR end
    end
    if name == "Main" then buildMain()
    elseif name == "Player" then buildPlayer()
    elseif name == "Teleport" then buildTeleport()
    elseif name == "Settings" then buildSettings()
    elseif name == "Info" then buildInfo() end
end
for name, btn in pairs(tabs) do btn.MouseButton1Click:Connect(function() setActiveTab(name) end) end

-- initial
setActiveTab("Main")

-- Close / Minimize
local minimized = false
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false; minimized = true
    if not ScreenGui:FindFirstChild("RimuruMiniBtn") then
        local mini = Instance.new("ImageButton"); mini.Name = "RimuruMiniBtn"; mini.Size = UDim2.new(0,56,0,56); mini.Position = UDim2.new(1,-86,1,-120); mini.BackgroundColor3 = Color3.fromRGB(10,18,26); mini.Parent = ScreenGui
        Instance.new("UICorner", mini).CornerRadius = UDim.new(0,12)
        local t = Instance.new("TextLabel", mini); t.Size = UDim2.new(1,1,1,1); t.BackgroundTransparency = 1; t.Text = "YH"; t.Font = Enum.Font.GothamBold; t.TextColor3 = ACCENT
        mini.MouseButton1Click:Connect(function() MainFrame.Visible = true; mini:Destroy(); minimized = false end)
        mini.Active = true; mini.Draggable = true
    end
end)
MiniBtn.MouseButton1Click:Connect(function()
    if minimized then return end
    MainFrame.Visible = false
    if not ScreenGui:FindFirstChild("RimuruMiniBtn") then
        local mini = Instance.new("ImageButton"); mini.Name = "RimuruMiniBtn"; mini.Size = UDim2.new(0,56,0,56); mini.Position = UDim2.new(1,-86,1,-120); mini.BackgroundColor3 = Color3.fromRGB(10,18,26); mini.Parent = ScreenGui
        Instance.new("UICorner", mini).CornerRadius = UDim.new(0,12)
        local t = Instance.new("TextLabel", mini); t.Size = UDim2.new(1,1,1,1); t.BackgroundTransparency = 1; t.Text = "YH"; t.Font = Enum.Font.GothamBold; t.TextColor3 = ACCENT
        mini.MouseButton1Click:Connect(function() MainFrame.Visible = true; mini:Destroy() end)
        mini.Active = true; mini.Draggable = true
    end
end)

-- RightShift toggle (simple)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- entrance animate
MainFrame.Position = UDim2.new(0.5,0,0.5,-20)
MainFrame.BackgroundTransparency = 1
tweenObject(MainFrame, {BackgroundTransparency = 0.15, Position = UDim2.new(0.5,0,0.5,0)}, 0.45, Enum.EasingStyle.Cubic)

-- Save & load GUI position (to same yanz-script.json)
local function saveGuiPos()
    if not MainFrame then return end
    local pos = MainFrame.Position
    persisted.pos = {X = pos.X.Scale, Xo = pos.X.Offset, Y = pos.Y.Scale, Yo = pos.Y.Offset}
    savePersist()
end
local function loadGuiPos()
    if persisted and persisted.pos and MainFrame then
        local p = persisted.pos
        local ok, pos = pcall(function() return UDim2.new(p.X or 0.5, p.Xo or 0, p.Y or 0.5, p.Yo or 0) end)
        if ok and pos then MainFrame.Position = pos end
    end
end
-- apply load
pcall(loadGuiPos)
MainFrame:GetPropertyChangedSignal("Position"):Connect(saveGuiPos)

-- adjust for screen sizes (mobile friendly)
local function adjustForScreen()
    local sg = camera.ViewportSize
    if sg.X < 900 then
        MainFrame.Size = UDim2.new(0,420,0,340)
    else
        MainFrame.Size = UDim2.new(0,500,0,360)
    end
end
adjustForScreen()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustForScreen)

-- cleanup on leave
player.AncestryChanged:Connect(function(_, parent) if not parent then pcall(function() if descendantConnection then descendantConnection:Disconnect() end end) end end)

print("Auto Fishing Rimuru UI — updated with new teleport tab ✅")
