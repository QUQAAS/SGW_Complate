using System.Text.Json;
using AssettoServer.Server;
using AssettoServer.Shared;
using SGW.Complete.Server.CarSwap.Events;
using SGW.Complete.Server.CarSwap.Models;

namespace SGW.Complete.Server.CarSwap;

public class CarSwapManager
{
    private readonly IServer _server;
    private readonly IPluginLogger _logger;
    private readonly EntryListManager _entryListManager;
    private readonly Dictionary<int, CarVisualState> _playerStates = new();
    private readonly Dictionary<string, WheelFitData> _fineTuneCache = new();

    public CarSwapManager(IServer server, IPluginLogger logger, EntryListManager entryListManager)
    {
        _server = server;
        _logger = logger;
        _entryListManager = entryListManager;
        LoadFineTunes();
    }

    public void HandleEvent(AssettoServer.Server.Connection connection, string eventName, object? data)
    {
        var carId = connection.Car?.Id ?? -1;

        switch (eventName)
        {
            case CarSwapEventNames.RequestCarList:
                HandleRequestCarList(connection, carId);
                break;
            case CarSwapEventNames.RequestSwap:
                HandleRequestSwap(connection, carId, data);
                break;
            case CarSwapEventNames.RequestReset:
                HandleRequestReset(connection, carId);
                break;
            case CarSwapEventNames.RequestFineTuneSave:
                HandleFineTuneSave(connection, carId, data);
                break;
            case CarSwapEventNames.RequestFineTuneLoad:
                HandleFineTuneLoad(connection, carId, data);
                break;
        }
    }

    private void HandleRequestCarList(AssettoServer.Server.Connection connection, int carId)
    {
        var car = connection.Car;
        if (car == null) return;

        var playerCarData = CarCompatibilityData.FromEntry(
            _server.EntryList.FirstOrDefault(x => x.Model == car.Model && x.Skin == car.Skin)
            ?? new EntryListEntry { Model = car.Model, Skin = car.Skin }, _server);

        var availableCars = _entryListManager.GetAvailableCars(playerCarData);

        var response = new CarListResponseEvent(availableCars, car.Model);
        connection.SendEvent(CarSwapEventNames.CarListResponse, response);
    }

    private void HandleRequestSwap(AssettoServer.Server.Connection connection, int carId, object? data)
    {
        if (data is not JsonElement json) return;

        var targetIndex = json.GetProperty("targetCarIndex").GetInt32();
        var targetModel = json.GetProperty("targetModel").GetString() ?? "";
        var targetSkin = json.GetProperty("targetSkin").GetString() ?? "";

        var car = connection.Car;
        if (car == null) return;

        var reservedSlot = _entryListManager.GetReservedSlot(targetModel);
        if (!reservedSlot.HasValue)
        {
            connection.SendEvent(CarSwapEventNames.Error, new ErrorEvent($"No reserved slot for {targetModel}"));
            return;
        }

        if (!_entryListManager.ClaimSlot(reservedSlot.Value, connection.PlayerName, targetSkin))
        {
            connection.SendEvent(CarSwapEventNames.Error, new ErrorEvent("Failed to claim slot"));
            return;
        }

        if (_playerStates.TryGetValue(carId, out var oldState) && oldState.IsSwapped)
        {
            _entryListManager.ReleaseSlot(oldState.EntryIndex);
        }

        var playerCarData = CarCompatibilityData.FromEntry(
            _server.EntryList.FirstOrDefault(x => x.Model == car.Model && x.Skin == car.Skin)
            ?? new EntryListEntry { Model = car.Model, Skin = car.Skin }, _server);

        var targetCarData = CarCompatibilityData.FromEntry(_server.EntryList[reservedSlot.Value], _server);
        var wheelFit = CalculateWheelFit(playerCarData, targetCarData);

        var cacheKey = $"{car.Model}_{targetModel}";
        if (_fineTuneCache.TryGetValue(cacheKey, out var fineTune))
        {
            wheelFit = fineTune;
        }

        var newState = new CarVisualState
        {
            PlayerCarId = carId,
            OriginalModel = car.Model,
            OriginalSkin = car.Skin,
            VisualModel = targetModel,
            VisualSkin = targetSkin,
            EntryIndex = reservedSlot.Value,
            WheelFitData = wheelFit,
            IsSwapped = true,
            SwapTime = DateTime.UtcNow
        };

        _playerStates[carId] = newState;

        var executedEvent = new SwapExecutedEvent(carId, targetModel, targetSkin, reservedSlot.Value, wheelFit);
        _server.EventManager.BroadcastEvent(CarSwapEventNames.SwapExecuted, executedEvent);
        BroadcastFullState();

        _logger.LogInformation($"Car swap: {connection.PlayerName} {car.Model} -> {targetModel} ({targetSkin})");
    }

