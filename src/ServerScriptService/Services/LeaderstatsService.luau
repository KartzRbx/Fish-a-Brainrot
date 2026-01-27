--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local networker = require(ReplicatedStorage.CustomPackages.networker)
local LeaderstatsServiceUtils = require(ReplicatedStorage.Shared.Services.LeaderstatsService.LeaderstatsServiceUtils)

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).server

local LeaderstatsService = {}

type LeaderstatsService = typeof(LeaderstatsService)

function LeaderstatsService.init(self : LeaderstatsService)
    self.networker = networker.server.new("LeaderstatsService", self)

	Players.PlayerAdded:Connect(function(player)
		self:setupLeaderstats(player)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(function(): ()
			self:setupLeaderstats(player)
		end)
	end
end

function LeaderstatsService.setupLeaderstats(self : LeaderstatsService, player: Player)
	local data = DataService:waitForData(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

    local function updateInstance(InstanceName, NewValue)
        local int = leaderstats:FindFirstChild(InstanceName)  :: IntValue
        if not int then
            int = Instance.new("IntValue")
            int.Name = InstanceName
            int.Parent = leaderstats
        end

        int.Value = NewValue

		local props : LeaderstatsServiceUtils.props = {
			InstanceName = InstanceName,
			NewValue = NewValue,
		}

        self.networker:fire(player, 'UpdateCurrencyUIs', props)
    end

	-- Initial set
	updateInstance('Fishers Caught', data:get({"Stats", "Fishers_Caught"}))
	updateInstance('Money', data:get({"Stats", "Money"}))

	-- Listen for changes
	data:getChangedSignal({"Stats", "Fishers_Caught"}):Connect(function(newValue)
		updateInstance('Fishers Caught', newValue)
	end)

	data:getChangedSignal({"Stats", "Money"}):Connect(function(newValue)
		updateInstance('Money', newValue)
	end)
end



return LeaderstatsService
