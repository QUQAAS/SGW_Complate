using System.IO;

namespace SGW.Complete.Server.CarSwap.Models;

public class CarCompatibilityData
{
    public string Model { get; set; } = "";
    public string Skin { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public float FrontTrack { get; set; }
    public float RearTrack { get; set; }
    public float WheelRadius { get; set; }
    public bool HasValidData { get; set; }

    public static CarCompatibilityData FromEntry(AssettoServer.Shared.EntryListEntry entry, IServer server)
    {
        var data = new CarCompatibilityData
        {
            Model = entry.Model,
            Skin = entry.Skin,
            DisplayName = $"{entry.Model} ({entry.Skin})"
        };

        var carPath = Path.Combine(server.ContentPath, "cars", entry.Model);
        data.TryLoadIniData(carPath);

        return data;
    }

    private void TryLoadIniData(string carPath)
    {
        try
        {
            var suspensionsPath = Path.Combine(carPath, "data", "suspensions.ini");
            var tyresPath = Path.Combine(carPath, "data", "tyres.ini");

            if (File.Exists(suspensionsPath))
            {
                var ini = File.ReadAllText(suspensionsPath);
                FrontTrack = ParseIniFloat(ini, "FRONT", "TRACK") ?? 1.5f;
                RearTrack = ParseIniFloat(ini, "REAR", "TRACK") ?? 1.5f;
            }

            if (File.Exists(tyresPath))
            {
                var ini = File.ReadAllText(tyresPath);
                WheelRadius = ParseIniFloat(ini, "TYRE_0", "RADIUS") ?? 0.33f;
            }

            HasValidData = FrontTrack > 0 && RearTrack > 0 && WheelRadius > 0;
        }
        catch
        {
            HasValidData = false;
        }
    }

    private float? ParseIniFloat(string content, string section, string key)
    {
        var lines = content.Split('\n');
        bool inSection = false;
        foreach (var line in lines)
        {
            var trimmed = line.Trim();
            if (trimmed.StartsWith('[') && trimmed.EndsWith(']'))
            {
                inSection = trimmed[1..^1].Equals(section, StringComparison.OrdinalIgnoreCase);
            }
            else if (inSection && trimmed.Contains('='))
            {
                var parts = trimmed.Split('=', 2);
                if (parts[0].Trim().Equals(key, StringComparison.OrdinalIgnoreCase))
                {
                    if (float.TryParse(parts[1].Trim(), out var val))
                        return val;
                }
            }
        }
        return null;
    }
}