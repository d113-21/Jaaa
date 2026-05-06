-- Delta用: 演出強化版 Target Kill (flytumm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- --- 設定 ---
local launchPower = 35000
local liftHeight = 20
getgenv().TargetPlayer = nil

-- 既存GUI削除
if CoreGui:FindFirstChild("SkullKillGui") then CoreGui.SkullKillGui:Destroy() end

-- --- GUI作成 ---
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "SkullKillGui"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 150, 0, 200)
main.Position = UDim2.new(0, 50, 0.4, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BackgroundTransparency = 0.2
main.Draggable = true
main.Active = true

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(150, 0, 255)
title.Text = "SKULL KILLER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)

local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, 0, 1, -30)
scroll.Position = UDim2.new(0, 0, 0, 30)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 3

local uiList = Instance.new("UIListLayout", scroll)

-- --- 演出：ドクロと黒いエフェクト ---
local function playSkullEffect(pos)
    local part = Instance.new("Part", workspace)
    part.Anchored = true
    part.CanCollide = false
    part.Position = pos + Vector3.new(0, 5, 0)
    part.Transparency = 1
    
    local attachment = Instance.new("Attachment", part)
    local skull = Instance.new("BillboardGui", attachment)
    skull.Size = UDim2.new(10, 0, 10, 0)
    skull.AlwaysOnTop = true
    
    local img = Instance.new("ImageLabel", skull)
    img.Size = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://6031063035" -- ドクロのID
    
    task.delay(1, function() part:Destroy() end)
end

-- --- キル実行 ---
local function killTarget(target)
    if target and target.Character then
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            playSkullEffect(root.Position) -- ドクロ出現
            
            -- 高速掴み直し演出（一瞬）
            for i = 1, 10 do
                root.CFrame = root.CFrame * CFrame.new(math.random(-5,5), 2, math.random(-5,5))
                task.wait(0.01)
            end
            
            -- 爆破リリース
            target.Character:BreakJoints()
            root.Velocity = Vector3.new(0, launchPower, 0)
        end
    end
end

-- --- リスト更新 ---
local function updateList()
    for _, v in pairs(scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton", scroll)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = p.DisplayName
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.MouseButton1Click:Connect(function() killTarget(p) end)
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y)
end

updateList()
Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)
