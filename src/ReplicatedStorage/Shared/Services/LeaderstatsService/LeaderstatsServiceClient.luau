local ReplicatedStorage = game:GetService("ReplicatedStorage")
local networker = require(ReplicatedStorage.CustomPackages.networker)
local LeaderstatsService = {}

type LeaderstatsService = typeof(LeaderstatsService)


function LeaderstatsService.init(self : LeaderstatsService)
    self.networker = networker.client.new("LeaderstatsService", self, {
        self.UpdateCurrencyUIs,
    })

end

function LeaderstatsService.UpdateCurrencyUIs(self : LeaderstatsService)
    print('Solicitado atualização de UI')
end

return LeaderstatsService