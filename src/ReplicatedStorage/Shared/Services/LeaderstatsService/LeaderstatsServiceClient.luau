local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")


local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local formatnumber = require(CustomPackages:WaitForChild("formatnumber"))
local networker = require(CustomPackages:WaitForChild("networker"))
local LeaderstatsServiceUtils = require(ReplicatedStorage.Shared.Services.LeaderstatsService.LeaderstatsServiceUtils)

local LeaderstatsService = {
    lastValues = {} :: {[string]: number},
    activeTweens = {} :: {[string]: {Stop: (any) -> ()}}
}

type LeaderstatsService = typeof(LeaderstatsService) 


function LeaderstatsService.init(self : LeaderstatsService)
    self.networker = networker.client.new("LeaderstatsService", self, {
        self.UpdateCurrencyUIs,
    })

end

function LeaderstatsService.UpdateCurrencyUIs(self : LeaderstatsService, props : LeaderstatsServiceUtils.props)
    if not props then
        return
    end

    local hud = LeaderstatsServiceUtils.getHud()
    if not hud then
        return
    end

    local label : TextLabel?
    local prefix = ""
    local suffix = ""

    if props.InstanceName == 'Money' then
        label = hud.BottomLeftHolder.Currency
        prefix = "$"
    end

    if not label then return end

    local lastValue = self.lastValues[props.InstanceName] or 0
    local newValue = props.NewValue
    self.lastValues[props.InstanceName] = newValue

    if self.activeTweens[props.InstanceName] then
        self.activeTweens[props.InstanceName]:Stop()
    end

    local duration = 0.5
    local startTime = os.clock()
    
    local animationObject = {
        Stopped = false,
        Stop = function(self)
            self.Stopped = true
        end
    }
    self.activeTweens[props.InstanceName] = animationObject

    task.spawn(function()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if animationObject.Stopped then
                connection:Disconnect()
                return
            end

            local elapsed = os.clock() - startTime
            local alpha = math.clamp(elapsed / duration, 0, 1)

            local currentDisplayValue = math.floor(lastValue + (newValue - lastValue) * alpha)
            
            label.Text = prefix .. formatnumber.Simple.Format(currentDisplayValue) .. suffix
            
            if alpha >= 1 then
                connection:Disconnect()
                if self.activeTweens[props.InstanceName] == animationObject then
                    self.activeTweens[props.InstanceName] = nil
                end
            end
        end)
    end)


    local uiScale = label:FindFirstChildWhichIsA("UIScale")
    if uiScale then
        local targetScale = 1.2
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true)
        TweenService:Create(uiScale, tweenInfo, {Scale = targetScale}):Play()
    else
        local originalSize = label.Size
        local targetSize = UDim2.new(
            originalSize.X.Scale * 1.15, originalSize.X.Offset, 
            originalSize.Y.Scale * 1.15, originalSize.Y.Offset
        )
        
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true)
        TweenService:Create(label, tweenInfo, {Size = targetSize}):Play()
    end
end

return LeaderstatsService