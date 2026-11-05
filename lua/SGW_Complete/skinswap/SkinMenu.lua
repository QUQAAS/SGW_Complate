local ui = require('ui')
local ac = require('ac')
local Config = require('shared/Config')
local SkinApplier = require('skinswap/core/SkinApplier')

local SkinMenu = { isVisible = false, availableSkins = {} }

function SkinMenu.init()
    SkinMenu.loadAvailableSkins()
end

function SkinMenu.loadAvailableSkins()
    local model = ac.getCarName(0)
    SkinMenu.availableSkins = { 'Orijinal', 'SGW_Kırmızı', 'SGW_Siyah', 'SGW_Beyaz', 'SGW_Gri', 'SGW_Altın', 'SGW_Mat_Siyah', 'SGW_Mat_Kırmızı' }
end

function SkinMenu.setVisible(v) SkinMenu.isVisible = v end

function SkinMenu.draw(isOpen)
    if not isOpen then return end

    local theme = Config.current.theme
    local COLORS = { bg = theme.background, panel = theme.panel, accent = theme.primary, text = theme.text, textDim = theme.textDim, green = theme.success }

    ui.setNextWindowPos(vec2(ac.getUI().windowSize.x * 0.5 - 200, 200), ui.Cond.FirstUseEver)
    ui.setNextWindowSize(vec2(400, 400), ui.Cond.FirstUseEver)

    if ui.beginWindow('SGW SkinSwap', true, ui.WindowFlags.NoCollapse + ui.WindowFlags.NoResize) then
        ui.pushFont(ui.Font.Title)
        ui.textColored('KAPLAMA / RENK', COLORS.accent)
        ui.popFont()
        ui.dummy(vec2(0, 15))

        ui.textColored('Mevcut Araç: ' .. ac.getCarName(0), COLORS.textDim)
        ui.dummy(vec2(0, 10))

        ui.beginChild('##skinlist', vec2(0, 280), true)
        for _, skin in ipairs(SkinMenu.availableSkins) do
            if ui.selectable(skin, false, 0, vec2(0, 30)) then
                SkinApplier.applySkin(skin)
            end
        end
        ui.endChild()

        ui.dummy(vec2(0, 10))
        if ui.button('ORİJİNALE DÖN', vec2(180, 32)) then SkinApplier.reset() end
        ui.sameLine()
        if ui.button('KAPAT', vec2(180, 32)) then SkinMenu.isVisible = false end

        ui.endWindow()
    else
        SkinMenu.isVisible = false
    end
end

return SkinMenu