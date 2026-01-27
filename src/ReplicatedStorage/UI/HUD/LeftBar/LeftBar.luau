local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')

local GuiService = require(ReplicatedStorage.Shared.Modules.GuiService)
local LeftBar_Util = require(script.Parent.LeftBar_Util)

local LeftBar = {}

-- Configurações das animações
local HOVER_SCALE = 1.1
local PRESS_SCALE = 0.95
local TWEEN_TIME = 0.15

function LeftBar:applyButtonEffects(button: ImageButton)
    local icon = button:FindFirstChild("Icon") :: ImageLabel
    
    -- Tamanho Original
    local originalScale = button.Size

    local function createTween(target: any, props: { [string]: any })
        return TweenService:Create(target, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    end

    -- Mouse Enter (Hover)
    button.MouseEnter:Connect(function()
        createTween(button, {
            Size = UDim2.new(originalScale.X.Scale * HOVER_SCALE, originalScale.X.Offset, originalScale.Y.Scale * HOVER_SCALE, originalScale.Y.Offset),
            ImageColor3 = Color3.fromRGB(230, 230, 230)
        }):Play()

        if icon then
            createTween(icon, {Rotation = 5}):Play()
        end
    end)

    -- Mouse Leave
    button.MouseLeave:Connect(function()
        createTween(button, {
            Size = originalScale,
            ImageColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()

        if icon then
            createTween(icon, {Rotation = 0}):Play()
        end
    end)

    

    -- Mouse Button 1 Down (Click)
    button.MouseButton1Down:Connect(function()
        createTween(button, {
            Size = UDim2.new(originalScale.X.Scale * PRESS_SCALE, originalScale.X.Offset, originalScale.Y.Scale * PRESS_SCALE, originalScale.Y.Offset)
        }):Play()

        
       GuiService.ToggleUI(button.Name)
    end)

    -- Mouse Button 1 Up
    button.MouseButton1Up:Connect(function()
        createTween(button, {
            Size = UDim2.new(originalScale.X.Scale * HOVER_SCALE, originalScale.X.Offset, originalScale.Y.Scale * HOVER_SCALE, originalScale.Y.Offset)
        }):Play()
    end)
end

function LeftBar:init()
    local buttons = LeftBar_Util.UI.LeftButtons
    
    -- Aplicar efeitos em todos os botões da barra lateral
    for _, child in buttons:GetChildren() do
        if child:IsA("ImageButton") then
            self:applyButtonEffects(child)
        end
    end
end

return LeftBar