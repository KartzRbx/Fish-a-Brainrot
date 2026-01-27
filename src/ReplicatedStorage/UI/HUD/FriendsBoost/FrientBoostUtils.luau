local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Main : ScreenGui = playerGui:WaitForChild("Main")
local Hud : Frame = Main:WaitForChild("Hud")
local BottomLeftHolder : Frame = Hud:WaitForChild("BottomLeftHolder")
local BoostText : TextLabel = BottomLeftHolder:WaitForChild("Boost")

local texttemplate = 'Friend boost: +d%'

local FrientBoostUtils = {}
FrientBoostUtils.UI = {
    Main = Main,
    Hud = Hud,
    BottomLeftHolder = BottomLeftHolder,
    BoostText = BoostText,
}

return FrientBoostUtils