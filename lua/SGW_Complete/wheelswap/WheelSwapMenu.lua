local ui = require('ui')
local ac = require('ac')
local Config = require('shared/Config')
local WheelApplier = require('wheelswap/core/WheelApplier')

local WheelSwapMenu = { isVisible = false, wheelCatalog = {}, selectedWheel = 1, searchFilter = "" }

function WheelSwapMenu.init() end

function WheelSwapMenu.setWheelCatalog(catalog) WheelSwapMenu.wheelCatalog = catalog or {} end
function WheelSwapMenu.setVisible(v) WheelSwapMenu.isVisible = v end

function WheelSwapMenu.draw(isOpen)
    if not isOpen then return end

    local theme = Config.current.theme
    local COLORS = { bg = theme.background, panel = theme.panel, accent = theme.primary, text = theme.text, textDim = theme.textDim }

    ui.setNextWindowPos(vec2(ac.getUI().windowSize.x * 0.5 - 350, 100), ui.Cond.FirstUseEver)
    ui.setNextWindowSize(vec2(700, 500), ui.Cond.FirstUseEver)

    if ui.beginWindow('SGW WheelSwap', true, ui.WindowFlags.NoCollapse + ui.WindowFlags.NoResize) then
        ui.pushFont(ui.Font.Title)
        ui.textColored('JANT DEĞİŞTİRME', COLORS.accent)
        ui.popFont()
        ui.dummy(vec2(0, 10))

        ui.pushItemWidth(300)
        local changed, newFilter = ui.inputText('##search', WheelSwapMenu.searchFilter, ui.InputTextFlags.PlaceholderText)
        if changed then WheelSwapMenu.searchFilter = newFilter end
        ui.popItemWidth()
        ui.sameLine()
        ui.textColored('Jant ara...', COLORS.textDim)

        ui.dummy(vec2(0, 10))
        ui.beginChild('##wheellist', vec2(0, 380), true)

        for carName, carData in pairs(WheelSwapMenu.wheelCatalog) do
            if WheelSwapMenu.searchFilter == "" or carName:lower():find(WheelSwapMenu.searchFilter:lower()) then
                if ui.treeNode(carName .. ' (' .. #carData.wheels .. ' jant)') then
                    for _, wheel in ipairs(carData.wheels) do
                        ui.bulletText(wheel.mesh_name .. ' [' .. wheel.type .. '] r=' .. string.format('%.2f', wheel.estimated_radius))
                        ui.sameLine()
                        if ui.button('TAK##' .. wheel.mesh_name, vec2(60, 22)) then
                            WheelApplier.applyWheel(wheel)
                        end
                    end
                    ui.treePop()
                end
            end
        end
        ui.endChild()

        ui.dummy(vec2(0, 10))
        if ui.button('ORİJİNALE DÖN', vec2(150, 32)) then WheelApplier.reset() end
        ui.sameLine()
        if ui.button('KAPAT', vec2(100, 32)) then WheelSwapMenu.isVisible = false end

        ui.endWindow()
    else
        WheelSwapMenu.isVisible = false
    end
end

return WheelSwapMenu