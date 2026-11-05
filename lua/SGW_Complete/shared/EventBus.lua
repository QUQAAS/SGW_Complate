local ac = require('ac')

local EventBus = {}

local listeners = {}

function EventBus.init()
    listeners = {}

    ac.onServerEvent('SGW:CarSwap:CarListResponse', function(data) EventBus.emit('carswap:carList', data) end)
    ac.onServerEvent('SGW:CarSwap:SwapExecuted', function(data) EventBus.emit('carswap:swapExecuted', data) end)
    ac.onServerEvent('SGW:CarSwap:SwapReset', function(data) EventBus.emit('carswap:swapReset', data) end)
    ac.onServerEvent('SGW:CarSwap:PlayerVisualState', function(data) EventBus.emit('carswap:playerVisualState', data) end)
    ac.onServerEvent('SGW:CarSwap:FineTuneSaved', function(data) EventBus.emit('carswap:fineTuneSaved', data) end)
    ac.onServerEvent('SGW:CarSwap:FineTuneLoaded', function(data) EventBus.emit('carswap:fineTuneLoaded', data) end)
    ac.onServerEvent('SGW:CarSwap:Error', function(data) EventBus.emit('carswap:error', data) end)

    ac.onServerEvent('SGW:Race:InviteReceived', function(data) EventBus.emit('race:inviteReceived', data) end)
    ac.onServerEvent('SGW:Race:RaceStarting', function(data) EventBus.emit('race:starting', data) end)
    ac.onServerEvent('SGW:Race:Countdown', function(data) EventBus.emit('race:countdown', data) end)
    ac.onServerEvent('SGW:Race:RaceStarted', function(data) EventBus.emit('race:started', data) end)
    ac.onServerEvent('SGW:Race:RaceUpdate', function(data) EventBus.emit('race:update', data) end)
    ac.onServerEvent('SGW:Race:RaceFinished', function(data) EventBus.emit('race:finished', data) end)
    ac.onServerEvent('SGW:Race:RaceCancelled', function(data) EventBus.emit('race:cancelled', data) end)
    ac.onServerEvent('SGW:Race:RaceTypesList', function(data) EventBus.emit('race:typesList', data) end)
    ac.onServerEvent('SGW:Race:Error', function(data) EventBus.emit('race:error', data) end)

    ac.onServerEvent('SGW:Stance:Update', function(data) EventBus.emit('stance:update', data) end)
    ac.onServerEvent('SGW:SkinSwap:Change', function(data) EventBus.emit('skinswap:change', data) end)
end

function EventBus.on(event, callback)
    listeners[event] = listeners[event] or {}
    table.insert(listeners[event], callback)
end

function EventBus.emit(event, data)
    local list = listeners[event]
    if list then
        for _, cb in ipairs(list) do
            local ok, err = pcall(cb, data)
            if not ok then ac.log('[EventBus] Error in ' .. event .. ': ' .. tostring(err)) end
        end
    end
end

function EventBus.process() end

return EventBus