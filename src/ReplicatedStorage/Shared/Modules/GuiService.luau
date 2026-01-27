local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

local Blur = Lighting:WaitForChild('Blur')

-- Configuration
local CONFIG = {
	Blur = {
		Default = 1.25,
		Show = 12
	},
	FOV = {
		Default = 70,
		Show = 60
	},
	TweenInfo = {
		Enable = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		Disable = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	},
	Debounce = {
		Duration = 0.5
	},
	Animation = {
		Duration = 0.4
	}
}

-- Services
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild('PlayerGui')
local Main = PlayerGui:WaitForChild('Main')
local Center = Main:WaitForChild('Center')

local ENABLE_UI_SOUND = ReplicatedStorage.Assets.Sounds.Window

-- GuiService Class
local GuiService = {}
GuiService.__index = GuiService

-- Private Properties
local ActiveUIs = {}
local IsDebounced = false
local CurrentTweens = {}

-- Private Methods
local function SetDebounce()
	if IsDebounced then 
		return true 
	end

	IsDebounced = true
	task.delay(CONFIG.Debounce.Duration, function()
		IsDebounced = false
	end)

	return false
end

local function CleanupTweens()
	for _, tween in pairs(CurrentTweens) do
		if tween and tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Cancel()
		end
	end
	table.clear(CurrentTweens)
end

local function PlayTween(instance, tweenInfo, properties)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	table.insert(CurrentTweens, tween)
	tween:Play()
	return tween
end

local function ValidateUI(guiName: string): (boolean, string?)
	if not guiName or guiName == "" then
		return false, "GUI name cannot be empty"
	end

	local gui = Center:FindFirstChild(guiName)
	if not gui then
		return false, "UI not found: " .. guiName
	end

	if not gui:IsA('Frame') and not gui:IsA('CanvasGroup') then
		return false, "UI must be a Frame or CanvasGroup"
	end

	return true, nil
end

-- Public Methods
function GuiService.OpenUI(guiName: string): (boolean, string?)
	if SetDebounce() then 
		return false, "Please wait before opening another UI" 
	end

	local isValid, errorMsg = ValidateUI(guiName)
	if not isValid then
		return false, errorMsg
	end

	if ActiveUIs[guiName] then
		return false, "UI is already opened: " .. guiName
	end

	-- Close other UIs first
	GuiService.CloseAll()

	-- Mark as active
	ActiveUIs[guiName] = true

	-- Apply visual effects
	PlayTween(Blur, CONFIG.TweenInfo.Enable, {Size = CONFIG.Blur.Show})
	PlayTween(workspace.CurrentCamera, CONFIG.TweenInfo.Enable, {FieldOfView = CONFIG.FOV.Show})

	-- Play sound
	if ENABLE_UI_SOUND then
		PlayTween(ENABLE_UI_SOUND, CONFIG.TweenInfo.Enable, {Volume = 1})
		ENABLE_UI_SOUND:Play()
	end

	-- Show UI
	local gui = Center[guiName]
	gui.Position = UDim2.new(0.5, 0, -1, 0)
	gui.Visible = true
	gui:TweenPosition(
		UDim2.new(0.5, 0, 0.5, 0),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Quint,
		CONFIG.Animation.Duration,
		true
	)

	return true, nil
end

function GuiService.CloseUI(guiName: string): (boolean, string?)
	if SetDebounce() then 
		return false, "Please wait before closing UI" 
	end

	if not guiName then
		return GuiService.CloseAll()
	end

	local isValid, errorMsg = ValidateUI(guiName)
	if not isValid then
		return false, errorMsg
	end

	if not ActiveUIs[guiName] then
		return false, "UI is not currently open: " .. guiName
	end

	-- Remove from active UIs
	ActiveUIs[guiName] = nil

	local gui = Center[guiName]
	gui:TweenPosition(
		UDim2.new(0.5, 0, -1, 0),
		Enum.EasingDirection.In,
		Enum.EasingStyle.Quint,
		CONFIG.Animation.Duration,
		true
	)

	task.delay(CONFIG.Animation.Duration, function()
		if not ActiveUIs[guiName] then
			gui.Visible = false
		end
	end)

	-- If no more UIs are active, restore defaults
	if not next(ActiveUIs) then
		GuiService.RestoreDefaults()
	end

	return true, nil
end

function GuiService.CloseAll(): (boolean, string?)
	if SetDebounce() then 
		return false, "Please wait before closing UIs" 
	end

	-- Clear active UIs
	table.clear(ActiveUIs)

	-- Restore visual effects
	GuiService.RestoreDefaults()

	-- Close all UI frames
	for _, gui in ipairs(Center:GetChildren()) do
		if (gui:IsA('Frame') or gui:IsA('CanvasGroup')) and gui.Visible then
			gui:TweenPosition(
				UDim2.new(0.5, 0, -1, 0),
				Enum.EasingDirection.In,
				Enum.EasingStyle.Quint,
				CONFIG.Animation.Duration,
				true
			)

			task.delay(CONFIG.Animation.Duration, function()
				gui.Visible = false
			end)
		end
	end

	return true, nil
end

function GuiService.RestoreDefaults()
	PlayTween(Blur, CONFIG.TweenInfo.Disable, {Size = CONFIG.Blur.Default})
	PlayTween(workspace.CurrentCamera, CONFIG.TweenInfo.Disable, {FieldOfView = CONFIG.FOV.Default})

	if ENABLE_UI_SOUND then
		PlayTween(ENABLE_UI_SOUND, CONFIG.TweenInfo.Disable, {Volume = 0})
		task.delay(CONFIG.Animation.Duration, function()
			ENABLE_UI_SOUND:Stop()
		end)
	end
end

function GuiService.IsUIOpen(guiName: string): boolean
	return ActiveUIs[guiName] == true
end

function GuiService.GetOpenUIs(): {string}
	local openUIs = {}
	for guiName, _ in pairs(ActiveUIs) do
		table.insert(openUIs, guiName)
	end
	return openUIs
end

function GuiService.ToggleUI(guiName: string): (boolean, string?)
	if GuiService.IsUIOpen(guiName) then
		return GuiService.CloseUI(guiName)
	else
		return GuiService.OpenUI(guiName)
	end
end


Players.PlayerRemoving:Connect(function(player)
	if player == Player then
		CleanupTweens()
	end
end)

return GuiService