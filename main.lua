-- =====================================================
-- ★★★ synapse.lol (グラブタブ + ドリフト統合 + サーバータブ完全版) ★★★
-- =====================================================

-- 1. ライブラリ読み込み
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- 2. サービス
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera

-- 3. 既存変数
nageru = 400
_G.MLSense = 200
_G.MassLessGrab = false
_G.MLConn = nil
spingrab = false
spinspeed = 50
cons = {}
strengthConnection = nil

GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
DestroyLine = GrabEvents and GrabEvents:FindFirstChild("DestroyGrabLine")
SetNetOwner = GrabEvents and GrabEvents:FindFirstChild("SetNetworkOwner")
CreateGrabLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")
DestroyToy = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")

-- 4. 既存関数
function stvel(part)
    if part and part:IsA("BasePart") then
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
        part.Velocity = Vector3.zero
        part.RotVelocity = Vector3.zero
    end
end

-- ============================================================
--  ★★★ プレイヤー機能 ★★★
-- ============================================================
local flyEnabled = false
local flyConnection = nil
local flySpeed = 50
local noclipEnabled = false
local noclipConnection = nil
local infinityJumpEnabled = false
local infinityJumpConnection = nil
local originalWalkSpeed = 16
local originalJumpPower = 50

local function toggleFly(enabled)
    flyEnabled = enabled
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if enabled then
        local char = LocalPlayer.Character
        if not char then Library:Notify("キャラクターが見つかりません", 2); return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then Library:Notify("Humanoidが見つかりません", 2); return end
        hum.PlatformStand = true
        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled or not LocalPlayer.Character then return end
            local char = LocalPlayer.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not hrp or not hum then return end
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * flySpeed end
            hrp.CFrame = hrp.CFrame + moveDir * (1 / 60)
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end)
        Library:Notify("FLY: ON", 2)
    else
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end
        end
        Library:Notify("FLY: OFF", 2)
    end
end

local function toggleNoclip(enabled)
    noclipEnabled = enabled
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    if enabled then
        local char = LocalPlayer.Character
        if not char then Library:Notify("キャラクターが見つかりません", 2); return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        noclipConnection = RunService.RenderStepped:Connect(function()
            if not noclipEnabled or not LocalPlayer.Character then return end
            local char = LocalPlayer.Character
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then part.CanCollide = false end
            end
        end)
        Library:Notify("Noclip: ON", 2)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == false then part.CanCollide = true end
            end
        end
        Library:Notify("Noclip: OFF", 2)
    end
end

local function toggleInfinityJump(enabled)
    infinityJumpEnabled = enabled
    if infinityJumpConnection then infinityJumpConnection:Disconnect(); infinityJumpConnection = nil end
    if enabled then
        infinityJumpConnection = UserInputService.JumpRequest:Connect(function()
            if not infinityJumpEnabled then return end
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid then
                local jumpPower = humanoid.UseJumpPower and humanoid.JumpPower or 50
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, jumpPower, hrp.AssemblyLinearVelocity.Z)
            end
        end)
        Library:Notify("Infinity Jump: ON（修正版）", 2)
    else
        Library:Notify("Infinity Jump: OFF", 2)
    end
end

local function setWalkSpeed(speed)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = speed end
    end
end

local function setJumpPower(power)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then originalJumpPower = power; hum.JumpPower = power end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if flyEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = true end
    end
    if noclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    if Options and Options.WalkSpeedSlider then setWalkSpeed(Options.WalkSpeedSlider.Value) end
    if Options and Options.JumpPowerSlider then setJumpPower(Options.JumpPowerSlider.Value) end
end)

-- ============================================================
--  ★★★ 統合防御システム (Defence) ★★★
-- ============================================================
function FWC(Parent, Name, Time)
    return Parent:FindFirstChild(Name) or Parent:WaitForChild(Name, Time or 3)
end

function grab(prt)
    if not prt or not prt:IsA("BasePart") then return end
    local GE = ReplicatedStorage:FindFirstChild("GrabEvents")
    if GE and GE:FindFirstChild("SetNetworkOwner") then
        pcall(function() GE.SetNetworkOwner:FireServer(prt, prt.CFrame) end)
    end
end

function spawntoy(name, cframe, vector)
    local toyFolder = Workspace:FindFirstChild(LocalPlayer.Name .. 'SpawnedInToys')
    if not toyFolder then return nil end
    local spawnedToy = nil
    local connection
    connection = toyFolder.ChildAdded:Connect(function(toy)
        if toy.Name == name then spawnedToy = toy; connection:Disconnect() end
    end)
    task.spawn(function()
        local MT = ReplicatedStorage:FindFirstChild("MenuToys")
        if MT and MT:FindFirstChild("SpawnToyRemoteFunction") then
            pcall(function() MT.SpawnToyRemoteFunction:InvokeServer(name, cframe, vector or Vector3.new()) end)
        end
    end)
    local waitStart = tick()
    while not spawnedToy and tick() - waitStart < 4 do RunService.Heartbeat:Wait() end
    if connection then connection:Disconnect() end
    return spawnedToy
end

-- 防御システム変数（簡略化のため一部省略。実際はフル実装）
local antiGrabActive = false
local antiGrabStruggle = nil
local antiGrabIsHeld = nil
local antiGrabNRDActive = false
local antiGrabNRDProc = false
local antiGrabNRDWalk = false
local antiGrabNRDStruggle = nil
local antiGrabNRDRagdoll = nil
local antiGrabNRDConn = nil
local antiVoidActive = false
local antiVoidConn = nil
local antiExplodeActive = false
local antiExplodeConn = nil
local antiBurnActive = false
local antiBurnConn = nil
local antiBurnConn2 = nil
local HRP_Burn = nil
local hum_Burn = nil
local antiStickyActive = false
local antiLagActive = false
local autoAntiLagActive = false
local autoAntiLagLines = 0
local autoAntiLagLagger = nil
local antiBananaSitActive = false
local antiBananaSitTask = nil
local antiBlobmanKillActive = false
local antiBlobmanKillTask = nil
local antiRagBlobActive = false
local antiRagBlobConns = {}
local antiKickActive = false
local antiKickTask = nil
local antiKickBreakPCLDActive = false
local antiKickBreakPCLDStored = {}
local antiKickBreakPCLDConn = nil
local antiKickBreakPCLDRoot = nil
local godModeActive = false
local godModeOriginalFallen = Workspace.FallenPartsDestroyHeight
local godModeLastCFrame = nil
local godModeLoopCoroutine = nil
local gucciActive = false
local gucciRunId = 0
local antiInputLagActive = false
local antiInputLagTask = nil
local antiInputLagSelectedToy = "FoodHamburger"
local removeAllAntiInputActive = false
local removeAllAntiInputTask = nil

-- [Anti Explode]
local function ToggleAntiExplode(v)
    antiExplodeActive = v
    if v then
        if antiExplodeConn then antiExplodeConn:Disconnect() end
        local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not (HRP and hum and hum:FindFirstChild("Ragdolled")) then return end
        antiExplodeConn = Workspace.ChildAdded:Connect(function(c)
            if not antiExplodeActive then return end
            if c.Name == "Part" then
                if (c.Position - HRP.Position).Magnitude < 40 and hum.Ragdolled.Value == true then
                    HRP.Anchored = true; task.wait(0.01); HRP.Anchored = false
                    stvel(HRP); hum:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    else
        if antiExplodeConn then antiExplodeConn:Disconnect(); antiExplodeConn = nil end
    end
end

-- [Anti Burn]
local function ToggleAntiBurn(v)
    antiBurnActive = v
    if v then
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        HRP_Burn = char:WaitForChild("HumanoidRootPart", 0.5)
        hum_Burn = char:WaitForChild("Humanoid", 0.5)
        if antiBurnConn then antiBurnConn:Disconnect() end
        antiBurnConn = hum_Burn.FireDebounce.Changed:Connect(function()
            if not antiBurnActive then return end
            if hum_Burn.FireDebounce.Value == true then
                local bar = Workspace.Plots.Plot1.Barrier.PlotBarrier
                local pos = bar.CFrame
                task.spawn(function()
                    repeat task.wait() bar.CFrame = HRP_Burn.CFrame until not hum_Burn.FireDebounce.Value
                end)
                task.wait(1); hum_Burn.FireDebounce.Value = false; task.wait(); bar.CFrame = pos
            end
        end)
        if antiBurnConn2 then antiBurnConn2:Disconnect() end
        antiBurnConn2 = LocalPlayer.CharacterAdded:Connect(function(char)
            if antiBurnActive then
                HRP_Burn = char:WaitForChild("HumanoidRootPart", 0.5)
                hum_Burn = char:WaitForChild("Humanoid", 0.5)
                if antiBurnConn then antiBurnConn:Disconnect() end
                antiBurnConn = hum_Burn.FireDebounce.Changed:Connect(function()
                    if not antiBurnActive then return end
                    if hum_Burn.FireDebounce.Value == true then
                        local bar = Workspace.Plots.Plot1.Barrier.PlotBarrier
                        local pos = bar.CFrame
                        task.spawn(function()
                            repeat task.wait() bar.CFrame = HRP_Burn.CFrame until not hum_Burn.FireDebounce.Value
                        end)
                        task.wait(1); hum_Burn.FireDebounce.Value = false; task.wait(); bar.CFrame = pos
                    end
                end)
            end
        end)
    else
        if antiBurnConn then antiBurnConn:Disconnect(); antiBurnConn = nil end
        if antiBurnConn2 then antiBurnConn2:Disconnect(); antiBurnConn2 = nil end
    end
end

-- [Anti Void]
local function ToggleAntiVoid(v)
    antiVoidActive = v
    if antiVoidConn then antiVoidConn:Disconnect(); antiVoidConn = nil end
    if v then
        antiVoidConn = RunService.Heartbeat:Connect(function()
            if not antiVoidActive then return end
            local char = LocalPlayer.Character
            local primary = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
            if primary then
                local pos = primary.Position
                if pos.Y < -50 then
                    primary.CFrame = CFrame.new(pos.X, pos.Y + 100, pos.Z)
                    primary.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)
    end
end

-- [Anti Banana Sit]
local function ToggleAntiBananaSit(v)
    antiBananaSitActive = v
    if antiBananaSitTask then task.cancel(antiBananaSitTask); antiBananaSitTask = nil end
    if v then
        antiBananaSitTask = task.spawn(function()
            while antiBananaSitActive do
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        hum.Sit = true; hum:ChangeState(Enum.HumanoidStateType.Running)
                        local cam = Workspace.CurrentCamera
                        if cam then
                            local lookVec = cam.CFrame.LookVector
                            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVec.X, 0, lookVec.Z))
                        end
                    end
                end
                task.wait()
            end
        end)
    end
end

-- [Anti Blobman Kill]
local function ToggleAntiBlobmanKill(v)
    antiBlobmanKillActive = v
    if antiBlobmanKillTask then task.cancel(antiBlobmanKillTask); antiBlobmanKillTask = nil end
    if v then
        antiBlobmanKillTask = task.spawn(function()
            while antiBlobmanKillActive do
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        hum.Sit = true; hum:ChangeState(Enum.HumanoidStateType.Running)
                        local cam = Workspace.CurrentCamera
                        if cam then
                            local lookVec = cam.CFrame.LookVector
                            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(lookVec.X, 0, lookVec.Z))
                        end
                    end
                end
                task.wait()
            end
        end)
    end
end

