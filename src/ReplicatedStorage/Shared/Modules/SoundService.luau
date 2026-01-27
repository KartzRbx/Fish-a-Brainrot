local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Constants.Types)

local Sounds = ReplicatedStorage.Assets.Sounds

-- Service Definition
local CustomSoundService = {}

export type SoundService = {
	PlaySound: (target: Player, soundName: string, config: Types.SoundConfig?) -> Sound?,
	EnableSoundWithEffect: (target: Player, soundName: string, effectType: Types.EffectType, config: Types.SoundConfig?) -> Sound?,
	EnableSound: (target: Player, soundName: string, config: Types.SoundConfig?) -> Sound?,
	StopSound: (target: Player, soundName: string, fadeOutDuration: number?) -> (),
	StopAllSounds: (target: Player, fadeOutDuration: number?) -> (),
	PingSound: (target: Player, soundName: string, config: Types.SoundConfig?) -> (),
	AdjustVolume: (target: Player, soundName: string, newVolume: number, tweenDuration: number?) -> (),
	AdjustPitch: (target: Player, soundName: string, newPitch: number, tweenDuration: number?) -> (),
	IsPlaying: (target: Player, soundName: string) -> boolean,
	GetActiveSound: (target: Player, soundName: string) -> Sound?,
	PlaySoundForAll: (soundName: string, config: Types.SoundConfig?) -> (),
	CrossfadeSound: (target: Player, currentSound: string, newSound: string, duration: number, config: Types.SoundConfig?) -> (),
}

-- Advanced State Management
local activeSounds: { [Player]: { [string]: Sound } } = {}
local soundTweens: { [Sound]: Tween } = {}

-- Types for Internal Use
type ActiveSoundMap = { [string]: Sound }
type PlayerActiveSounds = { [Player]: ActiveSoundMap }

-- Constants
local DEFAULT_CONFIG: Types.SoundConfig = {
	Volume = 0.5,
	Pitch = 1,
	PlaybackSpeed = 1,
	Looped = false,
	FadeIn = 0,
	FadeOut = 0,
}

-- Private Functions
local function createSound(soundName: string, parent: Instance): Sound?
	local soundTemplate = Sounds:FindFirstChild(soundName)

	if not soundTemplate then
		warn(`[SoundService] Sound '{soundName}' not found!`)
		return nil
	end

	local sound = soundTemplate:Clone()
	sound.Parent = parent
	return sound
end

local function getPlayerSounds(player: Player): Folder?
	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then
		return nil
	end

	local soundFolder = playerGui:FindFirstChild("Sounds")
	if not soundFolder then
		soundFolder = Instance.new("Folder")
		soundFolder.Name = "Sounds"
		soundFolder.Parent = playerGui
	end

	return soundFolder
end

local function applySoundConfig(sound: Sound, config: Types.SoundConfig): ()
	sound.Volume = config.Volume or DEFAULT_CONFIG.Volume
	sound.PlaybackSpeed = config.PlaybackSpeed or DEFAULT_CONFIG.PlaybackSpeed
	sound.Looped = config.Looped or DEFAULT_CONFIG.Looped

	if config.Pitch and config.Pitch ~= 1 then
		local pitchEffect = Instance.new("PitchShiftSoundEffect")
		pitchEffect.Octave = config.Pitch
		pitchEffect.Parent = sound
	end
end

local function fadeIn(sound: Sound, duration: number, targetVolume: number): ()
	sound.Volume = 0
	sound:Play()

	local tween = TweenService:Create(
		sound,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{ Volume = targetVolume }
	)

	soundTweens[sound] = tween
	tween:Play()
end

local function fadeOut(sound: Sound, duration: number, destroyAfter: boolean?): ()
	local tween = TweenService:Create(
		sound,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Volume = 0 }
	)

	soundTweens[sound] = tween
	tween:Play()

	if destroyAfter then
		tween.Completed:Connect(function()
			sound:Stop()
			sound:Destroy()
			soundTweens[sound] = nil
		end)
	end
end

local function addSoundEffect(sound: Sound, effectType: Types.EffectType): ()
	local effect: SoundEffect?

	if effectType == "Reverb" then
		effect = Instance.new("ReverbSoundEffect")
		effect.DryLevel = 0
		effect.WetLevel = -6
	elseif effectType == "Echo" then
		effect = Instance.new("EchoSoundEffect")
		effect.Delay = 0.5
		effect.Feedback = 0.3
	elseif effectType == "Distortion" then
		effect = Instance.new("DistortionSoundEffect")
		effect.Level = 0.5
	elseif effectType == "Equalizer" then
		effect = Instance.new("EqualizerSoundEffect")
		effect.HighGain = 0
		effect.MidGain = 0
		effect.LowGain = 0
	elseif effectType == "Compressor" then
		effect = Instance.new("CompressorSoundEffect")
		effect.Threshold = -10
		effect.Ratio = 20
	end

	if effect then
		effect.Parent = sound
	end
end

