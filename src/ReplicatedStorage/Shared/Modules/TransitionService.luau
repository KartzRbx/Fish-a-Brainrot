local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

local Player = Players.LocalPlayer
local currentCamera = workspace.CurrentCamera

Player.CharacterAdded:Wait()

local PlayerGui = Player.PlayerGui
local TransitionFrame = PlayerGui:WaitForChild('Main'):WaitForChild('Transition') :: Frame
local Circle = TransitionFrame:WaitForChild('Circle') :: Frame

local T_Info = TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

local TransitionService = {}

function TransitionService.Apply(WaitDuration : number)
    print('Animação sendo chamada')
    TransitionService.Enable()
    task.wait(WaitDuration)
    TransitionService.Disable()
end

function TransitionService.Enable()
    Circle.Visible = true
    TweenService:Create(Circle, T_Info, {Size = UDim2.fromScale(2, 2)}):Play()
    TweenService:Create(currentCamera, T_Info, {FieldOfView = 50}):Play()
    
end

function TransitionService.Disable()
    local tween  = TweenService:Create(Circle, T_Info, {Size = UDim2.fromScale(0, 0)})
    TweenService:Create(currentCamera, T_Info, {FieldOfView = 70}):Play()
    tween:Play()

    tween.Completed:Connect(function()
        task.wait()
        Circle.Visible = false
    end)
end

return TransitionService