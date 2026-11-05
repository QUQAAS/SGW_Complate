local ac = require('ac')
local ui = require('ui')
local EventBus = require('shared/EventBus')
local WheelSwapMenu = require('wheelswap/WheelSwapMenu')
local WheelApplier = require('wheelswap/core/WheelApplier')

local WheelSwapModule = { isInitialized = false, isMenuOpen = false, wheelCatalog = {} }

function WheelSwapModule.init()
    WheelApplier.init()
    WheelSwapMenu.init()
    WheelSwapModule.loadWheelCatalog()
    WheelSwapModule.isInitialized = true
end

function WheelSwapModule.loadWheelCatalog()
    local path = ac.getFolder(ac.FolderID.Content) .. '/apps/lua/SGW_Complete/wheels_index.json'
    if io.fileExists(path) then
        local content = io.loadText(path)
        local ok, data = pcall(require('json').decode, content)
        if ok then WheelSwapModule.wheelCatalog = data end
    end
    WheelSwapMenu.setWheelCatalog(WheelSwapModule.wheelCatalog)
end

function WheelSwapModule.update(dt)
    if not WheelSwapModule.isInitialized then return end
    WheelApplier.update(dt)
end

function WheelSwapModule.drawUI()
    if not WheelSwapModule.isInitialized then return end
    WheelSwapMenu.draw(WheelSwapModule.isMenuOpen)
end

function WheelSwapModule.toggleMenu()
    WheelSwapModule.isMenuOpen = not WheelSwapModule.isMenuOpen
    WheelSwapMenu.setVisible(WheelSwapModule.isMenuOpen)
end

return WheelSwapModule