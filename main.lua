local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- --- 設定 ---
getgenv().AutoLaunch = false
getgenv().LaunchPower = 200000 -- 飛ばす威力（さらに強化）
getgenv().GrabTime = 0.5        -- 何秒間掴んでから放出するか

-- 古いGUIを削除
if CoreGui:FindFirstChild("AutoLaunchHub") then CoreGui.AutoLaunchHub:Destroy() end

-- --- GUI作成 (imosuke hub風) ---
local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "AutoLaunchHub"

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 200, 0, 100)
main.Position = UDim2.new(0.5, -100, 0.5, -50)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(255, 0, 0)
stroke.Thickness = 2

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "AUTO LAUNCHER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1

local toggleBtn = Instance.new("TextButton", main)
toggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
toggleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = "自動放出: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", toggleBtn)

-- --- 自動放出ロジック ---
local processing = {} -- 二重処理防止用

RunService.RenderStepped:Connect(function()
    if getgenv().AutoLaunch then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and not processing[p] then
                local tRoot = p.Character.HumanoidRootPart
                local dist = (tRoot.Position - myRoot.Position).Magnitude
                
                -- 範囲内に入ったら自動処理開始
                if dist < 25 then
                    processing[p] = true
                    task.spawn(function()
                        -- 1. 瞬間的に掴んで固定
                        local startTime = tick()
                        while tick() - startTime < getgenv().GrabTime do
                            tRoot.CFrame = myRoot.CFrame * CFrame.new(0, 2, -7)
                            tRoot.Velocity = Vector3.new(0, 0, 0)
                            task.wait()
                        end
                        
                        -- 2. 自動放出！
                        tRoot.Velocity = (myRoot.CFrame.LookVector + Vector3.new(0, 0.5, 0)).Unit * getgenv().LaunchPower
                        
                        -- 3. クールタイム（連続で掴み続けないように）
                        task.wait(0.5)
                        processing[p] = nil
                    end)
                end
            end
        end
    end
end)

-- スイッチ
toggleBtn.MouseButton1Click:Connect(function()
    getgenv().AutoLaunch = not getgenv().AutoLaunch
    if getgenv().AutoLaunch then
        toggleBtn.Text = "自動放出: 稼働中"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        stroke.Color = Color3.fromRGB(255, 255, 0)
    else
        toggleBtn.Text = "自動放出: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        stroke.Color = Color3.fromRGB(255, 0, 0)
    end
end)
