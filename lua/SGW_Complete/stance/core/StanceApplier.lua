local ac = require('ac')

local StanceApplier = {}
local stanceData = { frontCamber = 0, rearCamber = 0, frontOffset = 0, rearOffset = 0 }
local originalRotations = {}
local originalPositions = {}

function StanceApplier.init()
    StanceApplier.captureOriginals()
end

function StanceApplier.captureOriginals()
    local wheels = {'FL_WHEEL', 'FR_WHEEL', 'RL_WHEEL', 'RR_WHEEL'}
    for _, name in ipairs(wheels) do
        local node = ac.findNode(name)
        if node then
            originalRotations[name] = ac.getNodeRotation(node.index)
            originalPositions[name] = ac.getNodePosition(node.index)
        end
    end
end

function StanceApplier.apply()
    if not (ac.setNodeRotation and ac.setNodePosition and ac.findNode) then return end

    local fCamber = math.rad(stanceData.frontCamber)
    local rCamber = math.rad(stanceData.rearCamber)
    local fOffset = stanceData.frontOffset / 100
    local rOffset = stanceData.rearOffset / 100

    local fl = ac.findNode('FL_WHEEL')
    local fr = ac.findNode('FR_WHEEL')
    if fl and originalRotations.FL_WHEEL then
        ac.setNodeRotation(fl.index, vec3(originalRotations.FL_WHEEL.x + fCamber, originalRotations.FL_WHEEL.y, originalRotations.FL_WHEEL.z))
        ac.setNodePosition(fl.index, vec3(originalPositions.FL_WHEEL.x + fOffset, originalPositions.FL_WHEEL.y, originalPositions.FL_WHEEL.z))
    end
    if fr and originalRotations.FR_WHEEL then
        ac.setNodeRotation(fr.index, vec3(originalRotations.FR_WHEEL.x - fCamber, originalRotations.FR_WHEEL.y, originalRotations.FR_WHEEL.z))
        ac.setNodePosition(fr.index, vec3(originalPositions.FR_WHEEL.x - fOffset, originalPositions.FR_WHEEL.y, originalPositions.FR_WHEEL.z))
    end

    local rl = ac.findNode('RL_WHEEL')
    local rr = ac.findNode('RR_WHEEL')
    if rl and originalRotations.RL_WHEEL then
        ac.setNodeRotation(rl.index, vec3(originalRotations.RL_WHEEL.x + rCamber, originalRotations.RL_WHEEL.y, originalRotations.RL_WHEEL.z))
        ac.setNodePosition(rl.index, vec3(originalPositions.RL_WHEEL.x + rOffset, originalPositions.RL_WHEEL.y, originalPositions.RL_WHEEL.z))
    end
    if rr and originalRotations.RR_WHEEL then
        ac.setNodeRotation(rr.index, vec3(originalRotations.RR_WHEEL.x - rCamber, originalRotations.RR_WHEEL.y, originalRotations.RR_WHEEL.z))
        ac.setNodePosition(rr.index, vec3(originalPositions.RR_WHEEL.x - rOffset, originalPositions.RR_WHEEL.y, originalPositions.RR_WHEEL.z))
    end
end

function StanceApplier.reset()
    stanceData = { frontCamber = 0, rearCamber = 0, frontOffset = 0, rearOffset = 0 }
    if ac.setNodeRotation and ac.setNodePosition then
        for name, rot in pairs(originalRotations) do
            local node = ac.findNode(name)
            if node then ac.setNodeRotation(node.index, rot) end
        end
        for name, pos in pairs(originalPositions) do
            local node = ac.findNode(name)
            if node then ac.setNodePosition(node.index, pos) end
        end
    end
end

function StanceApplier.setFrontCamber(val) stanceData.frontCamber = math.max(-5, math.min(5, val)); StanceApplier.apply(); StanceApplier.broadcast() end
function StanceApplier.setRearCamber(val) stanceData.rearCamber = math.max(-5, math.min(5, val)); StanceApplier.apply(); StanceApplier.broadcast() end
function StanceApplier.setFrontOffset(val) stanceData.frontOffset = math.max(-5, math.min(5, val)); StanceApplier.apply(); StanceApplier.broadcast() end
function StanceApplier.setRearOffset(val) stanceData.rearOffset = math.max(-5, math.min(5, val)); StanceApplier.apply(); StanceApplier.broadcast() end

function StanceApplier.getData() return stanceData end

function StanceApplier.broadcast()
    ac.sendClientEvent("SGW:Stance:Update", stanceData)
end

function StanceApplier.applyRemote(data)
    stanceData = data
    StanceApplier.apply()
end

function StanceApplier.update(dt) end

return StanceApplier