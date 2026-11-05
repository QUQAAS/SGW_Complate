local Utils = {}

function Utils.deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[Utils.deepCopy(k)] = Utils.deepCopy(v)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Utils.deepMerge(target, source)
    local result = Utils.deepCopy(target)
    for k, v in pairs(source) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = Utils.deepMerge(result[k], v)
        else
            result[k] = Utils.deepCopy(v)
        end
    end
    return result
end

function Utils.clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.formatDistance(meters)
    if meters >= 1000 then
        return string.format('%.2f km', meters / 1000)
    else
        return string.format('%.0f m', meters)
    end
end

function Utils.formatTime(seconds)
    if seconds >= 60 then
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format('%d:%06.3f', mins, secs)
    else
        return string.format('%.3f', seconds)
    end
end

return Utils