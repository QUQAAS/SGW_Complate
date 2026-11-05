using System.Collections.Concurrent;
using System.Text.Json;
using AssettoServer.Server;
using AssettoServer.Shared;
using SGW.Complete.Server.Race.Events;
using SGW.Complete.Server.Race.RaceTypes;

namespace SGW.Complete.Server.Race;

public class InviteSystem
{
    private readonly IServer _server;
    private readonly IPluginLogger _logger;
    private readonly RaceTypeRegistry _raceTypeRegistry;
    private readonly ConcurrentDictionary<int, PendingInvite> _pendingInvites = new();
    private int _nextInviteId = 1;

    public InviteSystem(IServer server, IPluginLogger logger, RaceTypeRegistry raceTypeRegistry)
    {
        _server = server;
        _logger = logger;
        _raceTypeRegistry = raceTypeRegistry;
    }

    public void SendInvite(AssettoServer.Server.Connection inviter, RaceInviteRequest request)
    {
        var inviteId = Interlocked.Increment(ref _nextInviteId);

        var invite = new PendingInvite
        {
            InviteId = inviteId,
            InviterConnection = inviter,
            InviterCarId = inviter.Car?.Id ?? -1,
            InviterName = inviter.PlayerName,
            RaceTypeId = request.RaceTypeId,
            DistanceMeters = request.DistanceMeters,
            TargetCarIds = request.TargetCarIds,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddSeconds(15)
        };

        _pendingInvites[inviteId] = invite;

        foreach (var targetCarId in request.TargetCarIds)
        {
            var targetConn = _server.Session.Connections.FirstOrDefault(c => c.Car?.Id == targetCarId);
            if (targetConn != null)
            {
                var raceType = _raceTypeRegistry.Get(request.RaceTypeId);
                var inviteEvent = new RaceInviteEvent(
                    invite.InviterCarId, invite.InviterName,
                    invite.RaceTypeId, raceType?.Name ?? request.RaceTypeId,
                    invite.DistanceMeters, inviteId);

                targetConn.SendEvent(RaceEventNames.InviteReceived, inviteEvent);
            }
        }

        _ = Task.Run(async () =>
        {
            await Task.Delay(TimeSpan.FromSeconds(15));
            HandleTimeout(inviteId);
        });
    }

    public void HandleResponse(int inviteId, bool accepted, AssettoServer.Server.Connection responder)
    {
        if (!_pendingInvites.TryRemove(inviteId, out var invite)) return;

        var inviterConn = _server.Session.Connections.FirstOrDefault(c => c.Car?.Id == invite.InviterCarId);

        if (accepted)
        {
            invite.AcceptedCarIds.Add(responder.Car?.Id ?? -1);

            if (inviterConn != null)
            {
                inviterConn.SendEvent(RaceEventNames.InviteResponse, new InviteResponseEvent(inviteId, true));
            }

            if (invite.AcceptedCarIds.Count > 0 && !invite.RacePrepared)
            {
                PrepareRace(invite);
            }
        }
        else
        {
            if (inviterConn != null)
            {
                inviterConn.SendEvent(RaceEventNames.InviteResponse, new InviteResponseEvent(inviteId, false));
            }
        }
    }

    private void PrepareRace(PendingInvite invite)
    {
        invite.RacePrepared = true;

        var participants = new List<int> { invite.InviterCarId };
        participants.AddRange(invite.AcceptedCarIds);

        var gridPositions = GridPositioner.CalculateGridPositions(_server, participants, invite.DistanceMeters);
        var (finishPos, finishDir) = FinishLineDetector.CalculateFinishLine(_server, gridPositions[0].Position, gridPositions[0].Rotation, invite.DistanceMeters);

        var session = new RaceSession
        {
            InviteId = invite.InviteId,
            RaceTypeId = invite.RaceTypeId,
            DistanceMeters = invite.DistanceMeters,
            ParticipantCarIds = participants,
            StartPos = gridPositions[0].Position,
            StartRot = gridPositions[0].Rotation,
            FinishLinePos = finishPos,
            FinishLineDir = finishDir,
            State = RaceState.Countdown
        };

        foreach (var carId in participants)
        {
            var conn = _server.Session.Connections.FirstOrDefault(c => c.Car?.Id == carId);
            session.Racers[carId] = new RacerState
            {
                CarId = carId,
                DriverName = conn?.PlayerName ?? $"Driver_{carId}",
                LastPos = gridPositions.First(g => g.CarId == carId).Position
            };
        }

        foreach (var carId in participants)
        {
            var conn = _server.Session.Connections.FirstOrDefault(c => c.Car?.Id == carId);
            if (conn != null)
            {
                var startEvent = new RaceStartEvent(invite.InviteId, gridPositions, finishPos, finishDir, invite.DistanceMeters);
                conn.SendEvent(RaceEventNames.RaceStarting, startEvent);
            }
        }

        _ = Task.Run(async () => await RunCountdown(session));
    }