-- [Anti Ragdoll on Blob]
local function ToggleAntiRagBlob(v)
    antiRagBlobActive = v
    for _, conn in pairs(antiRagBlobConns) do if conn then conn:Disconnect() end end
    antiRagBlobConns = {}
    if v then
        local function SetupAntiRagBlob(char)
            if not antiRagBlobActive then return end
            local hum = char and char:FindFirstChild("Humanoid")
            local HRP = char and char:FindFirstChild("HumanoidRootPart")
            local RagdollRemote = ReplicatedStorage:FindFirstChild("CharacterEvents") and ReplicatedStorage.CharacterEvents:FindFirstChild("RagdollRemote")
            if not (hum and HRP and RagdollRemote) then return end
            if antiRagBlobConns["ARSeat"] then antiRagBlobConns["ARSeat"]:Disconnect(); antiRagBlobConns["ARSeat"] = nil end
            local ragdolledSit = false
            antiRagBlobConns["ARSeat"] = hum:GetPropertyChangedSignal("SeatPart"):Connect(function()
                if not antiRagBlobActive then return end
                if hum.SeatPart and hum.SeatPart.Parent and hum.SeatPart.Parent.Name == "CreatureBlobman" and not ragdolledSit then
                    ragdolledSit = true
                    local Seat = hum.SeatPart
                    while not hum.Sit do task.wait() end
                    RagdollRemote:FireServer(HRP, 3)
                    while not (hum:FindFirstChild("Ragdolled") and hum.Ragdolled.Value) and not hum.Sit do task.wait() end
                    task.wait(0.4); hum.Sit = false
                    if Seat and Seat:IsA("Part") then Seat:Sit(hum) end
                    task.delay(0.25, function()
                        while hum and hum.SeatPart do
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                RagdollRemote:FireServer(LocalPlayer.Character.HumanoidRootPart, 1)
                            end
                            task.wait(0.05)
                        end
                        ragdolledSit = false
                    end)
                end
            end)
        end
        SetupAntiRagBlob(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
        antiRagBlobConns["ARChar"] = LocalPlayer.CharacterAdded:Connect(SetupAntiRagBlob)
    end
end

-- [Anti Kick (Shuriken)]
local function ToggleAntiKick(v)
    antiKickActive = v
    if antiKickTask then task.cancel(antiKickTask); antiKickTask = nil end
    if v then
        antiKickTask = task.spawn(function()
            local function ClearAntiKickToys()
                local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                local destroyrem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
                if inv and destroyrem then
                    for _, v in pairs(inv:GetChildren()) do
                        if v.Name == "AntiKick" or v.Name == "NinjaShuriken" then pcall(function() destroyrem:FireServer(v) end) end
                    end
                end
            end
            local function StickShurikenToPlayer(kunai)
                if not kunai or not kunai:FindFirstChild("StickyPart") then return end
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local firePart = hrp:FindFirstChild("FirePlayerPart") or hrp:WaitForChild("FirePlayerPart", 5)
                if not firePart then return end
                local SetNetOwner = ReplicatedStorage:FindFirstChild("GrabEvents") and ReplicatedStorage.GrabEvents:FindFirstChild("SetNetworkOwner")
                local StickyEvent = ReplicatedStorage:FindFirstChild("PlayerEvents") and ReplicatedStorage.PlayerEvents:FindFirstChild("StickyPartEvent")
                if not SetNetOwner or not StickyEvent then return end
                for _, obj in pairs(kunai:GetChildren()) do
                    if obj:IsA("BasePart") then
                        obj.CanTouch = false; obj.CanCollide = false; obj.CanQuery = false
                        obj.AssemblyLinearVelocity = Vector3.zero; obj.AssemblyAngularVelocity = Vector3.zero
                    end
                end
                local soundPart = kunai:FindFirstChild("SoundPart")
                if soundPart and not (soundPart:FindFirstChild("PartOwner") and soundPart.PartOwner.Value == LocalPlayer.Name) then
                    pcall(function() SetNetOwner:FireServer(soundPart, soundPart.CFrame) end)
                end
                kunai:PivotTo(firePart.CFrame * CFrame.Angles(0, math.rad(90), math.rad(90)))
                StickyEvent:FireServer(kunai.StickyPart, firePart, CFrame.new() * CFrame.Angles(0, math.rad(90), math.rad(90)))
                kunai.Name = "AntiKick"
            end
            local function SpawnAntiKickToy(name)
                local char = LocalPlayer.Character
                if not char then return nil end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return nil end
                local SpawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
                if not SpawnRemote then return nil end
                pcall(function() SpawnRemote:InvokeServer(name, hrp.CFrame * CFrame.new(0, 2, 2), Vector3.new()) end)
                local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                if inv then return inv:WaitForChild(name, 2) end
                return nil
            end
            while antiKickActive do
                task.wait(0.05)
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then continue end
                local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                local kunai = inv and (inv:FindFirstChild("NinjaShuriken") or inv:FindFirstChild("AntiKick"))
                if not kunai then
                    kunai = SpawnAntiKickToy("NinjaShuriken")
                    if kunai then kunai.Name = "AntiKick" end
                end
                if kunai and kunai:FindFirstChild("StickyPart") then
                    local isWelded = kunai.StickyPart:FindFirstChild("StickyWeld") and kunai.StickyPart.StickyWeld.Part1 ~= nil
                    if not isWelded and kunai.StickyPart.CanTouch == true then
                        StickShurikenToPlayer(kunai); task.wait(0.1)
                    end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - kunai.StickyPart.Position).Magnitude >= 20 then ClearAntiKickToys() end
                end
            end
            ClearAntiKickToys()
        end)
    else
        local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        local destroyrem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
        if inv and destroyrem then
            for _, v in pairs(inv:GetChildren()) do
                if v.Name == "AntiKick" or v.Name == "NinjaShuriken" then pcall(function() destroyrem:FireServer(v) end) end
            end
        end
    end
end

-- [Anti Kick Break PCLD]
local function ToggleAntiKickBreakPCLD(v)
    antiKickBreakPCLDActive = v
    local serverPos = CFrame.new(-272.2197265625, -7.350403785705566, 475.0108947753906)
    if v then
        Workspace.FallenPartsDestroyHeight = 0/0
        local char = LocalPlayer.Character
        if not char then return end
        antiKickBreakPCLDRoot = char:WaitForChild("HumanoidRootPart")
        for _, v2 in pairs(char:GetDescendants()) do
            if v2:IsA("Motor6D") then
                antiKickBreakPCLDStored[v2] = v2.Part0
                v2.Part0 = nil
            end
        end
        antiKickBreakPCLDRoot.CFrame = serverPos
        antiKickBreakPCLDConn = RunService.RenderStepped:Connect(function()
            if antiKickBreakPCLDRoot and antiKickBreakPCLDRoot.Parent then
                antiKickBreakPCLDRoot.AssemblyLinearVelocity = Vector3.zero
                antiKickBreakPCLDRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    else
        if antiKickBreakPCLDConn then antiKickBreakPCLDConn:Disconnect(); antiKickBreakPCLDConn = nil end
        for m, p0 in pairs(antiKickBreakPCLDStored) do
            if m and m.Parent then m.Part0 = p0 end
        end
        antiKickBreakPCLDStored = {}
    end
end

-- [Anti Lag]
local function ToggleAntiLag(v)
    antiLagActive = v
    pcall(function() LocalPlayer.PlayerScripts.CharacterAndBeamMove.Enabled = not v end)
end

-- [Auto Anti Lag]
local function ToggleAutoAntiLag(v)
    autoAntiLagActive = v
    if v then
        task.spawn(function()
            while autoAntiLagActive do
                if autoAntiLagLines > 100 then
                    pcall(function() LocalPlayer.PlayerScripts.CharacterAndBeamMove.Enabled = false end)
                    autoAntiLagLines = 0
                end
                task.wait()
            end
        end)
    else
        pcall(function() LocalPlayer.PlayerScripts.CharacterAndBeamMove.Enabled = true end)
    end
end

Workspace.DescendantAdded:Connect(function(d)
    if d.Name == "GrabBeam" then
        autoAntiLagLines = autoAntiLagLines + 1
        autoAntiLagLagger = d.Parent and d.Parent.Parent and d.Parent.Parent.Parent
    end
end)

-- [Anti Sticky]
local function ToggleAntiSticky(v)
    antiStickyActive = v
    pcall(function() LocalPlayer.PlayerScripts.StickyPartsTouchDetection.Enabled = not v end)
end

-- [Anti Grab]
local function ToggleAntiGrab(v)
    antiGrabActive = v
    if not v then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not antiGrabActive then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not antiGrabStruggle then
        local CE = ReplicatedStorage:FindFirstChild("CharacterEvents")
        if CE then antiGrabStruggle = CE:FindFirstChild("Struggle") end
    end
    if not antiGrabIsHeld then antiGrabIsHeld = LocalPlayer:FindFirstChild("IsHeld") end
    if antiGrabIsHeld and antiGrabIsHeld.Value == true then
        if antiGrabStruggle then pcall(function() antiGrabStruggle:FireServer(LocalPlayer) end) end
        hrp.Velocity = Vector3.zero; hrp.Anchored = true
    else
        hrp.Anchored = false
    end
end)

-- [Anti Grab NRD]
local function ToggleAntiGrabNRD(v)
    antiGrabNRDActive = v
    if not v then
        antiGrabNRDProc = false; antiGrabNRDWalk = false
        return
    end
    local function SetupAntiGrabNRD(char)
        if not antiGrabNRDActive then return end
        local hrp = FWC(char, "HumanoidRootPart", 5)
        local hum = FWC(char, "Humanoid", 5)
        local head = FWC(char, "Head", 5)
        if not hrp or not hum or not head then return end
        if not antiGrabNRDStruggle then
            local CE = ReplicatedStorage:FindFirstChild("CharacterEvents")
            if CE then
                antiGrabNRDStruggle = CE:FindFirstChild("Struggle")
                antiGrabNRDRagdoll = CE:FindFirstChild("RagdollRemote")
            end
        end
        head.ChildAdded:Connect(function(PartOwner)
            if not antiGrabNRDActive then return end
            if PartOwner and PartOwner.Name == "PartOwner" then
                if not antiGrabNRDProc then
                    antiGrabNRDProc = true
                    pcall(function() hum.Sit = false end)
                    if antiGrabNRDStruggle then pcall(function() antiGrabNRDStruggle:FireServer(LocalPlayer) end) end
                    task.spawn(function()
                        while antiGrabNRDActive and (head and head:FindFirstChild("PartOwner")) do
                            if antiGrabNRDStruggle then pcall(function() antiGrabNRDStruggle:FireServer(LocalPlayer) end) end
                            if antiGrabNRDRagdoll then pcall(function() antiGrabNRDRagdoll:FireServer(hrp, 0) end) end
                            task.wait()
                        end
                    end)
                    pcall(function() hrp.Anchored = true end)
                    if not antiGrabNRDWalk then
                        antiGrabNRDWalk = true
                        while antiGrabNRDActive and task.wait() do
                            local held = LocalPlayer:FindFirstChild("IsHeld")
                            if not held or not held.Value then break end
                            pcall(function()
                                if hum and hum.MoveDirection then
                                    hrp.CFrame = hrp.CFrame + hum.MoveDirection * 0.43
                                end
                            end)
                        end
                        antiGrabNRDWalk = false
                    end
                    pcall(function() hrp.Anchored = false end)
                    antiGrabNRDProc = false
                end
            end
        end)
        local ragdolledValue = FWC(hum, "Ragdolled", 3)
        if ragdolledValue then
            ragdolledValue.Changed:Connect(function()
                if not antiGrabNRDActive then return end
                if ragdolledValue.Value then
                    for _, v in pairs(char:GetChildren()) do
                        if v:IsA("BasePart") and v:FindFirstChild("BallSocketConstraint") and v.Name ~= "Head" then
                            pcall(function() v.BallSocketConstraint.Enabled = false end)
                            if v:FindFirstChild("RagdollLimbPart") then
                                pcall(function() v.RagdollLimbPart.WeldConstraint.Enabled = false end)
                            end
                        end
                    end
                end
            end)
        end
    end
    if LocalPlayer.Character then task.defer(function() SetupAntiGrabNRD(LocalPlayer.Character) end) end
    if antiGrabNRDConn then antiGrabNRDConn:Disconnect() end
    antiGrabNRDConn = LocalPlayer.CharacterAdded:Connect(SetupAntiGrabNRD)
end

-- [God Mode]
local function ToggleGodMode(v)
    godModeActive = v
    if v then
        godModeOriginalFallen = Workspace.FallenPartsDestroyHeight
        Workspace.FallenPartsDestroyHeight = 0/0
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then godModeLastCFrame = root.CFrame end
        end
        if godModeLoopCoroutine then coroutine.close(godModeLoopCoroutine); godModeLoopCoroutine = nil end
        godModeLoopCoroutine = coroutine.create(function()
            while godModeActive do
                if not LocalPlayer.Character then task.wait(0.5)
                else
                    local char = LocalPlayer.Character
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    if not godModeLastCFrame then godModeLastCFrame = root.CFrame end
                    local original = root.CFrame
                    local startTime = tick()
                    local radius = 10000
                    while tick() - startTime < 1 and godModeActive do
                        if not LocalPlayer.Character or not root.Parent then return end
                        local t = tick() * 12
                        local x = math.cos(t) * radius
                        local z = math.sin(t) * radius
                        root.CFrame = original + Vector3.new(x, -10000, z)
                        RunService.RenderStepped:Wait()
                    end
                    if godModeActive and root and root.Parent then root.CFrame = original end
                end
                task.wait(0.0001)
            end
        end)
        coroutine.resume(godModeLoopCoroutine)
    else
        godModeActive = false
        if godModeLoopCoroutine then coroutine.close(godModeLoopCoroutine); godModeLoopCoroutine = nil end
        Workspace.FallenPartsDestroyHeight = godModeOriginalFallen ~= nil and godModeOriginalFallen or -100
        local char = LocalPlayer.Character
        if char and godModeLastCFrame then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = godModeLastCFrame end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if godModeActive then
        task.wait(0.1)
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(0, -15000, 0) end
    end
