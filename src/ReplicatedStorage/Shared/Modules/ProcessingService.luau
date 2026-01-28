local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local _currentCamera = workspace.CurrentCamera

Player.CharacterAdded:Wait()

local T_Info = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local PlayerGui = Player.PlayerGui
local Main = PlayerGui:WaitForChild("Main")
local ProcessFrame = Main:WaitForChild("Process") :: Frame
local CircleBar = ProcessFrame:WaitForChild("CircleBar") :: ImageLabel
local Blur = Lighting:FindFirstChild("Blur")

local ProcessingService = {}
local RotatingConnection
local FPS = 1 / 30
local ROTATE_VELOCITY = 4

function ProcessingService.Enable()
	ProcessingService.Disable()

	CircleBar.Rotation = 0

	local Accumulator = 0
	RotatingConnection = RunService.PreRender:Connect(function(Delta: number)
		Accumulator += Delta
		if Accumulator <= FPS then
			return
		end
		Accumulator = 0

		CircleBar.Rotation += ROTATE_VELOCITY
	end)

	ProcessFrame.Visible = true

	TweenService:Create(CircleBar, T_Info, { ImageTransparency = 0 }):Play()
	TweenService:Create(ProcessFrame, T_Info, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(Blur, T_Info, { Size = 10 }):Play()
end

function ProcessingService.Disable()
	if RotatingConnection then
		RotatingConnection:Disconnect()
		RotatingConnection = nil
	end

	TweenService:Create(CircleBar, T_Info, { ImageTransparency = 1 }):Play()
	TweenService:Create(ProcessFrame, T_Info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(Blur, T_Info, { Size = 0 }):Play()

	ProcessFrame.Visible = false
end

return ProcessingService
