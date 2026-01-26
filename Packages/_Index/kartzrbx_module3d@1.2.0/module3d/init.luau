--[[
Enhanced Module3D with Advanced Camera System
Based on TheNexusAvenger's Module3D
GitHub: https://github.com/TheNexusAvenger/Module3D

New Features:
- Advanced camera positioning with aspect ratio consideration
- Smart FOV calculation based on model dimensions
- Adaptive depth calculation with bounding sphere
- Support for different projection modes
- Better handling of elongated models
- Automatic framing optimization
- Camera orbit and tilt controls
- Zoom constraints and limits
--]]

--Position to move the part/model to. Used to ensure the physics don't interact with the game.
local FAR_POSITION = Vector3.new(0,10000,0)

local Module3D = {}

--[[
Checks if a model is a player character
--]]
local function IsPlayerCharacter(Model)
	if not Model:IsA("Model") then return false end

	local humanoid = Model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local bodyParts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
	local r15Parts = {"UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm"}

	local hasBodyParts = false
	for _, partName in pairs(bodyParts) do
		if Model:FindFirstChild(partName) then
			hasBodyParts = true
			break
		end
	end

	if not hasBodyParts then
		for _, partName in pairs(r15Parts) do
			if Model:FindFirstChild(partName) then
				hasBodyParts = true
				break
			end
		end
	end

	return hasBodyParts
end

--[[
Gets all accessories from a character model
--]]
local function GetCharacterAccessories(Model)
	local accessories = {}

	for _, child in pairs(Model:GetChildren()) do
		if child:IsA("Accessory") then
			table.insert(accessories, child)
		elseif child:IsA("Hat") then
			table.insert(accessories, child)
		end
	end

	return accessories
end

--[[
Gets all body parts from a character
--]]
local function GetCharacterBodyParts(Model)
	local bodyParts = {}

	for _, child in pairs(Model:GetChildren()) do
		if child:IsA("BasePart") then
			local bodyPartNames = {
				"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
				"UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", 
				"LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
				"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
				"LeftFoot", "RightFoot"
			}

			for _, partName in pairs(bodyPartNames) do
				if child.Name == partName then
					table.insert(bodyParts, child)
					break
				end
			end
		end
	end

	return bodyParts
end

--[[
Properly positions an accessory handle on a character part
--]]
local function PositionAccessory(Accessory, Character)
	if not Accessory:IsA("Accessory") and not Accessory:IsA("Hat") then return end

	local handle = Accessory:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then return end

	-- Get attachment point from accessory
	local attachmentPoint = Accessory:FindFirstChild("AttachmentPoint")
	local accessoryAttachment = handle:FindFirstChildOfClass("Attachment")

	if not accessoryAttachment then return end

	-- Find matching attachment on character
	local attachmentName = accessoryAttachment.Name
	local targetPart = nil
	local targetAttachment = nil

	-- Search for matching attachment in character
	for _, part in pairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			local att = part:FindFirstChild(attachmentName)
			if att and att:IsA("Attachment") then
				targetPart = part
				targetAttachment = att
				break
			end
		end
	end

	-- If found, position the accessory correctly
	if targetPart and targetAttachment then
		-- Create weld to attach accessory to body part
		local weld = Instance.new("Weld")
		weld.Part0 = targetPart
		weld.Part1 = handle
		weld.C0 = targetAttachment.CFrame
		weld.C1 = accessoryAttachment.CFrame
		weld.Parent = handle

		-- Disable handle physics
		handle.Anchored = false
		handle.CanCollide = false
	end
end

