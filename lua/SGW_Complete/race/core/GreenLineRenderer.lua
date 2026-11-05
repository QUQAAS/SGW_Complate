local ac = require('ac')

local GreenLineRenderer = { finishLinePos = nil, finishLineDir = nil, visible = false, lineWidth = 12.0 }

function GreenLineRenderer.init() end

function GreenLineRenderer.setFinishLine(pos, dir)
    GreenLineRenderer.finishLinePos = vec3(pos.x, pos.y + 0.05, pos.z)
    GreenLineRenderer.finishLineDir = vec3(dir.x, 0, dir.z)
    if GreenLineRenderer.finishLineDir:length() > 0 then GreenLineRenderer.finishLineDir = GreenLineRenderer.finishLineDir:normalize() end
    GreenLineRenderer.visible = true
end

function GreenLineRenderer.clear()
    GreenLineRenderer.visible = false
    GreenLineRenderer.finishLinePos = nil
    GreenLineRenderer.finishLineDir = nil
end

function GreenLineRenderer.update(dt) end

function GreenLineRenderer.render(dt)
    if not GreenLineRenderer.visible or not GreenLineRenderer.finishLinePos or not ac.draw3DLine then return end

    local right = vec3(-GreenLineRenderer.finishLineDir.z, 0, GreenLineRenderer.finishLineDir.x)
    local startPt = GreenLineRenderer.finishLinePos - right * (GreenLineRenderer.lineWidth / 2)
    local endPt = GreenLineRenderer.finishLinePos + right * (GreenLineRenderer.lineWidth / 2)

    ac.draw3DLine(startPt, endPt, rgbm(0, 1, 0, 1), 0.3)

    for i = 1, 3 do
        local offset = i * 5
        local s = startPt + GreenLineRenderer.finishLineDir * offset
        local e = endPt + GreenLineRenderer.finishLineDir * offset
        ac.draw3DLine(s, e, rgbm(0, 1, 0, 0.5), 0.15)
        local s2 = startPt - GreenLineRenderer.finishLineDir * offset
        local e2 = endPt - GreenLineRenderer.finishLineDir * offset
        ac.draw3DLine(s2, e2, rgbm(0, 1, 0, 0.5), 0.15)
    end

    if ac.draw3DText then
        local textPos = GreenLineRenderer.finishLinePos + GreenLineRenderer.finishLineDir * 3 + vec3(0, 2, 0)
        ac.draw3DText(textPos, "FINISH", rgbm(0, 1, 0, 1), 1.5, true)
    end
end

return GreenLineRenderer