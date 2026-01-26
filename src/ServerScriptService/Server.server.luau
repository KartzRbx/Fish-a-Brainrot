local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).server

local DataTemplate = require(ReplicatedStorage.Shared.Shared.Constants.DataTemplate)
local LeaderstatsService = require(ServerScriptService.Server.Services.LeaderstatsService)

DataService:init({
	template = DataTemplate,
	profileStoreIndex = "DataTeste",
	useMock = game.PlaceId == 0,
})

LeaderstatsService:init()
