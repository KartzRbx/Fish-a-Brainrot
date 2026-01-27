local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataservice = require(ReplicatedStorage.CustomPackages.dataservice).server
local InventoryServiceUtils = require(ReplicatedStorage.Shared.Services.InventoryService.InventoryServiceUtils)
local Janitor = require(ReplicatedStorage.CustomPackages.janitor)

local InventoryService = {}
InventoryService.PlayersManagers = {}
InventoryService.Janitors = {}

function InventoryService.OnPlayerAdded(self: InventoryService, player: Player)
	if self.PlayersManagers[player] then
		return
	end

	local data = dataservice:waitForData(player)
    if not data then return end

	local inventory: InventoryServiceUtils.Inventory = data:get('Inventory')
	self.PlayersManagers[player] = inventory
    
    local playerJanitor = Janitor.new()
    self.Janitors[player] = playerJanitor

    local characterJanitor = Janitor.new()
    playerJanitor:GiveChore(characterJanitor)

    local function setupCharacter(character: Model)
        characterJanitor:Clean()
        
        characterJanitor:GiveChore(character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                self:RegisterTool(player, child, true)
            end
        end))

        -- Check existing tools in character
        for _, child in character:GetChildren() do
            if child:IsA("Tool") then
                self:RegisterTool(player, child, true)
            end
        end
    end

    if player.Character then
        setupCharacter(player.Character)
    end
    playerJanitor:GiveChore(player.CharacterAdded:Connect(setupCharacter))

    task.spawn(function()
        local backpack = player:WaitForChild("Backpack", 5)
        if not backpack or not self.Janitors[player] then return end

        playerJanitor:GiveChore(backpack.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                self:RegisterTool(player, child, false)
            end
        end))

        -- Check existing tools in backpack
        for _, child in backpack:GetChildren() do
            if child:IsA("Tool") then
                self:RegisterTool(player, child, false)
            end
        end
    end)

    print("Inventory initialized for " .. player.Name)
end

function InventoryService.RegisterTool(self : InventoryService, player : Player, tool : Tool, isEquipped : boolean)
    local inventory = self.PlayersManagers[player]
    if not inventory then return end

    local stack, _ = InventoryServiceUtils.FindToolInInventory(inventory, tool)
    
    if not stack then
        -- New tool found, create a stack
        inventory.NextStackId += 1
        
        stack = {
            StackId = inventory.NextStackId,
            Itens = {tool},
            Equipped = isEquipped,
        }

        table.insert(inventory.Inventory, stack)
    else
        -- Tool already exists, just update equipped status
        stack.Equipped = isEquipped
    end

    -- Assign to hotbar ONLY if equipped and not already there
    if isEquipped and not InventoryServiceUtils.IsStackInHotbar(inventory.HotBar, stack.StackId) then
        local emptySlot = InventoryServiceUtils.GetFirstEmptySlot(inventory.HotBar)
        if emptySlot then
            inventory.HotBar[emptySlot] = stack.StackId
        end
    end

    -- Update the data to fire signals
    local data = dataservice:waitForData(player)
    data:set("Inventory", inventory)

    self.networker:fire(player, "UpdateInventoryUI", inventory)
end

function InventoryService.OnPlayerRemoving(self: InventoryService, player: Player) 
    if self.Janitors[player] then
        self.Janitors[player]:Destroy()
        self.Janitors[player] = nil
    end
    self.PlayersManagers[player] = nil
end

function InventoryService.init(self: InventoryService)
    self.networker = require(ReplicatedStorage.CustomPackages.networker).server.new("InventoryService", self)

	for _, player: Player in Players:GetPlayers() do
		task.spawn(function()
            self:OnPlayerAdded(player)
        end)
	end

    Players.PlayerAdded:Connect(function(player: Player)  
        self:OnPlayerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player: Player) 
        self:OnPlayerRemoving(player)
    end)
end

type InventoryService = typeof(InventoryService)

return InventoryService
