local ui = require('ui')
local ac = require('ac')
local Config = require('shared/Config')
local StanceApplier = require('stance/core/StanceApplier')

local StanceMenu = { isVisible = false }

function StanceMenu.init() end
function StanceMenu.setVisible(v) StanceMenu.isVisible = v end

function StanceMenu.draw(isOpen)
    if not isOpen then return end

    local theme = Config.current.theme
    local COLORS = { bg = theme.background, panel = theme.panel, accent = theme.primary, text = theme.text, textDim = theme.textDim, green = theme.success }

    ui.setNextWindowPos(vec2(ac.getUI().windowSize.x * 0.5 - 200, 200), ui.Cond.FirstUseEver)
    ui.setNextWindowSize(vec2(400, 350), ui.Cond.FirstUseEver)

    if ui.beginWindow('SGW Stance', true, ui.WindowFlags.NoCollapse + ui.WindowFlags.NoResize) then
        ui.pushFont(ui.Font.Title)
        ui.textColored('STANCE AYARLARI', COLORS.accent)
        ui.popFont()
        ui.dummy(vec2(0, 15))

        local data = StanceApplier.getData()

        local function slider(label, key, min, max)
            ui.text(label)
            ui.sameLine(180)
            ui.pushItemWidth(200)
            local changed, val = ui.slider('##' .. key, data[key], min, max, '%.1f')
            if changed then StanceApplier['set' .. key:sub(1,1):upper() .. key:sub(2)](val) end
            ui.popItemWidth()
        end

        slider('Ön Kamber', 'frontCamber', -5, 5)
        slider('Arka Kamber', 'rearCamber', -5, 5)
        slider('Ön Offset (cm)', 'frontOffset', -5, 5)
        slider('Arka Offset (cm)', 'rearOffset', -5, 5)

        ui.dummy(vec2(0, 20))
        if ui.button('SIFIRLA', vec2(180, 36)) then StanceApplier.reset() end
        ui.sameLine()
        if ui.button('KAPAT', vec2(180, 36)) then StanceMenu.isVisible = false end

        ui.endWindow()
    else
        StanceMenu.isVisible = false
    end
end

return StanceMenu