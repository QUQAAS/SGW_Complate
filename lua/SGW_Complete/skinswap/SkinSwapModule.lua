local ac = require('ac')
local ui = require('ui')
local EventBus = require('shared/EventBus')
local SkinMenu = require('skinswap/SkinMenu')
local SkinApplier = require('skinswap/core/SkinApplier')

local SkinSwapModule = { isInitialized = false, isMenuOpen = false }

function SkinSwapModule.init()
    SkinApplier.init()
    SkinMenu.init()
    SkinSwapModule.isInitialized = true
end

function SkinSwapModule.update(dt)
    if not SkinSwapModule.isInitialized then return end
end

function SkinSwapModule.drawUI()
    if not SkinSwapModule.isInitialized then return end
    SkinMenu.draw(SkinSwapModule.isMenuOpen)
end

function SkinSwapModule.toggleMenu()
    SkinSwapModule.isMenuOpen = not SkinSwapModule.isMenuOpen
    SkinMenu.setVisible(SkinSwapModule.isMenuOpen)
end

return SkinSwapModule