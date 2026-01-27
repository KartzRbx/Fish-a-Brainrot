
local RunService = game:GetService("RunService")

local PlayerGui
if RunService:IsClient() then
    local player = game:GetService('Players').LocalPlayer
    PlayerGui = player:WaitForChild('PlayerGui')
end

type hud = Frame & {
    BottomLeftHolder : Frame & {
        Currency : TextLabel,
    },
}

local LeaderstatsServiceUtils  = {}

function LeaderstatsServiceUtils.getHud()
    if not PlayerGui then return nil end
    local Main = PlayerGui:FindFirstChild('Main')
    if not Main then return nil end
    return Main:FindFirstChild('Hud') :: hud?
end

export type props = {
    InstanceName : string,
    NewValue : number,
}

return LeaderstatsServiceUtils