using System.Text.Json;
using AssettoServer.Server;
using AssettoServer.Shared;
using SGW.Complete.Server.Race.Events;
using SGW.Complete.Server.Race.RaceTypes;

namespace SGW.Complete.Server.Race;

public class RaceManager
{
    private readonly IServer _server;
    private readonly IPluginLogger _logger;
    private readonly RaceTypeRegistry _raceTypeRegistry;
    private readonly InviteSystem _inviteSystem;

    public RaceManager(IServer server, IPluginLogger logger)
    {
        _server = server;
        _logger = logger;
        _raceTypeRegistry = new RaceTypeRegistry();
        _raceTypeRegistry.Register(new SprintRace());
        _raceTypeRegistry.Register(new EnduranceRace());
        _raceTypeRegistry.Register(new CannonballRace());
        _raceTypeRegistry.Register(new DriftBattleRace());

        _inviteSystem = new InviteSystem(server, logger, _raceTypeRegistry);
    }

    public void HandleEvent(AssettoServer.Server.Connection connection, string eventName, object? data)
    {
        switch (eventName)
        {
            case RaceEventNames.RequestRaceInvite:
                if (data is JsonElement json)
                {
                    var request = JsonSerializer.Deserialize<RaceInviteRequest>(json.GetRawText());
                    _inviteSystem.SendInvite(connection, request!);
                }
                break;

            case RaceEventNames.RespondInvite:
                if (data is JsonElement respJson)
                {
                    var inviteId = respJson.GetProperty("inviteId").GetInt32();
                    var accepted = respJson.GetProperty("accepted").GetBoolean();
                    _inviteSystem.HandleResponse(inviteId, accepted, connection);
                }
                break;

            case RaceEventNames.RequestRaceTypes:
                var types = _raceTypeRegistry.GetAll().Select(rt => new RaceTypeInfo(
                    rt.Id, rt.Name, rt.Description, rt.DefaultDistances)).ToList();
                connection.SendEvent(RaceEventNames.RaceTypesList, new { types });
                break;
        }
    }

    public void OnPlayerDisconnect(int carId)
    {
        _inviteSystem.OnPlayerDisconnect(carId);
    }
}

public class RaceTypeRegistry
{
    private readonly Dictionary<string, IRaceType> _types = new();

    public void Register(IRaceType type) => _types[type.Id] = type;
    public IRaceType? Get(string id) => _types.TryGetValue(id, out var t) ? t : null;
    public IEnumerable<IRaceType> GetAll() => _types.Values;
}