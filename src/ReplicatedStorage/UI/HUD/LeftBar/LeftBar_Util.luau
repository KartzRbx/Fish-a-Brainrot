
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Main : ScreenGui = playerGui:WaitForChild("Main")
local Hud : Frame = Main:WaitForChild("Hud")

type props = {
    Icon : ImageLabel,
    Name : TextLabel
}

type leftButtons = Frame & {
    UIAspectRatioConstraint : UIAspectRatioConstraint,
    UIListLayout : UIListLayout,
    Index : ImageButton & props,
    Rebirth : ImageButton & props,
    Shop : ImageButton & props,
    Trade : ImageButton & props,
}

local LeftButtons : leftButtons = Hud:WaitForChild("LeftButtons")


local LeftBar_Util = {}
LeftBar_Util.UI = {
    Main = Main,
    Hud = Hud,
    LeftButtons = LeftButtons,
}




return LeftBar_Util