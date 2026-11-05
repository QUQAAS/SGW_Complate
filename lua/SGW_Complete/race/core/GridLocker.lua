local ac = require('ac')

local GridLocker = { isLocked = false, lockPos = vec3(0,0,0), lockRot = vec3(0,0,0) }

function GridLocker.init() end

function GridLocker.lockToPosition(pos, rot)
    GridLocker.lockPos = pos
    GridLocker.lockRot = rot
    GridLocker.isLocked = true
end

function GridLocker.unlock()
    GridLocker.isLocked = false
end

function GridLocker.update(dt)
    if not GridLocker.isLocked then return end
    if ac.setCarPosition then ac.setCarPosition(0, GridLocker.lockPos, GridLocker.lockRot) end
    if ac.setCarVelocity then ac.setCarVelocity(0, vec3(0,0,0)) end
end

return GridLocker