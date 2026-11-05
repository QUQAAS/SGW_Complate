local ac = require('ac')

local NodeManipulator = {}
local originalModelNodes = {}
local isSwapped = false
local currentVisualModel = ""
local currentVisualSkin = ""

function NodeManipulator.init()
    NodeManipulator.captureOriginalNodes()
end

function NodeManipulator.captureOriginalNodes()
    originalModelNodes = {}
    local importantNodes = {'BODY', 'FL_WHEEL', 'FR_WHEEL', 'RL_WHEEL', 'RR_WHEEL', 'STEER', 'DASHBOARD', 'INTERIOR'}
    if ac.getCarNodes then
        local nodes = ac.getCarNodes()
        for _, node in ipairs(nodes) do
            for _, name in ipairs(importantNodes) do
                if node.name:upper():find(name) then
                    originalModelNodes[name] = { index = node.index, name = node.name, visible = true }
                end
            end
        end
    end
end

function NodeManipulator.applySwap(model, skin, wheelFit)
    isSwapped = true
    currentVisualModel = model
    currentVisualSkin = skin
    NodeManipulator.hideOriginalModel()
    NodeManipulator.setupInterior()
    ac.log('[SGW CarSwap] Applied swap to ' .. model .. ' (' .. skin .. ')')
end

function NodeManipulator.hideOriginalModel()
    if ac.setNodeVisible then
        for _, data in pairs(originalModelNodes) do
            if data.name ~= 'STEER' and data.name ~= 'DASHBOARD' then
                ac.setNodeVisible(data.index, false)
            end
        end
    end
end

function NodeManipulator.showOriginalModel()
    if ac.setNodeVisible then
        for _, data in pairs(originalModelNodes) do
            ac.setNodeVisible(data.index, true)
        end
    end
end

function NodeManipulator.setupInterior()
    if ac.getCarNodes then
        local nodes = ac.getCarNodes()
        for _, node in ipairs(nodes) do
            local name = node.name:upper()
            if name:find('STEER') or name:find('DASH') or name:find('INTERIOR') or name:find('PEDAL') or name:find('SEAT') then
                if ac.setNodeVisible then ac.setNodeVisible(node.index, true) end
            end
        end
    end
end

function NodeManipulator.updateVisibility()
    if isSwapped then NodeManipulator.hideOriginalModel() end
end

function NodeManipulator.resetToOriginal()
    isSwapped = false
    currentVisualModel = ""
    currentVisualSkin = ""
    NodeManipulator.showOriginalModel()
    ac.log('[SGW CarSwap] Reset to original model')
end

function NodeManipulator.render3D(dt)
    if isSwapped and ac.draw3DLine then
        local wheelNodes = {'FL_WHEEL', 'FR_WHEEL', 'RL_WHEEL', 'RR_WHEEL'}
        for _, name in ipairs(wheelNodes) do
            local node = ac.findNode(name)
            if node then
                local pos = ac.getNodePosition(node.index)
                ac.draw3DLine(pos, pos + vec3(0, 0.5, 0), rgbm(1, 0, 0, 1), 0.02)
            end
        end
    end
end

return NodeManipulator