end)

-- [Gucci Anti-Grab]
local function ToggleGucci(v)
    if v then
        gucciRunId = gucciRunId + 1
        local MyId = gucciRunId
        local isSetupFinished = false
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = FWC(char, "Humanoid")
        local hrp = FWC(char, "HumanoidRootPart")
        if not (hum and hrp) then return end
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
        task.spawn(function()
            local t = tick()
            while tick() - t < 0.8 and MyId == gucciRunId do
                if hrp and hrp.Parent then
                    hrp.Velocity = Vector3.zero; hrp.RotVelocity = Vector3.zero
                end
                RunService.Heartbeat:Wait()
            end
        end)
        local Blob = spawntoy("CreatureBlobman", hrp.CFrame * CFrame.new(0, 0, -5), Vector3.new(0, -15.716, 0))
        if not Blob then return end
        local BHead = FWC(Blob, "Head")
        local HitBox = FWC(Blob, "GrabbableHitbox")
        local Seat = FWC(Blob, "VehicleSeat")
        task.spawn(function()
            local startTime = tick()
            while MyId == gucciRunId and not isSetupFinished and tick() - startTime < 1.2 do
                if HitBox and HitBox.Parent then grab(HitBox) end
                if BHead and BHead.Parent then grab(BHead) end
                if Seat and Seat.Parent and Seat.Occupant ~= hum then pcall(function() Seat:Sit(hum) end) end
                local CE = ReplicatedStorage:FindFirstChild("CharacterEvents")
                if CE and CE:FindFirstChild("RagdollRemote") then pcall(function() CE.RagdollRemote:FireServer(hrp, 0.09) end) end
                RunService.Heartbeat:Wait()
            end
        end)
        task.wait(0.45)
        if MyId ~= gucciRunId then
            if Blob and Blob.Parent then Blob:Destroy() end
            return
        end
        isSetupFinished = true
        pcall(function() hum.Sit = false end)
        if Seat and Seat.Parent then
            Seat.Disabled = true; Seat.CanTouch = false; Seat.CanQuery = false
            for _, v in pairs(Seat:GetChildren()) do
                if v:IsA("Weld") or v.Name == "SeatWeld" then v:Destroy() end
            end
        end
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        task.wait(0.05)
        local CE = ReplicatedStorage:FindFirstChild("CharacterEvents")
        if CE and CE:FindFirstChild("RagdollRemote") then pcall(function() CE.RagdollRemote:FireServer(hrp, false) end) end
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        Blob.Name = "Gucci"
        for _, v in pairs(Blob:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false; v.CanTouch = false; v.CanQuery = false; v.Massless = true
            end
        end
        task.spawn(function()
            while MyId == gucciRunId and BHead and BHead.Parent do
                if BHead and BHead.Parent then BHead.CFrame = CFrame.new(BHead.Position.X, 100000, BHead.Position.Z) end
                RunService.Heartbeat:Wait()
            end
        end)
        gucciActive = true
    else
        gucciRunId = gucciRunId + 1
        gucciActive = false
        local toyFolder = Workspace:FindFirstChild(LocalPlayer.Name .. 'SpawnedInToys')
        if toyFolder then
            for _, v in pairs(toyFolder:GetChildren()) do
                if v.Name == "Gucci" or v.Name == "CreatureBlobman" then pcall(function() v:Destroy() end) end
            end
        end
    end
end

-- [Anti Input Lag]
local ToyList = {
    Coconut = "FoodCoconut", Banana = "FoodBanana", Fries = "FoodFrenchFries",
    MeatStick = "FoodMeatStick", Donut = "FoodDonut", Cake = "FoodCakePink",
    Burger = "FoodHamburger", Pizza = "FoodPizzaCheese", Hotdog = "FoodHotdog",
    Mushroom = "FoodMushroomPoison", Pepperoni = "FoodPizzaPepperoni",
    Bread = "FoodBread", Egg = "FoodDippyEgg", Mayo = "FoodMayonnaise",
    WhiteMug = "CupMugWhite", Ocarina = "InstrumentWoodwindOcarina",
    Trumpet = "InstrumentBrassTrumpet", Snare = "InstrumentDrumSnare"
}

local function ToggleAntiInputLag(v, selectedToy)
    antiInputLagActive = v
    if selectedToy then antiInputLagSelectedToy = selectedToy end
    if antiInputLagTask then task.cancel(antiInputLagTask); antiInputLagTask = nil end
    if v then
        antiInputLagTask = task.spawn(function()
            while antiInputLagActive do
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")
                local SpawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
                local toysFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                if not toysFolder then task.wait(0.1); continue end
                local toy = toysFolder:FindFirstChild(antiInputLagSelectedToy)
                if not toy then
                    pcall(function() SpawnRemote:InvokeServer(antiInputLagSelectedToy, hrp.CFrame * CFrame.new(0, 5, 0), Vector3.zero) end)
                    local t0 = tick()
                    repeat
                        RunService.Heartbeat:Wait()
                        toysFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                        toy = toysFolder and toysFolder:FindFirstChild(antiInputLagSelectedToy)
                    until toy or tick() - t0 > 1
                end
                if toy and toy.Parent then
                    local holdPart = toy:FindFirstChild("HoldPart")
                    if holdPart then
                        local holdingPlayer = holdPart:FindFirstChild("HoldingPlayer")
                        holdingPlayer = holdingPlayer and holdingPlayer.Value
                        if holdingPlayer and holdingPlayer ~= LocalPlayer then
                            pcall(function() holdPart.DropItemRemoteFunction:InvokeServer(toy, hrp.CFrame * CFrame.new(0, 2000, 0), Vector3.zero) end)
                            toy:Destroy()
                        else
                            local highPos = hrp.CFrame * CFrame.new(0, 2000, 0)
                            task.spawn(function()
                                holdPart.HoldItemRemoteFunction:InvokeServer(toy, char)
                                RunService.Heartbeat:Wait()
                                holdPart.DropItemRemoteFunction:InvokeServer(toy, highPos, highPos)
                            end)
                        end
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end)
    end
end

-- [Remove All Anti Input]
local function ToggleRemoveAllAntiInput(v)
    removeAllAntiInputActive = v
    if removeAllAntiInputTask then task.cancel(removeAllAntiInputTask); removeAllAntiInputTask = nil end
    if v then
        local AllowedItems = {
            FoodHamburger = true, FoodCoconut = true, FoodPizzaCheese = true,
            FoodPizzaPepperoni = true, FoodHotdog = true, FoodMushroomPoison = true,
            FoodBread = true, FoodDippyEgg = true, FoodMayonnaise = true,
            FoodFrenchFries = true, FoodMeatStick = true, FoodDonut = true,
            FoodCakePink = true, InstrumentGuitarBanjo = true, InstrumentGuitarViolin = true,
            InstrumentGuitarUkulele = true, InstrumentWoodwindSaxophone = true,
            InstrumentWoodwindOcarina = true, InstrumentBrassVuvuzelaQwizik = true,
            InstrumentBrassTrumpet = true, InstrumentDrumBongos = true,
            InstrumentDrumSnare = true, InstrumentPianoMelodica = true,
            InstrumentVoiceMicrophone = true, CupMugWhite = true, CupMugBrown = true,
            PoopPile = true, PoopPileSparkle = true
        }
        removeAllAntiInputTask = task.spawn(function()
            local burgers = {}
            local descConn = Workspace.DescendantAdded:Connect(function(obj)
                if AllowedItems[obj.Name] and obj:IsA("Model") then
                    task.spawn(function()
                        if obj:WaitForChild("HoldPart", 3) then table.insert(burgers, obj) end
                    end)
                end
            end)
            for _, v in ipairs(Workspace:GetDescendants()) do
                if AllowedItems[v.Name] and v:IsA("Model") and v:FindFirstChild("HoldPart") then table.insert(burgers, v) end
            end
            while removeAllAntiInputActive do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for i = #burgers, 1, -1 do
                        local b = burgers[i]
                        if not b or not b.Parent or not b:FindFirstChild("HoldPart") then
                            table.remove(burgers, i)
                        else
                            local hp = b.HoldPart
                            pcall(function() hp.HoldItemRemoteFunction:InvokeServer(b, char) end)
                            task.wait()
                            pcall(function() hp.DropItemRemoteFunction:InvokeServer(b, CFrame.new(hrp.Position + Vector3.new(0, -2000, 0)), Vector3.zero) end)
                        end
                    end
                end
                task.wait()
            end
            descConn:Disconnect()
        end)
    end
end

-- ============================================================
--  ★★★ GrabKick 統合機能 ★★★
-- ============================================================
local grabKickActive = false
local grabKickTargetName = nil
local grabKickTargetPlayer = nil
local grabKickPallet = nil
local isSpawningPallet = false
local isLagSpamming = false
local renderConnection = nil
local grabKickLoopTask = nil
local TELEPORT_DISTANCE = 25

local function getPlayerFromDisplay(displayString)
    if not displayString or displayString == "" then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        local full = player.DisplayName .. " (@ " .. player.Name .. ")"
        if full == displayString then return player end
    end
    return nil
end

local function getGrabKickPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(list, player.DisplayName .. " (@ " .. player.Name .. ")") end
    end
    table.sort(list)
    return list
end

local function waitForChildWithTimeout(parent, childName, timeout)
    return parent:FindFirstChild(childName) or parent:WaitForChild(childName, timeout or 5)
end

local function hasChild(parent, childName)
    return parent:FindFirstChild(childName) ~= nil
end

local function forceSetOwner(part)
    if part and part:IsA("BasePart") and SetNetOwner then
        pcall(function() SetNetOwner:FireServer(part, part.CFrame) end)
        task.wait()
    end
end

local function teleportBehindTarget(targetPlayer, rootPart)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not rootPart then return end
    local originalCFrame = rootPart.CFrame
    rootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
    for _ = 1, 15 do
        if SetNetOwner then pcall(function() SetNetOwner:FireServer(targetRoot, targetRoot.CFrame) end) end
        task.wait()
    end
    rootPart.CFrame = originalCFrame
end

local function spawnGrabKickPallet()
    if isSpawningPallet then return nil end
    isSpawningPallet = true
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local waitCount = 0
    while not LocalPlayer:FindFirstChild("CanSpawnToy") or not LocalPlayer.CanSpawnToy.Value do
        if waitCount > 50 then break end
        task.wait(0.1)
        waitCount = waitCount + 1
    end
    local spawnCFrame = rootPart.CFrame * CFrame.new(0, 14, 20)
    local container = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    if not container then
        container = Workspace:FindFirstChild("PlotItems")
        if container then
            container = container:FindFirstChild("Plot1")
        end
    end
    if not container then container = Workspace end
    local spawnedPart = nil
    local connection = container.ChildAdded:Connect(function(child)
        if child.Name == "PalletLightBrown" then spawnedPart = child end
    end)
    task.spawn(function()
        pcall(function()
            if SpawnToyRemote then
                SpawnToyRemote:InvokeServer("PalletLightBrown", spawnCFrame, Vector3.zero)
            end
        end)
    end)
    local startTime = tick()
    repeat task.wait(0.05) until spawnedPart or (tick() - startTime) > 5
    connection:Disconnect()
    if not spawnedPart then isSpawningPallet = false; return nil end
    local soundPart = waitForChildWithTimeout(spawnedPart, "SoundPart", 3)
    if not soundPart then spawnedPart:Destroy(); isSpawningPallet = false; return nil end
    local retryCount = 0
    while retryCount < 10 do
        if not grabKickActive then spawnedPart:Destroy(); isSpawningPallet = false; return nil end
        forceSetOwner(soundPart)
        if hasChild(soundPart, "PartOwner") then break end
        retryCount = retryCount + 1
    end
    if not hasChild(soundPart, "PartOwner") then
        spawnedPart:Destroy()
        isSpawningPallet = false
        return nil
    end
    for _, descendant in ipairs(spawnedPart:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.Transparency = 0.8
        end
    end
    spawnedPart.Name = "RagdollPalete"
    local velocity = Instance.new("BodyVelocity")
    velocity.MaxForce = Vector3.new(0, math.huge, 0)
    velocity.Velocity = Vector3.new(0, 900, 0)
    velocity.Parent = soundPart
    isSpawningPallet = false
    return spawnedPart
end

local function startLagSpam()
    if isLagSpamming or not CreateGrabLine then return end
    isLagSpamming = true
    task.spawn(function()
        while isLagSpamming do
            local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
            if spawnLocation then
                pcall(function()
                    CreateGrabLine:FireServer(spawnLocation, CFrame.new(math.random(-2010000000, 2000000001), 0, math.random(-2008100000, 2000200000)))
                end)
            end
            task.wait()
        end
    end)
end

local function stopLagSpam()
    isLagSpamming = false
end

local function grabKickLoop()
    while grabKickActive do
        local target = grabKickTargetPlayer
        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if target and localRoot then
            local targetChar = target.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                if distance > TELEPORT_DISTANCE then teleportBehindTarget(target, localRoot) end
                if SetNetOwner then pcall(function() SetNetOwner:FireServer(targetRoot, targetRoot.CFrame) end) end
                if GrabEvents and GrabEvents:FindFirstChild("DestroyGrabLine") then pcall(function() GrabEvents.DestroyGrabLine:FireServer(targetRoot) end) end
                targetRoot.AssemblyLinearVelocity = Vector3.zero
                targetRoot.AssemblyAngularVelocity = Vector3.zero
                local bodyPos = targetRoot:FindFirstChild("ControlBP")
                if not bodyPos then
                    bodyPos = Instance.new("BodyPosition")
                    bodyPos.Name = "ControlBP"
                    bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bodyPos.P = 800000
                    bodyPos.Parent = targetRoot
                end
                bodyPos.Position = localRoot.Position + Vector3.new(5, 10, 5)
            end
        end
        task.wait()
    end
    if grabKickTargetPlayer and grabKickTargetPlayer.Character then
        local root = grabKickTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and root:FindFirstChild("ControlBP") then root.ControlBP:Destroy() end
    end
end

local function toggleGrabKick(enabled)
    grabKickActive = enabled
    if enabled then
        grabKickTargetPlayer = getPlayerFromDisplay(grabKickTargetName)
        if not grabKickTargetPlayer then
            Library:Notify("対象プレイヤーを選択してください", 3)
            return
        end
        startLagSpam()
        grabKickLoopTask = task.spawn(grabKickLoop)
        renderConnection = RunService.RenderStepped:Connect(function()
            if not grabKickActive then return end
            local target = grabKickTargetPlayer
            if not target or not target.Character then return end
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = target.Character:FindFirstChild("Humanoid")
            if not targetRoot or not humanoid then return end
            if grabKickPallet and grabKickPallet:IsDescendantOf(Workspace) then
                local soundPart = grabKickPallet:FindFirstChild("SoundPart")
                if soundPart then
                    if not hasChild(soundPart, "PartOwner") then
                        grabKickPallet:Destroy()
                        grabKickPallet = nil
                    end
                else
                    grabKickPallet:Destroy()
                    grabKickPallet = nil
                end
            end
            if not isSpawningPallet and (not grabKickPallet or not grabKickPallet:IsDescendantOf(Workspace)) then
                local container = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                grabKickPallet = container and container:FindFirstChild("RagdollPalete") or spawnGrabKickPallet()
            end
            if grabKickPallet and grabKickPallet:FindFirstChild("SoundPart") then
                local ragdolled = humanoid:FindFirstChild("Ragdolled")
                if ragdolled and not ragdolled.Value then
                    grabKickPallet.SoundPart.Position = targetRoot.Position
                end
            end
        end)
        Library:Notify("GrabKick: 有効化 ✓", 3)
    else
        stopLagSpam()
        if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
        if grabKickLoopTask then task.cancel(grabKickLoopTask); grabKickLoopTask = nil end
        if grabKickPallet and grabKickPallet:IsDescendantOf(Workspace) then
            if DestroyToy then pcall(function() DestroyToy:FireServer(grabKickPallet) end) else grabKickPallet:Destroy() end
            grabKickPallet = nil
        end
        Library:Notify("GrabKick: 無効化", 3)
    end
end

-- ============================================================
--  ★★★ ドリフトキック機能 ★★★
-- ============================================================
local driftKickTarget = nil
local driftKickEnabled = false
local driftOrbitAngle = 0
local driftOrbitRadius = 15
local driftOrbitSpeed = 30
local driftCurrentBlobman = nil
local driftSpeedMultiplier = 1.0
local driftKickLoopTask = nil

local function getDriftKickPlayerList()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr.DisplayName .. " (" .. plr.Name .. ")") end
    end
    table.sort(list)
    return list
end

local function getPlayerFromDriftSelection(selection)
    if not selection or selection == "" then return nil end
    local username = selection:match("%(([^)]+)%)")
    if username then return Players:FindFirstChild(username) end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.DisplayName == selection then return plr end
    end
    return nil
end

local function spawnDriftBlobman()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local SpawnRemote = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("SpawnToyRemoteFunction")
    if not SpawnRemote then return false end
    local success, err = pcall(function()
        SpawnRemote:InvokeServer("CreatureBlobman", hrp.CFrame * CFrame.new(0, 0, 5), Vector3.zero)
    end)
    if not success then return false end
    local timeout = tick() + 5
    while tick() < timeout do
        local toysFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
        if toysFolder then
            for _, obj in ipairs(toysFolder:GetChildren()) do
                if obj.Name == "CreatureBlobman" then
                    driftCurrentBlobman = obj
                    return true
                end
            end
        end
        task.wait(0.1)
    end
    return false
end

local function startDriftKick()
    if not driftKickTarget then
        Library:Notify("先にターゲットを選択してください", 3)
        return
    end
    local toysFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    if toysFolder then
        for _, obj in ipairs(toysFolder:GetChildren()) do
            if obj.Name == "CreatureBlobman" and obj.Parent then
                driftCurrentBlobman = obj
                break
            end
        end
    end
    if not driftCurrentBlobman or not driftCurrentBlobman.Parent then
        spawnDriftBlobman()
        task.wait(0.5)
    end
    driftKickEnabled = true
    driftOrbitAngle = 0
    local target = driftKickTarget
    local blob = driftCurrentBlobman
    if driftKickLoopTask then task.cancel(driftKickLoopTask); driftKickLoopTask = nil end
    driftKickLoopTask = task.spawn(function()
        local GE = ReplicatedStorage:WaitForChild("GrabEvents")
        if not blob then return end
        local blobRoot = blob:FindFirstChild("HumanoidRootPart") or blob.PrimaryPart
        local scriptObj = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
        local CG = scriptObj and scriptObj:FindFirstChild("CreatureGrab")
        local CD = scriptObj and scriptObj:FindFirstChild("CreatureDrop")
        local R_Det = blob:FindFirstChild("RightDetector")
        local R_Weld = R_Det and (R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld"))
        if not blobRoot then return end
        local SavedPos = blobRoot.CFrame
        local tChar = target.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if tRoot and blobRoot then
            local bringStart = tick()
            while tick() - bringStart < 0.25 do
                if not driftKickEnabled then break end
                blobRoot.CFrame = tRoot.CFrame
                blobRoot.Velocity = Vector3.zero
                pcall(function()
                    if CG and R_Det then CG:FireServer(R_Det, tRoot, R_Weld) end
                    if GE and GE.CreateGrabLine then GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false) end
                    if GE and GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, blobRoot.CFrame) end
                end)
                RunService.Heartbeat:Wait()
            end
            blobRoot.CFrame = SavedPos
            blobRoot.Velocity = Vector3.zero
            task.wait(0.02)
        end
        local packetTimer = 0
        while driftKickEnabled do
            if not target or not target.Parent or not target.Character then break end
            if not blobRoot or not blobRoot.Parent then break end
            tChar = target.Character
            tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
            local tHum = tChar and tChar:FindFirstChild("Humanoid")
            if tRoot and tHum and tHum.Health > 0 then
                local lockPos = SavedPos * CFrame.new(0, 23, 0)
                tRoot.CFrame = lockPos
                tRoot.Velocity = Vector3.zero
                tRoot.RotVelocity = Vector3.zero
                local dt = RunService.RenderStepped:Wait()
                driftOrbitAngle = driftOrbitAngle + (dt * driftOrbitSpeed * driftSpeedMultiplier * 10)
                local orbitX = math.cos(driftOrbitAngle) * driftOrbitRadius
                local orbitZ = math.sin(driftOrbitAngle) * driftOrbitRadius
                local orbitCFrame = lockPos * CFrame.new(orbitX, 0, orbitZ)
                local lookAtCFrame = CFrame.lookAt(orbitCFrame.Position, lockPos.Position)
                blobRoot.CFrame = lookAtCFrame
                blobRoot.Velocity = Vector3.zero
                if tick() - packetTimer > 0.005 then
                    packetTimer = tick()
                    pcall(function()
                        tHum.PlatformStand = true; tHum.Sit = true
                        if GE and GE.SetNetworkOwner then GE.SetNetworkOwner:FireServer(tRoot, lockPos) end
                        if R_Det then
                            local weld = R_Det:FindFirstChild("RightWeld") or R_Det:FindFirstChildWhichIsA("Weld")
                            if weld and CD then CD:FireServer(weld) end
                        end
                        if GE and GE.DestroyGrabLine then GE.DestroyGrabLine:FireServer(tRoot) end
                        if CG and R_Det then CG:FireServer(R_Det, tRoot, R_Weld) end
                        if GE and GE.CreateGrabLine then GE.CreateGrabLine:FireServer(tRoot, Vector3.zero, tRoot.Position, false) end
                    end)
                end
            else
                if blobRoot and blobRoot.Parent then
                    blobRoot.CFrame = SavedPos
                    blobRoot.Velocity = Vector3.zero
                end
            end
            task.wait(0)
        end
        driftKickEnabled = false
        if blobRoot and blobRoot.Parent then
            blobRoot.CFrame = SavedPos
            blobRoot.Velocity = Vector3.zero
        end
    end)
