--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local networker = require(ReplicatedStorage.CustomPackages.networker)
local LeaderstatsServiceUtils = require(ReplicatedStorage.Shared.Services.LeaderstatsService.LeaderstatsServiceUtils)

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).server

local LeaderstatsService = {
    networker = nil :: any
}

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

   --[[
  -- Loop de teste para adicionar dinheiro (Apenas para teste)
    task.spawn(function()
        while true do
            task.wait(5)
            for _, player in Players:GetPlayers() do
                local data = DataService:waitForData(player)
                if data then
                    local currentMoney = data:get({"Stats", "Money"})
                    data:set({"Stats", "Money"}, currentMoney + 100)
                end
            end
        end
    end)  
   ]]
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
    end

    -- Currency
    updateInstance('Money', data:get({"Stats", "Currency", "Money"}))
    updateInstance('Cristal', data:get({"Stats", "Currency", "Cristal"}))

    -- Currency
    data:getChangedSignal({"Stats", "Currency", "Money"}):Connect(function(newValue)
        updateInstance('Money', newValue)
    end)
    data:getChangedSignal({"Stats", "Currency", "Cristal"}):Connect(function(newValue)
        updateInstance('Cristal', newValue)
    end)

end



return LeaderstatsService