--[[
Clones a character model with all accessories and body parts
--]]
local function CloneCharacterModel(Model)
	local clonedModel = Instance.new("Model")
	clonedModel.Name = Model.Name .. "_Clone"

	-- Clone humanoid first
	local originalHumanoid = Model:FindFirstChildOfClass("Humanoid")
	if originalHumanoid then
		local clonedHumanoid = originalHumanoid:Clone()
		clonedHumanoid.Parent = clonedModel
	end

	-- Clone all body parts with their children (meshes, decals, etc.)
	local bodyParts = GetCharacterBodyParts(Model)
	local primaryPart = nil
	local bodyPartMap = {} -- Map original to cloned parts

	for _, part in pairs(bodyParts) do
		local clonedPart = part:Clone()
		clonedPart.Parent = clonedModel
		bodyPartMap[part] = clonedPart

		-- Set primary part (prefer Torso/UpperTorso, then Head)
		if part.Name == "Torso" or part.Name == "UpperTorso" then
			primaryPart = clonedPart
		elseif part.Name == "Head" and not primaryPart then
			primaryPart = clonedPart
		end
	end

	-- Clone accessories and position them correctly
	local accessories = GetCharacterAccessories(Model)
	for _, accessory in pairs(accessories) do
		local clonedAccessory = accessory:Clone()
		clonedAccessory.Parent = clonedModel

		-- Position accessory on cloned character
		task.defer(function()
			PositionAccessory(clonedAccessory, clonedModel)
		end)
	end

	-- Clone clothing and appearance items
	for _, child in pairs(Model:GetChildren()) do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			local clonedItem = child:Clone()
			clonedItem.Parent = clonedModel
		elseif child:IsA("BodyColors") then
			local clonedBodyColors = child:Clone()
			clonedBodyColors.Parent = clonedModel
		elseif child:IsA("CharacterMesh") then
			-- Clone character meshes (for R6 custom bodies)
			local clonedMesh = child:Clone()
			clonedMesh.Parent = clonedModel
		elseif child:IsA("Folder") and child.Name == "R15ArtistIntent" then
			-- Clone R15 art intent folder
			local clonedFolder = child:Clone()
			clonedFolder.Parent = clonedModel
		end
	end

	-- Clone face and other decals from head
	local head = Model:FindFirstChild("Head")
	if head then
		local clonedHead = clonedModel:FindFirstChild("Head")
		if clonedHead then
			for _, decal in pairs(head:GetChildren()) do
				if decal:IsA("Decal") and not clonedHead:FindFirstChild(decal.Name) then
					local clonedDecal = decal:Clone()
					clonedDecal.Parent = clonedHead
				end
			end
		end
	end

	-- Set primary part
	if primaryPart then
		clonedModel.PrimaryPart = primaryPart
	elseif clonedModel:FindFirstChildWhichIsA("BasePart", true) then
		clonedModel.PrimaryPart = clonedModel:FindFirstChildWhichIsA("BasePart", true)
	end

	return clonedModel
end

--[[
Prepares a model for 3D display
--]]
local function PrepareModel(InputModel)
	local Model = InputModel
	local isPlayerChar = IsPlayerCharacter(InputModel)
	local shouldClone = false

	if isPlayerChar then
		Model = CloneCharacterModel(InputModel)
		shouldClone = true
		print("Detected player character, cloning with accessories...")
	end

	if InputModel:IsA("BasePart") then
		local NewModel = Instance.new("Model")
		NewModel.Name = "Model3D"
		local ClonedPart = InputModel:Clone()
		ClonedPart.Parent = NewModel
		NewModel.PrimaryPart = ClonedPart
		Model = NewModel
		shouldClone = true
	end

	return Model, shouldClone, isPlayerChar
end

--[[
Advanced camera calculation system
--]]
local CameraSystem = {}
CameraSystem.__index = CameraSystem

