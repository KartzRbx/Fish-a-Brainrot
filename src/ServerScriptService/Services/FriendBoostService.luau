--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local networker = require(ReplicatedStorage.CustomPackages.networker)

local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local DataService = require(CustomPackages:WaitForChild("dataservice")).server

local FriendBoostService = {
    networker = nil :: any
}

type FriendBoostService = typeof(FriendBoostService)

function FriendBoostService.init(self: FriendBoostService)
    self.networker = networker.server.new("FriendBoostService", self)

	Players.PlayerAdded:Connect(function(player)
		self:setupBoost(player)
		self:updateAllBoosts()
	end)

	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			self:updateAllBoosts()
		end)
	end)

	for _, player in Players:GetPlayers() do
		self:setupBoost(player)
	end
	self:updateAllBoosts()
end

function FriendBoostService.setupBoost(self: FriendBoostService, player: Player)
	local data = DataService:waitForData(player)
	if data then
		data:getChangedSignal({"FriendBoost"}):Connect(function(newValue)
			self.networker:fire(player, "UpdateBoostUI", newValue)
		end)
	end
end

function FriendBoostService.updateAllBoosts(self: FriendBoostService)
	local allPlayers = Players:GetPlayers()
	
	for _, player in ipairs(allPlayers) do
		task.spawn(function()
			local boost = self:calculateBoost(player, allPlayers)
			local data = DataService:waitForData(player)
			if data then
				data:set({"FriendBoost"}, boost)
			end
		end)
	end
end

function FriendBoostService.calculateBoost(self: FriendBoostService, player: Player, allPlayers: {Player}): number
	local friendCount = 0
	
	for _, otherPlayer in ipairs(allPlayers) do
		if player ~= otherPlayer then
			local success, isFriend = pcall(function()
				return player:IsFriendsWith(otherPlayer.UserId)
			end)
			
			if success and isFriend then
				friendCount += 1
			end
		end
	end
	
	return friendCount * 5
end

return FriendBoostService
