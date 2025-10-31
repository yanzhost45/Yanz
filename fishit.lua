local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

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

-- Membuat Window WindUI
local Window = WindUI:CreateWindow({
    Icon = "rbxassetid://136343770817701",
    Title = "YanzHost",
    Folder = "YanzFishit",
    Theme = "Pumpkin",
    SideBarWidth = 180,
    Resizable = false,
    Transparent = true,
    Size = UDim2.fromOffset(500, 400),
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

-- 👉 [MERGED] Backend net dari Script 1
local net = ReplicatedStorage:WaitForChild("Packages", 1):WaitForChild("_Index", 1):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local RFChargeFishingRod = net:WaitForChild("RF/ChargeFishingRod")
local RFRequestFishingMinigameStarted = net:WaitForChild("RF/RequestFishingMinigameStarted")
local REFishingCompleted = net:WaitForChild("RE/FishingCompleted")
local REFishCaught = net:WaitForChild("RE/FishCaught")
local RFCancelFishingInputs = net:WaitForChild("RF/CancelFishingInputs")

-- 👉 [MERGED] Teleport presets dari Script 1
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

--==================================================
-- 🎣 TAB MAIN (Logika Auto Fish Diperbaiki)
--==================================================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "fish"
})

-- State untuk Auto Fish
local isFishing = false
local fishCount = 0
local startTime = 0
local biteDelay = 1.5 -- Default delay, akan di-load oleh WindUI

-- UI untuk statistik
local statsSection = MainTab:Section({
    Title = "Statistics",
    Desc = "🐟 Total Ikan: 0\n🕒 Waktu: 0m 0s"
})

-- Fungsi untuk memperbarui statistik
local function updateStats()
    if isFishing then
        local elapsed = math.floor(tick() - startTime)
        local m = math.floor(elapsed / 60)
        local s = elapsed % 60
        statsSection:SetDesc(string.format("🐟 Total Ikan: %d\n🕒 Waktu: %dm %ds", fishCount, m, s))
    else
        statsSection:SetDesc(string.format("🐟 Total Ikan: %d\n🕒 Waktu: 0m 0s", fishCount))
    end
end

-- 👉 [REVISED] Loop Auto Fish yang benar (sesuai spy script)
local autoFishLoop
local function startAutoFish()
    if isFishing then return end
    isFishing = true
    fishCount = 0
    startTime = tick()
    
    autoFishLoop = task.spawn(function()
        while isFishing do
            -- 1. Charge Rod
            RFChargeFishingRod:InvokeServer(workspace:GetServerTimeNow())
            task.wait(0.01) -- Jeda singkat

            -- 2. Start Minigame
            RFRequestFishingMinigameStarted:InvokeServer(-0.3, 0.2, workspace:GetServerTimeNow())

            -- 3. Tunggu ikan memakan umpan (Bite Delay)
            task.wait(biteDelay)

            -- 4. Angkat kail / Complete
            REFishingCompleted:FireServer()

            -- Jeda kecil sebelum loop berikutnya untuk mencegah spam
            task.wait(0.2)
        end
    end)
end

local function stopAutoFish()
    if isFishing then
        isFishing = false
        if autoFishLoop then
            task.cancel(autoFishLoop)
        end
        -- Pastikan untuk membatalkan input saat berhenti
        pcall(RFCancelFishingInputs.InvokeServer, RFCancelFishingInputs)
        updateStats()
    end
end

-- UI Elements
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

MainTab:Slider({
    Title = "Bite Delay",
    Desc = "Jeda menunggu ikan (detik)",
    Step = 0.1,
    Value = { Min = 0.5, Max = 5.0, Default = 1.5 },
    Callback = function(v)
        biteDelay = v
    end,
})

-- Event untuk menghitung ikan
REFishCaught.OnClientEvent:Connect(function()
    fishCount = fishCount + 1
    updateStats()
end)

-- Loop untuk update timer
task.spawn(function()
    while true do
        task.wait(1)
        if isFishing then
            updateStats()
        end
    end
end)


--==================================================
-- 👤 TAB PLAYER
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
        if hum then hum.WalkSpeed = v end
    end
})

PlayerTab:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(v)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
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
                    if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
                end)
            end
        else
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
                local char = player.Character
                if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
            end
        end
    end
})


--==================================================
-- 🌍 TAB TELEPORT
--==================================================
local TabTeleport = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin"
})

local selectedLocation = nil

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

TabTeleport:Dropdown({
    Title = "Select Teleport Location",
    Values = (function()
        local keys = {}
        for name in pairs(TELEPORT_PRESETS) do table.insert(keys, name) end
        return keys
    end)(),
    Callback = function(selected) selectedLocation = selected end
})

TabTeleport:Button({
    Title = "Teleport Now",
    Callback = function()
        if selectedLocation and TELEPORT_PRESETS[selectedLocation] then
            teleportTo(TELEPORT_PRESETS[selectedLocation])
            WindUI:Notify({ Title = "Teleport", Content = "Teleported to " .. selectedLocation })
        else
            WindUI:Notify({ Title = "Error", Content = "Please select a location first." })
        end
    end
})

TabTeleport:Button({
    Title = "Copy Position",
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
-- ⚙️ TAB SETTINGS
--==================================================
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

SettingsTab:Button({
    Title = "Force Stop AutoFishing",
    Callback = function()
        stopAutoFish()
        WindUI:Notify({ Title = "Force Stop", Content = "AutoFishing has been force stopped." })
    end
})