end

local function stopDriftKick()
    driftKickEnabled = false
    driftOrbitAngle = 0
    if driftKickLoopTask then task.cancel(driftKickLoopTask); driftKickLoopTask = nil end
end

-- ============================================================
--  ★★★ Trainタブ用変数・関数 ★★★
-- ============================================================
local AutomationEnabled = false
local AutomationConnection = nil
local TargetItemName = "InstrumentWoodwindOcarina"
local SecondItemName = "FoodMayonnaise"
local occupiedSeats = {}
local seatConnections = {}
local firstTimeRiders = {}
local allSeats = {}

local function getPlayerCharacter()
    local character = Workspace:FindFirstChild(LocalPlayer.Name .. "_sub")
    if not character then
        character = Workspace:FindFirstChild(LocalPlayer.Name)
    end
    if not character then
        character = LocalPlayer.Character
    end
    return character
end

local function getAllItemsWithRemote()
    local items = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("RemoteFunction") and obj.Name == "HoldItemRemoteFunction" then
            local holdPart = obj.Parent
            if holdPart and holdPart.Name == "HoldPart" then
                local item = holdPart.Parent
                if item then
                    local dropRemote = holdPart:FindFirstChild("DropItemRemoteFunction")
                    table.insert(items, {
                        Name = item.Name,
                        Object = item,
                        RemoteFunction = obj,
                        DropRemoteFunction = dropRemote,
                        Path = item:GetFullName()
                    })
                end
            end
        end
    end
    return items
end

local function holdItem(itemData)
    local success = pcall(function()
        local playerCharacter = getPlayerCharacter()
        if playerCharacter and itemData.RemoteFunction then
            itemData.RemoteFunction:InvokeServer(itemData.Object, playerCharacter)
        end
    end)
    return success
end

local function useItem(itemData)
    local success = pcall(function()
        local UseRemote = ReplicatedStorage:FindFirstChild("HoldEvents")
        if UseRemote then
            local Use = UseRemote:FindFirstChild("Use")
            if Use then
                Use:FireServer(itemData.Object)
            end
        end
    end)
    return success
end

local function dropItemAtPlayer(itemData)
    local success = pcall(function()
        if itemData.DropRemoteFunction then
            local playerCharacter = getPlayerCharacter()
            if playerCharacter then
                local humanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local currentCFrame = humanoidRootPart.CFrame
                    local dropPos = currentCFrame * CFrame.new(0, 900, 0)
                    itemData.DropRemoteFunction:InvokeServer(itemData.Object, dropPos, Vector3.new(0, 900, 0))
                end
            end
        end
    end)
    return success
end

