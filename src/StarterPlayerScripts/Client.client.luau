local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaderstatsServiceClient = require(ReplicatedStorage.Shared.Shared.Services.LeaderstatsService.LeaderstatsServiceClient)

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).client

-- Initialize DataService first as other services might depend on it
DataService:init()
LeaderstatsServiceClient:init()



