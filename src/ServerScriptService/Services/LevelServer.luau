--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local dataservice = require(ReplicatedStorage.CustomPackages.dataservice)
local networker = require(ReplicatedStorage.CustomPackages.networker)
local DataService = require(ReplicatedStorage.CustomPackages.dataservice).server

local LevelServer = {
    networker = nil :: any
}

type LevelServer = typeof(LevelServer)

function LevelServer.init(self: LevelServer)

        -- Modo teste: loop para dar experiência a cada 5 segundos
        task.spawn(function()
            while true do
                task.wait(5)
                for _, player in Players:GetPlayers() do
                    local data = DataService:waitForData(player)
                    if data then
                        local exp = data:get({"Stats", "Progress", "Experience"})
                        local toNext = data:get({"Stats", "Progress", "ToNext"})
                        local level = data:get({"Stats", "Progress", "Level"})
                        local addExp = 100

                        exp += addExp
                        while exp >= toNext do
                            exp -= toNext
                            level += 1
                            toNext = math.floor(toNext * 1.15)
                        end

                        data:set({"Stats", "Progress", "Experience"}, exp)
                        data:set({"Stats", "Progress", "Level"}, level)
                        data:set({"Stats", "Progress", "ToNext"}, toNext)
                        -- Envia atualização para o cliente imediatamente
                        self.networker:fire(player, "UpdateUI", {
                            Level = level,
                            Experience = exp,
                            ToNext = toNext
                        })
                    end
                end
            end
        end)
    self.networker = networker.server.new("LevelServer", self)

    

    -- Removido o loop de teste automático de experiência

    --[[
    data:getChangedSignal({"Stats", "Progress", "Experience"}):Connect(function(newValue, player)
        local data = DataService:waitForData(player)
        if not data then return end
        local level = data:get({"Stats", "Progress", "Level"})
        local toNext = data:get({"Stats", "Progress", "ToNext"})
        local exp = newValue

        self.networker:fire(player, "UpdateUI", {
            Level = level,
            Experience = exp,
            ToNext = toNext
        })
    end)
    ]]

end

function LevelServer.addExperience(self: LevelServer, player: Player, amount: number)
    local data = DataService:waitForData(player)
    if not data then return end
    local exp = data:get({"Stats", "Progress", "Experience"})
    local toNext = data:get({"Stats", "Progress", "ToNext"})
    local level = data:get({"Stats", "Progress", "Level"})

    exp += amount
    while exp >= toNext do
        exp -= toNext
        level += 1
        toNext = math.floor(toNext * 1.15)
    end

    data:set({"Stats", "Progress", "Experience"}, exp)
    data:set({"Stats", "Progress", "Level"}, level)
    data:set({"Stats", "Progress", "ToNext"}, toNext)
end

return LevelServer