    private async Task RunCountdown(RaceSession session)
    {
        for (int i = 3; i >= 1; i--)
        {
            await BroadcastToParticipants(session, RaceEventNames.Countdown, new CountdownEvent(i));
            await Task.Delay(1000);
        }

        session.State = RaceState.Racing;
        session.StartTime = DateTime.UtcNow;
        await BroadcastToParticipants(session, RaceEventNames.RaceStarted, new { });
        _ = Task.Run(() => RunRaceLoop(session));
    }

    private async Task RunRaceLoop(RaceSession session)
    {
        var raceType = _raceTypeRegistry.Get(session.RaceTypeId)!;
        var lastUpdate = DateTime.UtcNow;

        while (session.State == RaceState.Racing)
        {
            var now = DateTime.UtcNow;
            var deltaTime = (float)(now - lastUpdate).TotalSeconds;
            lastUpdate = now;

            session.ElapsedTime = (float)(now - session.StartTime).TotalSeconds;

            UpdateRacerPositions(session);

            raceType.OnRaceUpdate(session, deltaTime);

            var result = raceType.CheckFinishCondition(session);
            if (result != null)
            {
                await FinishRace(session, result);
                break;
            }

            await BroadcastRaceUpdate(session);
            await Task.Delay(100);
        }
    }

    private void UpdateRacerPositions(RaceSession session)
    {
        foreach (var carId in session.ParticipantCarIds)
        {
            var conn = _server.Session.Connections.FirstOrDefault(c => c.Car?.Id == carId);
            if (conn?.Car != null)
            {
                var car = conn.Car;
                if (session.Racers.TryGetValue(carId, out var racer))
                {
                    var currentPos = car.Position;
                    var lastPos = racer.LastPos;
                    var distance = Vector3.Distance(currentPos, lastPos);
                    racer.DistanceTraveled += distance;
                    racer.LastPos = currentPos;
                    racer.LastSpeed = car.SpeedKmh;
                }
            }
        }
    }

    private async Task FinishRace(RaceSession session, RaceFinishResult result)
    {
        session.State = RaceState.Finished;

        var finishEvent = new RaceFinishEvent(
            result.WinnerCarId,
            session.Racers[result.WinnerCarId].DriverName,
            result.Results);

        await BroadcastToParticipants(session, RaceEventNames.RaceFinished, finishEvent);
        _pendingInvites.TryRemove(session.InviteId, out _);
    }

    private async Task BroadcastRaceUpdate(RaceSession session)
    {
        var racers = session.Racers.Values.Select(r => new RacerInfo(
            r.CarId, r.DriverName, r.DistanceTraveled, r.LastSpeed,
            0, r.Points > 0 ? r.Points : null, r.Combo > 1 ? r.Combo : null)).ToList();

        var sorted = racers.OrderByDescending(r => r.DistanceTraveled).ToList();
        for (int i = 0; i < sorted.Count; i++) sorted[i].Position = i + 1;

        var update = new RaceUpdateEvent(session.ElapsedTime, racers);
        await BroadcastToParticipants(session, RaceEventNames.RaceUpdate, update);
    }

    private Task BroadcastToParticipants(RaceSession session, string eventName, object data)
    {
        var tasks = session.ParticipantCarIds.Select(carId =>
        {
            var conn = _server.Session.Connections.FirstOrDefault(c => c.Car?.Id == carId);
            if (conn != null) conn.SendEvent(eventName, data);
            return Task.CompletedTask;
        });
        return Task.WhenAll(tasks);
    }

    private void HandleTimeout(int inviteId)
    {
        if (_pendingInvites.TryRemove(inviteId, out var invite))
        {
            var inviterConn = _server.Session.Connections.FirstOrDefault(c => c.Car?.Id == invite.InviterCarId);
            if (inviterConn != null)
            {
                inviterConn.SendEvent(RaceEventNames.RaceCancelled, new RaceCancelEvent("Invite timed out"));
            }
        }
    }

    public void OnPlayerDisconnect(int carId)
    {
        // Aktif yarışlarda oyuncu çıkarsa iptal et
    }
}

public class PendingInvite
{
    public int InviteId { get; set; }
    public AssettoServer.Server.Connection InviterConnection { get; set; } = null!;
    public int InviterCarId { get; set; }
    public string InviterName { get; set; } = "";
    public string RaceTypeId { get; set; } = "";
    public float DistanceMeters { get; set; }
    public List<int> TargetCarIds { get; set; } = new();
    public List<int> AcceptedCarIds { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool RacePrepared { get; set; }
}