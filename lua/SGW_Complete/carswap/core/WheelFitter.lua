local ac = require('ac')

local WheelFitter = {}
local currentFit = nil
local originalWheelPositions = {}

function WheelFitter.init()
    WheelFitter.captureOriginalPositions()
end

function WheelFitter.captureOriginalPositions()
    originalWheelPositions = {}
    local wheelNodes = {'FL_WHEEL', 'FR_WHEEL', 'RL_WHEEL', 'RR_WHEEL'}
    for _, name in ipairs(wheelNodes) do
        if ac.findNode then
            local node = ac.findNode(name)
            if node then originalWheelPositions[name] = ac.getNodePosition(node.index) end
        end
    end
end

function WheelFitter.applyFit(fitData)
    if not fitData then return end
    currentFit = fitData

    if ac.setNodePosition and ac.findNode then
        local fl = ac.findNode('FL_WHEEL')
        local fr = ac.findNode('FR_WHEEL')
        if fl and originalWheelPositions.FL_WHEEL then
            local pos = originalWheelPositions.FL_WHEEL
            ac.setNodePosition(fl.index, vec3(pos.x + fitData.frontOffsetX, pos.y + fitData.heightOffset, pos.z))
        end
        if fr and originalWheelPositions.FR_WHEEL then
            local pos = originalWheelPositions.FR_WHEEL
            ac.setNodePosition(fr.index, vec3(pos.x - fitData.frontOffsetX, pos.y + fitData.heightOffset, pos.z))
        end

        local rl = ac.findNode('RL_WHEEL')
        local rr = ac.findNode('RR_WHEEL')
        if rl and originalWheelPositions.RL_WHEEL then
            local pos = originalWheelPositions.RL_WHEEL
            ac.setNodePosition(rl.index, vec3(pos.x + fitData.rearOffsetX, pos.y + fitData.heightOffset, pos.z))
        end
        if rr and originalWheelPositions.RR_WHEEL then
            local pos = originalWheelPositions.RR_WHEEL
            ac.setNodePosition(rr.index, vec3(pos.x - fitData.rearOffsetX, pos.y + fitData.heightOffset, pos.z))
        end
    end

    if fitData.scale and fitData.scale ~= 1.0 and ac.setNodeScale and ac.findNode then
        local body = ac.findNode('BODY')
        if body then ac.setNodeScale(body.index, vec3(fitData.scale, fitData.scale, fitData.scale)) end
    end

    if fitData.camberFront and fitData.camberFront ~= 0 and ac.setNodeRotation and ac.findNode then
        local fl = ac.findNode('FL_WHEEL')
        local fr = ac.findNode('FR_WHEEL')
        local rad = math.rad(fitData.camberFront)
        if fl then ac.setNodeRotation(fl.index, vec3(0, 0, rad)) end
        if fr then ac.setNodeRotation(fr.index, vec3(0, 0, -rad)) end
    end
    if fitData.camberRear and fitData.camberRear ~= 0 and ac.setNodeRotation and ac.findNode then
        local rl = ac.findNode('RL_WHEEL')
        local rr = ac.findNode('RR_WHEEL')
        local rad = math.rad(fitData.camberRear)
        if rl then ac.setNodeRotation(rl.index, vec3(0, 0, rad)) end
        if rr then ac.setNodeRotation(rr.index, vec3(0, 0, -rad)) end
    end
end

function WheelFitter.reset()
    currentFit = nil
    if ac.setNodePosition then
        for name, pos in pairs(originalWheelPositions) do
            local node = ac.findNode(name)
            if node then ac.setNodePosition(node.index, pos) end
        end
    end
    if ac.setNodeScale and ac.findNode then
        local body = ac.findNode('BODY')
        if body then ac.setNodeScale(body.index, vec3(1,1,1)) end
    end
    if ac.setNodeRotation and ac.findNode then
        for _, name in ipairs({'FL_WHEEL','FR_WHEEL','RL_WHEEL','RR_WHEEL'}) do
            local node = ac.findNode(name)
            if node then ac.setNodeRotation(node.index, vec3(0,0,0)) end
        end
    end
end

function WheelFitter.getCurrentFit() return currentFit end

return WheelFitter