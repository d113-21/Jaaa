-- Delta用: 本家Blitz再現スクリプト 日本語版 (flytumm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- --- Blitz設定 ---
local blitzRange = 100    -- 索敵範囲（この範囲内の人を自動で狙う）
local hitCount = 25       -- 攻撃回数（多いほど長くボコボコにする）
local dashSpeed = 0.02    -- 移動速度（小さいほど高速）
getgenv().BlitzActive = false

-- 既存GUI削除
if CoreGui:FindFirstChild("DeltaBlitzJP") then CoreGui.DeltaBlitzJP:Destroy() end

-- --- GUI作成 ---
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "DeltaBlitzJP"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 180, 0, 110)
main.Position = UDim2.new(0, 50, 0.5, 0)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
title.Text = "デルタ・ブリッツ"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local btn = Instance.new("TextButton", main)
btn.Size = UDim2.new(0.9, 0, 0, 50)
btn.Position = UDim2.new(0.05, 0, 0.45, 0)
btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btn.Text = "ブリッツ開始"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.TextSize = 18
btn.Font = Enum.Font.SourceSansBold
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

-- --- Blitzコアロジック ---
local function doBlitz(target)
    local char = target.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if root and myRoot then
        for i = 1, hitCount do
            if not getgenv().BlitzActive then break end
            
            -- 相手の周りにランダムテレポート
            local offsets = {
                Vector3.new(0, 2, 6), Vector3.new(0, 2, -6),
                Vector3.new(6, 2, 0), Vector3.new(-6, 2, 0),
                Vector3.new(4, 5, 4), Vector3.new(-4, 1, -4)
            }
            local offset = offsets[math.random(1, #offsets)]
            
            -- 高速掴み直し
            root.CFrame = myRoot.CFrame * CFrame.new(offset)
            root.Velocity = Vector3.new(0, 0, 0)
            
            -- 青い閃光エフェクト
            local p = Instance.new("Part", workspace)
            p.Anchored = true
            p.CanCollide = false
            p.Size = Vector3.new(0.3, 15, 0.3)
            p.CFrame = root.CFrame
            p.Color = Color3.fromRGB(0, 255, 255)
            p.Material = Enum.Material.Neon
            task.delay(0.05, function() p:Destroy() end)
            
            task.wait(dashSpeed)
        end
        -- 最後に空へ飛ばす
        root.Velocity = Vector3.new(0, 600, 0)
    end
end

-- --- ボタン切り替え ---
btn.MouseButton1Click:Connect(function()
