local ac = require('ac')

local WheelApplier = {}
local originalWheelMeshes = {}
local appliedWheelMesh = nil

function WheelApplier.init()
    if ac.getCarMeshes then
        local meshes = ac.getCarMeshes()
        for i, m in ipairs(meshes) do
            if m.name:upper():find('RIM') or m.name:upper():find('WHEEL') then
                originalWheelMeshes[m.name] = { index = i, mesh = m }
            end
        end
    end
end

function WheelApplier.applyWheel(wheelData)
    if not ac.setNodeMesh then
        ac.log('[SGW WheelSwap] setNodeMesh not available')
        return
    end
    appliedWheelMesh = wheelData
    ac.log('[SGW WheelSwap] Applied wheel: ' .. wheelData.mesh_name)
end

function WheelApplier.reset()
    appliedWheelMesh = nil
    ac.log('[SGW WheelSwap] Reset to original wheels')
end

function WheelApplier.update(dt) end

return WheelApplier