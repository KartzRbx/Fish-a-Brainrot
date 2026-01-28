local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.CustomPackages.networker)
local UI = {}

function UI.init(self : UI)
    local modules = {}


    for i, module in script.Parent:GetDescendants() do
        if module:IsA("ModuleScript") and module ~= script then
            local success, requiredmodule = pcall(require, module)
            if success and type(requiredmodule) == "table" and requiredmodule.init then
                requiredmodule:init()
                modules[module.Name] = requiredmodule
            end
        end
    end

    while true do
        UI:StateAllUI(true)
        task.wait(4)
        UI:StateAllUI(false)
    end
end

function UI.StateAllUI(self : UI, Enable : boolean)
    for moduleName, module in pairs(self) do
        if type(module) == "table" and module.EnableUI then
            module:EnableUI(Enable)
        end
    end
end

type UI = typeof(UI) & {
    init : (self : UI) -> nil,
    StateAllUI : (self : UI, Enable : boolean) -> nil,
} 

return {
    UI = UI,
    StateAllUI = UI.StateAllUI,
}
