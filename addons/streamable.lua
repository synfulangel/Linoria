Grim = getgenv().Grim
if Grim.Setup.Loaded then
    local grimUI = Instance.new("ScreenGui")
    grimUI.Name = "GrimUI"
    grimUI.Parent = game.CoreGui
    grimUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "grimUIBlur"
    Blur.Size = 0
    Blur.Parent = game.Lighting
    
    local function tweenGui(uiObject, properties, duration)
        local tweenInfo = TweenInfo.new(duration or 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        local tween = game:GetService("TweenService"):Create(uiObject, tweenInfo, properties)
        tween:Play()
        return tween
    end
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = grimUI
    Title.Size = UDim2.new(0, 230, 0, 50)
    Title.Position = UDim2.new(0.5, -60, 0.5, -25)
    Title.AnchorPoint = Vector2.new(0.4, 0.5)
    Title.BackgroundTransparency = 1
    Title.Text = "grim"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.Font = Enum.Font.SourceSansBold
    
    local ccLabel = Instance.new("TextLabel")
    ccLabel.Name = "CCLabel"
    ccLabel.Parent = Title
    ccLabel.Size = UDim2.new(0, 140, 0, 50)
    ccLabel.Position = UDim2.new(0.54, -10, 0, 0)
    ccLabel.AnchorPoint = Vector2.new(0, 0)
    ccLabel.BackgroundTransparency = 1
    ccLabel.Text = ".cc"
    ccLabel.TextColor3 = Color3.fromRGB(127, 0, 255) -- Changed to purple (RGB: 127, 0, 255)
    ccLabel.TextScaled = true
    ccLabel.Font = Enum.Font.SourceSansBold
    
    local Subtext = Instance.new("TextLabel")
    Subtext.Name = "Subtext"
    Subtext.Parent = grimUI
    Subtext.Size = UDim2.new(0, 300, 0, 20)
    Subtext.Position = UDim2.new(0.5, 0, 0.5, -3)
    Subtext.AnchorPoint = Vector2.new(0.5, 0)
    Subtext.BackgroundTransparency = 1
    Subtext.Text = "The future of Da Hood exploiting."
    Subtext.TextColor3 = Color3.fromRGB(255, 255, 255)
    Subtext.TextScaled = true
    Subtext.Font = Enum.Font.SourceSans
    
    local function showUI()
        tweenGui(Title, { TextTransparency = 0 }, 0.5)
        tweenGui(ccLabel, { TextTransparency = 0 }, 0.5)
        tweenGui(Subtext, { TextTransparency = 0 }, 0.5)
        tweenGui(Blur, { Size = 20 }, 0.5)
    
        wait(5)
    
        local fadeOutTween1 = tweenGui(Title, { TextTransparency = 1 }, 0.5)
        tweenGui(ccLabel, { TextTransparency = 1 }, 0.5)
        tweenGui(Subtext, { TextTransparency = 1 }, 0.5)
        tweenGui(Blur, { Size = 0 }, 0.5)
    
        fadeOutTween1.Completed:Connect(function()
            grimUI:Destroy()
        end)
    end
    
    showUI()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function GlobalChecks(Target)
    if Grim.Checks.Dead then
        if Target.Character.BodyEffects["K.O"].Value then
            return false
        end
    end

    if Grim.Checks.Grabbed then
        if Target.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            return false
        end
    end

    if Grim.Checks.Visible then
        local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        local TargetVisiblePart = Target.Character:FindFirstChild("Head")

        if head and TargetVisiblePart then
            local ray = Ray.new(head.Position, (TargetVisiblePart.Position - head.Position).unit * 9e9)
            local part, position = game.Workspace:FindPartOnRay(ray, LocalPlayer.Character)
            
            if part and part:IsDescendantOf(Target.Character) then
                return true
            else
                return false
            end
        end
    end

    return true
end

local function DrawCamlockFOVCircle()
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = Grim.Camlock.FOV.Thickness or 1
    FOVCircle.Radius = Grim.Camlock.FOV.Radius or 150
    FOVCircle.Color = Grim.Camlock.FOV.Color or Color3.fromRGB(255, 0, 0)
    FOVCircle.Transparency = Grim.Camlock.FOV.Transparency or 0.5
    FOVCircle.Visible = Grim.Camlock.FOV.Visible
    return FOVCircle
end

local function DrawSilentFOVCircle()
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = Grim.Silent.FOV.Thickness or 1
    FOVCircle.Radius = Grim.Silent.FOV.Radius or 150
    FOVCircle.Color = Grim.Silent.FOV.Color or Color3.fromRGB(255, 0, 0)
    FOVCircle.Transparency = Grim.Silent.FOV.Transparency or 0.5
    FOVCircle.Visible = Grim.Silent.FOV.Visible
    return FOVCircle
end

local CamlockFOVCircle = DrawCamlockFOVCircle()
local SilentFOVCircle = DrawSilentFOVCircle()

local function GetClosestTargetToMouse()
    local closestTarget = nil
    local shortestDistance = Grim.Camlock.FOV.Radius 

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Grim.Camlock.HitPart) then
            local TargetPart = player.Character:FindFirstChild(Grim.Camlock.HitPart)
            local ScreenPoint, onScreen = Camera:WorldToScreenPoint(TargetPart.Position)
            
            if onScreen then
                local mouseLocation = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
                local distance = (Vector2.new(ScreenPoint.X, ScreenPoint.Y) - mouseLocation).magnitude
                
                if distance < shortestDistance and GlobalChecks(player) then
                    closestTarget = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestTarget
