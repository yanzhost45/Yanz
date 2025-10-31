local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- 👉 [MERGED] Persistence dari Script 1 (disesuaikan dengan WindUI)
-- WindUI sudah menangani persistensi secara otomatis, jadi kita tidak perlu `safeWrite`/`safeRead` manual.
-- State untuk Auto Fish akan disimpan oleh WindUI.

-- 🎃 Tema "Pumpkin Contrast"
WindUI:AddTheme({
    Name = "Pumpkin",
    Accent = Color3.fromHex("#FF8C32"),
    Dialog = Color3.fromHex("#000000"),
    Outline = Color3.fromHex("#FFB14E"),
    Text = Color3.fromHex("#FF7B00"),
    Placeholder = Color3.fromHex("#DDA86B"),
    Background = Color3.fromHex("#000000"),
    Button = Color3.fromHex("#FF9B26"),
    Icon = Color3.fromHex("#FF7B00")
})
WindUI:SetTheme("Pumpkin")

local Window = WindUI:CreateWindow({
    Icon = "rbxassetid://136343770817701",
    Title = "YanzHost",
    Folder = "YanzFishit", -- WindUI akan menyimpan pengaturan di folder ini
    Theme = "Pumpkin",
    SideBarWidth = 180, -- Diperlebar sedikit untuk tab baru
    Resizable = false,
    Transparent = true,
    Size = UDim2.fromOffset(500, 400), -- Diperbesar untuk konten baru
    KeySystem = false,
    OpenButton = {
        Icon = "rbxassetid://136343770817701",
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 0,
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true,
    }
})

Window:SetIconSize(45)

-- 👉 [MERGED] Backend net dari Script 1 (disesuaikan)
local net = nil
pcall(function()
    net = ReplicatedStorage:WaitForChild("Packages", 1) and ReplicatedStorage.Packages:WaitForChild("_Index", 1) and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0") and ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]:FindFirstChild("net")
end)
if not net then pcall(function() net = ReplicatedStorage:FindFirstChild("net") end) end

local REFishCaught = net and net["RE/FishCaught"] or nil
local CancelFishingRemote = net and net["RF/CancelFishingInputs"] or nil

--==================================================
-- 🎣 TAB MAIN (Diperbarui dengan logika dari Script 1)
--==================================================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "fish"
})

-- 👉 [MERGED] Variabel dan fungsi Auto Fish dari Script 1
local FuncAutoFish = {
    autofish = false,
    minigameDelay = 0.5 -- Delay default, akan disimpan oleh WindUI
}
local autoFishLoop
local fishCount = 0
local startTime = 0

-- Fungsi untuk memperbarui label statistik
local statsSection
local function updateStats()
    if statsSection then
        local elapsed = math.floor(tick() - startTime)
        local m = math.floor(elapsed / 60)
        local s = elapsed % 60
        statsSection:SetDesc(string.format("🐟 Total Ikan: %d\n🕒 Waktu: %dm %ds", fishCount, m, s))
    end
end

