-- Imosuke Hub Style: Black Hole & Blitz (flytumm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 古いGUIを削除
if CoreGui:FindFirstChild("ImosukeHub") then CoreGui.ImosukeHub:Destroy() end

-- --- 変数設定 ---
getgenv().BlackHoleActive = false
getgenv().RotationSpeed = 5
getgenv().Radius = 20

-- --- GUI作成 ---
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "ImosukeHub"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 400, 0, 280)
main.Position = UDim2.new(0.5, -200, 0.5, -140)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main)

-- サイドバー
local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 100, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
sidebar.BorderSizePixel = 0
Instance.new("UICorner", sidebar)

local title = Instance.new("TextLabel", sidebar)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "imo hub"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1

-- メインコンテンツ
local container = Instance.new("Frame", main)
container.Size = UDim2.new(1, -110, 1, -10)
container.Position = UDim2.new(0, 105, 0, 5)
container.BackgroundTransparency = 1

local list = Instance.new("UIListLayout", container)
list.Padding = UDim.new(0, 10)

-- ブラックホールボタン
local function createButton(txt, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local bhBtn = createButton("ブラックホール: OFF", function() end)

-- --- ブラックホールロジック (動画の再現) ---
RunService.Heartbeat:Connect(function()
    if getgenv().BlackHoleActive then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        
        local time = tick() * getgenv().RotationSpeed
        local playerList = {}
        
        -- 自分以外の全プレイヤーを取得
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(playerList, p.Character.HumanoidRootPart)
            end
        end
        
        -- 円形に配置して回転させる
        for i, root in ipairs(playerList) do
            local angle = i * (math.pi * 2 / #playerList) + time
            local x = math.cos(angle) * getgenv().Radius
            local z = math.sin(angle) * getgenv().Radius
            
            -- 座標を強制書き換え（ブラックホール中心は自分の位置）
            root.CFrame = myRoot.CFrame * CFrame.new(x, 2, z)
            root.Velocity = Vector3.new(0, 0, 0) -- 逃げられないように速度をゼロに
        end
    end
end)

bhBtn.MouseButton1Click:Connect(function()
    getgenv().BlackHoleActive = not getgenv().BlackHoleActive
    if getgenv().BlackHoleActive then
        bhBtn.Text = "ブラックホール: 起動中"
        bhBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 255)
    else
        bhBtn.Text = "ブラックホール: OFF"
        bhBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

-- 閉じるボタン
local close = Instance.new("TextButton", main)
close.Size = UDim2.new(0, 20, 0, 20)
close.Position = UDim2.new(1, -25, 0, 5)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.BackgroundTransparency = 1
close.MouseButton1Click:Connect(function() sg:Destroy() end)
