local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages.dataservice).server


local DataTemplate = require(ReplicatedStorage.Shared.Constants.DataTemplate)
local LeaderstatsService = require(ServerScriptService.Services.LeaderstatsService)
local LevelServer = require(ServerScriptService.Services.LevelServer)

DataService:init({
	template = DataTemplate,
	profileStoreIndex = "DataTeste2",
	useMock = game.PlaceId == 0,
})


LeaderstatsService:init()
LevelServer:init()
