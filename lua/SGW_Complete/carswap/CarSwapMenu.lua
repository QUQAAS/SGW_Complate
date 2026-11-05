local ui = require('ui')
local ac = require('ac')
local Config = require('shared/Config')
local EventClient = require('carswap/sync/EventClient')
local Utils = require('shared/Utils')

local CarSwapMenu = {}

local windowVisible = false
local selectedCarIndex = 1
local searchFilter = ""
local fineTuneMode = false
local fineTuneValues = {
    frontOffsetX = 0, rearOffsetX = 0, heightOffset = 0,
    scale = 1.0, camberFront = 0, camberRear = 0
}
local errorMessage = ""
local errorTimer = 0
local showCompatibility = true

local COLORS = {}

function CarSwapMenu.init()
    CarSwapMenu.updateColors()
end

function CarSwapMenu.updateColors()
    local theme = Config.current.theme
    COLORS = {
        bg = theme.background,
        panel = theme.panel,
        accent = theme.primary,
        accentHover = rgbm(math.min(1, theme.primary.r + 0.15), math.min(1, theme.primary.g + 0.05), math.min(1, theme.primary.b + 0.05), 1),
        text = theme.text,
        textDim = theme.textDim,
        green = theme.success,
        yellow = theme.warning,
        red = theme.danger,
        border = rgbm(theme.primary.r, theme.primary.g, theme.primary.b, 0.3),
        sliderBg = rgbm(0.2, 0.05, 0.05, 0.8)
    }
end

function CarSwapMenu.setVisible(visible)
    windowVisible = visible
end

function CarSwapMenu.draw(isOpen, availableCars, currentState)
    if not isOpen then return end

    CarSwapMenu.updateColors()

    ui.setNextWindowPos(vec2(ac.getUI().windowSize.x * 0.5 - 450, 100), ui.Cond.FirstUseEver)
    ui.setNextWindowSize(vec2(900, 600), ui.Cond.FirstUseEver)

    if ui.beginWindow('SGW CarSwap', true, ui.WindowFlags.NoCollapse + ui.WindowFlags.NoResize) then
        CarSwapMenu.drawHeader()
        ui.separator()
        CarSwapMenu.drawCarList(availableCars)
        ui.separator()
        CarSwapMenu.drawFooter(currentState)
        ui.endWindow()
    else
        windowVisible = false
    end
end

function CarSwapMenu.drawHeader()
    ui.dummy(vec2(0, 5))
    ui.sameLine(20)

    local iconPath = ac.getFolder(ac.FolderID.Content) .. '/apps/lua/SGW_Complete/assets/icon.png'
    if ui.imageButton('##logo', iconPath, vec2(32, 32), vec2(0,0), vec2(1,1), COLORS.panel, COLORS.accent) then end
    ui.sameLine()

    ui.pushFont(ui.Font.Title)
    ui.textColored('SÖNMEZ GAME WORLD', COLORS.accent)
    ui.popFont()
    ui.sameLine()
    ui.textColored('|  GÖRSEL ARAÇ DEĞİŞTİRME', COLORS.textDim)

    ui.dummy(vec2(0, 5))

    ui.pushItemWidth(300)
    local changed, newFilter = ui.inputText('##search', searchFilter, ui.InputTextFlags.PlaceholderText)
    if changed then searchFilter = newFilter end
    ui.popItemWidth()
    ui.sameLine()
    ui.textColored('Araç ara...', COLORS.textDim)

    ui.sameLine(ui.getWindowWidth() - 200)
    if ui.checkbox('Uyumluluk Göster', showCompatibility) then showCompatibility = not showCompatibility end
end

function CarSwapMenu.drawCarList(availableCars)
    local cars = availableCars or {}
    local filtered = {}

    for i, car in ipairs(cars) do
        if searchFilter == "" or car.model:lower():find(searchFilter:lower()) or (car.displayName and car.displayName:lower():find(searchFilter:lower())) then
            table.insert(filtered, {index = i, data = car})
        end
    end

    if #filtered == 0 then
        ui.textColored('Uygun araç bulunamadı', COLORS.textDim)
        return
    end

    ui.beginChild('##carlist', vec2(0, 380), true, ui.WindowFlags.HorizontalScrollbar)
    ui.columns(5, '##carlistcols', true)
    ui.setColumnWidth(0, 40)
    ui.setColumnWidth(1, 280)
    ui.setColumnWidth(2, 150)
    ui.setColumnWidth(3, 120)
    ui.setColumnWidth(4, 120)

    ui.textColored('#', COLORS.textDim); ui.nextColumn()
    ui.textColored('Model', COLORS.textDim); ui.nextColumn()
    ui.textColored('Skin', COLORS.textDim); ui.nextColumn()
    ui.textColored('Uyumluluk', COLORS.textDim); ui.nextColumn()
    ui.textColored('İşlem', COLORS.textDim); ui.nextColumn()
    ui.separator()

    for _, item in ipairs(filtered) do
        local i = item.index
        local car = item.data
        local isSelected = (i == selectedCarIndex)

        ui.text(tostring(i)); ui.nextColumn()

        if isSelected then ui.pushStyleColor(ui.StyleColor.Text, COLORS.accent) end
        ui.text(car.model or 'Unknown'); ui.nextColumn()
        if isSelected then ui.popStyleColor() end

        ui.text(car.skin or 'default'); ui.nextColumn()

        if showCompatibility and car.compatibility then
            local compat = car.compatibility
            local compatColor = compat.level == 'green' and COLORS.green or compat.level == 'yellow' and COLORS.yellow or COLORS.red
            ui.textColored('● ' .. (compat.reason or 'Bilinmiyor'), compatColor)
        else
            ui.text('')
        end
        ui.nextColumn()

        local btnLabel = (CarSwapModule and CarSwapModule.currentState and CarSwapModule.currentState.isSwapped) and 'DEĞİŞTİR' or 'SEÇ'
        if ui.button(btnLabel .. '##' .. i, vec2(100, 28)) then
            selectedCarIndex = i
            CarSwapMenu.onSelectCar(car)
        end
        ui.nextColumn()
    end

    ui.columns(1)
    ui.endChild()
