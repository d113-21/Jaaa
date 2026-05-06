-- Delta用: 本家Blitz再現スクリプト (flytumm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- --- Blitz設定 ---
local blitzRange = 100    -- 索敵範囲
local hitCount = 20       -- 一撃あたりの連撃数
local dashSpeed = 0.03    -- テレポートの間隔
getgenv().BlitzActive = false

-- 既存GUI削除
if CoreGui:FindFirstChild("DeltaBlitz") then CoreGui.DeltaBlitz:Destroy() end

-- --- GUI作成 ---
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "DeltaBlitz"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 160, 0, 100)
main.Position = UDim2.new(0, 50, 0.5, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
title.Text = "DELTA BLITZ v2"
title.TextColor3 = Color3.fromRGB(255, 255, 255)

local btn = Instance.new("TextButton", main)
btn.Size = UDim2.new(0.9, 0, 0, 50)
btn.Position = UDim2.new(0.05, 0, 0.4, 0)
btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btn.Text = "START BLITZ"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- --- Blitzコアロジック ---
local function doBlitz(target)
    local char = target.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if root and myRoot then
        for i = 1, hitCount do
            if not getgenv().BlitzActive then break end
            
            -- 相手の前後左右に超高速ワープ
            local offsets = {
                Vector3.new(0, 0, 5), Vector3.new(0, 0, -5),
                Vector3.new(5, 0, 0), Vector3.new(-5, 0, 0),
                Vector3.new(3, 3, 3), Vector3.new(-3, 3, -3)
            }
            local offset = offsets[math.random(1, #offsets)]
            
            -- 相手を自分の位置に引き寄せて固定（掴み直し再現）
            root.CFrame = myRoot.CFrame * CFrame.new(offset)
            root.Velocity = Vector3.new(0, 0, 0)
            
            -- エフェクト（青い閃光）
            local p = Instance.new("Part", workspace)
            p.Anchored = true
            p.CanCollide = false
            p.Size = Vector3.new(0.5, 10, 0.5)
            p.CFrame = root.CFrame
            p.Color = Color3.fromRGB(0, 255, 255)
            p.Material = Enum.Material.Neon
            task.delay(0.05, function() p:Destroy() end)
            
            task.wait(dashSpeed)
        end
        -- 最後に吹き飛ばす
        root.Velocity = Vector3.new(0, 500, 0)
    end
end

-- --- トグル切り替え ---
btn.MouseButton1Click:Connect(function()
    getgenv().BlitzActive = not getgenv().BlitzActive
    if getgenv().BlitzActive then
        btn.Text = "BLITZING..."
        btn.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        
        -- 最も近いプレイヤーを探してBlitz開始
        while getgenv().BlitzActive do
            local closest = nil
            local dist = blitzRange
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        closest = p
                    end
                end
            end
            if closest then doBlitz(closest) end
            task.wait(0.1)
        end
    else
        btn.Text = "START BLITZ"
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)
