-- FTAP Style Kick Reproduce (flytumm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- --- FTAP設定 ---
local power = 100000       -- 射出力（FTAP風の超高速射出）
local shakeAmount = 3     -- 拘束中のガクガク度
local holdTime = 1.5      -- 射出までの溜め時間

-- 既存GUI削除
if CoreGui:FindFirstChild("FTAP_Kick") then CoreGui.FTAP_Kick:Destroy() end

-- --- GUI作成 ---
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "FTAP_Kick"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 170, 0, 240)
main.Position = UDim2.new(0, 30, 0.4, 0)
main.BackgroundColor3 = Color3.fromRGB(30, 0, 0) -- 警告色っぽい赤黒
main.BorderSizePixel = 2
main.Draggable = true
main.Active = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
title.Text = "FTAP KICK REPRO"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.SourceSansBold

local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 2
local uiList = Instance.new("UIListLayout", scroll)

-- --- FTAP Kick ロジック ---
local function ftapKick(target)
    local char = target.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if root and hum and myRoot then
        -- 1. 拘束フェーズ (FTAP特有の目の前ガクガク)
        local startTime = tick()
        while tick() - startTime < holdTime do
            -- 自分の少し前に固定して激しく揺らす
            local shake = Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1)) * shakeAmount
            root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -4) * CFrame.new(shake)
            root.Velocity = Vector3.new(0, 0, 0)
            
            -- 物理を無効化して逃げられなくする
            hum.Sit = true 
            task.wait()
        end

        -- 2. FTAPエフェクト（爆発音的な視覚効果）
        local exp = Instance.new("Explosion", workspace)
        exp.Position = root.Position
        exp.BlastRadius = 0
        exp.Visible = true

        -- 3. 射出 (Kick)
        hum.Health = 0 -- 死亡判定
        root.Velocity = (myRoot.CFrame.LookVector + Vector3.new(0, 0.5, 0)).Unit * power
    end
end

-- --- プレイヤーリスト ---
local function updateList()
    for _, v in pairs(scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton", scroll)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = "KICK: " .. p.DisplayName
            btn.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", btn)
            
            btn.MouseButton1Click:Connect(function()
                btn.Text = "KICKING..."
                ftapKick(p)
                btn.Text = "KICK: " .. p.DisplayName
            end)
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y)
end

updateList()
Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)
