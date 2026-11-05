local ac = require('ac')
local io = require('io')

local CarDataReader = {}
local carDataCache = {}

function CarDataReader.init()
    carDataCache = {}
end

function CarDataReader.getCarData(model, skin)
    local key = model .. "_" .. (skin or "")
    if carDataCache[key] then return carDataCache[key] end

    local data = {
        model = model, skin = skin,
        frontTrack = 1.5, rearTrack = 1.5, wheelRadius = 0.33,
        hasValidData = false
    }

    local carPath = ac.getFolder(ac.FolderID.Cars) .. '/' .. model .. '/data/'

    local suspPath = carPath .. 'suspensions.ini'
    if io.fileExists(suspPath) then
        local content = io.loadText(suspPath)
        data.frontTrack = CarDataReader.parseIniFloat(content, 'FRONT', 'TRACK') or 1.5
        data.rearTrack = CarDataReader.parseIniFloat(content, 'REAR', 'TRACK') or 1.5
    end

    local tyrePath = carPath .. 'tyres.ini'
    if io.fileExists(tyrePath) then
        local content = io.loadText(tyrePath)
        data.wheelRadius = CarDataReader.parseIniFloat(content, 'TYRE_0', 'RADIUS') or 0.33
    end

    data.hasValidData = data.frontTrack > 0 and data.rearTrack > 0 and data.wheelRadius > 0
    carDataCache[key] = data
    return data
end

function CarDataReader.parseIniFloat(content, section, key)
    local inSection = false
    for line in content:gmatch('[^\r\n]+') do
        line = line:match('^%s*(.-)%s*$')
        if line:sub(1,1) == '[' and line:sub(-1) == ']' then
            inSection = line:sub(2,-2):lower() == section:lower()
        elseif inSection then
            local k, v = line:match('^([^=]+)=(.+)$')
            if k and k:match('^%s*(.-)%s*$'):lower() == key:lower() then
                return tonumber(v:match('^%s*(.-)%s*$'))
            end
        end
    end
    return nil
end

function CarDataReader.calculateCompatibility(sourceModel, targetCar)
    local sourceData = CarDataReader.getCarData(sourceModel, "")
    if not sourceData.hasValidData or not targetCar.hasValidData then
        return { score = 0.5, level = 'yellow', reason = 'Veri eksik' }
    end

    local trackDiff = math.abs(targetCar.frontTrack - sourceData.frontTrack) + math.abs(targetCar.rearTrack - sourceData.rearTrack)
    local radiusDiff = math.abs(targetCar.wheelRadius - sourceData.wheelRadius)
    local score = 1.0 - math.min(1.0, (trackDiff * 2.0 + radiusDiff * 5.0))

    local level, reason
    if score >= 0.85 then level, reason = 'green', 'Mükemmel uyum'
    elseif score >= 0.65 then level, reason = 'yellow', 'Küçük ayar gerekli'
    else level, reason = 'red', 'Büyük fark, manuel ayar önerilir' end

    return { score = score, level = level, reason = reason }
end

return CarDataReader