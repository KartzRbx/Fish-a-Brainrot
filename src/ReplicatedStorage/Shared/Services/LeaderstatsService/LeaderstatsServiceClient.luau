local ReplicatedStorage = game:GetService("ReplicatedStorage")
local networker = require(ReplicatedStorage.CustomPackages.networker)
local LeaderstatsServiceUtils = require(ReplicatedStorage.Shared.Services.LeaderstatsService.LeaderstatsServiceUtils)
local LeaderstatsService = {}

type LeaderstatsService = typeof(LeaderstatsService) 


function LeaderstatsService.init(self : LeaderstatsService)
    self.networker = networker.client.new("LeaderstatsService", self, {
        self.UpdateCurrencyUIs,
    })

end

function LeaderstatsService.UpdateCurrencyUIs(self : LeaderstatsService, props : LeaderstatsServiceUtils.props)
    if not props then
        return
    end

    print('Solicitado atualização de UI')
    print(props.InstanceName, props.NewValue)
end

return LeaderstatsService