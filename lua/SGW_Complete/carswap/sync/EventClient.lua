local ac = require('ac')

local EventClient = {}

function EventClient.init() end

function EventClient.requestCarList()
    ac.sendServerEvent("SGW:CarSwap:RequestCarList", {})
end

function EventClient.requestSwap(targetIndex, targetModel, targetSkin)
    ac.sendServerEvent("SGW:CarSwap:RequestSwap", {
        targetCarIndex = targetIndex,
        targetModel = targetModel,
        targetSkin = targetSkin
    })
end

function EventClient.requestReset()
    ac.sendServerEvent("SGW:CarSwap:RequestReset", {})
end

function EventClient.requestFineTuneSave(wheelFitData)
    ac.sendServerEvent("SGW:CarSwap:RequestFineTuneSave", wheelFitData)
end

function EventClient.requestFineTuneLoad(cacheKey)
    ac.sendServerEvent("SGW:CarSwap:RequestFineTuneLoad", { cacheKey = cacheKey })
end

return EventClient