end

function CarSwapMenu.drawFooter(currentState)
    ui.dummy(vec2(0, 10))

    if currentState and currentState.isSwapped then
        ui.pushStyleColor(ui.StyleColor.Button, COLORS.accent)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, COLORS.accentHover)
        if ui.button('ORİJİNALE DÖN', vec2(180, 36)) then
            CarSwapMenu.onReset()
        end
        ui.popStyleColor(2)
        ui.sameLine()
        ui.dummy(vec2(20, 0))
        ui.sameLine()

        if ui.button('İNCE AYAR', vec2(140, 36)) then
            fineTuneMode = not fineTuneMode
        end
        ui.sameLine()
    end

    ui.dummy(vec2(0, 0))
    ui.sameLine(ui.getWindowWidth() - 120)
    if ui.button('KAPAT', vec2(100, 36)) then
        windowVisible = false
    end

    if errorMessage ~= "" then
        ui.dummy(vec2(0, 10))
        ui.textColored(errorMessage, COLORS.red)
    end

    if fineTuneMode then
        CarSwapMenu.drawFineTunePanel()
    end
end

function CarSwapMenu.drawFineTunePanel()
    ui.dummy(vec2(0, 15))
    ui.separator()
    ui.textColored('İNCE AYAR (Kaydedilecek)', COLORS.accent)

    local fit = CarSwapModule.currentState and CarSwapModule.currentState.wheelFit or {}

    ui.columns(2, '##finetune', false)
    ui.setColumnWidth(0, 200)

    local function slider(label, key, min, max, format)
        ui.text(label); ui.nextColumn()
        ui.pushItemWidth(300)
        local val = fit[key] or 0
        local changed, newVal = ui.slider('##' .. key, val, min, max, format or '%.3f')
        if changed then fit[key] = newVal end
        ui.popItemWidth()
        ui.nextColumn()
    end

    slider('Ön Offset X', 'frontOffsetX', -0.3, 0.3)
    slider('Arka Offset X', 'rearOffsetX', -0.3, 0.3)
    slider('Yükseklik', 'heightOffset', -0.15, 0.15)
    slider('Ölçek', 'scale', 0.9, 1.1, '%.2f')
    slider('Ön Kamber', 'camberFront', -5, 5, '%.1f°')
    slider('Arka Kamber', 'camberRear', -5, 5, '%.1f°')

    ui.columns(1)

    ui.dummy(vec2(0, 10))
    if ui.button('UYGULA VE KAYDET', vec2(180, 32)) then
        CarSwapMenu.onFineTuneSave(fit)
        fineTuneMode = false
    end
    ui.sameLine()
    if ui.button('SIFIRLA', vec2(120, 32)) then
        fit.frontOffsetX = 0; fit.rearOffsetX = 0; fit.heightOffset = 0
        fit.scale = 1.0; fit.camberFront = 0; fit.camberRear = 0
    end
    ui.sameLine()
    if ui.button('İPTAL', vec2(100, 32)) then
        fineTuneMode = false
    end
end

function CarSwapMenu.onSelectCar(car)
    EventClient.requestSwap(car.index - 1, car.model, car.skin or 'default')
end

function CarSwapMenu.onReset()
    EventClient.requestReset()
end

function CarSwapMenu.onFineTuneSave(fit)
    EventClient.requestFineTuneSave(fit)
end

function CarSwapMenu.onSwapSuccess() end
function CarSwapMenu.onSwapReset() end
function CarSwapMenu.onFineTuneSaved(cacheKey) end
function CarSwapMenu.onFineTuneLoaded(fit) end

function CarSwapMenu.showError(msg)
    errorMessage = msg
    errorTimer = 5.0
end

function CarSwapMenu.refreshCarList(cars)
end

return CarSwapMenu