    private WheelFitData CalculateWheelFit(CarCompatibilityData source, CarCompatibilityData target)
    {
        var fit = new WheelFitData();

        if (!source.HasValidData || !target.HasValidData) return fit;

        fit.FrontOffsetX = (target.FrontTrack - source.FrontTrack) / 2f;
        fit.RearOffsetX = (target.RearTrack - source.RearTrack) / 2f;
        fit.HeightOffset = target.WheelRadius - source.WheelRadius;
        fit.Scale = Math.Clamp(target.WheelRadius / source.WheelRadius, 0.95f, 1.05f);

        return fit;
    }

    private void HandleRequestReset(AssettoServer.Server.Connection connection, int carId)
    {
        if (_playerStates.TryGetValue(carId, out var state) && state.IsSwapped)
        {
            _entryListManager.ReleaseSlot(state.EntryIndex);

            state.IsSwapped = false;
            state.VisualModel = "";
            state.VisualSkin = "";
            state.EntryIndex = -1;
            state.WheelFitData = new WheelFitData();

            _server.EventManager.BroadcastEvent(CarSwapEventNames.SwapReset, new SwapResetEvent(carId));
            BroadcastFullState();

            _logger.LogInformation($"Car swap reset: {connection.PlayerName}");
        }
    }

    private void HandleFineTuneSave(AssettoServer.Server.Connection connection, int carId, object? data)
    {
        if (data is not JsonElement json) return;
        if (!_playerStates.TryGetValue(carId, out var state) || !state.IsSwapped) return;

        var fitData = JsonSerializer.Deserialize<WheelFitData>(json.GetRawText());
        if (fitData == null) return;

        var cacheKey = $"{state.OriginalModel}_{state.VisualModel}";
        _fineTuneCache[cacheKey] = fitData;
        SaveFineTuneToFile(cacheKey, fitData);

        connection.SendEvent(CarSwapEventNames.FineTuneSaved, new FineTuneSavedEvent(cacheKey, fitData));
    }

    private void HandleFineTuneLoad(AssettoServer.Server.Connection connection, int carId, object? data)
    {
        if (data is not JsonElement json) return;
        var cacheKey = json.GetProperty("cacheKey").GetString() ?? "";

        if (_fineTuneCache.TryGetValue(cacheKey, out var fitData))
        {
            connection.SendEvent(CarSwapEventNames.FineTuneLoaded, new FineTuneLoadedEvent(cacheKey, fitData));
        }
    }

    public void OnPlayerDisconnect(int carId)
    {
        if (_playerStates.TryGetValue(carId, out var state) && state.IsSwapped)
        {
            _entryListManager.ReleaseSlot(state.EntryIndex);
            _playerStates.Remove(carId);

            _server.EventManager.BroadcastEvent(CarSwapEventNames.SwapReset, new SwapResetEvent(carId));
            BroadcastFullState();
        }
    }

    private void BroadcastFullState()
    {
        var states = _playerStates.Values
            .Where(s => s.IsSwapped)
            .Select(s => new PlayerVisualStateEvent(s.PlayerCarId, s.VisualModel, s.VisualSkin, s.WheelFitData, true))
            .ToList();

        foreach (var conn in _server.Session.Connections)
        {
            foreach (var state in states)
            {
                conn.SendEvent(CarSwapEventNames.PlayerVisualState, state);
            }
        }
    }

    private void SaveFineTuneToFile(string key, WheelFitData data)
    {
        try
        {
            var path = Path.Combine(_server.BasePath, "plugins", "SGW_Complete", "finetunes");
            Directory.CreateDirectory(path);
            var file = Path.Combine(path, $"{key.Replace('/', '_')}.json");
            File.WriteAllText(file, JsonSerializer.Serialize(data, new JsonSerializerOptions { WriteIndented = true }));
        }
        catch { }
    }

    private void LoadFineTunes()
    {
        try
        {
            var path = Path.Combine(_server.BasePath, "plugins", "SGW_Complete", "finetunes");
            if (!Directory.Exists(path)) return;

            foreach (var file in Directory.GetFiles(path, "*.json"))
            {
                var key = Path.GetFileNameWithoutExtension(file);
                var json = File.ReadAllText(file);
                var data = JsonSerializer.Deserialize<WheelFitData>(json);
                if (data != null) _fineTuneCache[key] = data;
            }
        }
        catch { }
    }
}