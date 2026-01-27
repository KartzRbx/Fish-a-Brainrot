local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaderstatsServiceClient = require(ReplicatedStorage.Shared.Services.LeaderstatsService.LeaderstatsServiceClient)
local InventoryServiceClient = require(ReplicatedStorage.Shared.Services.InventoryService.InventoryServiceClient)

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).client

-- Initialize DataService first as other services might depend on it
DataService:init()
LeaderstatsServiceClient:init()
InventoryServiceClient:init()

-- Inicia o sistema de UI
require(ReplicatedStorage.UI):init()



