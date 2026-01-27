local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).server

local InventoryService = require(ServerScriptService.Services.InventoryService)
local DataTemplate = require(ReplicatedStorage.Shared.Constants.DataTemplate)
local LeaderstatsService = require(game:GetService("ServerScriptService").Services.LeaderstatsService)

DataService:init({
	template = DataTemplate,
	profileStoreIndex = "DataTeste",
	useMock = game.PlaceId == 0,
})

InventoryService:init()
LeaderstatsService:init()