function CameraSystem.new()
	local self = setmetatable({}, CameraSystem)

	-- Camera settings
	self.DepthMultiplier = 1
	self.CFrameOffset = CFrame.new()
	self.FOVPadding = 1.15 -- Extra padding for FOV (15% extra space)
	self.MinDistance = 5
	self.MaxDistance = 1000
	self.AspectRatioCompensation = true
	self.UseAdaptiveFOV = true
	self.ProjectionMode = "Perspective" -- "Perspective" or "Orthographic"

	-- Camera orientation
	self.OrbitAngle = 0 -- Horizontal rotation around model
	self.TiltAngle = 0 -- Vertical tilt angle
	self.RollAngle = 0 -- Camera roll

	-- Smart framing
	self.AutoCenter = true
	self.FocusPoint = Vector3.new(0, 0, 0) -- Relative to model center
	self.UseWeightedCenter = false -- Weight center based on part sizes

	return self
end

--[[
Calculate bounding sphere radius (more accurate than box for camera distance)
--]]
function CameraSystem:CalculateBoundingSphere(Model)
	local boundingCFrame, boundingSize = Model:GetBoundingBox()
	local center = boundingCFrame.Position

	-- Calculate radius of bounding sphere (encompasses entire model)
	local radius = math.sqrt(
		boundingSize.X^2 + 
			boundingSize.Y^2 + 
			boundingSize.Z^2
	) / 2

	return center, radius, boundingSize
end

--[[
Calculate weighted center based on part masses/sizes
--]]
function CameraSystem:CalculateWeightedCenter(Model)
	local totalWeight = 0
	local weightedPosition = Vector3.new(0, 0, 0)

	local function processDescendants(parent)
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("BasePart") then
				local weight = child.Size.X * child.Size.Y * child.Size.Z
				weightedPosition = weightedPosition + (child.Position * weight)
				totalWeight = totalWeight + weight
			elseif child:IsA("Model") or child:IsA("Accessory") then
				processDescendants(child)
			end
		end
	end

	processDescendants(Model)

	if totalWeight > 0 then
		return weightedPosition / totalWeight
	end

	return Model:GetBoundingBox().Position
end

--[[
Calculate optimal FOV for model
--]]



function CameraSystem:CalculateOptimalFOV(BoundingSize, AspectRatio)
	if not self.UseAdaptiveFOV then
		return 70 -- Default FOV
	end

	-- Determine which dimension is more important based on aspect ratio
	local horizontalFit = BoundingSize.X / AspectRatio
	local verticalFit = BoundingSize.Y

	-- Calculate FOV based on larger constraint
	local maxDimension = math.max(horizontalFit, verticalFit)
	local minDimension = math.min(BoundingSize.X, BoundingSize.Y, BoundingSize.Z)

	-- Adaptive FOV: wider for larger models, narrower for detailed models
	local baseFOV = 70
	local dimensionRatio = maxDimension / (minDimension + 0.001)

	-- Adjust FOV based on model proportions
	if dimensionRatio > 3 then
		-- Elongated model: use wider FOV
		baseFOV = math.min(90, 70 + (dimensionRatio - 3) * 5)
	elseif dimensionRatio < 1.5 then
		-- Compact model: use narrower FOV for more detail
		baseFOV = math.max(50, 70 - (1.5 - dimensionRatio) * 10)
	end

	return baseFOV
end

--[[
Calculate camera distance with advanced algorithms
--]]
function CameraSystem:CalculateCameraDistance(BoundingSize, FOV, AspectRatio)
	-- Method 1: Spherical bounding calculation
	local boundingRadius = math.sqrt(
		BoundingSize.X^2 + 
			BoundingSize.Y^2 + 
			BoundingSize.Z^2
	) / 2

	-- Method 2: Frustum-based calculation
	local fovRad = math.rad(FOV / 2)
	local tanFOV = math.tan(fovRad)

	-- Calculate distance needed for horizontal and vertical fit
	local distanceForHeight = (BoundingSize.Y / 2) / tanFOV
	local distanceForWidth = (BoundingSize.X / 2) / (tanFOV * AspectRatio)
	local distanceForDepth = BoundingSize.Z / 2

	-- Use the maximum distance needed
	local frustumDistance = math.max(distanceForHeight, distanceForWidth)

	-- Combine both methods with weighted average
	local sphereDistance = boundingRadius / tanFOV
	local combinedDistance = (frustumDistance * 0.6) + (sphereDistance * 0.4)

	-- Apply padding and depth multiplier
	combinedDistance = combinedDistance * self.FOVPadding * self.DepthMultiplier

	-- Add depth offset to ensure back of model is visible
	combinedDistance = combinedDistance + distanceForDepth

	-- Clamp distance
	combinedDistance = math.clamp(combinedDistance, self.MinDistance, self.MaxDistance)

	return combinedDistance
