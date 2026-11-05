using System.Numerics;
using AssettoServer.Server;

namespace SGW.Complete.Server.Race;

public static class FinishLineDetector
{
    public static (Vector3 Position, Vector3 Direction) CalculateFinishLine(
        IServer server, Vector3 startPos, Quaternion startRot, float distanceMeters)
    {
        var track = server.Track;

        if (track?.FastLane != null && track.FastLane.Count > 0)
        {
            var spline = track.FastLane;
            float accumulated = 0;
            Vector3 lastPoint = spline[0];

            for (int i = 1; i < spline.Count; i++)
            {
                var segment = spline[i] - lastPoint;
                float segLen = segment.Length();

                if (accumulated + segLen >= distanceMeters)
                {
                    float remain = distanceMeters - accumulated;
                    float t = remain / segLen;
                    var finishPos = lastPoint + segment * t;
                    var finishDir = Vector3.Normalize(segment);

                    var right = Vector3.Transform(Vector3.UnitX, Quaternion.LookRotation(finishDir, Vector3.UnitY));
                    finishPos += right * 6f;
                    finishPos.Y += 0.05f;

                    return (finishPos, finishDir);
                }

                accumulated += segLen;
                lastPoint = spline[i];
            }

            var finalDir = Vector3.Normalize(spline[^1] - spline[^2]);
            var finalPos = spline[^1] + finalDir * (distanceMeters - accumulated);
            var rightFinal = Vector3.Transform(Vector3.UnitX, Quaternion.LookRotation(finalDir, Vector3.UnitY));
            finalPos += rightFinal * 6f;
            finalPos.Y += 0.05f;

            return (finalPos, finalDir);
        }

        var forward = Vector3.Transform(Vector3.UnitZ, startRot);
        var finishPosition = startPos + forward * distanceMeters;
        finishPosition.Y += 0.05f;

        return (finishPosition, forward);
    }
}