local function findTargetItem()
    local items = getAllItemsWithRemote()
    for _, item in pairs(items) do
        if item.Name == TargetItemName then return item end
    end
    return nil
end

local function findSecondItem()
    local items = getAllItemsWithRemote()
    for _, item in pairs(items) do
        if item.Name == SecondItemName then return item end
    end
    return nil
end

local function spawnItem(itemName)
    pcall(function()
        local Character = getPlayerCharacter()
        if not Character then return end
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then return end
        local SpawnPosition = RootPart.Position + Vector3.new(0, 900, 0)
        local SpawnCFrame = CFrame.new(SpawnPosition)
        local SpawnToyRemote = ReplicatedStorage:FindFirstChild("MenuToys")
        if SpawnToyRemote then
            local SpawnFunc = SpawnToyRemote:FindFirstChild("SpawnToyRemoteFunction")
            if SpawnFunc then
                SpawnFunc:InvokeServer(itemName, SpawnCFrame, Vector3.new(0, 0, 0))
            end
        end
    end)
end

local function performAutoAction(isFirstTime)
    if isFirstTime then
        local targetItem = findTargetItem()
        if not targetItem then spawnItem(TargetItemName) end
        local secondItem = findSecondItem()
        if not secondItem then spawnItem(SecondItemName) end
        task.wait(1.0)
        targetItem = findTargetItem()
        secondItem = findSecondItem()
        if targetItem then holdItem(targetItem); task.wait(0.1) end
        if secondItem then holdItem(secondItem); task.wait(0.1) end
        if targetItem then useItem(targetItem); task.wait(0.1) end
        if targetItem then dropItemAtPlayer(targetItem); task.wait(0.1) end
        if secondItem then dropItemAtPlayer(secondItem) end
    else
        local targetItem = findTargetItem()
        if not targetItem then
            spawnItem(TargetItemName)
            task.wait(1.0)
            targetItem = findTargetItem()
        end
        if targetItem then
            if holdItem(targetItem) then
                task.wait(0.3)
                dropItemAtPlayer(targetItem)
            end
        end
    end
end

local function checkAllSeats()
    local count = 0
    for seat, player in pairs(occupiedSeats) do
        if seat.Occupant then count = count + 1 end
    end
end

local function onSeatOccupied(seat, player)
    occupiedSeats[seat] = player
    local isFirstTimeRider = not firstTimeRiders[player.UserId]
    if isFirstTimeRider then
        firstTimeRiders[player.UserId] = true
        if AutomationEnabled then performAutoAction(true) end
    else
        if AutomationEnabled then performAutoAction(false) end
    end
    checkAllSeats()
end

local function onSeatLeft(seat, player)
    occupiedSeats[seat] = nil
    checkAllSeats()
    if AutomationEnabled then performAutoAction(false) end
end

local function setupSeat(seat)
    local connection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        local humanoid = seat.Occupant
        if humanoid then
            local character = humanoid.Parent
            local player = game.Players:GetPlayerFromCharacter(character)
            if player then
                onSeatOccupied(seat, player)
            end
            local sitConnection
            sitConnection = humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
                if not humanoid.Sit and player then
                    onSeatLeft(seat, player)
                    if sitConnection then sitConnection:Disconnect() end
                end
            end)
        end
    end)
    seatConnections[seat] = connection
    table.insert(allSeats, seat)
end

local function startSeatDetection()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Seat") and obj.Name == "Seat" then setupSeat(obj) end
    end
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Seat") and obj.Name == "Seat" then setupSeat(obj) end
    end)
end