end

--[[
Apply camera orbit and tilt transformations
--]]
function CameraSystem:ApplyOrbitTransform(BaseCFrame, Distance)
	-- Apply orbit (horizontal rotation)
	local orbitCFrame = CFrame.Angles(0, math.rad(self.OrbitAngle), 0)

	-- Apply tilt (vertical rotation)
	local tiltCFrame = CFrame.Angles(math.rad(self.TiltAngle), 0, 0)

	-- Apply roll
	local rollCFrame = CFrame.Angles(0, 0, math.rad(self.RollAngle))

	-- Combine transformations
	local finalCFrame = BaseCFrame * orbitCFrame * tiltCFrame * CFrame.new(0, 0, Distance) * rollCFrame

	return finalCFrame
end

--[[
Main camera update function with advanced calculations
--]]
function CameraSystem:UpdateCamera(Model, Camera, ViewportFrame)
	-- Get model bounds
	local center, radius, boundingSize = self:CalculateBoundingSphere(Model)

	-- Calculate weighted center if enabled
	if self.UseWeightedCenter then
		center = self:CalculateWeightedCenter(Model)
	end

	-- Apply focus point offset
	center = center + self.FocusPoint

	-- Get viewport aspect ratio
	local aspectRatio = 1
	if ViewportFrame and ViewportFrame.AbsoluteSize.X > 0 and ViewportFrame.AbsoluteSize.Y > 0 then
		aspectRatio = ViewportFrame.AbsoluteSize.X / ViewportFrame.AbsoluteSize.Y
	end

	-- Calculate optimal FOV
	local optimalFOV = self:CalculateOptimalFOV(boundingSize, aspectRatio)
	Camera.FieldOfView = optimalFOV

	-- Calculate camera distance
	local distance = self:CalculateCameraDistance(boundingSize, optimalFOV, aspectRatio)

	-- Create base camera CFrame pointing at center
	local baseCFrame = CFrame.new(center)

	-- Apply user-defined offset
	baseCFrame = baseCFrame * self.CFrameOffset

	-- Apply orbit and tilt transformations
	local finalCFrame = self:ApplyOrbitTransform(baseCFrame, distance)

	-- Set camera properties
	Camera.CFrame = finalCFrame
	Camera.Focus = CFrame.new(center)

	-- Return calculated values for debugging
	return {
		Center = center,
		Distance = distance,
		FOV = optimalFOV,
		BoundingSize = boundingSize,
		AspectRatio = aspectRatio
	}
end