-- 👉 [MERGED] Loop Auto Fish dari Script 1
local function AutoFishLoop()
    if not net then
        WindUI:Notify({ Title = "Error", Content = "Net library not found!" })
        FuncAutoFish.autofish = false
        return
    end

    if getgenv().AutoFishingRunning then
        WindUI:Notify({ Title = "Info", Content = "Auto Fishing is already running." })
        return
    end

    -- Mulai
    getgenv().AutoFishingRunning = true
    getgenv().AutoFishingStopRequested = false
    fishCount = 0
    startTime = tick()

    while FuncAutoFish.autofish do
        if getgenv().AutoFishingStopRequested then
            FuncAutoFish.autofish = false
            break
        end

        pcall(function()
            if net["RF/ChargeFishingRod"] then net["RF/ChargeFishingRod"]:InvokeServer(workspace:GetServerTimeNow()) end
        end)
        if not FuncAutoFish.autofish or getgenv().AutoFishingStopRequested then break end

        pcall(function()
            if net["RF/RequestFishingMinigameStarted"] then net["RF/RequestFishingMinigameStarted"]:InvokeServer(-0.3, 0.2, workspace:GetServerTimeNow()) end
        end)
        if not FuncAutoFish.autofish or getgenv().AutoFishingStopRequested then break end

        -- Tunggu delay
        local sT = tick()
        while tick() - sT < FuncAutoFish.minigameDelay do
            if getgenv().AutoFishingStopRequested then FuncAutoFish.autofish = false; break end
            task.wait(0.05)
        end
        if not FuncAutoFish.autofish then break end

        pcall(function()
            if net["RE/FishingCompleted"] then net["RE/FishingCompleted"]:FireServer() end
        end)
        if getgenv().AutoFishingStopRequested then break end

        local mini = tick()
        while tick() - mini < 0.3 do
            if getgenv().AutoFishingStopRequested then FuncAutoFish.autofish = false; break end
            task.wait(0.05)
        end
        if not FuncAutoFish.autofish then break end

        pcall(function()
            if net["RF/CancelFishingInputs"] then net["RF/CancelFishingInputs"]:InvokeServer() end
        end)
    end

    -- Pastikan server cancel dipanggil saat berhenti
    pcall(function()
        if CancelFishingRemote then
            CancelFishingRemote:InvokeServer()
        end
    end)

    -- Bersihkan
    getgenv().AutoFishingRunning = false
    getgenv().AutoFishingStopRequested = false
end

local function startAutoFish()
    FuncAutoFish.autofish = true
    spawn(AutoFishLoop)
end

local function stopAutoFish()
    FuncAutoFish.autofish = false
    getgenv().AutoFishingStopRequested = true
end

-- UI Elements di Main Tab
MainTab:Button({
    Title = "Equip Rod",
    Icon = "pointer",
    Callback = function()
        local r = net and net:FindFirstChild("RE/EquipToolFromHotbar")
        if r then
            r:FireServer(1)
        end
    end
})

MainTab:Toggle({
    Title = "Auto Fish",
    Callback = function(value)
        if value then
            startAutoFish()
        else
            stopAutoFish()
        end
    end
})

-- 👉 [MERGED] Slider delay dari Script 1 (menggunakan WindUI)
MainTab:Slider({
    Title = "Minigame Delay",
    Desc = "Jeda untuk minigame memancing (detik)",
    Step = 0.1,
    Value = { Min = 0.1, Max = 3.0, Default = 0.5 },
    Callback = function(v)
        FuncAutoFish.minigameDelay = v
    end,
    -- WindUI akan otomatis menyimpan nilai ini
})

-- 👉 [MERGED] Label statistik dari Script 1 (menggunakan Section WindUI)
statsSection = MainTab:Section({
    Title = "Statistics",
    Desc = "🐟 Total Ikan: 0\n🕒 Waktu: 0m 0s"
})

-- Loop untuk update timer
spawn(function()
    while true do
        task.wait(1)
        if FuncAutoFish.autofish then
            updateStats()
        end
    end
end)

-- Event untuk menghitung ikan
if REFishCaught then
    REFishCaught.OnClientEvent:Connect(function()
        fishCount = fishCount + 1
        updateStats()
    end)
end

-- Fitur lama dari Script 2
local autoSellState = false
local lastSell = 0
local AUTO_SELL_DELAY = 30

MainTab:Toggle({
    Title = "Auto Sell",
    Icon = "coins",
    Callback = function(value)
        autoSellState = value
        if value then
            WindUI:Notify({ Title = "Auto Sell", Content = "Started Auto Selling" })
            task.spawn(function()
                while autoSellState do
                    pcall(function()
                        local sellFunc = net and net:FindFirstChild("RF/SellAllItems")
                        if sellFunc and os.time() - lastSell >= AUTO_SELL_DELAY then
                            sellFunc:InvokeServer()
                            lastSell = os.time()
                        end
                    end)
                    task.wait(10)
                end
            end)
        else
            WindUI:Notify({ Title = "Auto Sell", Content = "Stopped Auto Selling" })
        end
    end
})

