local UI = {}

function UI:init()
    for i, module in script.Parent:GetDescendants() do
        if module:IsA("ModuleScript") and module ~= script then
            local success, requiredmodule = pcall(require, module)
            if success and type(requiredmodule) == "table" and requiredmodule.init then
                requiredmodule:init()
            end
        end
    end
end

return UI
