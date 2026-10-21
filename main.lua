local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Trigger = {
    Holding = false
}

local humanoidSize = 40

-- whitelist: players in this table are IGNORED by the triggerbot
local IgnoreList = {}

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
params.IgnoreWater = true

local function GetGun()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then
            return v
        end
    end
end

-- simple GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TriggerWhitelist"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 300)
Frame.Position = UDim2.new(0, 20, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "Ignore List"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -10, 1, -40)
Scrolling.Position = UDim2.new(0, 5, 0, 35)
Scrolling.BackgroundTransparency = 1
Scrolling.ScrollBarThickness = 4
Scrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
Scrolling.Parent = Frame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 4)
UIList.Parent = Scrolling

local function RefreshList()
    for _, child in ipairs(Scrolling:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local y = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.BackgroundColor3 = IgnoreList[plr.Name] and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(50, 50, 50)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
            btn.Parent = Scrolling

            btn.MouseButton1Click:Connect(function()
                if IgnoreList[plr.Name] then
                    IgnoreList[plr.Name] = nil
                    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                else
                    IgnoreList[plr.Name] = true
                    btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
                end
            end)

            y = y + 32
        end
    end
    Scrolling.CanvasSize = UDim2.new(0, 0, 0, y)
end

Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(function(plr)
    IgnoreList[plr.Name] = nil
    RefreshList()
end)
RefreshList()

-- toggle GUI with RightShift
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Frame.Visible = not Frame.Visible
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Y then
        Trigger.Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Y then
        Trigger.Holding = false
    end
end)

RunService.RenderStepped:Connect(function()
    if not Trigger.Holding then return end

    local char = LocalPlayer.Character
    if not char then return end
    params.FilterDescendantsInstances = { char }

    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not result then return end

    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if not model or model == char then return end

    -- whitelist check
    local targetPlayer = Players:GetPlayerFromCharacter(model)
    if targetPlayer and IgnoreList[targetPlayer.Name] then
        return
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local rayOrigin = Camera.CFrame.Position
    local rayDir = (result.Position - rayOrigin).Unit
    local toCenter = root.Position - rayOrigin
    local projection = rayDir:Dot(toCenter)
    local closestPoint = rayOrigin + rayDir * projection

    if (closestPoint - root.Position).Magnitude > humanoidSize then return end

    local gun = GetGun()
    if not gun then return end

    gun:Activate()
end)
