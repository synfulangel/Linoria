local Grim = getgenv().Grim

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Vector3New = Vector3.new
local UDim2New = UDim2.new
local Color3New = Color3.new
local LockedTarget = nil

local function GlobalChecks(Target)
    local Character = Target.Character
    if Grim.Checks.Dead and Character.BodyEffects["K.O"].Value then return false end
    if Grim.Checks.Grabbed and Character:FindFirstChild("GRABBING_CONSTRAINT") then return false end
    if Grim.Checks.Visible then
        local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        local TargetVisiblePart = Character:FindFirstChild("Head")
        if head and TargetVisiblePart then
            local ray = Ray.new(head.Position, (TargetVisiblePart.Position - head.Position).unit * (TargetVisiblePart.Position - head.Position).magnitude)
            local part = game.Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            return part and part:IsDescendantOf(Character)
        end
        return false
    end
    return true
end

local function DrawFOVCircle(FOVConfig)
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = FOVConfig.Thickness or 1
    FOVCircle.Radius = FOVConfig.Radius
    FOVCircle.Color = FOVConfig.Color or Color3New(255, 0, 0)
    FOVCircle.Transparency = FOVConfig.Transparency or 0.5
    FOVCircle.Visible = FOVConfig.Visible
    FOVCircle.Filled = false
    return FOVCircle
end

local CamlockFOVCircle = DrawFOVCircle(Grim.Camlock.FOV)
local SilentFOVCircle = DrawFOVCircle(Grim.Silent.FOV)

local function GetClosestTargetToMouse(FOVConfig, HitPart)
    local closestTarget, shortestDistance = nil, FOVConfig.Radius
    local mouseLocation = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(HitPart) then
            local TargetPart = player.Character:FindFirstChild(HitPart)
            local ScreenPoint, onScreen = Camera:WorldToScreenPoint(TargetPart.Position)
            if onScreen then
                local distance = (Vector2.new(ScreenPoint.X, ScreenPoint.Y) - mouseLocation).magnitude
                if distance < shortestDistance and GlobalChecks(player) then
                    closestTarget, shortestDistance = player, distance
                end
            end
        end
    end

    return closestTarget
end

local function PredictTargetPosition(Target)
    local TargetPart = Target.Character:FindFirstChild(Grim.Camlock.HitPart)
    local Velocity = TargetPart.Velocity
    local ping = tonumber(string.split(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString(), '(')[1])
    local RegularPrediction = Grim.Camlock.Prediction.AutoPred and (ping < 130 and (ping / 1000 + 0.037) or (ping / 1000 + 0.033)) or Grim.Camlock.Prediction.Regular_Prediction
    local PredictedPosition = TargetPart.Position + Velocity * (RegularPrediction or 0)

    local AirPart = Target.Character:FindFirstChild(Grim.Camlock.AirPart)
    if AirPart and Target.Character.Humanoid.FloorMaterial == Enum.Material.Air then
        PredictedPosition = AirPart.Position
    end

    return PredictedPosition
end

local sgg = Instance.new("ScreenGui", game.CoreGui)
local wm = Instance.new("TextLabel", sgg)
wm.Size = UDim2New(0, 200, 0, 20)
wm.TextColor3 = Color3New(1, 1, 1)
wm.BackgroundTransparency = 1
wm.TextTransparency = 0.6
wm.Font = Enum.Font.Code
wm.TextSize = 14
wm.Text = "grim.cc : streamable"
wm.TextStrokeTransparency = 0.8
wm.Visible = false

local function updateWatermarkPosition()
    local Mouse = LocalPlayer:GetMouse()
    wm.Position = UDim2New(0, Mouse.X - wm.AbsoluteSize.X / 2, 0, Mouse.Y + 25)
end

RunService.RenderStepped:Connect(function()
    if Grim.Setup.Watermark then
        updateWatermarkPosition()
    end
end)

local function Camlock()
    if not Grim.Camlock.Enabled then
        LockedTarget = nil
        return
    end
    if not LockedTarget then
        LockedTarget = GetClosestTargetToMouse(Grim.Camlock.FOV, Grim.Camlock.HitPart)
    end
    if LockedTarget and GlobalChecks(LockedTarget) then
        local PredictedPosition = PredictTargetPosition(LockedTarget)
        local CamPos = Camera.CFrame.Position
        local Direction = (PredictedPosition - CamPos).unit
        local TargetPosition = CamPos + Direction
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(CamPos, TargetPosition), Grim.Camlock.Smoothness.X_Axis or 0.1, Grim.Camlock.Smoothness.Y_Axis or 0.1)
    else
        LockedTarget = nil
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Grim.Camlock.Keybind.Bind then
        Grim.Camlock.Enabled = not Grim.Camlock.Enabled
        LockedTarget = Grim.Camlock.Enabled and GetClosestTargetToMouse(Grim.Camlock.FOV, Grim.Camlock.HitPart) or nil
    elseif input.KeyCode == Grim.Silent.Keybind.Bind then
        Grim.Silent.Enabled = not Grim.Silent.Enabled
    end
end)

local function SilentAim(tool)
    if tool:IsA("Tool") then
        tool.Activated:Connect(function()
            if not Grim.Silent.Enabled then return end

            local closestTarget = GetClosestTargetToMouse(Grim.Silent.FOV, Grim.Silent.HitPart)
            if closestTarget and GlobalChecks(closestTarget) then
                local Target = closestTarget.Character
                local TargetPart = Target[Grim.Silent.HitPart]
                local Velocity = TargetPart.Velocity
                local ping = tonumber(string.split(Stats.Network.ServerStatsItem["Data Ping"]:GetValueString(), '(')[1])
                local RegularPrediction = Grim.Silent.Prediction.AutoPred and (ping < 130 and (ping / 1000 + 0.037) or (ping / 1000 + 0.033)) or Grim.Silent.Prediction.Regular_Prediction
                local PredictedPosition = TargetPart.Position + Velocity * RegularPrediction

                local AirPart = Target:FindFirstChild(Grim.Silent.AirPart)
                if AirPart and Target.Humanoid.FloorMaterial == Enum.Material.Air then
                    PredictedPosition = AirPart.Position
                end

                tool.Grip = CFrame.new(TargetPart.Position, PredictedPosition)
            end
        end)
    end
end

LocalPlayer.Backpack.ChildAdded:Connect(SilentAim)

RunService.RenderStepped:Connect(function()
    if Grim.Silent.Enabled then
        local closestTarget = GetClosestTargetToMouse(Grim.Silent.FOV, Grim.Silent.HitPart)
        if closestTarget and GlobalChecks(closestTarget) then
            SilentFOVCircle.Visible = true
            local ScreenPoint, onScreen = Camera:WorldToScreenPoint(closestTarget.Character[Grim.Silent.HitPart].Position)
            if onScreen then
                SilentFOVCircle.Position = Vector2.new(ScreenPoint.X, ScreenPoint.Y)
            end
        else
            SilentFOVCircle.Visible = false
        end
    else
        SilentFOVCircle.Visible = false
    end

    if Grim.Camlock.Enabled then
        CamlockFOVCircle.Visible = true
        Camlock()
    else
        CamlockFOVCircle.Visible = false
    end
end)