local function sitOnRandomEmptySeat()
    local emptySeats = {}
    for _, seat in pairs(allSeats) do
        if seat and seat.Parent and seat:IsA("Seat") and not seat.Occupant then
            table.insert(emptySeats, seat)
        end
    end
    if #emptySeats == 0 then
        Library:Notify("座席がありません", 2)
        return
    end
    local randomSeat = emptySeats[math.random(1, #emptySeats)]
    local character = getPlayerCharacter()
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and humanoidRootPart then
            humanoid.Sit = false
            task.wait(0.2)
            humanoidRootPart.CFrame = randomSeat.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            randomSeat:Sit(humanoid)
            Library:Notify("座席に座りました", 2)
        end
    end
end

local function startAutomation()
    if AutomationConnection then AutomationConnection:Disconnect() end
    local character = getPlayerCharacter()
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    AutomationConnection = humanoid.Seated:Connect(function(active, seat)
        if AutomationEnabled then
            if active then
                task.wait(0.1)
                performAutoAction(true)
            else
                task.wait(0.1)
                performAutoAction(false)
            end
        end
    end)
    if AutomationEnabled and humanoid.SeatPart then
        performAutoAction(true)
    end
end

local function stopAutomation()
    if AutomationConnection then
        AutomationConnection:Disconnect()
        AutomationConnection = nil
    end
end

local antiExplosionConnection = nil
local function setupAntiExplosion(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    local ragdolled = humanoid:FindFirstChild("Ragdolled")
    if ragdolled and ragdolled:IsA("BoolValue") then
        if antiExplosionConnection then antiExplosionConnection:Disconnect() end
        antiExplosionConnection = ragdolled:GetPropertyChangedSignal("Value"):Connect(function()
            if ragdolled.Value then
                for _, part in ipairs(character:GetChildren()) do
                    if part:IsA("BasePart") then part.Anchored = true end
                end
            else
                for _, part in ipairs(character:GetChildren()) do
                    if part:IsA("BasePart") then part.Anchored = false end
                end
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if AutomationEnabled then
        startAutomation()
        startSeatDetection()
    end
    setupAntiExplosion(char)
end)

task.spawn(function()
    task.wait(1)
    startSeatDetection()
    if AutomationEnabled then startAutomation() end
    if LocalPlayer.Character then setupAntiExplosion(LocalPlayer.Character) end
end)

-- ============================================================
--  ★★★ サーバーDestroy v2（古いKickタブのサーバーキック） ★★★
-- ============================================================
local serverKickHeight = "Spawn"
local serverKickLineLagThread = nil
local serverKickLineLagEnabled = false
local serverKickFixLoopActive = false
local serverKickFixLoopConn = nil
local serverKickFixedPlayerData = {}
local serverKickFixedPositions = {}

local function serverKickGetAllPlayers()
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(players, plr) end
    end
    return players
end

local function serverKickSpamOwnership(hrp)
    if not GrabEvents then return end
    local setOwner = GrabEvents:FindFirstChild("SetNetworkOwner")
    if setOwner and hrp then pcall(function() setOwner:FireServer(hrp, hrp.CFrame) end) end
end

local function serverKickTeleportToPlayer(myHrp, targetHrp)
    if not myHrp or not targetHrp then return end
    pcall(function()
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 5, 5)
        myHrp.AssemblyLinearVelocity = Vector3.zero
    end)
end

local function serverKickDestroyLineOnPlayer(hrp)
    if not GrabEvents then return end
    local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
    local destroyLine = GrabEvents:FindFirstChild("DestroyGrabLine")
    if not createLine or not destroyLine then return end
    pcall(function()
        createLine:FireServer(hrp, CFrame.new(0, 1e9, 0))
        task.wait()
        destroyLine:FireServer(hrp)
    end)
end

local function serverKickStartLineLag()
    if serverKickLineLagEnabled then return end
    serverKickLineLagEnabled = true
    serverKickLineLagThread = coroutine.create(function()
        if not GrabEvents then return end
        local createLine = GrabEvents:FindFirstChild("CreateGrabLine")
        if not createLine then return end
        while serverKickLineLagEnabled do
            local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
            if spawnLocation then
                for i = 1, 520 do
                    local randomX = math.random(-1e9, 1e9)
                    local randomZ = math.random(-1e9, 1e9)
                    createLine:FireServer(spawnLocation, CFrame.new(randomX, 0, randomZ))
                end
            end
            task.wait(1)
        end
    end)
    coroutine.resume(serverKickLineLagThread)
end

local function serverKickStopLineLag()
    serverKickLineLagEnabled = false
    if serverKickLineLagThread then
        coroutine.close(serverKickLineLagThread)
        serverKickLineLagThread = nil
    end
end

local function serverKickStartFixLoop(playerData, centerPos, height, radius)
    serverKickFixLoopActive = true
    serverKickFixedPlayerData = playerData
    serverKickFixedPositions = {}
    local count = #playerData
    local actualRadius = math.max(radius, count * 2.5)
    for idx, data in ipairs(playerData) do
        local angle = ((idx - 1) / count) * 2 * math.pi
        local x = centerPos.X + math.cos(angle) * actualRadius
        local z = centerPos.Z + math.sin(angle) * actualRadius
        serverKickFixedPositions[idx] = Vector3.new(x, height, z)
    end
    if serverKickFixLoopConn then serverKickFixLoopConn:Disconnect() end
    serverKickFixLoopConn = RunService.Heartbeat:Connect(function()
        if not serverKickFixLoopActive then return end
        for idx, data in ipairs(serverKickFixedPlayerData) do
            local hrp = data.hrp
            if not hrp or not hrp.Parent then continue end
            local targetPos = serverKickFixedPositions[idx]
            if not targetPos then continue end
            pcall(function()
                hrp.CFrame = CFrame.new(targetPos)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            local bp = hrp:FindFirstChild("FixBodyPosition")
            if not bp then
                bp = Instance.new("BodyPosition")
                bp.Name = "FixBodyPosition"
                bp.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bp.P = 9e9
                bp.D = 5000
                bp.Parent = hrp
            end
            bp.Position = targetPos
        end
    end)
end

local function serverKickStopFixLoop()
    serverKickFixLoopActive = false
    if serverKickFixLoopConn then
        serverKickFixLoopConn:Disconnect()
        serverKickFixLoopConn = nil
    end
    for _, data in ipairs(serverKickFixedPlayerData) do
        local hrp = data.hrp
        if hrp then
            local bp = hrp:FindFirstChild("FixBodyPosition")
            if bp then bp:Destroy() end
        end
    end
    serverKickFixedPlayerData = {}
    serverKickFixedPositions = {}
end

local function serverKickDestroy()
    task.spawn(function()
        Library:Notify("デストロイ開始✅", 2)
        local height = (serverKickHeight == "Heaven") and 1e9 or 35
        serverKickStartLineLag()
        task.wait(1)
        local players = serverKickGetAllPlayers()
        if #players == 0 then
            serverKickStopLineLag()
            Library:Notify("対象プレイヤーがいません", 3)
            return
        end
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then serverKickStopLineLag(); return end
        local playerData = {}
        for _, plr in ipairs(players) do
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then table.insert(playerData, {player = plr, hrp = hrp}) end
        end
        if #playerData == 0 then
            serverKickStopLineLag()
            Library:Notify("有効な対象プレイヤーがいません", 3)
            return
        end
        Library:Notify("全員ブリング💪", 2)
        for _, data in ipairs(playerData) do
            serverKickTeleportToPlayer(myHrp, data.hrp)
            task.wait(0.2)
            serverKickSpamOwnership(data.hrp)
            task.wait()
        end
        local centerPos = myHrp.Position
        serverKickStartFixLoop(playerData, centerPos, height, 40)
        Library:Notify("固定完了✅", 2)
        Library:Notify("ラグオン‼️", 2)
        for i = 1, 30 do
            for _, data in ipairs(playerData) do
                serverKickDestroyLineOnPlayer(data.hrp)
            end
            task.wait(0.1)
        end
        Library:Notify("キックオール完了（固定ループ中）", 2)
    end)
end

local function serverKickStop()
    serverKickStopLineLag()
    serverKickStopFixLoop()
    Library:Notify("ラグと固定解除完了✅", 2)
end

-- ============================================================
--  ★★★ サーバーDestroy v1（新サーバー破壊システム） ★★★
-- ============================================================
local serverDestroy = {}
local serverDestroyLineLagEnabled = false
local serverDestroyLineLagThread = nil
local serverDestroyLineLagLPS = 100
local serverDestroyPacketLagEnabled = false
local serverDestroyPacketLagTask = nil
local serverDestroyPacketLagStrength = 2000
local serverDestroyPacketDetectorEnabled = false
local serverDestroyLastLagSource = false
local serverDestroyHeightMode = "Spawn"
local serverDestroyThread = nil
local serverDestroyBlobmanKickActive = false

-- ユーティリティ
local function sdIsTargetable(player)
    if not player or player == LocalPlayer then return false end
    return true
end

local function sdGetAllPlayers()
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if sdIsTargetable(plr) then table.insert(players, plr) end
    end
    return players
end

-- Line Lag
local function sdStartLineLag()
    if serverDestroyLineLagEnabled then return end
    serverDestroyLineLagEnabled = true
    serverDestroyLineLagThread = coroutine.create(function()
        if not CreateGrabLine then return end
        while serverDestroyLineLagEnabled do
            local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChild("Spawn")
                or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
            if spawnLocation then
                for i = 1, serverDestroyLineLagLPS do
                    local randomX = math.random(-9e9, 9e9)
                    local randomZ = math.random(-9e9, 9e9)
                    local directions = {
                        CFrame.new(randomX, 0, randomZ),
                        CFrame.new(-randomX, 0, -randomZ),
                        CFrame.new(randomX, 0, -randomZ),
                        CFrame.new(-randomX, 0, randomZ),
                    }
                    for _, pos in pairs(directions) do
                        pcall(function() CreateGrabLine:FireServer(spawnLocation, pos) end)
                    end
                end
            end
            task.wait(1)
        end
    end)
    coroutine.resume(serverDestroyLineLagThread)
end

local function sdStopLineLag()
    if not serverDestroyLineLagEnabled then return end
    serverDestroyLineLagEnabled = false
    if serverDestroyLineLagThread then
        coroutine.close(serverDestroyLineLagThread)
        serverDestroyLineLagThread = nil
    end
end

local function sdToggleLineLag(enabled, lps)
    if lps then serverDestroyLineLagLPS = lps end
    if enabled then sdStartLineLag() else sdStopLineLag() end
end

-- Packet Lag
local function sdStartPacketLag()
    if serverDestroyPacketLagEnabled then return end
    serverDestroyPacketLagEnabled = true
    serverDestroyPacketLagTask = task.spawn(function()
        while serverDestroyPacketLagEnabled do
            task.wait(1)
            if ExtendGrabLine then
                local data = string.rep("😂😂😂😂🤣🤣🤣🤣", serverDestroyPacketLagStrength)
                pcall(function() ExtendGrabLine:FireServer(data) end)
            end
        end
    end)
end

local function sdStopPacketLag()
    serverDestroyPacketLagEnabled = false
    if serverDestroyPacketLagTask then
        task.cancel(serverDestroyPacketLagTask)
        serverDestroyPacketLagTask = nil
    end
end

local function sdTogglePacketLag(enabled, strength)
    if strength then serverDestroyPacketLagStrength = strength end
    if enabled then sdStartPacketLag() else sdStopPacketLag() end
end

-- Packet Lag Detector
local function sdStartPacketDetector()
    if not ExtendGrabLine then return end
    serverDestroyPacketDetectorEnabled = true
    ExtendGrabLine.OnClientEvent:Connect(function(arg1, data)
        if not serverDestroyPacketDetectorEnabled then return end
        if typeof(data) == "string" and not serverDestroyLastLagSource then
            local len = string.len(data)
            if len > 300 then
                serverDestroyLastLagSource = true
                local sizeMB = len / (1024 * 1024)
                Library:Notify(string.format("Packet Lag: %.3f MB from %s", sizeMB, tostring(arg1)), 3)
                task.delay(5, function() serverDestroyLastLagSource = false end)
            end
        end
    end)
end

local function sdTogglePacketDetector(enabled)
    serverDestroyPacketDetectorEnabled = enabled
end

-- Destroy Server
local function sdGetDestroyHeight()
    return serverDestroyHeightMode == "Heaven" and 1e9 or 35
end

local function sdDestroyServer()
    if serverDestroyThread then return end
    serverDestroyThread = task.spawn(function()
        local height = sdGetDestroyHeight()
        sdStartLineLag()
        task.wait(1)
        local players = sdGetAllPlayers()
        if #players == 0 then
            sdStopLineLag()
            Library:Notify("対象プレイヤーがいません", 3)
            serverDestroyThread = nil
            return
        end
        local myChar = LocalPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHrp then
            sdStopLineLag()
            serverDestroyThread = nil
            return
        end
        local playerData = {}
        for _, plr in ipairs(players) do
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then table.insert(playerData, {player = plr, hrp = hrp}) end
        end
        for _, data in ipairs(playerData) do
            myHrp.CFrame = data.hrp.CFrame * CFrame.new(0, 5, 5)
            myHrp.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.2)
            if SetNetworkOwner then pcall(function() SetNetworkOwner:FireServer(data.hrp, data.hrp.CFrame) end) end
            task.wait()
        end
        local radius = 40
        local angleStep = (math.pi * 2) / #playerData
        for idx, data in ipairs(playerData) do
            local angle = (idx - 1) * angleStep
            local x = math.cos(angle) * radius
            local z = math.sin(angle) * radius
            local pos = Vector3.new(x, height, z)
            pcall(function()
                data.hrp.CFrame = CFrame.new(pos)
                data.hrp.AssemblyLinearVelocity = Vector3.zero
                data.hrp.Velocity = Vector3.zero
            end)
            local bp = Instance.new("BodyPosition")
            bp.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bp.P = 50000000
            bp.Position = pos
            bp.Parent = data.hrp
            task.delay(2, function() pcall(function() bp:Destroy() end) end)
            task.wait()
        end
        for i = 1, 8 do
            for _, data in ipairs(playerData) do
                task.spawn(function()
                    pcall(function()
                        if CreateGrabLine then CreateGrabLine:FireServer(data.hrp, CFrame.new(0, 1e9, 0)) end
                        task.wait()
                        if DestroyGrabLine then DestroyGrabLine:FireServer(data.hrp) end
                    end)
                end)
            end
            task.wait(0.3)
        end
        Library:Notify("サーバー破壊完了 ✅", 3)
        sdStopLineLag()
        serverDestroyThread = nil
    end)
end

local function sdSetDestroyHeight(mode)
    serverDestroyHeightMode = mode
end

-- Blobman Kick All
local function sdBlobmanKickAll()
    if serverDestroyBlobmanKickActive then return end
    serverDestroyBlobmanKickActive = true
    local allPlayers = sdGetAllPlayers()
    if #allPlayers == 0 then
        Library:Notify("対象プレイヤーがいません", 3)
        serverDestroyBlobmanKickActive = false
        return
    end
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    if rootPart and SpawnToyRemote then
        local spawnPos = rootPart.CFrame * CFrame.new(0, 0, -5)
        pcall(function() SpawnToyRemote:InvokeServer("CreatureBlobman", spawnPos, Vector3.new(0, 127, 0)) end)
    end
    task.wait(0.5)
    local toyFolder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
    local currentBlob = toyFolder and toyFolder:FindFirstChild("CreatureBlobman")
    if not currentBlob then
        serverDestroyBlobmanKickActive = false
        return
    end
    local vehicleSeat = currentBlob:FindFirstChild("VehicleSeat")
    if vehicleSeat and LocalPlayer.Character then
        pcall(function() vehicleSeat:Sit(LocalPlayer.Character:FindFirstChildOfClass("Humanoid")) end)
    end
    task.wait(0.3)
    local myRoot = rootPart
    if not myRoot then
        serverDestroyBlobmanKickActive = false
        return
    end
    for _, targetPlayer in ipairs(allPlayers) do
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            myRoot.CFrame = targetRoot.CFrame
            task.wait(0.02)
            for i = 1, 3 do
                pcall(function()
                    local script = currentBlob:FindFirstChild("BlobmanSeatAndOwnerScript")
                    if script then
                        if script:FindFirstChild("CreatureGrab") then
                            script.CreatureGrab:FireServer(currentBlob.LeftDetector, targetRoot, currentBlob.LeftDetector.LeftWeld)
                        end
                        if script:FindFirstChild("CreatureRelease") then
                            script.CreatureRelease:FireServer(currentBlob.LeftDetector.LeftWeld)
                        end
                    end
                end)
                if i < 3 then task.wait(0.08) end
            end
        end
    end
    local radius = 15
    for i, targetPlayer in ipairs(allPlayers) do
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local angle = math.rad((i - 1) * (360 / #allPlayers))
            local x = radius * math.cos(angle)
            local z = radius * math.sin(angle)
            pcall(function() targetRoot.CFrame = CFrame.new(x, 110, z) end)
        end
    end
    task.wait(0.1)
    for _ = 1, 2 do
        for _, targetPlayer in ipairs(allPlayers) do
            local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                task.spawn(function()
                    pcall(function()
                        if SetNetworkOwner then SetNetworkOwner:FireServer(targetRoot, CFrame.new(targetRoot.Position)) end
                        if DestroyGrabLine then DestroyGrabLine:FireServer(targetRoot) end
                    end)
                end)
            end
        end
        task.wait(0.1)
    end
    for _, targetPlayer in ipairs(allPlayers) do
        local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            task.spawn(function()
                pcall(function()
                    local script = currentBlob:FindFirstChild("BlobmanSeatAndOwnerScript")
                    if script then
                        if script:FindFirstChild("CreatureGrab") then
                            script.CreatureGrab:FireServer(currentBlob.LeftDetector, targetRoot, currentBlob.LeftDetector.LeftWeld)
                            script.CreatureGrab:FireServer(currentBlob.RightDetector, targetRoot, currentBlob.RightDetector.RightWeld)
                        end
                    end
                end)
            end)
        end
    end
    if myRoot then myRoot.CFrame = CFrame.new(0, -50000, 0) end
    for _, part in ipairs(currentBlob:GetDescendants()) do
        if part:IsA("BasePart") then pcall(function() part.Anchored = false end) end
    end
    task.wait(1)
    serverDestroyBlobmanKickActive = false
    Library:Notify("Blobmanキック完了 ✅", 3)
end

-- Kick All（単発）
local function sdKickAll()
    local allPlayers = sdGetAllPlayers()
    if #allPlayers == 0 then
        Library:Notify("対象プレイヤーがいません", 3)
        return
    end
    for _, target in ipairs(allPlayers) do
        local char = target.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                pcall(function()
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 600, 0)
                    local bv = Instance.new("BodyVelocity", hrp)
                    bv.MaxForce = Vector3.new(0, math.huge, 0)
                    bv.Velocity = Vector3.new(0, 700, 0)
                    task.wait(0.1)
                    bv:Destroy()
                end)
            end
        end
    end
    Library:Notify("キック完了 ✅", 3)
end

-- Teleport All
local function sdTeleportAll(height)
    height = height or 1000
    local allPlayers = sdGetAllPlayers()
    if #allPlayers == 0 then
        Library:Notify("対象プレイヤーがいません", 3)
        return
    end
    local radius = 30
    local angleStep = (math.pi * 2) / #allPlayers
    for i, target in ipairs(allPlayers) do
        local char = target.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local angle = (i - 1) * angleStep
                local x = math.cos(angle) * radius
                local z = math.sin(angle) * radius
                local pos = Vector3.new(x, height, z)
                pcall(function()
                    hrp.CFrame = CFrame.new(pos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end)
            end
        end
    end
    Library:Notify("テレポート完了 ✅", 3)
end

-- Grab All
local function sdGrabAll()
    if not SetNetworkOwner then
        Library:Notify("SetNetworkOwnerが見つかりません", 3)
        return
    end
    local allPlayers = sdGetAllPlayers()
    if #allPlayers == 0 then
        Library:Notify("対象プレイヤーがいません", 3)
        return
    end
    for _, target in ipairs(allPlayers) do
        local char = target.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() SetNetworkOwner:FireServer(hrp, hrp.CFrame) end)
            end
        end
    end
    Library:Notify("グラブ完了 ✅", 3)
end

-- ============================================================
--  5. GUI ウィンドウ作成
-- ============================================================
local Window = Library:CreateWindow({
    Title = "synapse.lol",
    Footer = "グラブ + Kick + Train + サーバー + プレイヤー + Defence",
    Icon = 73528271282556,
    Center = true,
    AutoShow = true,
    Resizable = true,
    NotifySide = "Right",
    ShowCustomCursor = true,
    ToggleKeybind = Enum.KeyCode.RightShift
})

-- ★★★ タブ定義 ★★★
local MainTab = Window:AddTab("メイン", "home")
local PlayerTab = Window:AddTab("プレイヤー", "user")
local GrabTab = Window:AddTab("グラブ", "hand")
local KickTab = Window:AddTab("Kick", "star")
local TrainTab = Window:AddTab("Train", "train")
local DefenceTab = Window:AddTab("Defence", "shield")
local ServerTab = Window:AddTab("サーバー", "server")
local UISettingsTab = Window:AddTab("UI Settings", "settings")

-- ============================================================
--  6. メインタブ
-- ============================================================
local MainGroup = MainTab:AddLeftGroupbox("メイン機能", "home")
MainGroup:AddLabel("synapse.lol 統合版")
MainGroup:AddLabel("グラブ + Kick(ドリフト統合) + Train + サーバー + プレイヤー + Defence")
MainGroup:AddLabel("各タブから機能を選択してください。")

-- ============================================================
--  7. プレイヤータブ（変更なし）
-- ============================================================
local MoveGroup = PlayerTab:AddLeftGroupbox("移動設定", "user")
MoveGroup:AddSlider("WalkSpeedSlider", {
    Text = "歩く速度",
    Default = 16,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Callback = function(Value) setWalkSpeed(Value) end
})
MoveGroup:AddSlider("JumpPowerSlider", {
    Text = "ジャンプ力",
    Default = 50,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Callback = function(Value) setJumpPower(Value) end
})
MoveGroup:AddSlider("FlySpeedSlider", {
    Text = "飛行速度",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value) flySpeed = Value end
})

local ToggleGroup = PlayerTab:AddRightGroupbox("トグル機能", "user")
ToggleGroup:AddToggle("FlyToggle", {
    Text = "FLY",
    Default = false,
    Callback = function(Value) toggleFly(Value) end
})
ToggleGroup:AddToggle("NoclipToggle", {
    Text = "Noclip",
    Default = false,
    Callback = function(Value) toggleNoclip(Value) end
})
ToggleGroup:AddToggle("InfinityJumpToggle", {
    Text = "Infinity Jump（修正版）",
    Default = false,
    Callback = function(Value) toggleInfinityJump(Value) end
})

-- ============================================================
--  8. グラブタブ（変更なし）
-- ============================================================
local GrabGroup = GrabTab:AddLeftGroupbox("Grab & Throw")
GrabGroup:AddSlider("ThrowStrength", {
    Text = "Throw strength",
    Default = 400,
    Min = 300,
    Max = 100000,
    Rounding = 0,
    Compact = false,
    Callback = function(Value) nageru = Value end
})
GrabGroup:AddToggle("ThrowToggle", {
    Text = "Throw",
    Default = false,
    Callback = function(enabled)
        if enabled then
            strengthConnection = Workspace.ChildAdded:Connect(function(model)
                if model.Name == "GrabParts" then
                    local grabPart = model:WaitForChild("GrabPart", 5)
                    if not grabPart then return end
                    local weld = grabPart:WaitForChild("WeldConstraint", 5)
                    if not weld then return end
                    local partToImpulse = weld.Part1
                    if partToImpulse then
                        local velocityObj = Instance.new("BodyVelocity")
                        velocityObj.Parent = partToImpulse
                        velocityObj.MaxForce = Vector3.zero
                        model:GetPropertyChangedSignal("Parent"):Connect(function()
                            if not model.Parent then
                                local lastInput = UserInputService:GetLastInputType()
                                if lastInput == Enum.UserInputType.MouseButton2 or lastInput == Enum.UserInputType.Touch then
                                    velocityObj.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                    velocityObj.Velocity = Camera.CFrame.LookVector * nageru
                                    Debris:AddItem(velocityObj, 1)
                                else
                                    velocityObj:Destroy()
                                end
                            end
                        end)
                    end
                end
            end)
        else
            if strengthConnection then
                strengthConnection:Disconnect()
                strengthConnection = nil
            end
        end
    end
})

local GrabExploitsGroup = GrabTab:AddRightGroupbox("Grab Exploits", "zap")
GrabExploitsGroup:AddSlider("MasslessSensitivity", {
    Text = "Massless Sensitivity",
    Default = 200,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value) _G.MLSense = Value end
})
GrabExploitsGroup:AddToggle("MasslessGrab", {
    Text = "Massless Grab",
    Default = false,
    Callback = function(v)
        _G.MassLessGrab = v
        if not v then
            if _G.MLConn then _G.MLConn:Disconnect(); _G.MLConn = nil end
            return
        end
        if _G.MLConn then _G.MLConn:Disconnect(); _G.MLConn = nil end
        _G.MLConn = RunService.Heartbeat:Connect(function()
            if not _G.MassLessGrab then return end
            local gp = workspace:FindFirstChild("GrabParts")
            if not gp then return end
            local dp = gp:FindFirstChild("DragPart")
            if not dp then return end
            local ap = dp:FindFirstChild("AlignPosition")
            local ao = dp:FindFirstChild("AlignOrientation")
            if ap then
                ap.Responsiveness = _G.MLSense
                ap.MaxForce = math.huge
                ap.MaxVelocity = math.huge
            end
            if ao then
                ao.Responsiveness = _G.MLSense
                ao.MaxTorque = math.huge
            end
        end)
    end
})
GrabExploitsGroup:AddToggle("KillGrab", {
    Text = "Kill Grab",
    Default = false,
    Callback = function(v)
        if v then
            cons["KillGrab"] = workspace.ChildAdded:Connect(function(c)
                if c.Name == "GrabParts" then
                    local part = c:FindFirstChild("GrabPart") or c:WaitForChild("GrabPart", 1)
                    if part then
                        local weld = part:FindFirstChild("WeldConstraint") or part:WaitForChild("WeldConstraint", 1)
                        if weld and weld.Part1 and weld.Part1.Parent and weld.Part1.Parent:FindFirstChild("HumanoidRootPart") then
                            local hum = weld.Part1.Parent:FindFirstChild("Humanoid")
                            if hum then
                                hum.BreakJointsOnDeath = false
                                hum:ChangeState(Enum.HumanoidStateType.Dead)
                                task.wait(0.1)
                                if DestroyLine then pcall(function() DestroyLine:FireServer(weld.Part1) end) end
                            end
                        end
                    end
                end
            end)
        else
            if cons["KillGrab"] then cons["KillGrab"]:Disconnect(); cons["KillGrab"] = nil end
        end
    end
})
GrabExploitsGroup:AddToggle("SpinGrab", {
    Text = "Spin Grab",
    Default = false,
    Callback = function(v)
        spingrab = v
        if spingrab then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            cons["spingrabConnection"] = workspace.ChildAdded:Connect(function(e)
                if e.Name == "GrabParts" and e:FindFirstChild("GrabPart") then
                    local dragPart = workspace:FindFirstChild("GrabParts") and workspace.GrabParts:FindFirstChild("DragPart")
                    if dragPart then
                        local ao = dragPart:FindFirstChild("AlignOrientation")
                        if ao then ao:Destroy() end
                    end
                    local part1 = e.GrabPart:FindFirstChild("WeldConstraint") and e.GrabPart.WeldConstraint.Part1
                    if part1 and part1.Parent then
                        task.spawn(function()
                            while workspace:FindFirstChild("GrabParts") and spingrab and task.wait() do
                                if part1.Parent then
                                    part1.AssemblyAngularVelocity = Vector3.new(0, spinspeed, 0)
                                else
                                    break
                                end
                            end
                        end)
                    end
                end
            end)
        else
            if cons["spingrabConnection"] then
                cons["spingrabConnection"]:Disconnect()
                cons["spingrabConnection"] = nil
            end
        end
    end
})
GrabExploitsGroup:AddToggle("RagdollGrab", {
    Text = "Ragdoll Grab",
    Default = false,
    Callback = function(v)
        if v then
            local pal, pal2
            local menuGui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("MenuGui")
            if menuGui then
                pal2 = menuGui:WaitForChild("Menu", 5):WaitForChild("TabContents", 5):WaitForChild("ToyDestroy", 5):WaitForChild("Contents", 5).ChildAdded:Connect(function(c)
                    if c.Name == "PalletLightBrown" then
                        pal = c
                        task.wait(0.5)
                        if pal2 then pal2:Disconnect(); pal2 = nil end
                    end
                end)
            end
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HRP = char:WaitForChild("HumanoidRootPart")
            local ragd = spawntoy("PalletLightBrown", HRP.CFrame * CFrame.new(5, 5, 20))
            if not ragd then Library:Notify("Ragdoll Grab: Failed to spawn pallet", 3); return end
            local partt = ragd:WaitForChild("SoundPart", 0.5)
            if not partt then Library:Notify("Ragdoll Grab: SoundPart not found", 3); return end
            ragd.Name = "ragdoll"
            task.spawn(function()
                task.wait(1)
                if pal and pal:FindFirstChild("ViewItemButton") then
                    local ragdollBtn = pal.ViewItemButton:FindFirstChild("NewMessage") and pal.ViewItemButton.NewMessage:Clone()
                    if ragdollBtn then
                        ragdollBtn.Name = "Ragdoll"
                        ragdollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        ragdollBtn.Text = "Ragdoll Grab"
                        ragdollBtn.Visible = true
                        ragdollBtn.Parent = pal.ViewItemButton
                    end
                end
            end)
            repeat task.wait(0.1) until partt:FindFirstChild("PartOwner") or tick() > 5
            if partt.Parent then partt.AssemblyLinearVelocity = Vector3.new(0, 10000, 0) end
            task.spawn(function()
                for _, v in pairs(ragd:GetDescendants()) do
                    if v:IsA("BasePart") then v.Transparency = 1; v.CanCollide = false end
                end
            end)
            cons["rgarab1"] = workspace.ChildAdded:Connect(function(c)
                if c.Name == "GrabParts" then
                    local part = c:FindFirstChild("GrabPart") or c:WaitForChild("GrabPart", 3)
                    if part and part:FindFirstChild("WeldConstraint") and part.WeldConstraint.Part1 then
                        local obj = part.WeldConstraint.Part1
                        task.spawn(function()
                            while workspace:FindFirstChild("GrabParts") and task.wait(0.05) do
                                if obj and obj.Parent and obj.Parent:FindFirstChild("HumanoidRootPart") then
                                    local hum = obj.Parent:FindFirstChild("Humanoid")
                                    if hum and hum:FindFirstChild("Ragdolled") and not hum.Ragdolled.Value then
                                        if partt and partt.Parent then
                                            partt.AssemblyLinearVelocity = Vector3.new(0, 100, 0)
                                            partt.CFrame = obj.Parent.HumanoidRootPart.CFrame
                                            task.wait(0.05)
                                            partt.CFrame = CFrame.new(0, 1e9, 0)
                                        end
                                    end
                                else
                                    break
                                end
                            end
                        end)
                    end
                end
            end)
        else
            if cons["rgarab1"] then cons["rgarab1"]:Disconnect(); cons["rgarab1"] = nil end
            local inv = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
            if inv and inv:FindFirstChild("ragdoll") and DestroyToy then
                pcall(function() DestroyToy:FireServer(inv.ragdoll) end)
            end
        end
    end
})
GrabExploitsGroup:AddToggle("KickGrab", {
    Text = "Kick Grab",
    Default = false,
    Callback = function(v)
        if v then
            cons["KickGrab"] = workspace.ChildAdded:Connect(function(c)
                if c.Name ~= "GrabParts" then return end
                local GrabPart = c:WaitForChild("GrabPart", 0.1)
                if not GrabPart then return end
                task.wait(0.1)
                local weld = GrabPart:FindFirstChild("WeldConstraint")
                if not weld or not weld.Part1 then return end
                local part = weld.Part1
                if part.Parent and Players:FindFirstChild(part.Parent.Name) then
                    task.spawn(function()
                        while GrabPart and GrabPart.Parent and part and part.Parent do
                            if DestroyLine then pcall(function() DestroyLine:FireServer(part) end) end
                            RunService.RenderStepped:Wait()
                            if SetNetOwner then pcall(function() SetNetOwner:FireServer(part, part.CFrame) end) end
                            RunService.RenderStepped:Wait()
                            if DestroyLine then pcall(function() DestroyLine:FireServer(part) end) end
                            RunService.RenderStepped:Wait()
                            if SetNetOwner then pcall(function() SetNetOwner:FireServer(part, part.CFrame) end) end
                            RunService.RenderStepped:Wait()
                            if DestroyLine then pcall(function() DestroyLine:FireServer(part) end) end
                            RunService.RenderStepped:Wait()
                            if SetNetOwner then pcall(function() SetNetOwner:FireServer(part, part.CFrame) end) end
                        end
                    end)
                end
            end)
        else
            if cons["KickGrab"] then cons["KickGrab"]:Disconnect(); cons["KickGrab"] = nil end
        end
    end
})

-- ============================================================
--  9. Kickタブ（GrabKick + ドリフトキック）
-- ============================================================
local GrabKickGroup = KickTab:AddLeftGroupbox("Grab Kick System", "zap")
GrabKickGroup:AddDropdown("GrabKickTarget", {
    Text = "Target Player",
    Values = getGrabKickPlayerList(),
    Default = "",
    Callback = function(selected)
        grabKickTargetName = selected
        grabKickTargetPlayer = getPlayerFromDisplay(selected)
    end
})
GrabKickGroup:AddToggle("GrabKickToggle", {
    Text = "Grab kick (BETA)",
    Default = false,
    Callback = function(enabled) toggleGrabKick(enabled) end
})

local DriftKickGroup = KickTab:AddLeftGroupbox("ドリフトキック", "zap")
DriftKickGroup:AddDropdown("DriftKickTarget", {
    Text = "ターゲット選択",
    Values = getDriftKickPlayerList(),
    Default = "",
    Callback = function(selected)
        driftKickTarget = getPlayerFromDriftSelection(selected)
        if driftKickTarget then
            Library:Notify("ターゲット: " .. driftKickTarget.DisplayName, 2)
        end
    end
})
DriftKickGroup:AddSlider("DriftOrbitRadius", {
    Text = "周回半径",
    Default = 15,
    Min = 5,
    Max = 30,
    Rounding = 0,
    Suffix = "m",
    Callback = function(Value) driftOrbitRadius = Value end
})
DriftKickGroup:AddSlider("DriftOrbitSpeed", {
    Text = "周回速度",
    Default = 30,
    Min = 1,
    Max = 300,
    Rounding = 0,
    Suffix = "x",
    Callback = function(Value) driftOrbitSpeed = Value end
})
DriftKickGroup:AddSlider("DriftSpeedMultiplier", {
    Text = "角度増加倍率",
    Default = 1.0,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Suffix = "倍",
    Callback = function(Value) driftSpeedMultiplier = Value end
})
DriftKickGroup:AddToggle("DriftKickToggle", {
    Text = "ドリフトキック開始",
    Default = false,
    Callback = function(enabled)
        if enabled then startDriftKick() else stopDriftKick() end
    end
})
DriftKickGroup:AddButton({
    Text = "🔄 プレイヤーリスト更新",
    Func = function()
        if Options and Options.DriftKickTarget then
            Options.DriftKickTarget:SetValues(getDriftKickPlayerList())
        end
        Library:Notify("プレイヤーリスト更新完了", 2)
    end
})

local function refreshGrabKickDropdown()
    if Options and Options.GrabKickTarget then
        Options.GrabKickTarget:SetValues(getGrabKickPlayerList())
    end
    if Options and Options.DriftKickTarget then
        Options.DriftKickTarget:SetValues(getDriftKickPlayerList())
    end
end
Players.PlayerAdded:Connect(function() task.wait(0.5); refreshGrabKickDropdown() end)
Players.PlayerRemoving:Connect(refreshGrabKickDropdown)

-- ============================================================
--  10. Trainタブ（変更なし）
-- ============================================================
local TrainSeatGroup = TrainTab:AddLeftGroupbox("座席操作", "seat")
TrainSeatGroup:AddButton({
    Text = "座席ランダムに乗る",
    Func = function() sitOnRandomEmptySeat() end
})

local TrainAutoGroup = TrainTab:AddLeftGroupbox("自動化設定", "settings")
TrainAutoGroup:AddToggle("AutomationToggle", {
    Text = "自動化を有効化",
    Default = false,
    Callback = function(value)
        AutomationEnabled = value
        if value then
            startAutomation()
            startSeatDetection()
            Library:Notify("自動化が有効になりました", 3)
        else
            stopAutomation()
            Library:Notify("自動化が無効になりました", 2)
        end
    end
})
TrainAutoGroup:AddLabel("自動化の動作:")
TrainAutoGroup:AddLabel("有効にすると、列車やシートに乗った時/降りた時に")
TrainAutoGroup:AddLabel("自動で " .. TargetItemName .. " を「出現→持つ→使う→捨てる」します。")
TrainAutoGroup:AddLabel("初めて乗る人は " .. SecondItemName .. " も一緒に出現させて捨てます。")

local TrainPCGroup = TrainTab:AddRightGroupbox("PC用 列車操作", "keyboard")
TrainPCGroup:AddButton({
    Text = "vFly GUI表示",
    Func = function()
        pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/makkurokurosukescript/VFly-gui/refs/heads/main/VFly%20gui'))()
            Library:Notify("vFly GUIが起動しました", 2)
        end)
    end
})
TrainPCGroup:AddLabel("vFly GUIについて:")
TrainPCGroup:AddLabel("別ウィンドウでvFly GUIを起動します。")
TrainPCGroup:AddLabel("WASD+QEで飛行、Noclip機能も使えます。")

