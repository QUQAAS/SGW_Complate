using System.Text.Json;
using AssettoServer.Server;
using AssettoServer.Shared;
using Microsoft.Extensions.Logging;

namespace SGW.Complete.Server.SkinSwap;

public class SkinSwapSync
{
    private readonly IServer _server;
    private readonly IPluginLogger _logger;

    public SkinSwapSync(IServer server, IPluginLogger logger)
    {
        _server = server;
        _logger = logger;
    }

    public void HandleEvent(AssettoServer.Server.Connection connection, string eventName, object? data)
    {
        if (eventName == "SGW:SkinSwap:Change")
        {
            var json = JsonSerializer.Serialize(data);
            foreach (var conn in _server.Session.Connections)
            {
                if (conn != connection)
                {
                    conn.SendEvent("SGW:SkinSwap:Change", json);
                }
            }
        }
    }

    public void OnPlayerDisconnect(int carId) { }
}