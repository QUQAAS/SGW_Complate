local ui = require('ui')
local ac = require('ac')
local Config = require('shared/Config')
local Utils = require('shared/Utils')

local RaceHUD = { showHUD = false, raceData = nil, myCarId = -1 }

function RaceHUD.init() end

function RaceHUD.updateData(data) RaceHUD.raceData = data end

function RaceHUD.update(dt)
    if RaceHUD.myCarId == -1 then RaceHUD.myCarId = ac.getFocusedCar() end
    RaceHUD.showHUD = RaceHUD.raceData ~= nil
end

function RaceHUD.draw()
    if not RaceHUD.showHUD or not RaceHUD.raceData then return end

    local theme = Config.current.theme
    local COLORS = { bg = theme.background, panel = theme.panel, accent = theme.primary, text = theme.text, textDim = theme.textDim, green = theme.success, yellow = theme.warning }

    local sw, sh = ac.getUI().windowSize.x, ac.getUI().windowSize.y
    local w, h = 300, 180
    local x, y = 20, 20

    ui.setNextWindowPos(vec2(x, y), ui.Cond.Always)
    ui.setNextWindowSize(vec2(w, h), ui.Cond.Always)

    if ui.beginWindow('##RaceHUD', true, ui.WindowFlags.NoTitleBar + ui.WindowFlags.NoResize + ui.WindowFlags.NoMove) then
        ui.drawRectFilled(vec2(0,0), vec2(w, 35), COLORS.panel)
        ui.setCursorPos(vec2(10, 5))
        ui.pushFont(ui.Font.Title)
        ui.textColored('YARIŞ AKTİF', COLORS.accent)
        ui.popFont()
        ui.setCursorPos(vec2(w - 100, 5))
        ui.textColored(string.format('%.1fs', RaceHUD.raceData.elapsedTime), COLORS.text)

        ui.setCursorPos(vec2(10, 45))
        local myRacer = nil
        for _, r in ipairs(RaceHUD.raceData.racers or {}) do
            if r.carId == RaceHUD.myCarId then myRacer = r; break end
        end

        if myRacer then
            local remaining = math.max(0, (RaceHUD.raceData.distanceMeters or 0) - myRacer.distanceTraveled)
            ui.textColored(string.format('Kalan: %s', Utils.formatDistance(remaining)), COLORS.text)
            ui.setCursorPos(vec2(10, 70))
            ui.textColored(string.format('Sıralama: %d / %d', myRacer.position, #RaceHUD.raceData.racers), COLORS.accent)

            if myRacer.points and myRacer.points > 0 then
                ui.setCursorPos(vec2(10, 95))
                ui.textColored(string.format('Puan: %.0f', myRacer.points), COLORS.yellow)
                if myRacer.combo and myRacer.combo > 1 then
                    ui.sameLine()
                    ui.textColored(string.format(' x%d COMBO!', myRacer.combo), COLORS.accent)
                end
            end
        end

        ui.setCursorPos(vec2(10, 125))
        ui.textColored('KATILIMCILAR:', COLORS.textDim)
        local yOffset = 145
        for _, r in ipairs(RaceHUD.raceData.racers or {}) do
            if yOffset > h - 20 then break end
            ui.setCursorPos(vec2(15, yOffset))
            local color = (r.carId == RaceHUD.myCarId) and COLORS.accent or COLORS.text
            ui.textColored(string.format('%d. %s', r.position, r.driverName), color)
            yOffset = yOffset + 18
        end

        ui.endWindow()
    end
end

return RaceHUD