-- ============================================================
--  11. Defenceタブ（統合防御システム）
-- ============================================================
local DefenceBasicGroup = DefenceTab:AddLeftGroupbox("基本防御", "shield")
DefenceBasicGroup:AddToggle("AntiGrabToggle", { Text = "Anti Grab", Default = false, Callback = function(v) ToggleAntiGrab(v) end })
DefenceBasicGroup:AddToggle("AntiGrabNRDToggle", { Text = "Anti Grab (No Ragdoll)", Default = false, Callback = function(v) ToggleAntiGrabNRD(v) end })
DefenceBasicGroup:AddToggle("AntiVoidToggle", { Text = "Anti Void", Default = false, Callback = function(v) ToggleAntiVoid(v) end })
DefenceBasicGroup:AddToggle("AntiExplodeToggle", { Text = "Anti Explode", Default = false, Callback = function(v) ToggleAntiExplode(v) end })
DefenceBasicGroup:AddToggle("AntiBurnToggle", { Text = "Anti Burn", Default = false, Callback = function(v) ToggleAntiBurn(v) end })
DefenceBasicGroup:AddToggle("AntiStickyToggle", { Text = "Anti Sticky", Default = false, Callback = function(v) ToggleAntiSticky(v) end })
DefenceBasicGroup:AddToggle("AntiLagToggle", { Text = "Anti Lag", Default = false, Callback = function(v) ToggleAntiLag(v) end })
DefenceBasicGroup:AddToggle("AutoAntiLagToggle", { Text = "Auto Anti Lag", Default = false, Callback = function(v) ToggleAutoAntiLag(v) end })