MainTab:Toggle({
    Title = "Anti AFK",
    Icon = "moon",
    Callback = function(value)
        if value then
            WindUI:Notify({ Title = "Anti AFK", Content = "AFK protection enabled." })
            local VirtualUser = game:GetService("VirtualUser")
            player.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            WindUI:Notify({ Title = "Anti AFK", Content = "Disabled." })
        end
    end
})

local AnimFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations")
local noAnimEnabled = false
local animConnections = {}

MainTab:Toggle({
    Title = "No Animation",
    Icon = "user-x",
    Callback = function(value)
        noAnimEnabled = value
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        if value then
            WindUI:Notify({ Title = "No Animation", Content = "Semua animasi dimatikan." })
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                pcall(function() track:Stop() end)
            end
            local connection = animator.AnimationPlayed:Connect(function(track)
                if noAnimEnabled then
                    local anim = track.Animation
                    if anim and anim:IsDescendantOf(AnimFolder) then
                        pcall(function() track:Stop() end)
                    end
                end
            end)
            table.insert(animConnections, connection)
        else
            WindUI:Notify({ Title = "No Animation", Content = "Animasi diaktifkan kembali." })
            for _, c in ipairs(animConnections) do
                if typeof(c) == "RBXScriptConnection" then
                    c:Disconnect()
                end
            end
            animConnections = {}
        end
    end
})


--==================================================
-- 👉 [MERGED] TAB PLAYER (Baru dari Script 1)
--==================================================
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user"
})

PlayerTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(v)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = v
        end
    end
})

PlayerTab:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(v)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = v
        end
    end
})

local noclipConn = nil
PlayerTab:Toggle({
    Title = "Noclip",
    Callback = function(value)
        if value then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(function()
                    local char = player.Character
                    if char then
                        for _, p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.CanCollide = false
                            end
                        end
                    end
                end)
            end
        else
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
                local char = player.Character
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.CanCollide = true
                        end
                    end
                end
            end
        end
    end
})


--==================================================
-- 🌍 TAB TELEPORT (Diperbarui dengan lokasi dari Script 1)
--==================================================
local TabTeleport = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin"
})

-- 👉 [MERGED] Daftar lokasi teleport dari Script 1
local teleportLocations = {
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
    ["Sacred Temple"] = CFrame.new(1468.44946, -22.1250019, -651.350342, -0.114698552, -1.09982246e-07, 0.993400335, -1.87054479e-08, 1, 1.085531e-07, -0.993400335, -6.13110718e-09, -0.114698552),
}

local selectedLocation = nil

-- Fungsi teleport (dari Script 2, sudah bagus)
local function teleportTo(cf)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if not hum or not hrp then return end

    hum:MoveTo(cf.Position)
    task.wait(0.15)
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- Dropdown pilih lokasi
TabTeleport:Dropdown({
    Title = "Select Teleport Location",
    Desc = "Pilih lokasi tujuan",
    Values = (function()
        local keys = {}
        for name in pairs(teleportLocations) do
            table.insert(keys, name)
        end
        return keys
    end)(),
    Multi = false,
    AllowNone = false,
    Callback = function(selected)
        selectedLocation = selected
    end
})

-- Tombol teleport
TabTeleport:Button({
    Title = "Teleport Now",
    Desc = "Teleport ke lokasi yang dipilih",
    Callback = function()
        if selectedLocation and teleportLocations[selectedLocation] then
            teleportTo(teleportLocations[selectedLocation])
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedLocation })
        else
            WindUI:Notify({ Title = "Error", Content = "Please select a location first." })
        end
    end
})

