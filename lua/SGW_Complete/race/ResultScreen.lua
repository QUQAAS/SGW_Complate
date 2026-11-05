local ui = require('ui')
local ac = require('ac')
local Config = require('shared/Config')

local ResultScreen = { showResults = false, resultsData = nil, animProgress = 0 }

function ResultScreen.init() end

function ResultScreen.show(data)
    ResultScreen.resultsData = data
    ResultScreen.showResults = true
    ResultScreen.animProgress = 0
end

function ResultScreen.update(dt)
    if not ResultScreen.showResults then return end
    ResultScreen.animProgress = math.min(1, ResultScreen.animProgress + dt * 0.5)
end

function ResultScreen.draw()
    if not ResultScreen.showResults or not ResultScreen.resultsData then return end

    local theme = Config.current.theme
    local COLORS = { bg = theme.background, panel = theme.panel, accent = theme.primary, gold = rgbm(1, 0.85, 0.15, 1), silver = rgbm(0.75, 0.75, 0.75, 1), bronze = rgbm(0.8, 0.5, 0.2, 1), text = theme.text, textDim = theme.textDim }

    local sw, sh = ac.getUI().windowSize.x, ac.getUI().windowSize.y
    local w, h = 500, 400
    local x, y = (sw - w) * 0.5, (sh - h) * 0.5

    ui.setNextWindowPos(vec2(x, y), ui.Cond.Always)
    ui.setNextWindowSize(vec2(w, h), ui.Cond.Always)

    if ui.beginWindow('##RaceResult', true, ui.WindowFlags.NoTitleBar + ui.WindowFlags.NoResize + ui.WindowFlags.NoMove) then
        ui.drawRectFilled(vec2(0,0), vec2(w, h), COLORS.bg)

        ui.setCursorPos(vec2(0, 20))
        ui.pushFont(ui.Font.Title)
        local title = ResultScreen.resultsData.winnerCarId == ac.getFocusedCar() and 'KAZANDINIZ!' or 'YARIŞ BİTTİ'
        local titleSize = ui.measureText(title)
        ui.setCursorPosX((w - titleSize.x) * 0.5)
        ui.textColored(title, ResultScreen.resultsData.winnerCarId == ac.getFocusedCar() and COLORS.gold or COLORS.accent)
        ui.popFont()

        ui.setCursorPos(vec2(0, 60))
        ui.textColored(string.format('Kazanan: %s', ResultScreen.resultsData.winnerName), COLORS.text)

        ui.setCursorPos(vec2(30, 110))
        ui.columns(4, '##results', true)
        ui.setColumnWidth(0, 50); ui.setColumnWidth(1, 200); ui.setColumnWidth(2, 120); ui.setColumnWidth(3, 80)

        ui.textColored('#', COLORS.textDim); ui.nextColumn()
        ui.textColored('Sürücü', COLORS.textDim); ui.nextColumn()
        ui.textColored('Süre / Puan', COLORS.textDim); ui.nextColumn()
        ui.textColored('Poz', COLORS.textDim); ui.nextColumn()
        ui.separator()

        for i, result in ipairs(ResultScreen.resultsData.results) do
            local posColor = COLORS.text
            if i == 1 then posColor = COLORS.gold
            elseif i == 2 then posColor = COLORS.silver
            elseif i == 3 then posColor = COLORS.bronze end

            ui.textColored(tostring(i), posColor); ui.nextColumn()
            ui.textColored(result.driverName, posColor); ui.nextColumn()
            local scoreText = string.format('%.3f', result.score)
            if ResultScreen.resultsData.results[1].score > 100 then scoreText = string.format('%.0f', result.score) end
            ui.textColored(scoreText, posColor); ui.nextColumn()
            ui.textColored(tostring(result.position), posColor); ui.nextColumn()
        end

        ui.columns(1)

        ui.setCursorPos(vec2((w - 150) * 0.5, h - 60))
        if ui.button('KAPAT', vec2(150, 40)) then
            ResultScreen.showResults = false
            ResultScreen.resultsData = nil
        end

        ui.endWindow()
    end
end

return ResultScreen