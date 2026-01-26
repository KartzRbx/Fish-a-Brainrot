local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local networker = require(ReplicatedStorage.CustomPackages.networker)

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).server

local LeaderstatsService = {}

type LeaderstatsService = typeof(LeaderstatsService)

function LeaderstatsService.init(self : LeaderstatsService)
    self.networker = networker.server.new("LeaderstatsService", self)

	Players.PlayerAdded:Connect(function(player)
		self:setupLeaderstats(player)
        self.networker:fire(player, 'UpdateCurrencyUIs')
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

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data:get("Cash")
	cash.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data:get("Level")
	level.Parent = leaderstats

    local function updateInstance(InstanceName, NewValue)
        local int = leaderstats:FindFirstChild(InstanceName)
        if int then
            int.Value = NewValue
        end
        self.networker:fire(player, 'UpdateCurrencyUIs')
    end

	-- Listen for changes
	data:getChangedSignal("Cash"):Connect(function(newValue)
		cash.Value = newValue
        self.networker:fire(player, 'UpdateCurrencyUIs')
	end)

	data:getChangedSignal("Level"):Connect(function(newValue)
		level.Value = newValue
        self.networker:fire(player, 'UpdateCurrencyUIs')
	end)
end



return LeaderstatsService
