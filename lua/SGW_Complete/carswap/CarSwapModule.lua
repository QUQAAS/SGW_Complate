local ac = require('ac')
local ui = require('ui')
local EventBus = require('shared/EventBus')
local Config = require('shared/Config')
local CarSwapMenu = require('carswap/CarSwapMenu')
local EventClient = require('carswap/sync/EventClient')
local NodeManipulator = require('carswap/core/NodeManipulator')
local WheelFitter = require('carswap/core/WheelFitter')
local CameraAdjuster = require('carswap/core/CameraAdjuster')

local CarSwapModule = {
    isInitialized = false,
    isMenuOpen = false,
    playerCarId = -1,
    currentState = nil,
    availableCars = {}
}

function CarSwapModule.init()
    EventClient.init()
    NodeManipulator.init()
    WheelFitter.init()
    CameraAdjuster.init()
    CarSwapMenu.init()
    CarSwapModule.setupEventHandlers()
    CarSwapModule.isInitialized = true
end

function CarSwapModule.setupEventHandlers()
    EventBus.on('carswap:carList', function(data)
        CarSwapModule.availableCars = data.availableCars or {}
        CarSwapModule.currentCarModel = data.currentCarModel
        CarSwapMenu.refreshCarList(CarSwapModule.availableCars)
    end)

    EventBus.on('carswap:swapExecuted', function(data)
        if data.playerCarId == CarSwapModule.playerCarId then
            CarSwapModule.currentState = {
                visualModel = data.newModel,
                visualSkin = data.newSkin,
                wheelFit = data.wheelFitData,
                isSwapped = true
            }
            NodeManipulator.applySwap(data.newModel, data.newSkin, data.wheelFitData)
            CameraAdjuster.applyOffset(data.newModel)
            CarSwapMenu.onSwapSuccess()
        end
    end)

    EventBus.on('carswap:swapReset', function(data)
        if data.playerCarId == CarSwapModule.playerCarId then
            NodeManipulator.resetToOriginal()
            CameraAdjuster.resetOffset()
            CarSwapModule.currentState = { isSwapped = false }
            CarSwapMenu.onSwapReset()
        end
    end)

    EventBus.on('carswap:playerVisualState', function(data)
        if data.playerCarId ~= CarSwapModule.playerCarId then
        end
    end)

    EventBus.on('carswap:fineTuneSaved', function(data)
        CarSwapMenu.onFineTuneSaved(data.cacheKey)
    end)

    EventBus.on('carswap:fineTuneLoaded', function(data)
        if CarSwapModule.currentState then
            CarSwapModule.currentState.wheelFit = data.data
            WheelFitter.applyFit(data.data)
        end
        CarSwapMenu.onFineTuneLoaded(data.data)
    end)

    EventBus.on('carswap:error', function(data)
        CarSwapMenu.showError(data.message or 'Unknown error')
    end)
end

function CarSwapModule.update(dt)
    if not CarSwapModule.isInitialized then return end

    if CarSwapModule.playerCarId == -1 then
        for i = 0, ac.getCarsCount() - 1 do
            if ac.isCarFocused(i) then
                CarSwapModule.playerCarId = i
                break
            end
        end
    end

    if CarSwapModule.currentState and CarSwapModule.currentState.isSwapped then
        WheelFitter.applyFit(CarSwapModule.currentState.wheelFit)
        NodeManipulator.updateVisibility()
        CameraAdjuster.updateOffset(CarSwapModule.currentState.visualModel)
    end
end

function CarSwapModule.drawUI()
    if not CarSwapModule.isInitialized then return end
    CarSwapMenu.draw(CarSwapModule.isMenuOpen, CarSwapModule.availableCars, CarSwapModule.currentState)
end

function CarSwapModule.toggleMainMenu()
    CarSwapModule.isMenuOpen = not CarSwapModule.isMenuOpen
    CarSwapMenu.setVisible(CarSwapModule.isMenuOpen)
    if CarSwapModule.isMenuOpen then
        EventClient.requestCarList()
    end
end

return CarSwapModule