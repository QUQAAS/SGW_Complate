local ac = require('ac')
local ui = require('ui')
local EventBus = require('shared/EventBus')
local StanceMenu = require('stance/StanceMenu')
local StanceApplier = require('stance/core/StanceApplier')

local StanceModule = { isInitialized = false, isMenuOpen = false }

function StanceModule.init()
    StanceApplier.init()
    StanceMenu.init()
    StanceModule.setupEventHandlers()
    StanceModule.isInitialized = true
end

function StanceModule.setupEventHandlers()
    EventBus.on('stance:update', function(data)
        StanceApplier.applyRemote(data)
    end)
end

function StanceModule.update(dt)
    if not StanceModule.isInitialized then return end
    StanceApplier.update(dt)
end

function StanceModule.drawUI()
    if not StanceModule.isInitialized then return end
    StanceMenu.draw(StanceModule.isMenuOpen)
end

function StanceModule.toggleMenu()
    StanceModule.isMenuOpen = not StanceModule.isMenuOpen
    StanceMenu.setVisible(StanceModule.isMenuOpen)
end

return StanceModule