-- 👉 [MERGED] Tombol Salin Posisi dari Script 1
TabTeleport:Button({
    Title = "Copy Position",
    Desc = "Salin posisi karakter saat ini ke clipboard",
    Callback = function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and setclipboard then
            local posStr = string.format("Vector3.new(%.2f, %.2f, %.2f)", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
            setclipboard(posStr)
            WindUI:Notify({ Title = "Position Copied", Content = posStr })
        else
            WindUI:Notify({ Title = "Error", Content = "Could not copy position." })
        end
    end
})


--==================================================
-- 👉 [MERGED] TAB SETTINGS (Baru dari Script 1)
--==================================================
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

-- 👉 [MERGED] Logika Anti-Lag dari Script 1
local AntiLagState = { enabled = false, modified = {}, terrainOld = nil }
local descendantConnection = nil
local function applyAntiLagToDescendant(v)
    if not v then return end
    if v:IsA("Texture") or v:IsA("Decal") then
        if v.Transparency ~= 1 then table.insert(AntiLagState.modified, { inst = v, prop = "Transparency", old = v.Transparency }); pcall(function() v.Transparency = 1 end) end
    elseif v:IsA("SurfaceAppearance") then pcall(function() if v.Enabled ~= nil then table.insert(AntiLagState.modified, { inst = v, prop = "Enabled", old = v.Enabled }); v.Enabled = false end end) end
end
local function enableAntiLag()
    if AntiLagState.enabled then return end
    AntiLagState.enabled = true; AntiLagState.modified = {}
    for _, v in ipairs(Workspace:GetDescendants()) do applyAntiLagToDescendant(v) end
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then AntiLagState.terrainOld = { WaterReflectance = terrain.WaterReflectance, WaterTransparency = terrain.WaterTransparency, WaterWaveSize = terrain.WaterWaveSize, WaterWaveSpeed = terrain.WaterWaveSpeed }; pcall(function() terrain.WaterReflectance = 0; terrain.WaterTransparency = 1; terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0 end) end
    descendantConnection = Workspace.DescendantAdded:Connect(function(v) if AntiLagState.enabled then applyAntiLagToDescendant(v) end end)
    WindUI:Notify({ Title = "Anti-Lag", Content = "Enabled." })
end
local function disableAntiLag()
    if not AntiLagState.enabled then return end
    AntiLagState.enabled = false
    for _, rec in ipairs(AntiLagState.modified) do pcall(function() if rec.inst and rec.inst.Parent then if rec.prop == "Transparency" then rec.inst.Transparency = rec.old elseif rec.prop == "Enabled" then rec.inst.Enabled = rec.old end end end) end
    AntiLagState.modified = {}
    if AntiLagState.terrainOld then local terrain = Workspace:FindFirstChildOfClass("Terrain"); if terrain then pcall(function() terrain.WaterReflectance = AntiLagState.terrainOld.WaterReflectance; terrain.WaterTransparency = AntiLagState.terrainOld.WaterTransparency; terrain.WaterWaveSize = AntiLagState.terrainOld.WaterWaveSize; terrain.WaterWaveSpeed = AntiLagState.terrainOld.WaterWaveSpeed end) end; AntiLagState.terrainOld = nil end
    if descendantConnection then descendantConnection:Disconnect(); descendantConnection = nil end
    WindUI:Notify({ Title = "Anti-Lag", Content = "Disabled." })
end

SettingsTab:Toggle({
    Title = "Anti-Lag",
    Desc = "Mengurangi lag dengan menonaktifkan tekstur dan efek air",
    Callback = function(value)
        if value then
            spawn(enableAntiLag)
        else
            spawn(disableAntiLag)
        end
    end
})

-- 👉 [MERGED] Tombol Force Stop dari Script 1
SettingsTab:Button({
    Title = "Force Stop AutoFishing",
    Desc = "Hentikan paksa loop Auto Fish jika macet",
    Callback = function()
        pcall(function() getgenv().AutoFishingStopRequested = true; getgenv().AutoFishingRunning = false end)
        if CancelFishingRemote then pcall(function() CancelFishingRemote:InvokeServer() end) end
        WindUI:Notify({ Title = "Force Stop", Content = "AutoFishing has been force stopped." })
    end
})