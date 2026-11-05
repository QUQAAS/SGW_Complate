using System.Numerics;
using AssettoServer.Server;

namespace SGW.Complete.Server.Race;

public static class GridPositioner
{
    public static List<GridPosition> CalculateGridPositions(IServer server, List<int> carIds, float raceDistance)
    {
        var positions = new List<GridPosition>();

        Vector3 startPos;
        Quaternion startRot;

        var track = server.Track;
        if (track?.PitExit != null)
        {
            startPos = track.PitExit.Position;
            startRot = track.PitExit.Rotation;
        }
        else
        {
            var firstCar = server.Session.Connections.FirstOrDefault(c => c.Car?.Id == carIds[0]);
            startPos = firstCar?.Car?.Position ?? Vector3.Zero;
            startRot = firstCar?.Car?.Rotation ?? Quaternion.Identity;
        }

        float laneWidth = 14f;
        if (track?.FastLane != null && track.FastLane.Count > 10)
        {
            laneWidth = 14f;
        }

        float spacing = laneWidth / Math.Max(1, carIds.Count);
        Vector3 right = Vector3.Transform(Vector3.UnitX, startRot);

        for (int i = 0; i < carIds.Count; i++)
        {
            float offset = (i - (carIds.Count - 1) / 2f) * spacing;
            var pos = startPos + right * offset;
            pos.Y += 0.1f;

            positions.Add(new GridPosition(carIds[i], pos, startRot));
        }

        return positions;
    }
}