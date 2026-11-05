local ui = require('ui')
local ac = require('ac')
local Config = require('shared/Config')
local RaceClient = require('race/core/RaceClient')

local RaceInviteCard = { showCard = false, inviteData = nil, autoCloseTimer = 15 }

function RaceInviteCard.init() end

function RaceInviteCard.show(data)
    RaceInviteCard.inviteData = data
    RaceInviteCard.showCard = true
    RaceInviteCard.autoCloseTimer = 15
end

function RaceInviteCard.hide()
    RaceInviteCard.showCard = false
    RaceInviteCard.inviteData = nil
end

function RaceInviteCard.update(dt)
    if not RaceInviteCard.showCard or not RaceInviteCard.inviteData then return end
    RaceInviteCard.autoCloseTimer = RaceInviteCard.autoCloseTimer - dt
    if RaceInviteCard.autoCloseTimer <= 0 then
        RaceClient.respondInvite(RaceInviteCard.inviteData.inviteId, false)
        RaceInviteCard.hide()
    end
end

function RaceInviteCard.draw()
    if not RaceInviteCard.showCard or not RaceInviteCard.inviteData then return end

    local theme = Config.current.theme
    local COLORS = { bg = theme.background, panel = theme.panel, accent = theme.primary, green = theme.success, red = theme.danger, text = theme.text, textDim = theme.textDim }

    local sw, sh = ac.getUI().windowSize.x, ac.getUI().windowSize.y
    local w, h = 420, 220
    local x, y = sw - w - 30, sh - h - 100

    ui.setNextWindowPos(vec2(x, y), ui.Cond.Always)
    ui.setNextWindowSize(vec2(w, h), ui.Cond.Always)

    if ui.beginWindow('##RaceInvite', true, ui.WindowFlags.NoTitleBar + ui.WindowFlags.NoResize + ui.WindowFlags.NoMove + ui.WindowFlags.AlwaysAutoResize) then
        ui.drawRectFilled(vec2(0,0), vec2(w, 50), COLORS.panel)
        ui.setCursorPos(vec2(15, 10))
        ui.pushFont(ui.Font.Title)
        ui.textColored('YARIŞ DAVETİ', COLORS.accent)
        ui.popFont()

        local barW = (w - 30) * (RaceInviteCard.autoCloseTimer / 15)
        ui.drawRectFilled(vec2(15, 45), vec2(15 + barW, 48), COLORS.green)

        ui.setCursorPos(vec2(15, 60))
        ui.textColored(RaceInviteCard.inviteData.inviterName .. ' seni davet ediyor', COLORS.text)
        ui.setCursorPos(vec2(15, 90))
        ui.textColored(RaceInviteCard.inviteData.raceTypeName, COLORS.accent)
        ui.setCursorPos(vec2(15, 115))
        ui.textColored(string.format('Mesafe: %s', Utils.formatDistance(RaceInviteCard.inviteData.distanceMeters)), COLORS.textDim)

        ui.setCursorPos(vec2(15, 160))
        ui.pushStyleColor(ui.StyleColor.Button, COLORS.green)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.3, 1, 0.4, 1))
        if ui.button('KABUL ET', vec2(170, 45)) then
            RaceClient.respondInvite(RaceInviteCard.inviteData.inviteId, true)
            RaceInviteCard.hide()
        end
        ui.popStyleColor(2)
        ui.sameLine(20)
        ui.pushStyleColor(ui.StyleColor.Button, COLORS.red)
        ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(1, 0.3, 0.3, 1))
        if ui.button('REDDET', vec2(170, 45)) then
            RaceClient.respondInvite(RaceInviteCard.inviteData.inviteId, false)
            RaceInviteCard.hide()
        end
        ui.popStyleColor(2)

        ui.endWindow()
    end
end

return RaceInviteCard