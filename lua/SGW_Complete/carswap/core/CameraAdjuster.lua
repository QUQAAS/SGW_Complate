local ac = require('ac')

local CameraAdjuster = {}
local originalCockpitOffset = vec3(0, 0, 0)
local hasCockpitOffsetApi = false
local modelOffsets = {}

function CameraAdjuster.init()
    if ac.getCockpitCameraOffset then
        hasCockpitOffsetApi = true
        originalCockpitOffset = ac.getCockpitCameraOffset()
        ac.log('[SGW CarSwap] Cockpit camera offset API available')
    else
        ac.log('[SGW CarSwap] Cockpit camera offset API NOT available')
    end
end

function CameraAdjuster.applyOffset(model)
    if not hasCockpitOffsetApi then return end
    local offset = modelOffsets[model]
    if not offset then
        offset = CameraAdjuster.calculateOffset(model)
        modelOffsets[model] = offset
    end
    ac.setCockpitCameraOffset(vec3(offset.x, offset.y, offset.z))
    ac.log('[SGW CarSwap] Applied cockpit offset for ' .. model .. ': ' .. tostring(offset))
end

function CameraAdjuster.calculateOffset(model)
    local dashNode = ac.findNode('DASHBOARD') or ac.findNode('DASH')
    if dashNode then
        local dashPos = ac.getNodePosition(dashNode.index)
        return vec3(0, 0.05, dashPos.z * 0.1)
    end
    return vec3(0, 0, 0)
end

function CameraAdjuster.updateOffset(model) end

function CameraAdjuster.resetOffset()
    if hasCockpitOffsetApi then ac.setCockpitCameraOffset(originalCockpitOffset) end
end

function CameraAdjuster.setManualOffset(x, y, z)
    if hasCockpitOffsetApi then ac.setCockpitCameraOffset(vec3(x, y, z)) end
end

return CameraAdjuster