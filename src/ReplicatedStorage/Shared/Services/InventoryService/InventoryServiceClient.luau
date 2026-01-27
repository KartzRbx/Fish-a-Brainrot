local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CustomPackages = ReplicatedStorage:WaitForChild("CustomPackages")
local networker = require(CustomPackages:WaitForChild("networker"))
local InventoryServiceUtils = require(ReplicatedStorage.Shared.Services.InventoryService.InventoryServiceUtils)

local InventoryServiceClient = {}
InventoryServiceClient.InventoryCache = nil

type InventoryServiceClient = typeof(InventoryServiceClient)

function InventoryServiceClient.init(self: InventoryServiceClient)
    self.networker = networker.client.new("InventoryService", self, {
        self.UpdateInventoryUI,
    })
end

function InventoryServiceClient.UpdateInventoryUI(self: InventoryServiceClient, inventory: InventoryServiceUtils.Inventory)
    self.InventoryCache = inventory
    print("Inventory UI Update Requested", self.InventoryCache)
    -- As requested, this only sets up the skeleton for UI update
end

function InventoryServiceClient.GetInventoryCache(self: InventoryServiceClient)
    return self.InventoryCache
end

return InventoryServiceClient
