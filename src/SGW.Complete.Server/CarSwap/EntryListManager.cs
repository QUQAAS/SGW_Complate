using AssettoServer.Server;
using AssettoServer.Shared;
using SGW.Complete.Server.CarSwap.Models;

namespace SGW.Complete.Server.CarSwap;

public class EntryListManager
{
    private readonly IServer _server;
    private readonly IPluginLogger _logger;
    private readonly Dictionary<string, int> _modelToReservedIndex = new();

    public EntryListManager(IServer server, IPluginLogger logger)
    {
        _server = server;
        _logger = logger;
    }

    public void Initialize()
    {
        EnsureReservedSlots(3);
    }

    public void EnsureReservedSlots(int slotsPerModel)
    {
        var entryList = _server.EntryList;
        var modelsInUse = entryList.Select(e => e.Model).Distinct().ToList();

        foreach (var model in modelsInUse)
        {
            for (int i = 0; i < slotsPerModel; i++)
            {
                var key = $"{model}_reserved_{i}";
                if (!_modelToReservedIndex.ContainsKey(key))
                {
                    var entry = new EntryListEntry
                    {
                        Model = model,
                        Skin = "sgw_reserved",
                        DriverName = $"SGW_RESERVED_{model}_{i}",
                        Team = "SGW_Reserved",
                        Guid = Guid.NewGuid().ToString(),
                        BallastKg = 0,
                        Restrictor = 1.0f,
                        FixedSetup = false
                    };

                    entryList.Add(entry);
                    _modelToReservedIndex[key] = entryList.Count - 1;
                    _logger.LogInformation($"Reserved slot for {model}: index {entryList.Count - 1}");
                }
            }
        }
    }

    public int? GetReservedSlot(string model)
    {
        for (int i = 0; i < 10; i++)
        {
            var key = $"{model}_reserved_{i}";
            if (_modelToReservedIndex.TryGetValue(key, out var index))
            {
                var entry = _server.EntryList[index];
                if (entry.Skin == "sgw_reserved")
                    return index;
            }
        }
        return null;
    }

    public bool ClaimSlot(int entryIndex, string playerName, string skin)
    {
        if (entryIndex < 0 || entryIndex >= _server.EntryList.Count) return false;

        var entry = _server.EntryList[entryIndex];
        if (entry.Skin != "sgw_reserved") return false;

        entry.Skin = skin;
        entry.DriverName = playerName;
        entry.Team = "SGW_CarSwap";
        return true;
    }

    public void ReleaseSlot(int entryIndex)
    {
        if (entryIndex < 0 || entryIndex >= _server.EntryList.Count) return;

        var entry = _server.EntryList[entryIndex];
        if (entry.Team == "SGW_CarSwap")
        {
            entry.Skin = "sgw_reserved";
            entry.DriverName = $"SGW_RESERVED_{entry.Model}";
            entry.Team = "SGW_Reserved";
        }
    }

    public List<CarCompatibilityData> GetAvailableCars(CarCompatibilityData playerCar)
    {
        var result = new List<CarCompatibilityData>();
        var entryList = _server.EntryList;

        foreach (var entry in entryList)
        {
            if (entry.Team == "SGW_Reserved" || entry.Team == "SGW_CarSwap") continue;
            if (entry.Model == playerCar.Model) continue;

            var data = CarCompatibilityData.FromEntry(entry, _server);
            result.Add(data);
        }

        return result;
    }
}