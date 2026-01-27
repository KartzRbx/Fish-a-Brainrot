local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local networker = require(CustomPackages.networker)
local FrientBoostUtils = require(script.Parent.FrientBoostUtils)

local FriendsBoostClient = {
    lastValue = 0,
    activeTween = nil
}

function FriendsBoostClient:init()
    self.networker = networker.client.new("FriendBoostService", self, {
        self.UpdateBoostUI,
    })
end

function FriendsBoostClient:UpdateBoostUI(newValue: number)
    local label = FrientBoostUtils.UI.BoostText
    if not label then return end

    local oldValue = self.lastValue
    self.lastValue = newValue

    -- Cancel previous tween
    if self.activeTween then
        self.activeTween:Stop()
    end

    local duration = 0.5
    local startTime = os.clock()
    
    local animationObject = {
        Stopped = false,
        Stop = function(self) self.Stopped = true end
    }
    self.activeTween = animationObject

    task.spawn(function()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if animationObject.Stopped then
                connection:Disconnect()
                return
            end

            local elapsed = os.clock() - startTime
            local alpha = math.clamp(elapsed / duration, 0, 1)

            local currentDisplayValue = math.floor(oldValue + (newValue - oldValue) * alpha)
            label.Text = "Friend boost: +" .. tostring(currentDisplayValue) .. "%"
            
            if alpha >= 1 then
                connection:Disconnect()
                if self.activeTween == animationObject then
                    self.activeTween = nil
                end
            end
        end)
    end)

    -- Pulse Effect
    local uiScale = label:FindFirstChildWhichIsA("UIScale")
    if uiScale then
        local targetScale = 1.2
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true)
        TweenService:Create(uiScale, tweenInfo, {Scale = targetScale}):Play()
    end
end

return FriendsBoostClient