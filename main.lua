-- Delta用: ターゲット限定・高速掴み直し再現 (flytumm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().TargetPlayer = nil

-- チャットでターゲットを指定
LocalPlayer.Chatted:Connect(function(msg)
    local args = string.split(msg, " ")
    if args[1] == "/target" and args[2] then
        for _, p in pairs(Players:GetPlayers()) do
            if string.find(p.Name:lower(), args[2]:lower()) or string.find(p.DisplayName:lower(), args[2]:lower()) then
                getgenv().TargetPlayer = p
                print("Locked: " .. p.DisplayName)
                break
            end
        end
    elseif msg == "/unlocked" then
        getgenv().TargetPlayer = nil
        print("Unlocked")
    end
end)

RunService.RenderStepped:Connect(function()
    local target = getgenv().TargetPlayer
    if not target or not target.Character then return end
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("LowerTorso"))
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
    
    if myRoot and tRoot then
        -- 超高速掴み直し再現（自分だけの画面で実行）
        local shake = Vector3.new(math.random(-4, 4), 2, math.random(-4, 4))
        tRoot.CFrame = myRoot.CFrame * CFrame.new(0, 10, -5) * CFrame.new(shake)
        tRoot.Velocity = Vector3.new(0, 0, 0)
        myRoot.Velocity = Vector3.new(0, -10, 0) -- 地面固定
    end
end)
