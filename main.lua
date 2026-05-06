local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- --- UIの作成 ---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CompactMenu"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 160, 0, 80)
MainFrame.Position = UDim2.new(0, 10, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Draggable = true -- スマホで位置を動かせるように
MainFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MainFrame
UIListLayout.Padding = UDim.new(0, 5)

-- --- 機能の変数 ---
local espEnabled = false
local aimEnabled = false

-- --- チェックボックス作成関数 ---
local function createToggle(text, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = MainFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.TextSize = 14
    label.Parent = row

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 20, 0, 20)
    box.Position = UDim2.new(0.75, 0, 0.2, 0)
    box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = ""
    box.Parent = row

    local status = false
    box.MouseButton1Click:Connect(function()
        status = not status
        box.Text = status and "✓" or ""
        callback(status)
    end)
end

-- --- ESP ロジック ---
local function updateESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChild("HighlightESP")
            if espEnabled then
                if not h then
                    h = Instance.new("Highlight")
                    h.Name = "HighlightESP"
                    h.FillColor = Color3.new(1, 0, 0)
                    h.Parent = p.Character
                end
            else
                if h then h:Destroy() end
            end
        end
    end
end

-- --- エイムロック ロジック ---
local function getClosestPlayer()
    local closest = nil
    local dist = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then
                dist = d
                closest = p
            end
        end
    end
    return closest
end

-- --- 実行ループ ---
RunService.RenderStepped:Connect(function()
    if espEnabled then
        updateESP()
    end
    
    if aimEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Character.HumanoidRootPart.Position)
        end
    end
end)

-- --- メニュー項目追加 ---
createToggle("プレイヤーESP", function(state)
    espEnabled = state
    if not state then updateESP() end -- オフ時に消去
end)

createToggle("自動照準", function(state)
    aimEnabled = state
end)

print("Compact Menu Loaded for Mobile")