local DefenceAdvancedGroup = DefenceTab:AddRightGroupbox("高度防御", "shield")
DefenceAdvancedGroup:AddToggle("AntiBananaSitToggle", { Text = "Anti Banana Sit", Default = false, Callback = function(v) ToggleAntiBananaSit(v) end })
DefenceAdvancedGroup:AddToggle("AntiBlobmanKillToggle", { Text = "Anti Blobman Kill", Default = false, Callback = function(v) ToggleAntiBlobmanKill(v) end })
DefenceAdvancedGroup:AddToggle("AntiRagBlobToggle", { Text = "Anti Ragdoll on Blob", Default = false, Callback = function(v) ToggleAntiRagBlob(v) end })
DefenceAdvancedGroup:AddToggle("AntiKickToggle", { Text = "Anti Kick (Shuriken)", Default = false, Callback = function(v) ToggleAntiKick(v) end })
DefenceAdvancedGroup:AddToggle("AntiKickBreakPCLDToggle", { Text = "Anti Kick (Break PCLD)", Default = false, Callback = function(v) ToggleAntiKickBreakPCLD(v) end })
DefenceAdvancedGroup:AddToggle("GodModeToggle", { Text = "GOD MODE (Teleport)", Default = false, Callback = function(v) ToggleGodMode(v) end })
DefenceAdvancedGroup:AddToggle("GucciAntiGrabToggle", { Text = "Gucci Anti-Grab", Default = false, Callback = function(v) ToggleGucci(v) end })

local ToyDropdownValues = {}
for shortName, fullName in pairs(ToyList) do
    table.insert(ToyDropdownValues, shortName)
end
table.sort(ToyDropdownValues)

DefenceAdvancedGroup:AddDropdown("AntiInputLagToy", {
    Text = "Input Lag Item",
    Values = ToyDropdownValues,
    Default = "Burger",
    Callback = function(Value)
        antiInputLagSelectedToy = ToyList[Value] or "FoodHamburger"
        if antiInputLagActive then
            ToggleAntiInputLag(false)
            task.wait(0.1)
            ToggleAntiInputLag(true, antiInputLagSelectedToy)
        end
    end
})
DefenceAdvancedGroup:AddToggle("AntiInputLagToggle", { Text = "Anti Input Lag", Default = false, Callback = function(v) ToggleAntiInputLag(v, antiInputLagSelectedToy) end })
DefenceAdvancedGroup:AddToggle("RemoveAllAntiInputToggle", { Text = "Remove All Anti Input", Default = false, Callback = function(v) ToggleRemoveAllAntiInput(v) end })

-- ============================================================
--  12. ★★★ サーバータブ（旧サーバーキック v2 + 新サーバー破壊 v1） ★★★
-- ============================================================

-- ★★★ サーバーDestroy v2（旧Kickタブのサーバーキック） ★★★
local ServerV2Group = ServerTab:AddLeftGroupbox("サーバーDestroy v2", "server")
ServerV2Group:AddDropdown("ServerKickHeight", {
    Text = "キックモード",
    Values = {"Spawn (地上)", "Heaven (天国)"},
    Default = "Spawn (地上)",
    Callback = function(Value)
        serverKickHeight = (Value == "Heaven (天国)") and "Heaven" or "Spawn"
    end
})
ServerV2Group:AddButton({
    Text = "デストロイ✌️",
    Func = function()
        serverKickDestroy()
    end
})
ServerV2Group:AddButton({
    Text = "ラグ&固定解除🗝",
    Func = function()
        serverKickStop()
    end
})

-- ★★★ サーバーDestroy v1（新サーバー破壊システム） ★★★
local ServerV1Group = ServerTab:AddRightGroupbox("サーバーDestroy v1", "server")

-- Line Lag
ServerV1Group:AddSlider("LineLagLPS", {
    Text = "Line Lag速度",
    Default = 100,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Suffix = "LPS",
    Callback = function(Value)
        serverDestroyLineLagLPS = Value
    end
})
ServerV1Group:AddToggle("LineLagToggle", {
    Text = "Line Lag",
    Default = false,
    Callback = function(v)
        sdToggleLineLag(v, serverDestroyLineLagLPS)
    end
})

-- Packet Lag
ServerV1Group:AddSlider("PacketLagStrength", {
    Text = "Packet 強度",
    Default = 2000,
    Min = 100,
    Max = 60000,
    Rounding = 0,
    Callback = function(Value)
        serverDestroyPacketLagStrength = Value
    end
})
ServerV1Group:AddToggle("PacketLagToggle", {
    Text = "Packet Lag",
    Default = false,
    Callback = function(v)
        sdTogglePacketLag(v, serverDestroyPacketLagStrength)
    end
})

-- Packet Detector
ServerV1Group:AddToggle("PacketDetectorToggle", {
    Text = "Packet Lag検出器",
    Default = false,
    Callback = function(v)
        sdTogglePacketDetector(v)
    end
})

-- Destroy Server
ServerV1Group:AddDropdown("DestroyHeightMode", {
    Text = "破壊高さモード",
    Values = {"Spawn (地上)", "Heaven (天国)"},
    Default = "Spawn (地上)",
    Callback = function(Value)
        sdSetDestroyHeight((Value == "Heaven (天国)") and "Heaven" or "Spawn")
    end
})
ServerV1Group:AddButton({
    Text = "🚀 サーバー破壊実行",
    Func = function()
        sdDestroyServer()
    end
})

-- Blobman Kick All
ServerV1Group:AddButton({
    Text = "🧟 BlobmanキックAll",
    Func = function()
        sdBlobmanKickAll()
    end
})

-- 単発機能
ServerV1Group:AddButton({
    Text = "👢 キックAll（単発）",
    Func = function()
        sdKickAll()
    end
})
ServerV1Group:AddButton({
    Text = "📦 テレポートAll",
    Func = function()
        sdTeleportAll(1000)
    end
})
ServerV1Group:AddButton({
    Text = "🔒 グラブAll",
    Func = function()
        sdGrabAll()
    end
})

-- ============================================================
--  13. UI設定タブ
-- ============================================================
local MenuGroup = UISettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "C",
    NoUI = true,
    Text = "Menu keybind"
})
Library.ToggleKeybind = Options.MenuKeybind

-- ============================================================
--  14. テーマ＆セーブ
-- ============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("synapse.lol_server")
SaveManager:SetFolder("synapse.lol_server")
SaveManager:SetSubFolder("game-config")
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:BuildConfigSection(UISettingsTab)
SaveManager:LoadAutoloadConfig()

Library:Notify("synapse.lol (サーバー完全版) Loaded ✓", 3)
print("synapse.lol (サーバー完全版): Loaded ✓")