-- Public Functions
function CustomSoundService.PlaySound(target: Player, soundName: string, config: Types.SoundConfig?): Sound?
	local soundFolder = getPlayerSounds(target)
	if not soundFolder then
		return nil
	end

	local sound = createSound(soundName, soundFolder)
	if not sound then
		return nil
	end

	local finalConfig = config or DEFAULT_CONFIG
	applySoundConfig(sound, finalConfig)

	-- Initialize player's sound table
	if not activeSounds[target] then
		activeSounds[target] = {}
	end

	-- Store active sound
	activeSounds[target][soundName] = sound

	-- Handle fade in
	if finalConfig.FadeIn and finalConfig.FadeIn > 0 then
		fadeIn(sound, finalConfig.FadeIn, sound.Volume)
	else
		sound:Play()
	end

	-- Auto cleanup when sound ends
	sound.Ended:Connect(function()
		if activeSounds[target] then
			activeSounds[target][soundName] = nil
		end
		if not sound.Looped then
			task.wait(0.1)
			sound:Destroy()
		end
	end)

	return sound
end

function CustomSoundService.EnableSoundWithEffect(
	target: Player,
	soundName: string,
	effectType: Types.EffectType,
	config: Types.SoundConfig?
): Sound?
	local sound = CustomSoundService.PlaySound(target, soundName, config)

	if sound then
		addSoundEffect(sound, effectType)
	end

	return sound
end

function CustomSoundService.EnableSound(target: Player, soundName: string, config: Types.SoundConfig?): Sound?
	return CustomSoundService.PlaySound(target, soundName, config)
end

function CustomSoundService.StopSound(target: Player, soundName: string, fadeOutDuration: number?): ()
	if not activeSounds[target] then
		return
	end

	local sound = activeSounds[target][soundName]
	if not sound then
		return
	end

	if fadeOutDuration and fadeOutDuration > 0 then
		fadeOut(sound, fadeOutDuration, true)
	else
		sound:Stop()
		sound:Destroy()
	end

	activeSounds[target][soundName] = nil
end

function CustomSoundService.StopAllSounds(target: Player, fadeOutDuration: number?): ()
	if not activeSounds[target] then
		return
	end

	for soundName, sound in pairs(activeSounds[target]) do
		if fadeOutDuration and fadeOutDuration > 0 then
			fadeOut(sound, fadeOutDuration, true)
		else
			sound:Stop()
			sound:Destroy()
		end
	end

	activeSounds[target] = {}
end

function CustomSoundService.PingSound(target: Player, soundName: string, config: Types.SoundConfig?): ()
	local soundFolder = getPlayerSounds(target)
	if not soundFolder then
		return
	end

	local sound = createSound(soundName, soundFolder)
	if not sound then
		return
	end

	local finalConfig = config or { Volume = 0.7, Looped = false }
	applySoundConfig(sound, finalConfig)

	sound:Play()

	sound.Ended:Connect(function()
		task.wait(0.1)
		sound:Destroy()
	end)
end

function CustomSoundService.AdjustVolume(
	target: Player,
	soundName: string,
	newVolume: number,
	tweenDuration: number?
): ()
	if not activeSounds[target] then
		return
	end

	local sound = activeSounds[target][soundName]
	if not sound then
		return
	end

	if tweenDuration and tweenDuration > 0 then
		local tween = TweenService:Create(
			sound,
			TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Volume = newVolume }
		)
		tween:Play()
	else
		sound.Volume = newVolume
	end
end

function CustomSoundService.AdjustPitch(target: Player, soundName: string, newPitch: number, tweenDuration: number?): ()
	if not activeSounds[target] then
		return
	end

	local sound = activeSounds[target][soundName]
	if not sound then
		return
	end

	if tweenDuration and tweenDuration > 0 then
		local tween = TweenService:Create(
			sound,
			TweenInfo.new(tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ PlaybackSpeed = newPitch }
		)
		tween:Play()
	else
		sound.PlaybackSpeed = newPitch
	end
end

function CustomSoundService.IsPlaying(target: Player, soundName: string): boolean
	if not activeSounds[target] then
		return false
	end

	local sound = activeSounds[target][soundName]
	return sound ~= nil and sound.IsPlaying
end

function CustomSoundService.GetActiveSound(target: Player, soundName: string): Sound?
	if not activeSounds[target] then
		return nil
	end
	return activeSounds[target][soundName]
end

function CustomSoundService.PlaySoundForAll(soundName: string, config: Types.SoundConfig?): ()
	for _, player in ipairs(Players:GetPlayers()) do
		CustomSoundService.PlaySound(player, soundName, config)
	end
end

function CustomSoundService.CrossfadeSound(
	target: Player,
	currentSound: string,
	newSound: string,
	duration: number,
	config: Types.SoundConfig?
): ()
	task.spawn(function()
		-- Start new sound
		local sound = CustomSoundService.PlaySound(target, newSound, config)

		if sound then
			sound.Volume = 0
			sound:Play()

			-- Fade in new sound
			TweenService:Create(
				sound,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{ Volume = config and config.Volume or 0.5 }
			):Play()
		end

		-- Fade out current sound
		CustomSoundService.StopSound(target, currentSound, duration)
	end)
end

return CustomSoundService :: SoundService
