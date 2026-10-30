
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local OrbsFolder = Workspace:WaitForChild("Orbs", 5)
local BugsFolder = Workspace:WaitForChild("Bugs", 5)
local AttackRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attack")

-- Chargement de NextUI
local NextUI = loadstring(game:HttpGet("https://diser.me/nextui/source.lua"))()

-- Création de la fenêtre
local Window = NextUI:CreateWindow({
    Title = "Bug Evolution",
    SubTitle = "v2.0",
    Theme = "Amethyst",
    Size = Vector2.new(820, 520),
    Resizable = true,
    Search = true,
    ToggleKey = { Enum.KeyCode.Insert, Enum.KeyCode.RightShift, Enum.KeyCode.LeftControl },
    MobileButton = true,
})


local isMagnetRunning = false
local isAutoAttackRunning = false
local isPlayerAttackRunning = false
local isSpeedRunning = false
local customSpeed = 70

local officialBugList = {"All", "Ant", "Cricket", "Caterpillar", "Beetle", "StagBeetle", "Centipede", "PillBug", "Scorpion", "Boss"}
local selectedBugTargets = {["All"] = true}

local selectedPlayerTargets = {["None"] = true}

local function updatePlayerList()
    local newList = {"None", "All Players"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(newList, p.Name)
        end
    end
    return newList
end

local biomes = {
    {Name = "Sunny meadow (Lvl 1+)", Pos = Vector3.new(-36.0, 12.6, 94.4)},
    {Name = "Muddy Lake (Lvl 8+)", Pos = Vector3.new(486.0, 14.7, -10.2)},
    {Name = "Mushroom Grove (Lvl 10+)", Pos = Vector3.new(-355.1, 29.7, 375.3)},
    {Name = "Whispering Woods (Lvl 15+)", Pos = Vector3.new(-366.8, 26.2, 11.0)},
    {Name = "Dusty Desert (Lvl 25+)", Pos = Vector3.new(291.7, 31.5, 467.6)},
    {Name = "Stony Ridge (Lvl 30+)", Pos = Vector3.new(-12.4, 12.1, -315.5)},
    {Name = "Web caves (Lvl 40+)", Pos = Vector3.new(419.1, 19.0, -388.2)}
}

local function getAllBugs()
    local bugs = {}
    if BugsFolder then
        for _, b in ipairs(BugsFolder:GetChildren()) do table.insert(bugs, b) end
    end
    if getnilinstances then
        for _, v in ipairs(getnilinstances()) do
            if v:IsA("Model") and v.Parent == nil then table.insert(bugs, v) end
        end
    end
    return bugs
end

-- ==================== CATÉGORIE & ONGLETS ====================
Window:AddCategory("Main Features")
local HunterTab = Window:AddTab("Hunter", "crosshair")
local TeleportTab = Window:AddTab("Teleportation", "map")
local SettingsTab = Window:AddTab("Settings", "settings")

-- ==================== ONGLET : HUNTER ====================
local FarmSection = HunterTab:AddSection({ Title = "Auto Farm & Combat", Icon = "crosshair" })

FarmSection:AddToggle({
    Title = "Teleport Orbs",
    Description = "Automatically teleports XP/Coins orbs to you",
    Default = false,
    Flag = "orbs_magnet",
    Callback = function(state)
        isMagnetRunning = state
    end,
})

FarmSection:AddToggle({
    Title = "Auto-Attack Bugs",
    Description = "Automatically attacks selected bug species",
    Default = false,
    Flag = "auto_attack",
    Callback = function(state)
        isAutoAttackRunning = state
    end,
})

FarmSection:AddDropdown({
    Title = "Target Bug Species",
    Values = officialBugList,
    Multi = true,
    Default = {"All"},
    Flag = "target_species",
    Callback = function(options)
        selectedBugTargets = {}
        if type(options) == "table" then
            for _, insect in ipairs(options) do
                selectedBugTargets[insect] = true
            end
        else
            selectedBugTargets[options] = true
        end
    end,
})

-- Section Joueurs
local PlayerSection = HunterTab:AddSection({ Title = "Player Target & Combat", Icon = "user" })

PlayerSection:AddToggle({
    Title = "Auto-Attack Players",
    Description = "Automatically targets and attacks selected players",
    Default = false,
    Flag = "auto_attack_players",
    Callback = function(state)
        isPlayerAttackRunning = state
    end,
})

local playerDropdownRef
playerDropdownRef = PlayerSection:AddDropdown({
    Title = "Target Players",
    Values = updatePlayerList(),
    Multi = true,
    Default = {"None"},
    Flag = "target_players",
    Callback = function(options)
        selectedPlayerTargets = {}
        if type(options) == "table" then
            for _, pName in ipairs(options) do
                selectedPlayerTargets[pName] = true
            end
        else
            selectedPlayerTargets[options] = true
        end
    end,
})

Players.PlayerAdded:Connect(function()
    if playerDropdownRef and playerDropdownRef.Refresh then
        playerDropdownRef:Refresh(updatePlayerList())
    end
end)
Players.PlayerRemoving:Connect(function()
    if playerDropdownRef and playerDropdownRef.Refresh then
        playerDropdownRef:Refresh(updatePlayerList())
    end
end)

-- ==================== ONGLET : TELEPORTATION ====================
local TpSection = TeleportTab:AddSection({ Title = "Biome Teleportation", Icon = "map", Collapsible = true })
TpSection:AddParagraph({ Title = "Info", Content = "Click any location button below to instantly teleport there." })

for _, biome in ipairs(biomes) do
    TpSection:AddButton({
        Title = biome.Name,
        Callback = function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(biome.Pos + Vector3.new(0, 5, 0))
            end
        end,
    })
end

-- ==================== ONGLET : SETTINGS ====================
local MovementSection = SettingsTab:AddSection({ Title = "Movement Options", Icon = "zap" })

MovementSection:AddToggle({
    Title = "Speed Hack",
    Description = "Enhances your flying/walking speed",
    Default = false,
    Flag = "speed_hack",
    Callback = function(state)
        isSpeedRunning = state
        if not isSpeedRunning then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

MovementSection:AddTextbox({
    Title = "Custom Speed Value",
    Default = "70",
    Numeric = true,
    Finished = true,
    Flag = "custom_speed_val",
    Callback = function(text)
        local val = tonumber(text)
        if val then
            customSpeed = val
        end
    end,
})

-- ==================== LOGIQUE EN ARRIÈRE-PLAN ====================

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if isSpeedRunning then
            if hum then hum.WalkSpeed = customSpeed end
            if hrp and hum and hum.MoveDirection.Magnitude > 0 then
                local moveDir = hum.MoveDirection
                hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * customSpeed, hrp.AssemblyLinearVelocity.Y, moveDir.Z * customSpeed)
            end
        end
    end
end)

-- TP Orbs (Magnet)
task.spawn(function()
    while true do
        task.wait(0.3)
        if isMagnetRunning and OrbsFolder then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, orb in ipairs(OrbsFolder:GetChildren()) do
                    if not isMagnetRunning then break end
                    local part = orb:IsA("BasePart") and orb or (orb:IsA("Model") and (orb.PrimaryPart or orb:FindFirstChildWhichIsA("BasePart")))
                    if part and part.Parent then
                        if (hrp.Position - part.Position).Magnitude < 300 then
                            hrp.CFrame = part.CFrame
                            task.wait(0.02)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto-Attack Bugs
task.spawn(function()
    while true do
        task.wait(0.15)
        if isAutoAttackRunning then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hrp then
                for _, bug in ipairs(getAllBugs()) do
                    if not isAutoAttackRunning then break end
                    if bug and bug.Parent and (bug:IsA("Model") or bug:IsA("BasePart")) then
                        if selectedBugTargets["All"] or selectedBugTargets[bug.Name] then
                            local bugPart = bug:IsA("Model") and (bug.PrimaryPart or bug:FindFirstChildWhichIsA("BasePart")) or bug
                            
                            if bugPart and bugPart.Parent then
                                pcall(function()
                                    hrp.CFrame = bugPart.CFrame * CFrame.new(0, 12, 0)
                                end)
                                pcall(function()
                                    AttackRemote:FireServer(bug)
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto-Attack Players
task.spawn(function()
    while true do
        task.wait(0.15)
        if isPlayerAttackRunning and not selectedPlayerTargets["None"] then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hrp then
                for _, player in ipairs(Players:GetPlayers()) do
                    if not isPlayerAttackRunning then break end
                    if player ~= LocalPlayer then
                        if selectedPlayerTargets["All Players"] or selectedPlayerTargets[player.Name] then
                            local targetChar = player.Character
                            local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                            local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

                            if targetHrp and targetHum and targetHum.Health > 0 then
                                pcall(function()
                                    hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 12, 0)
                                end)
                                pcall(function()
                                    AttackRemote:FireServer(player)
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)
