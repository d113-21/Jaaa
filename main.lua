local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- --- 設定 ---
getgenv().BlobmanKill = false

-- 既存GUI削除
if CoreGui:FindFirstChild("BlobmanEx") then CoreGui.BlobmanEx:Destroy() end

-- --- GUI作成 ---
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "BlobmanEx"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 200, 0, 100)
main.Position = UDim2.new(0.5, -100, 0.5, -50)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main)

-- ラベル
local label = Instance.new("TextLabel", main)
label.Size = UDim2.new(0, 100, 0, 40)
label.Position = UDim2.new(0, 20, 0.5, -20)
label.Text = "Loop Kill"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextXAlignment = Enum.TextXAlignment.Left
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.BackgroundTransparency = 1

-- チェックボックス（四角）
local checkbox = Instance.new("TextButton", main)
checkbox.Size = UDim2.new(0, 30, 0, 30)
checkbox.Position = UDim2.new(1, -50, 0.5, -15)
checkbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
checkbox.Text = "" -- 最初は空
checkbox.TextColor3 = Color3.fromRGB(255, 255, 255)
checkbox.Font = Enum.Font.GothamBold
checkbox.TextSize = 22
Instance.new("UICorner", checkbox).CornerRadius = UDim.new(0, 6)

-- 枠線
local stroke = Instance.new("UIStroke", checkbox)
stroke.Color = Color3.fromRGB(100, 100, 100)
stroke.Thickness = 2

-- --- ループキル・ロジック ---
local function doLoopKill()
    while getgenv().BlobmanKill do
        local character = LocalPlayer.Character
        -- Blobmanアイテムを装備しているか確認
        local blobItem = character and (character:FindFirstChild("Blobman") or LocalPlayer.Backpack:FindFirstChild("Blobman"))
        
        if blobItem then
            -- 全プレイヤーを対象
            for _, target in pairs(Players:GetPlayers()) do
                if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("Humanoid") then
                    -- Blobmanの攻撃（Activate）を実行
                    if blobItem.Parent ~= character then
                        blobItem.Parent = character -- 未装備なら手に持つ
                    end
                    blobItem:Activate()
                end
            end
        end
        task.wait(0.05) -- 超高速ループ
    end
end

-- --- チェックボックスの切り替え ---
checkbox.MouseButton1Click:Connect(function()
    getgenv().BlobmanKill = not getgenv().BlobmanKill
    
    if getgenv().BlobmanKill then
        -- ON: チェックマークを付けて青くする
        checkbox.Text = "✓"
        checkbox.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
        stroke.Color = Color3.fromRGB(0, 180, 255)
        task.spawn(doLoopKill)
    else
        -- OFF: チェックを消してグレーに戻す
        checkbox.Text = ""
        checkbox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        stroke.Color = Color3.fromRGB(100, 100, 100)
    end
end)
