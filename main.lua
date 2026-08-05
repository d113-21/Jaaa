-- LocalScript（StarterPlayerScripts または ツール内）
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- OlionLibraryをロード（あらかじめReplicatedStorageなどに親として入れておく）
local Olion = loadstring(game:HttpGet("https://raw.githubusercontent.com/olionlibraries/OlionLibrary/main/source.lua"))()

-- ラグ設定
local lagEnabled = false
local lagStrength = 0.1
local cpuIntensity = 1000

-- ウィンドウ作成
local window = Olion:CreateWindow({
    Name = "FTAP Lag Tool",
    Size = UDim2.new(0, 400, 0, 300),
    Theme = "Dark"
})

-- メインタブ
local mainTab = window:CreateTab({
    Name = "Main"
})

-- トグル（ラグON/OFF）
mainTab:CreateToggle({
    Name = "Lag ON/OFF",
    Default = false,
    Callback = function(state)
        lagEnabled = state
        print("ラグ状態: " .. tostring(lagEnabled))
    end
})

-- スライダー（ラグ強度）
mainTab:CreateSlider({
    Name = "Lag Strength",
    Min = 0.02,
    Max = 0.5,
    Default = 0.1,
    Callback = function(value)
        lagStrength = value
    end
})

-- スライダー（CPU負荷）
mainTab:CreateSlider({
    Name = "CPU Intensity",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Callback = function(value)
        cpuIntensity = value
    end
})

-- ラグ処理（Heartbeat）
RunService.Heartbeat:Connect(function(deltaTime)
    if lagEnabled then
        task.wait(lagStrength)
        local dummy = 0
        for i = 1, cpuIntensity do
            dummy = dummy + math.sqrt(i * math.pi)
        end
    end
end)
