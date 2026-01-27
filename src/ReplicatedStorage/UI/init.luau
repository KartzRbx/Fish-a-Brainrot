for i, module in script:GetDescendants() do
    if module:IsA("ModuleScript") then
        local requiredmodule = require(module)
        requiredmodule:init()
    end
end
