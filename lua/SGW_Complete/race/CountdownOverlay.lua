local ui = require('ui')
local ac = require('ac')

local CountdownOverlay = { countdownValue = 0, showCountdown = false, animScale = 1, animAlpha = 0 }

function CountdownOverlay.init() end

function CountdownOverlay.start(seconds)
    CountdownOverlay.countdownValue = seconds
    CountdownOverlay.showCountdown = true
    CountdownOverlay.animScale = 2.0
    CountdownOverlay.animAlpha = 0.0
end

function CountdownOverlay.setValue(val)
    CountdownOverlay.countdownValue = val
    CountdownOverlay.animScale = 2.0
    CountdownOverlay.animAlpha = 0.0
end

function CountdownOverlay.hide()
    CountdownOverlay.showCountdown = false
end

function CountdownOverlay.update(dt)
    if not CountdownOverlay.showCountdown then return end
    CountdownOverlay.animScale = CountdownOverlay.animScale - dt * 3
    if CountdownOverlay.animScale < 1 then CountdownOverlay.animScale = 1 end
    CountdownOverlay.animAlpha = CountdownOverlay.animAlpha + dt * 4
    if CountdownOverlay.animAlpha > 1 then CountdownOverlay.animAlpha = 1 end
    if CountdownOverlay.countdownValue <= 0 then CountdownOverlay.showCountdown = false end
end

function CountdownOverlay.draw()
    if not CountdownOverlay.showCountdown or CountdownOverlay.countdownValue <= 0 then return end

    local sw, sh = ac.getUI().windowSize.x, ac.getUI().windowSize.y
    local cx, cy = sw * 0.5, sh * 0.4

    ui.drawRectFilled(vec2(0,0), vec2(sw, sh), rgbm(0,0,0, CountdownOverlay.animAlpha * 0.5))

    local text = tostring(CountdownOverlay.countdownValue)
    local color = rgbm(0.85, 0.15, 0.15, CountdownOverlay.animAlpha)
    if CountdownOverlay.countdownValue == 2 then color = rgbm(1, 0.6, 0.1, CountdownOverlay.animAlpha)
    elseif CountdownOverlay.countdownValue == 1 then color = rgbm(0.2, 0.85, 0.3, CountdownOverlay.animAlpha) end

    ui.pushFont(ui.Font.Huge)
    local textSize = ui.measureText(text)
    ui.setCursorPos(vec2(cx - textSize.x * CountdownOverlay.animScale * 0.5, cy - textSize.y * CountdownOverlay.animScale * 0.5))
    ui.textColored(text, color)
    ui.popFont()
end

return CountdownOverlay