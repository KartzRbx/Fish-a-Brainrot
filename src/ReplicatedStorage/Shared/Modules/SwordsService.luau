local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SwordsFolder: Folder = ReplicatedStorage.Assets.Builds.Swords

local Dummys = require(ReplicatedStorage.Constants.Dummys)
local NotificationService = require(script.Parent.NotificationService)
local QuadTreeService = require(script.Parent.QuadTreeService)
local SwordsConfig = require(ReplicatedStorage.Constants.Swords)
local Types = require(ReplicatedStorage.Constants.Types)
local signal = require(ReplicatedStorage.Packages.signal)

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local ActiveSwords = {}

local CurrentAngle = 0
local Speed = 0
local RenderConnection = nil

local HEIGHT = 0
local RADIUS = 4
local ROTATION_FACTOR = 30

local SwordService = {}

local function UpdateRotation(dt)
	local swordCount = 0
	for _ in ActiveSwords do
		swordCount += 1
	end

	if swordCount == 0 then
		return
	end

	local k = ROTATION_FACTOR
	local speedTotal = math.sqrt(Speed * k)
	CurrentAngle = (CurrentAngle + speedTotal * dt) % 360

	local angleStep = 360 / swordCount
	local index = 0

	for stackId, SwordModel in ActiveSwords do
		local sword = SwordModel

		if sword and sword.Parent and sword.PrimaryPart then
			local swordAngle = CurrentAngle + (angleStep * index)
			local angleRad = math.rad(swordAngle)

			local offsetX = math.cos(angleRad) * RADIUS
			local offsetZ = math.sin(angleRad) * RADIUS

			local pos = HumanoidRootPart.Position
			local cframe = CFrame.new(pos.X + offsetX, pos.Y + HEIGHT, pos.Z + offsetZ)
				* CFrame.Angles(0, -angleRad, 0)
				* CFrame.Angles(math.pi, -math.pi / 2, 0)

			sword.PrimaryPart.CFrame = cframe
			index += 1
		end
	end
end

function SwordService.BoudingManager(SwordModel: Model, StackId, Touch: BasePart)
	RunService.PreRender:Connect(function(delta: number)
		local Overlap = OverlapParams.new()
		Overlap.FilterDescendantsInstances = { SwordModel }
		Overlap.FilterType = Enum.RaycastFilterType.Exclude

		local Parts: { BasePart? } = workspace:GetPartBoundsInBox(Touch.CFrame, Touch.Size, Overlap)

		if Parts and #Parts > 0 then
			for _, part in Parts do
				if not part then
					continue
				end
				local parent = part.Parent
				if not parent then
					continue
				end

				signal.FireServer("SwordService:Bouding", StackId, parent)
			end
		end
	end)
end

function SwordService.UpdateSwords(InventoryData)
	if RenderConnection then
		RenderConnection:Disconnect()
		RenderConnection = nil
	end

	for StackId, swordModel in ActiveSwords do
		if swordModel and swordModel.Parent then
			swordModel:Destroy()
		end
		ActiveSwords[StackId] = nil
	end

	local TotalSpeed = 0

	for StackId in InventoryData.Inventory.SwordsEquipeds do
		for _, StackData: Types.SwordDataModel in InventoryData.Inventory.Inventory do
			if StackData.StackId == StackId then
				if StackData.Buffers and StackData.Buffers.Speed then
					TotalSpeed += StackData.Buffers.Speed
				end
				break
			end
		end
	end

	Speed = TotalSpeed * (InventoryData.Multipliers.SpeedMultiplier or 1)

	for StackId, SwordName in InventoryData.Inventory.SwordsEquipeds do
		local SwordModel = SwordsFolder:FindFirstChild(SwordName)
		if SwordModel then
			local swordClone = SwordModel:Clone() :: Model
			swordClone.Parent = Character
			swordClone:SetAttribute('Stack', StackId)
			swordClone.PrimaryPart.Anchored = true
			ActiveSwords[StackId] = swordClone

			local Touch = swordClone:FindFirstChild("Touch")
			if Touch then
				SwordService.BoudingManager(swordClone, StackId, Touch)
			else
				warn("Sword " .. swordClone.Name(" not configured"))
			end
		else
			warn(`Sword model not found: {SwordName}`)
		end
	end

	if next(ActiveSwords) then
		RenderConnection = RunService.RenderStepped:Connect(UpdateRotation)
	end
end

signal.ListenRemote("RemoveSword", function(StackId)
	if ActiveSwords[StackId] then
		if ActiveSwords[StackId].Parent then
			ActiveSwords[StackId]:Destroy()
		end
		ActiveSwords[StackId] = nil
	end
end)

return SwordService
