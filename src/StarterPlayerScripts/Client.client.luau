local ReplicatedStorage = game:GetService("ReplicatedStorage")
local networker = require(ReplicatedStorage.CustomPackages.networker)
local LeaderstatsServiceClient = require(ReplicatedStorage.Shared.Services.LeaderstatsService.LeaderstatsServiceClient)
local UI = require(ReplicatedStorage.UI)

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).client

-- Initialize DataService first as other services might depend on it
DataService:init()
LeaderstatsServiceClient:init()
UI.UI:init()
