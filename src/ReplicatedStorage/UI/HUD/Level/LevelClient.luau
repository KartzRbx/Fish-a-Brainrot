local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local formatnumber = require(ReplicatedStorage.CustomPackages.formatnumber)
local networker = require(ReplicatedStorage.CustomPackages.networker)
local LevelUtilsModule = require(ReplicatedStorage.UI.HUD.Level.LevelUtils)
local LevelUtils = LevelUtilsModule.LevelUtils

local LevelClient = {}

function LevelClient.init(self : LevelClient)
    self.Player = Players.LocalPlayer
    self.PlayerGui = self.Player.PlayerGui
    self.LastLevel = 0

    -- Connections
    self.networker = networker.client.new("LevelServer", self, {
        self.UpdateUI
    })
end

type LevelUtilsModule = typeof(require(ReplicatedStorage.UI.HUD.Level.LevelUtils))
type level = LevelUtilsModule.level
type level_data = LevelUtilsModule.level_data
function LevelClient.UpdateUI(self : LevelClient, LevelData : level_data)
    self.HasUpdatedLevel = false
    self.InAnimation = false

    if LevelData.Level ~= self.LastLevel then
        self.LastLevel = LevelData.Level
        self.HasUpdatedLevel = true
    end

    local UI = LevelUtils.UI.Level.Rank
 
    local Arrow = UI.Images.Arrow
    local LoadingBar = UI.Images.LoadingBar
    local Texts = UI.Texts

    local function UpdateExperienceBar()
        print(LevelData)

        local percent = math.clamp(LevelData.Experience / LevelData.ToNext, 0, 1)
        TweenService:Create(LoadingBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(percent, 0, LoadingBar.Size.Y.Scale, LoadingBar.Size.Y.Offset)
        }):Play()

        if Texts.Percentage then
            Texts.Percentage.Text = string.format("%s/%s", formatnumber.Simple.Format(LevelData.Experience), formatnumber.Simple.Format(LevelData.ToNext))
        end
        if Texts.Last_Rank then
            Texts.Last_Rank.Text = 'Level: '.. tostring(LevelData.Level)
        end
        if Texts.Next_Rank then
            Texts.Next_Rank.Text = 'Level: '.. tostring(LevelData.Level + 1)
        end
    end

    local function ResetParams()
        Arrow.Position = LevelUtils.Origin.Arrow.OriginPosition
        Arrow.Visible = false
    end

    local function UpdateLevelAnim()
        if self.InAnimation then return end
        self.InAnimation = true

        Arrow.ImageTransparency = 1
        Arrow.Visible = true

        local ArrowEnableTween = TweenService:Create(Arrow, LevelUtils.Origin.Tweens.ArrowTween_Transparency, {ImageTransparency = 0})
        ArrowEnableTween:Play()

        local arrowPositionTweenStarted = false
        local function onArrowEnableCompleted(a0)
            if arrowPositionTweenStarted then return end
            arrowPositionTweenStarted = true
            local ArrowPositionTween = TweenService:Create(Arrow, LevelUtils.Origin.Tweens.ArrowTween_Position, {Position = LevelUtils.Origin.Arrow.TargetPosition, ImageTransparency = 1})
            ArrowPositionTween:Play()
            ArrowPositionTween.Completed:Connect(function()
                UpdateExperienceBar()
                self.InAnimation = false
                Arrow.Visible = false
                self.HasUpdatedLevel = false
                ResetParams()
            end)
        end
        ArrowEnableTween.Completed:Connect(onArrowEnableCompleted)
    end

    if self.InAnimation then return end

    
    if self.HasUpdatedLevel then
        UpdateLevelAnim()
    else
        UpdateExperienceBar()
    end
end

function LevelClient.EnableUI(self : LevelClient, Enable : boolean)
    local UI = self.UI :: level
    local Arrow = UI.Images.Arrow

    if Enable then
        UI.Visible = true
        TweenService:Create(UI, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0.96, 0)}):Play()
    else
        local Anim = TweenService:Create(UI, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 1.5, 0)})
        Anim:Play()
        Anim.Completed:Connect(function()
           UI.Visible = false
        end)
    end

end

type LevelClient = typeof(LevelClient) & {
    init : (self : LevelClient) -> nil,
}

return LevelClient