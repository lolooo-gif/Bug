local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local OrbsFolder = Workspace:WaitForChild("Orbs", 5)
local BugsFolder = Workspace:WaitForChild("Bugs", 5)
local BreakablesFolder = Workspace:WaitForChild("Breakables", 5)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackRemote = Remotes:WaitForChild("Attack")
-- Chargement de NextUI
local NextUI = loadstring(game:HttpGet("https://diser.me/nextui/source.lua"))()
-- Création de la fenêtre
local Window = NextUI:CreateWindow({
    Title = "Bug Evolution",
    SubTitle = "v2.1 [Anti-Void]",
    Theme = "Amethyst",
    Size = Vector2.new(820, 520),
    Resizable = true,
    Search = true,
    ToggleKey = { Enum.KeyCode.Insert, Enum.KeyCode.RightShift, Enum.KeyCode.LeftControl },
    MobileButton = true,
})
-- Variables d'état
local isMagnetRunning = false
local isAutoAttackRunning = false
local isBreakablesRunning = false
local isPlayerAttackRunning = false
local isSpeedRunning = false
local isAutoEvolveRunning = true
local isAutoTraitsRunning = true
local isAutoRewardsRunning = true
local isSafeModeRunning = true
local isAntiVoidRunning = true
local customSpeed = 70
local SafeZonePos = Vector3.new(0, 16, 180) -- Meadow Nest Safe Zone
local MinSafeY = 2.0 -- Anything below Y=2 is danger/water/void
local officialBugList = {"All", "Ant", "Cricket", "Caterpillar", "Beetle", "StagBeetle", "Centipede", "PillBug", "Scorpion", "Boss"}
local selectedBugTargets = {["All"] = true}
local officialBreakableList = {"All", "Cocoon", "Stash", "SugarCube", "EggCluster"}
local selectedBreakables = {["All"] = true}
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
    {Name = "Web caves (Lvl 40+)", Pos = Vector3.new(419.1, 19.0, -388.2)},
    {Name = "Meadow Nest (Safe Zone)", Pos = Vector3.new(0, 16, 180)}
}
-- Anti-Stuck & Floor Detection helper
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.IgnoreWater = true
local function getSafeStandCFrame(targetPos, lookAtPos, hoverOffset)
    local hover = hoverOffset or 3.2
    if not raycastParams.FilterDescendantsInstances[1] then
        local map = Workspace:FindFirstChild("Map")
        raycastParams.FilterDescendantsInstances = map and {Workspace.Terrain, map} or {Workspace.Terrain}
    end
    -- Cast downward from 10 studs above target to check exact ground
    local rayOrigin = targetPos + Vector3.new(0, 10, 0)
    local rayHit = Workspace:Raycast(rayOrigin, Vector3.new(0, -25, 0), raycastParams)
    local groundY = rayHit and rayHit.Position.Y or targetPos.Y
    local finalY = math.max(groundY + hover, targetPos.Y + hover, MinSafeY + 3)
    local standPos = Vector3.new(targetPos.X, finalY, targetPos.Z + 2.0)
    return CFrame.lookAt(standPos, Vector3.new(lookAtPos.X, finalY - 1.5, lookAtPos.Z))
end
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
local function matchesBug(bug)
    if selectedBugTargets["All"] then return true end
    local bugId = bug:GetAttribute("BugId") or ""
    local name = bug.Name or ""
    for targetName in pairs(selectedBugTargets) do
        if targetName == "All" then return true end
        if string.find(string.lower(name), string.lower(targetName)) or string.find(string.lower(bugId), string.lower(targetName)) then
            return true
        end
    end
    return false
end
local function matchesBreakable(b)
    if selectedBreakables["All"] then return true end
    local breakId = b:GetAttribute("BreakId") or ""
    local name = b.Name or ""
    for target in pairs(selectedBreakables) do
        if target == "All" then return true end
        if string.find(string.lower(name), string.lower(target)) or string.find(string.lower(breakId), string.lower(target)) then
            return true
        end
    end
    return false
