local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Main: ScreenGui = PlayerGui.Main
local Level = Main:WaitForChild("Level")

export type level = Frame & {
	Rank: ImageLabel & {
		Images: Folder & {
			Arrow: ImageLabel,
			LoadingBar: ImageLabel,
		},
		Texts: Folder & {
			Last_Rank: TextLabel,
			Next_Rank: TextLabel,
			Percentage: TextLabel,
		},
	},
}

export type level_data = {
	Level: number,
	Experience: number,
	ToNext: number,
}

local LevelUtils = {
	UI = {
		Main = Main,
		Level = Level :: level,
	},
	Origin = {
		Tweens = {
			ArrowTween_Transparency = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			ArrowTween_Position = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		},

		Arrow = {
			OriginPosition = UDim2.new(0.461, 0,1.85, 0),
			TargetPosition = UDim2.new(0.83, 0, 1.85, 0),
		},
	},
}

return {
	LevelUtils = LevelUtils,
}