end

local function GetClosestTargetToMouse_Silent()
    local closestTarget = nil
    local shortestDistance = Grim.Silent.FOV.Radius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Grim.Silent.HitPart) then
            local TargetPart = player.Character:FindFirstChild(Grim.Silent.HitPart)
            local ScreenPoint, onScreen = Camera:WorldToScreenPoint(TargetPart.Position)
            
            if onScreen then
                local mouseLocation = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
                local distance = (Vector2.new(ScreenPoint.X, ScreenPoint.Y) - mouseLocation).magnitude
                
                if distance < shortestDistance and GlobalChecks(player) then
                    closestTarget = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestTarget
end
local function PredictTargetPosition(Target)
    local TargetPart = Target.Character:FindFirstChild(Grim.Camlock.HitPart)
    local Velocity = TargetPart.Velocity
    local RegularPrediction

    if Grim.Camlock.Prediction.AutoPred then
        local ping = tonumber(string.split(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString(), '(')[1])
        RegularPrediction = ping < 130 and (ping / 1000 + 0.037) or (ping / 1000 + 0.033)
    else
        if Grim.Camlock.Prediction.Enable_Axis then
            RegularPrediction = Vector3.new(Grim.Camlock.Prediction.X_Axis, Grim.Camlock.Prediction.Y_Axis, 0)
        else
            RegularPrediction = Grim.Camlock.Prediction.Regular_Prediction
        end
    end

    local PredictedPosition = TargetPart.Position + Velocity * (RegularPrediction or 0)
    return PredictedPosition
end