end
-- ==================== CATÉGORIE & ONGLETS ====================
Window:AddCategory("Main Features")
local HunterTab = Window:AddTab("Hunter", "crosshair")
local AutoTab = Window:AddTab("Evolution & Auto", "zap")
local TeleportTab = Window:AddTab("Teleportation", "map")
local SettingsTab = Window:AddTab("Settings", "settings")
-- ==================== ONGLET : HUNTER ====================
local FarmSection = HunterTab:AddSection({ Title = "Auto Farm & Combat", Icon = "crosshair" })
FarmSection:AddToggle({
    Title = "Teleport Orbs",
    Description = "Automatically vacuums nearest XP orbs across the map",
    Default = false,
    Flag = "orbs_magnet",
    Callback = function(state)
        isMagnetRunning = state
    end,
})
FarmSection:AddToggle({
    Title = "Auto-Farm Breakables",
    Description = "Destroys Cocoons, Silk Stashes, Sugar Cubes, Egg Clusters",
    Default = false,
    Flag = "auto_breakables",
    Callback = function(state)
        isBreakablesRunning = state
    end,
})
FarmSection:AddDropdown({
    Title = "Target Breakables",
    Values = officialBreakableList,
    Multi = true,
    Default = {"All"},
    Flag = "target_breakables",
    Callback = function(options)
        selectedBreakables = {}
        if type(options) == "table" then
            for _, item in ipairs(options) do
                selectedBreakables[item] = true
            end
        else
            selectedBreakables[options] = true
        end
    end,
})
FarmSection:AddToggle({
    Title = "Auto-Attack Bugs",
    Description = "Automatically attacks selected bug species with Anti-Clip protection",
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
-- ==================== ONGLET : EVOLUTION & AUTO ====================
local AutoSection = AutoTab:AddSection({ Title = "Progression & Automation", Icon = "zap" })
AutoSection:AddToggle({
    Title = "Auto Evolve",
    Description = "Automatically evolves to next stage when level/XP cap is met",
    Default = true,
    Flag = "auto_evolve",
    Callback = function(state)
        isAutoEvolveRunning = state
    end,
})
AutoSection:AddToggle({
    Title = "Auto Pick Traits",
    Description = "Automatically selects trait offers upon leveling up",
    Default = true,
    Flag = "auto_traits",
    Callback = function(state)
        isAutoTraitsRunning = state
    end,
})
AutoSection:AddToggle({
    Title = "Auto Claim Rewards",
    Description = "Automatically claims free playtime rewards and gifts",
    Default = true,
    Flag = "auto_rewards",
    Callback = function(state)
        isAutoRewardsRunning = state
    end,
})
AutoSection:AddToggle({
    Title = "Safe Mode (Auto-Heal)",
    Description = "Retreats to Meadow Nest Safe Zone when HP drops below 35%",
    Default = true,
    Flag = "safe_mode",
    Callback = function(state)
        isSafeModeRunning = state
    end,
})
AutoSection:AddToggle({
    Title = "Anti-Void & Anti-Fall",
    Description = "Instantly rescues you if you clip underground or fall off the map",
    Default = true,
    Flag = "anti_void",
    Callback = function(state)
        isAntiVoidRunning = state
    end,
})
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
                hrp.AssemblyLinearVelocity = Vector3.zero
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
-- 1. Anti-Void & Anti-Fall Guardian (Runs every physics step)
RunService.Heartbeat:Connect(function()
    if isAntiVoidRunning then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Check if fallen below ground or falling at extreme speed
            if hrp.Position.Y < MinSafeY or hrp.AssemblyLinearVelocity.Y < -75 then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(SafeZonePos)
            end
        end
    end
end)
-- 2. Movement & Speed
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
-- 3. Auto Evolve & Traits Worker
task.spawn(function()
    while true do
        task.wait(2)
        if isAutoTraitsRunning then
            pcall(function() Remotes.PickTrait:FireServer(1) end)
        end
        if isAutoEvolveRunning then
            pcall(function() Remotes.Evolve:InvokeServer() end)
        end
    end
end)
-- 4. Auto Playtime Rewards Worker
task.spawn(function()
    while true do
        task.wait(20)
        if isAutoRewardsRunning then
            pcall(function() Remotes.Rewards:InvokeServer("ClaimPlaytime") end)
        end
    end
end)
-- Safe Mode Check helper
local function checkSafeMode()
    if not isSafeModeRunning then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hum and hrp and (hum.Health / math.max(1, hum.MaxHealth)) < 0.35 then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(SafeZonePos)
        while isSafeModeRunning and hum.Health < hum.MaxHealth * 0.9 do
            task.wait(1)
        end
        return true
    end
    return false
end
-- 5. Teleport Orbs (Safe height sweep)
local visitedOrbs = {}
task.spawn(function()
    while true do
        task.wait(0.08)
        if isMagnetRunning and OrbsFolder then
            if not checkSafeMode() then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bestOrb = nil
                    local shortestDist = math.huge
                    local myPos = hrp.Position
                    for _, orb in ipairs(OrbsFolder:GetChildren()) do
                        if orb:IsA("BasePart") and not visitedOrbs[orb] then
                            local d = (myPos - orb.Position).Magnitude
                            if d < shortestDist then
                                shortestDist = d
                                bestOrb = orb
                            end
                        end
                    end
                    if bestOrb and bestOrb:IsDescendantOf(workspace) then
                        visitedOrbs[bestOrb] = true
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        local orbY = math.max(bestOrb.Position.Y + 1.2, MinSafeY + 3)
                        hrp.CFrame = CFrame.new(bestOrb.Position.X, orbY, bestOrb.Position.Z)
                    else
                        table.clear(visitedOrbs)
                    end
                end
            end
        end
    end
end)
-- 6. Auto-Farm Breakables (Safe Hover)
task.spawn(function()
    while true do
        task.wait(0.15)
        if isBreakablesRunning and BreakablesFolder then
            if not checkSafeMode() then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bestB = nil
                    local shortestDist = math.huge
                    local myPos = hrp.Position
                    for _, b in ipairs(BreakablesFolder:GetChildren()) do
                        if b:IsA("Model") and b.PrimaryPart and (b:GetAttribute("HP") or 0) > 0 and matchesBreakable(b) then
                            local d = (myPos - b.PrimaryPart.Position).Magnitude
                            if d < shortestDist then
                                shortestDist = d
                                bestB = b
                            end
                        end
                    end
                    if bestB and bestB.PrimaryPart then
                        local targetPos = bestB.PrimaryPart.Position
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.CFrame = getSafeStandCFrame(targetPos, targetPos, 3.2)
                        local attacks = 0
                        while isBreakablesRunning and bestB:IsDescendantOf(workspace) and (bestB:GetAttribute("HP") or 0) > 0 and attacks < 15 do
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            AttackRemote:FireServer(bestB)
                            attacks = attacks + 1
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end
end)
-- 7. Auto-Attack Bugs (Safe Hover & Raycast Ground Check)
task.spawn(function()
    while true do
        task.wait(0.15)
        if isAutoAttackRunning then
            if not checkSafeMode() then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local bestBug = nil
                    local shortestDist = math.huge
                    local myPos = hrp.Position
                    for _, bug in ipairs(getAllBugs()) do
                        if bug and bug.Parent and (bug:IsA("Model") or bug:IsA("BasePart")) and matchesBug(bug) then
                            local mHum = bug:FindFirstChildOfClass("Humanoid")
                            local mHrp = bug:FindFirstChild("HumanoidRootPart") or (bug:IsA("BasePart") and bug) or bug.PrimaryPart
                            if mHrp and (not mHum or mHum.Health > 0) then
                                local d = (myPos - mHrp.Position).Magnitude
                                if d < shortestDist then
                                    shortestDist = d
                                    bestBug = bug
                                end
                            end
                        end
                    end
                    if bestBug then
                        local bugPart = bestBug:FindFirstChild("HumanoidRootPart") or (bestBug:IsA("Model") and bestBug.PrimaryPart) or bestBug
                        local mHum = bestBug:FindFirstChildOfClass("Humanoid")
                        if bugPart then
                            local targetPos = bugPart.Position
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.CFrame = getSafeStandCFrame(targetPos, targetPos, 3.2)
                            local attacks = 0
                            while isAutoAttackRunning and bestBug:IsDescendantOf(workspace) and (not mHum or mHum.Health > 0) and attacks < 18 do
                                hrp.AssemblyLinearVelocity = Vector3.zero
                                AttackRemote:FireServer(bestBug)
                                pcall(function() Remotes.UseAbility:FireServer(1) end)
                                pcall(function() Remotes.UseAbility:FireServer(2) end)
                                attacks = attacks + 1
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
    end
end)
-- 8. Auto-Attack Players (Safe Height)
task.spawn(function()
    while true do
        task.wait(0.15)
        if isPlayerAttackRunning and not selectedPlayerTargets["None"] then
            if not checkSafeMode() then
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
                                    local tPos = targetHrp.Position
                                    hrp.AssemblyLinearVelocity = Vector3.zero
                                    hrp.CFrame = getSafeStandCFrame(tPos, tPos, 3.5)
                                    
                                    AttackRemote:FireServer(targetChar)
                                    pcall(function() Remotes.UseAbility:FireServer(1) end)
                                    task.wait(0.2)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
