using System;
using System.Collections.Concurrent;
using System.Text.Json;
using AssettoServer.Server;
using AssettoServer.Server.Plugins;
using AssettoServer.Shared.Plugins;
using Microsoft.Extensions.Logging;
using SGW.Complete.Server.CarSwap;
using SGW.Complete.Server.Race;
using SGW.Complete.Server.Stance;
using SGW.Complete.Server.SkinSwap;

namespace SGW.Complete.Server;

public class Plugin : IPlugin
{
    public string Name => "SGW.Complete";
    public string Version => "1.0.0";

    private IServer? _server;
    private IPluginLogger? _logger;

    private CarSwapManager? _carSwapManager;
    private RaceManager? _raceManager;
    private StanceSync? _stanceSync;
    private SkinSwapSync? _skinSwapSync;

    public void Initialize(IServer server, IPluginLogger logger)
    {
        _server = server;
        _logger = logger;

        _logger.LogInformation("╔══════════════════════════════════════╗");
        _logger.LogInformation("║   SÖNMEZ GAME WORLD - COMPLETE PLUGIN ║");
        _logger.LogInformation("║   Version: {Version}                    ║", Version);
        _logger.LogInformation("╚══════════════════════════════════════╝");

        var entryListManager = new EntryListManager(server, logger);
        entryListManager.Initialize();
        _carSwapManager = new CarSwapManager(server, logger, entryListManager);

        _raceManager = new RaceManager(server, logger);
        _stanceSync = new StanceSync(server, logger);
        _skinSwapSync = new SkinSwapSync(server, logger);

        RegisterGlobalEvents();

        _logger.LogInformation("All modules initialized successfully");
    }

    private void RegisterGlobalEvents()
    {
        var events = _server!.EventManager;

        events.OnClientEventReceived += (sender, e) =>
        {
            var eventName = e.EventName;

            if (eventName.StartsWith("SGW:CarSwap:"))
            {
                _carSwapManager?.HandleEvent(e.Connection, eventName, e.Data);
            }
            else if (eventName.StartsWith("SGW:Race:"))
            {
                _raceManager?.HandleEvent(e.Connection, eventName, e.Data);
            }
            else if (eventName.StartsWith("SGW:Stance:"))
            {
                _stanceSync?.HandleEvent(e.Connection, eventName, e.Data);
            }
            else if (eventName.StartsWith("SGW:SkinSwap:"))
            {
                _skinSwapSync?.HandleEvent(e.Connection, eventName, e.Data);
            }
        };

        _server.Session.ConnectionDisconnected += (sender, e) =>
        {
            var carId = e.Connection.Car?.Id ?? -1;
            _carSwapManager?.OnPlayerDisconnect(carId);
            _raceManager?.OnPlayerDisconnect(carId);
            _stanceSync?.OnPlayerDisconnect(carId);
            _skinSwapSync?.OnPlayerDisconnect(carId);
        };
    }

    public void Dispose()
    {
        _logger?.LogInformation("SGW.Complete plugin disposed");
    }
}