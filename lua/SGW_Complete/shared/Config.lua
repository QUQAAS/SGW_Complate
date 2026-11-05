local ac = require('ac')
local io = require('io')
local json = require('json')

local Config = {}

local defaultConfig = {
    theme = {
        primary = {0.85, 0.15, 0.15, 1.0},
        background = {0.08, 0.08, 0.09, 0.98},
        panel = {0.12, 0.12, 0.13, 1.0},
        text = {1.0, 1.0, 1.0, 1.0},
        textDim = {0.7, 0.7, 0.7, 1.0},
        success = {0.2, 0.85, 0.3, 1.0},
        warning = {1.0, 0.85, 0.15, 1.0},
        danger = {0.9, 0.2, 0.2, 1.0}
    },
    keybinds = {
        openMainMenu = 0x70,
        openWheelMenu = 0x71,
        openStanceMenu = 0x72,
        openSkinMenu = 0x73,
        openRaceMenu = 0x74
    },
    carswap = {
        autoApplyFineTune = true,
        showCompatibilityIndicators = true,
        maxScaleDeviation = 0.05
    },
    wheelswap = { previewRotationSpeed = 1.0 },
    stance = { maxCamber = 5.0, maxOffset = 5.0 },
    race = { inviteTimeout = 15, countdownDuration = 3, showGreenLine = true, greenLineWidth = 12.0 }
}

Config.current = {}

function Config.load()
    local path = ac.getFolder(ac.FolderID.Cfg) .. '/SGW_Complete.json'

    if io.fileExists(path) then
        local content = io.loadText(path)
        local ok, loaded = pcall(json.decode, content)
        if ok and loaded then
            Config.current = Utils.deepMerge(defaultConfig, loaded)
        else
            Config.current = defaultConfig
        end
    else
        Config.current = defaultConfig
        Config.save()
    end

    for k, v in pairs(Config.current.theme) do
        if type(v) == 'table' and #v == 4 then
            Config.current.theme[k] = rgbm(v[1], v[2], v[3], v[4])
        end
    end
end

function Config.save()
    local path = ac.getFolder(ac.FolderID.Cfg) .. '/SGW_Complete.json'
    local toSave = Utils.deepCopy(Config.current)

    for k, v in pairs(toSave.theme) do
        if type(v) == 'userdata' then
            toSave.theme[k] = {v.r, v.g, v.b, v.a}
        end
    end

    io.saveText(path, json.encode(toSave, {indent = true}))
end

function Config.get(key)
    local keys = {}
    for k in key:gmatch('[^.]+') do table.insert(keys, k) end

    local val = Config.current
    for _, k in ipairs(keys) do
        if val[k] == nil then return nil end
        val = val[k]
    end
    return val
end

return Config