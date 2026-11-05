local ac = require('ac')

local RaceClient = {}
local pendingInvite = nil
local raceState = nil
local countdownValue = 0
local raceResults = nil

RaceEventNames = {
    RequestRaceInvite = "SGW:Race:RequestInvite",
    RespondInvite = "SGW:Race:RespondInvite",
    RequestRaceTypes = "SGW:Race:RequestTypes",
    InviteReceived = "SGW:Race:InviteReceived",
    RaceStarting = "SGW:Race:Starting",
    Countdown = "SGW:Race:Countdown",
    RaceStarted = "SGW:Race:Started",
    RaceUpdate = "SGW:Race:Update",
    RaceFinished = "SGW:Race:Finished",
    RaceCancelled = "SGW:Race:Cancelled",
    RaceTypesList = "SGW:Race:TypesList",
    Error = "SGW:Race:Error"
}

function RaceClient.init()
    ac.onServerEvent(RaceEventNames.InviteReceived, function(data) pendingInvite = data end)
    ac.onServerEvent(RaceEventNames.RaceStarting, function(data)
        raceState = {
            inviteId = data.inviteId,
            gridPositions = data.gridPositions,
            finishLinePos = data.finishLinePos,
            finishLineDir = data.finishLineDir,
            distanceMeters = data.distanceMeters,
            isRacing = false,
            isCountdown = true
        }
    end)
    ac.onServerEvent(RaceEventNames.Countdown, function(data) countdownValue = data.seconds end)
    ac.onServerEvent(RaceEventNames.RaceStarted, function(data)
        if raceState then raceState.isRacing = true; raceState.isCountdown = false end
    end)
    ac.onServerEvent(RaceEventNames.RaceUpdate, function(data)
        if raceState then raceState.elapsedTime = data.elapsedTime; raceState.racers = data.racers end
    end)
    ac.onServerEvent(RaceEventNames.RaceFinished, function(data)
        raceResults = data
        if raceState then raceState.isRacing = false end
    end)
    ac.onServerEvent(RaceEventNames.RaceCancelled, function(data)
        pendingInvite = nil; raceState = nil; countdownValue = 0
    end)
end

function RaceClient.process() end

function RaceClient.requestInvite(raceTypeId, distance, targetCarIds)
    ac.sendServerEvent(RaceEventNames.RequestRaceInvite, { raceTypeId = raceTypeId, distanceMeters = distance, targetCarIds = targetCarIds })
end

function RaceClient.respondInvite(inviteId, accepted)
    ac.sendServerEvent(RaceEventNames.RespondInvite, { inviteId = inviteId, accepted = accepted })
end

function RaceClient.requestRaceTypes()
    ac.sendServerEvent(RaceEventNames.RequestRaceTypes, {})
end

function RaceClient.getPendingInvite() return pendingInvite end
function RaceClient.getRaceState() return raceState end
function RaceClient.getCountdown() return countdownValue end
function RaceClient.getResults() return raceResults end

return RaceClient