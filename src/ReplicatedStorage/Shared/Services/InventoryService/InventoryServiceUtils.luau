local Players = game:GetService('Players')

local InventoryServiceUtils = {}

export type stack = {
    StackId : number,
    Itens : {Tool},
    Equipped : boolean,

}


export type hotbar = {
    Slot1 : number?,
    Slot2 : number?,
    Slot3 : number?,
    Slot4 : number?,
    Slot5 : number?,
    Slot6 : number?,
    Slot7 : number?,
    Slot8 : number?,
    Slot9 : number?,
}

export type Inventory = {
    HotBar : hotbar,
    Inventory : {stack},
    NextStackId : number,
}


function InventoryServiceUtils.FindToolInInventory(inventory : Inventory, tool : Tool) : (stack?, number?)
    if not inventory.Inventory then return nil, nil end
    for _, stack in inventory.Inventory do
        for i, item in stack.Itens do
            if item == tool then
                return stack, i
            end
        end
    end
    return nil, nil
end

function InventoryServiceUtils.IsToolEquipped(inventory : Inventory, tool : Tool) : boolean
    local stack = InventoryServiceUtils.FindToolInInventory(inventory, tool)
    return stack and stack.Equipped or false
end

function InventoryServiceUtils.GetFirstEmptySlot(hotbar : hotbar) : string?
    for i = 1, 9 do
        local key = "Slot" .. i
        if hotbar[key] == nil then
            return key
        end
    end
    return nil
end

function InventoryServiceUtils.IsStackInHotbar(hotbar : hotbar, stackId : number) : boolean
    for i = 1, 9 do
        local key = "Slot" .. i
        if hotbar[key] == stackId then
            return true
        end
    end
    return false
end

return InventoryServiceUtils