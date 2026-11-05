local ac = require('ac')
local ui = require('ui')
local EventBus = require('shared/EventBus')
local RaceClient = require('race/core/RaceClient')
local RaceHUD = require('race/RaceHUD')
local RaceInviteCard = require('race/RaceInviteCard')
local CountdownOverlay = require('race/CountdownOverlay')
local ResultScreen = require('race/ResultScreen')
local GreenLineRenderer = require('race/core/GreenLineRenderer')
local GridLocker = require('race/core/GridLocker')

local RaceModule = { isInitialized = false, isMenuOpen = false, isRacing = false }

function RaceModule.init()
    RaceClient.init()
    RaceHUD.init()
    RaceInviteCard.init()
    CountdownOverlay.init()
    ResultScreen.init()
    GreenLineRenderer.init()
    GridLocker.init()
    RaceModule.setupEventHandlers()
    RaceModule.isInitialized = true
end

function RaceModule.setupEventHandlers()
    EventBus.on('race:inviteReceived', function(data) RaceInviteCard.show(data) end)
    EventBus.on('race:starting', function(data)
        RaceModule.onRaceStarting(data)
    end)
    EventBus.on('race:countdown', function(data) CountdownOverlay.setValue(data.seconds) end)
    EventBus.on('race:started', function(data)
        RaceModule.isRacing = true
        GridLocker.unlock()
        CountdownOverlay.hide()
    end)
    EventBus.on('race:update', function(data) RaceHUD.updateData(data) end)
    EventBus.on('race:finished', function(data)
        RaceModule.isRacing = false
        ResultScreen.show(data)
        GreenLineRenderer.clear()
    end)
    EventBus.on('race:cancelled', function(data)
        RaceModule.isRacing = false
        RaceInviteCard.hide()
        GreenLineRenderer.clear()
        GridLocker.unlock()
    end)
end

function RaceModule.onRaceStarting(data)
    local myCarId = ac.getFocusedCar()
    for _, gp in ipairs(data.gridPositions) do
        if gp.carId == myCarId then
            GridLocker.lockToPosition(gp.position, gp.rotation)
            break
        end
    end
    GreenLineRenderer.setFinishLine(data.finishLinePos, data.finishLineDir)
    CountdownOverlay.start(3)
end

function RaceModule.update(dt)
    if not RaceModule.isInitialized then return end
    RaceClient.process()
    RaceInviteCard.update(dt)
    RaceHUD.update(dt)
    CountdownOverlay.update(dt)
    ResultScreen.update(dt)
    GreenLineRenderer.update(dt)
    GridLocker.update(dt)
end

function RaceModule.drawUI()
    if not RaceModule.isInitialized then return end
    RaceInviteCard.draw()
    if RaceModule.isRacing then RaceHUD.draw() end
    CountdownOverlay.draw()
    ResultScreen.draw()
end

function RaceModule.render3D(dt)
    if not RaceModule.isInitialized then return end
    GreenLineRenderer.render(dt)
end

function RaceModule.toggleMainMenu()
    RaceModule.isMenuOpen = not RaceModule.isMenuOpen
    RaceClient.requestRaceTypes()
end

return RaceModule