--[[
Creates a Model3D object.
--]]
function Module3D.new(InputModel)
	local Model3D = {}

	-- Prepare the model
	local Model, shouldClone, isPlayerChar = PrepareModel(InputModel)
	Model3D.Object3D = Model
	Model3D.IsPlayerCharacter = isPlayerChar
	Model3D.OriginalModel = InputModel

	-- Create advanced camera system
	Model3D.CameraSystem = CameraSystem.new()

	-- Create the viewport frame
	local ViewportFrame = Instance.new("ViewportFrame")
	ViewportFrame.BackgroundTransparency = 1
	Model3D.AdornFrame = ViewportFrame

	-- Create the camera
	local Camera = Instance.new("Camera")
	Camera.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = Camera

	-- Set up the model
	local BasePrimaryPart = Model.PrimaryPart
	if not BasePrimaryPart then
		Model.PrimaryPart = Model:FindFirstChildWhichIsA("BasePart",true)
	end

	-- Move model to far position
	if Model.PrimaryPart then
		local currentCFrame = Model.PrimaryPart.CFrame
		Model:SetPrimaryPartCFrame(CFrame.new(FAR_POSITION - Model.PrimaryPart.Position) * currentCFrame)
		Model.PrimaryPart = BasePrimaryPart
	else
		-- Move individual parts and accessories
		for _, child in pairs(Model:GetChildren()) do
			if child:IsA("BasePart") then
				child.CFrame = child.CFrame + FAR_POSITION
			elseif child:IsA("Accessory") and child:FindFirstChild("Handle") then
				child.Handle.CFrame = child.Handle.CFrame + FAR_POSITION
			end
		end
	end

	Model.Parent = ViewportFrame

	-- Position accessories after model is parented (for player characters)
	if isPlayerChar then
		task.defer(function()
			for _, child in pairs(Model:GetChildren()) do
				if child:IsA("Accessory") or child:IsA("Hat") then
					PositionAccessory(child, Model)
				end
			end
		end)
	end

	--[[
	Updates the camera's CFrame with advanced system
	--]]
	local function UpdateCFrame()
		return Model3D.CameraSystem:UpdateCamera(Model, Camera, ViewportFrame)
	end

	--[[
	Force updates the camera CFrame.
	--]]
	function Model3D:Update()
		return UpdateCFrame()
	end

	--[[
	Sets the frame being active.
	--]]
	function Model3D:SetActive(Active)
		ViewportFrame.Visible = Active
	end

	--[[
	Returns if the frame is active.
	--]]
	function Model3D:GetActive()
		return ViewportFrame.Visible
	end

	--[[
	Sets the CFrame offset.
	--]]
	function Model3D:SetCFrame(NewCF)
		self.CameraSystem.CFrameOffset = NewCF
		UpdateCFrame()
	end

	--[[
	Returns the CFrame offset.
	--]]
	function Model3D:GetCFrame()
		return self.CameraSystem.CFrameOffset
	end

	--[[
	Sets the multiplier for how far back the camera should go.
	--]]
	function Model3D:SetDepthMultiplier(Multiplier)
		self.CameraSystem.DepthMultiplier = Multiplier
		UpdateCFrame()
	end

	--[[
	Returns the depth multiplier
	--]]
	function Model3D:GetDepthMultiplier()
		return self.CameraSystem.DepthMultiplier
	end

	--[[
	Set camera orbit angle (horizontal rotation)
	--]]
	function Model3D:SetOrbitAngle(Angle)
		self.CameraSystem.OrbitAngle = Angle
		UpdateCFrame()
	end

	--[[
	Set camera tilt angle (vertical rotation)
	--]]
	function Model3D:SetTiltAngle(Angle)
		self.CameraSystem.TiltAngle = Angle
		UpdateCFrame()
	end

	--[[
	Set camera roll angle
	--]]
	function Model3D:SetRollAngle(Angle)
		self.CameraSystem.RollAngle = Angle
		UpdateCFrame()
	end

	--[[
	Set FOV padding (default 1.15 = 15% extra space)
	--]]
	function Model3D:SetFOVPadding(Padding)
		self.CameraSystem.FOVPadding = Padding
		UpdateCFrame()
	end

	--[[
	Enable/disable adaptive FOV
	--]]
	function Model3D:SetAdaptiveFOV(Enabled)
		self.CameraSystem.UseAdaptiveFOV = Enabled
		UpdateCFrame()
	end

	--[[
	Enable/disable weighted center calculation
	--]]
	function Model3D:SetWeightedCenter(Enabled)
		self.CameraSystem.UseWeightedCenter = Enabled
		UpdateCFrame()
	end

	--[[
	Set focus point offset relative to model center
	--]]
	function Model3D:SetFocusPoint(Offset)
		self.CameraSystem.FocusPoint = Offset
		UpdateCFrame()
	end

	--[[
	Set distance constraints
	--]]
	function Model3D:SetDistanceConstraints(MinDistance, MaxDistance)
		self.CameraSystem.MinDistance = MinDistance or 5
		self.CameraSystem.MaxDistance = MaxDistance or 1000
		UpdateCFrame()
	end

	--[[
	Get camera debug information
	--]]
	function Model3D:GetCameraInfo()
		return UpdateCFrame()
	end

	function Model3D:SetUdin2NewInViewPortSize(Udin2)
		ViewportFrame.Size = Udin2
		UpdateCFrame()
	end

	

	--[[
	Set the image color (tint) of the ViewportFrame
	--]]
	function Model3D:SetImageColor(Color)
		ViewportFrame.ImageColor3 = Color
	end

	--[[
	Get the current image color
	--]]
	function Model3D:GetImageColor()
		return ViewportFrame.ImageColor3
	end

	--[[
	Set the image transparency
	--]]
	function Model3D:SetImageTransparency(Transparency)
		ViewportFrame.ImageTransparency = Transparency
	end

	--[[
	Get the current image transparency
	--]]
	function Model3D:GetImageTransparency()
		return ViewportFrame.ImageTransparency
	end

	--[[
	Set the background color of the ViewportFrame
	--]]
	function Model3D:SetBackgroundColor(Color)
		ViewportFrame.BackgroundColor3 = Color
	end

	--[[
	Set the background transparency
	--]]
	function Model3D:SetBackgroundTransparency(Transparency)
		ViewportFrame.BackgroundTransparency = Transparency
	end

	--[[
	Set ambient lighting color
	--]]
	function Model3D:SetAmbient(Color)
		ViewportFrame.Ambient = Color
	end

	--[[
	Get ambient lighting color
	--]]
	function Model3D:GetAmbient()
		return ViewportFrame.Ambient
	end

	--[[
	Set lighting brightness
	--]]
	function Model3D:SetLightColor(Color)
		ViewportFrame.LightColor = Color
	end

	--[[
	Get lighting color
	--]]
	function Model3D:GetLightColor()
		return ViewportFrame.LightColor
	end

	--[[
	Set lighting direction
	--]]
	function Model3D:SetLightDirection(Direction)
		ViewportFrame.LightDirection = Direction
	end

	--[[
	Get lighting direction
	--]]
	function Model3D:GetLightDirection()
		return ViewportFrame.LightDirection
	end

	--[[
	Get the 3D model instance
	--]]
	function Model3D:GetModel()
		return self.Object3D
	end

	--[[
	Get the camera instance
	--]]
	function Model3D:GetCamera()
		return Camera
	end

	--[[
	Get the ViewportFrame instance
	--]]
	function Model3D:GetViewportFrame()
		return ViewportFrame
	end

	--[[
	Set the camera's Field of View directly (overrides adaptive FOV)
	--]]
	function Model3D:SetFieldOfView(FOV)
		self.CameraSystem.UseAdaptiveFOV = false
		Camera.FieldOfView = FOV
	end

	--[[
	Get the current Field of View
	--]]
	function Model3D:GetFieldOfView()
		return Camera.FieldOfView
	end

	--[[
	Rotate the model around Y axis
	--]]
	function Model3D:RotateModel(Angle)
		if Model.PrimaryPart then
			local currentCFrame = Model.PrimaryPart.CFrame
			local centerOffset = currentCFrame.Position - FAR_POSITION
			local newCFrame = CFrame.new(FAR_POSITION) * CFrame.Angles(0, math.rad(Angle), 0) * CFrame.new(centerOffset)
			Model:SetPrimaryPartCFrame(newCFrame)
		end
		UpdateCFrame()
	end

	--[[
	Set model rotation directly (in degrees)
	--]]
	function Model3D:SetModelRotation(X, Y, Z)
		if Model.PrimaryPart then
			local currentPosition = Model.PrimaryPart.Position
			local centerOffset = currentPosition - FAR_POSITION
			local newCFrame = CFrame.new(FAR_POSITION) * CFrame.Angles(math.rad(X), math.rad(Y), math.rad(Z)) * CFrame.new(centerOffset)
			Model:SetPrimaryPartCFrame(newCFrame)
		end
		UpdateCFrame()
	end

	--[[
	Get all parts in the model
	--]]
	function Model3D:GetParts()
		local parts = {}
		for _, descendant in pairs(self.Object3D:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end
		return parts
	end

	--[[
	Set all parts' material
	--]]
	function Model3D:SetMaterial(Material)
		for _, part in pairs(self:GetParts()) do
			part.Material = Material
		end
	end

	--[[
	Set all parts' color
	--]]
	function Model3D:SetColor(Color)
		for _, part in pairs(self:GetParts()) do
			part.Color = Color
		end
	end

	--[[
	Set all parts' transparency
	--]]
	function Model3D:SetTransparency(Transparency)
		for _, part in pairs(self:GetParts()) do
			part.Transparency = Transparency
		end
	end

	--[[
	Set all parts' reflectance
	--]]
	function Model3D:SetReflectance(Reflectance)
		for _, part in pairs(self:GetParts()) do
			part.Reflectance = Reflectance
		end
	end

	--[[
	Animate camera orbit continuously
	Returns a function to stop the animation
	--]]
	function Model3D:AnimateOrbit(Speed, Duration)
		local running = true
		local startTime = tick()
		
		task.spawn(function()
			while running do
				local elapsed = tick() - startTime
				if Duration and elapsed >= Duration then
					break
				end
				
				self:SetOrbitAngle((elapsed * Speed) % 360)
				task.wait()
			end
		end)
		
		return function()
			running = false
		end
	end

	--[[
	Reset camera to default settings
	--]]
	function Model3D:ResetCamera()
		self.CameraSystem.DepthMultiplier = 1
		self.CameraSystem.CFrameOffset = CFrame.new()
		self.CameraSystem.FOVPadding = 1.15
		self.CameraSystem.OrbitAngle = 0
		self.CameraSystem.TiltAngle = 0
		self.CameraSystem.RollAngle = 0
		self.CameraSystem.UseAdaptiveFOV = true
		self.CameraSystem.FocusPoint = Vector3.new(0, 0, 0)
		UpdateCFrame()
	end

	--[[
	Updates character appearance (useful for player characters)
	Preserves accessories and their positions
	--]]
	function Model3D:UpdateAppearance()
		if self.IsPlayerCharacter and self.OriginalModel then
			-- Re-clone the original model to get updated appearance
			local newModel = CloneCharacterModel(self.OriginalModel)

			-- Replace the old model
			self.Object3D:Destroy()
			self.Object3D = newModel

			-- Reposition the new model
			if newModel.PrimaryPart then
				newModel:SetPrimaryPartCFrame(CFrame.new(FAR_POSITION - newModel.PrimaryPart.Position) * newModel.PrimaryPart.CFrame)
			else
				-- Move individual parts if no primary part
				for _, child in pairs(newModel:GetChildren()) do
					if child:IsA("BasePart") then
						child.CFrame = child.CFrame + FAR_POSITION
					elseif child:IsA("Accessory") and child:FindFirstChild("Handle") then
						child.Handle.CFrame = child.Handle.CFrame + FAR_POSITION
					end
				end
			end

			newModel.Parent = ViewportFrame

			-- Reposition accessories
			task.defer(function()
				for _, child in pairs(newModel:GetChildren()) do
					if child:IsA("Accessory") or child:IsA("Hat") then
						PositionAccessory(child, newModel)
					end
				end
			end)

			UpdateCFrame()
		end
	end

	--[[
	Adds a new accessory to the character model
	--]]
	function Model3D:AddAccessory(Accessory)
		if not Accessory or not (Accessory:IsA("Accessory") or Accessory:IsA("Hat")) then
			warn("Invalid accessory provided")
			return false
		end

		local clonedAccessory = Accessory:Clone()
		clonedAccessory.Parent = self.Object3D

		-- Position the accessory
		task.defer(function()
			PositionAccessory(clonedAccessory, self.Object3D)
			UpdateCFrame()
		end)

		return true
	end

	--[[
	Removes an accessory by name or instance
	--]]
	function Model3D:RemoveAccessory(AccessoryNameOrInstance)
		local accessoryToRemove = nil

		if typeof(AccessoryNameOrInstance) == "string" then
			-- Search by name
			accessoryToRemove = self.Object3D:FindFirstChild(AccessoryNameOrInstance)
		elseif typeof(AccessoryNameOrInstance) == "Instance" then
			-- Direct instance
			accessoryToRemove = AccessoryNameOrInstance
		end

		if accessoryToRemove and (accessoryToRemove:IsA("Accessory") or accessoryToRemove:IsA("Hat")) then
			accessoryToRemove:Destroy()
			UpdateCFrame()
			return true
		end

		return false
	end

	--[[
	Gets all current accessories in the model
	--]]
	function Model3D:GetAccessories()
		return GetCharacterAccessories(self.Object3D)
	end

	--[[
	Clears all accessories from the model
	--]]
	function Model3D:ClearAccessories()
		local accessories = self:GetAccessories()
		for _, accessory in pairs(accessories) do
			accessory:Destroy()
		end
		UpdateCFrame()
	end

	--[[
	Destroys the frame and unparents the model.
	--]]
	function Model3D:Destroy()
		if self.AdornFrame then
			self.AdornFrame:Destroy()
		end
		if self.Object3D then
			self.Object3D:Destroy()
		end
	end

	--[[
	Destroys the frame and unparents the model (deprecated).
	--]]
	function Model3D:End()
		self:Destroy()
	end

	-- Create and set the object metatable
	local Metatable = {}
	setmetatable(Model3D, Metatable)
	Metatable.__index = function(self, Index)
		if Index == "Camera" then
			return ViewportFrame.CurrentCamera
		end

		local ObjectValue = rawget(Model3D, Index)
		if ObjectValue ~= nil then
			return ObjectValue
		end

		return ViewportFrame[Index]
	end
	Metatable.__newindex = function(self, Index, NewValue)
		ViewportFrame[Index] = NewValue
	end

	UpdateCFrame()
	return Model3D
end

--[[
Adorns a 3D model to a frame.
Returns a Model3D object.
--]]

local Knit = require(script.Parent.Packages.knit)

function Module3D:Attach3D(Frame, Model)
	local Model3D = Module3D.new(Model)
	Model3D.AnchorPoint = Vector2.new(0.5, 0.5)
	Model3D.Position = UDim2.new(0.5, 0, 0.5, 0)
	Model3D.Visible = true
	Model3D.Parent = Frame

	local function UpdateFrameSize()
		local AbsoluteSize = Frame.AbsoluteSize
		local MinSize = math.min(AbsoluteSize.X, AbsoluteSize.Y)
		Model3D.Size = UDim2.new(0, MinSize, 0, MinSize)
		Model3D:Update() -- Update camera when frame size changes
	end
	local FrameChanged = Frame.Changed:Connect(UpdateFrameSize)
	UpdateFrameSize()

	local AncestryChanged = Frame.AncestryChanged:Connect(function()
		if not Frame.Parent then
			Model3D:Destroy()
		end
	end)

	local BaseDestroy = Model3D.Destroy
	local function NewDestroy(self)
		if FrameChanged then
			FrameChanged:Disconnect()
			FrameChanged = nil
		end

		if AncestryChanged then
			AncestryChanged:Disconnect()
			AncestryChanged = nil
		end

		BaseDestroy(self)
	end
	rawset(Model3D, "Destroy", NewDestroy)

	return Model3D
end

return Module3D