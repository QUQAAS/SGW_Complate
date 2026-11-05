local ac = require('ac')
local ui = require('ui')

local Config = require('shared/Config')
local EventBus = require('shared/EventBus')
local Utils = require('shared/Utils')

local CarSwap = require('carswap/CarSwapModule')
local WheelSwap = require('wheelswap/WheelSwapModule')
local Stance = require('stance/StanceModule')
local SkinSwap = require('skinswap/SkinSwapModule')
local Race = require('race/RaceModule')

local SGW_Complete = {
    isInitialized = false,
    modules = {}
}

function script.prepare(dt)
    ac.log('[SGW Complete] Initializing...')

    Config.load()
    EventBus.init()

    CarSwap.init()
    WheelSwap.init()
    Stance.init()
    SkinSwap.init()
    Race.init()

    SGW_Complete.modules = {
        carswap = CarSwap,
        wheelswap = WheelSwap,
        stance = Stance,
        skinswap = SkinSwap,
        race = Race
    }

    SGW_Complete.isInitialized = true
    ac.log('[SGW Complete] All modules ready!')
end

function script.update(dt)
    if not SGW_Complete.isInitialized then return end

    for name, module in pairs(SGW_Complete.modules) do
        if module.update then
            local ok, err = pcall(module.update, dt)
            if not ok then ac.log('[SGW Complete] Error in ' .. name .. '.update: ' .. tostring(err)) end
        end
    end

    EventBus.process()
end

function script.drawUI()
    if not SGW_Complete.isInitialized then return end

    for name, module in pairs(SGW_Complete.modules) do
        if module.drawUI then
            local ok, err = pcall(module.drawUI)
            if not ok then ac.log('[SGW Complete] Error in ' .. name .. '.drawUI: ' .. tostring(err)) end
        end
    end
end

function script.render3D(dt)
    if not SGW_Complete.isInitialized then return end

    for name, module in pairs(SGW_Complete.modules) do
        if module.render3D then
            local ok, err = pcall(module.render3D, dt)
            if not ok then ac.log('[SGW Complete] Error in ' .. name .. '.render3D: ' .. tostring(err)) end
        end
    end
end

function script.onKeyDown(key)
    if key == Config.get('keybinds.openMainMenu') then
        CarSwap.toggleMainMenu()
    elseif key == Config.get('keybinds.openWheelMenu') then
        WheelSwap.toggleMenu()
    elseif key == Config.get('keybinds.openStanceMenu') then
        Stance.toggleMenu()
    elseif key == Config.get('keybinds.openSkinMenu') then
        SkinSwap.toggleMenu()
    elseif key == Config.get('keybinds.openRaceMenu') then
        Race.toggleMainMenu()
    end
end

return SGW_Complete