local SelectedEasing = Grim.Camlock.Smoothness.Easing
local Direction_1 = Grim.Camlock.Smoothness.Direction
local LockedTarget = nil
local function Camlock()
    if Grim.Camlock.Enabled == false then
        LockedTarget = nil
        return
    end
    if not Grim.Camlock.Enabled then
        LockedTarget = nil
        return
    end

    if not LockedTarget then
        LockedTarget = GetClosestTargetToMouse()
    end

    if LockedTarget and GlobalChecks(LockedTarget) then
        local PredictedPosition = PredictTargetPosition(LockedTarget)
        local CameraPosition = Camera.CFrame.Position
        local Direction = (PredictedPosition - CameraPosition).unit
        local TargetPosition = CameraPosition + Direction
        local NewCFrame = CFrame.new(CameraPosition, TargetPosition)
    
        local X_Axis = Grim.Camlock.Smoothness.X_Axis or 0.1
        local Y_Axis = Grim.Camlock.Smoothness.Y_Axis or 0.1

        if LockedTarget.Character.Humanoid.Jump then
            PredictedPosition = PredictedPosition + Vector3.new(0, Grim.Camlock.JumpOffset, 0)
        end
    
        local AirPart = nil
        if LockedTarget and LockedTarget.Character:FindFirstChild(Grim.Camlock.AirPart) then
            local humanoid = LockedTarget.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                AirPart = LockedTarget.Character:FindFirstChild(Grim.Camlock.AirPart)
            end
        end


        if AirPart then
            PredictedPosition = AirPart.Position
        end
    
        local LerpedCFrame = Camera.CFrame:Lerp(NewCFrame, X_Axis, Y_Axis, SelectedEasing, Direction_1)
        Camera.CFrame = LerpedCFrame
    else
        LockedTarget = nil
    end
end

local function SilentAim(tool)
    if tool:IsA("Tool") then
        tool.Activated:Connect(function()
            local closestTarget = GetClosestTargetToMouse_Silent()
            if closestTarget and GlobalChecks(closestTarget) then
                local PredictedPosition
                local RegularPrediction

                if Grim.Silent.Prediction.AutoPred then
                    local ping = tonumber(string.split(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString(), '(')[1])
                    RegularPrediction = ping < 130 and (ping / 1000 + 0.037) or (ping / 1000 + 0.033)
                else
                    if Grim.Silent.Prediction.Enable_Axis then
                        RegularPrediction = Vector3.new(Grim.Silent.Prediction.X_Axis, Grim.Silent.Prediction.Y_Axis, 0)
                    else
                        RegularPrediction = Grim.Silent.Prediction.Regular_Prediction
                    end
                end
                
                if closestTarget.Character:FindFirstChild(Grim.Silent.HitPart) then
                    local TargetPart = closestTarget.Character[Grim.Silent.HitPart]
                    local AirPart = nil

                    if Grim.Silent.AirPart and closestTarget.Character:FindFirstChild(Grim.Silent.AirPart) then
                    local humanoid = closestTarget.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                            AirPart = closestTarget.Character[Grim.Silent.AirPart]
                        end
                    end


                    if AirPart then
                        PredictedPosition = AirPart.Position
                    else
                        PredictedPosition = TargetPart.Position + (TargetPart.Velocity * RegularPrediction)
                        if Grim.Setup.Arg == "MousePosUpdate" then
                            PredictedPosition = PredictedPosition + Vector3.new(25, 100, 25)
                        end
                    end

                    game.ReplicatedStorage[Grim.Setup.Remote]:FireServer(Grim.Setup.Arg, PredictedPosition)
                end
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(SilentAim)
end)

if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(SilentAim)
end 
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Grim.Camlock.Keybind.Bind then
        Grim.Camlock.Enabled = not Grim.Camlock.Enabled
        if not Grim.Camlock.Enabled then
            LockedTarget = nil
        end
        if Grim.Camlock.Enabled then
            LockedTarget = GetClosestTargetToMouse()
        end
    elseif input.KeyCode == Grim.Silent.Keybind.Bind then
        SilentAim()
    end
end)

RunService.RenderStepped:Connect(function()
    Camlock()
    
    if Grim.Camlock.FOV.Visible then
        local mouseLocation = UserInputService:GetMouseLocation()
        CamlockFOVCircle.Position = mouseLocation
        CamlockFOVCircle.Visible = true
    else
        CamlockFOVCircle.Visible = false
    end

    if Grim.Silent.FOV.Visible then
        local mouseLocation = UserInputService:GetMouseLocation()
        SilentFOVCircle.Position = mouseLocation
        SilentFOVCircle.Visible = true
    else
        SilentFOVCircle.Visible = false
    end
end)
